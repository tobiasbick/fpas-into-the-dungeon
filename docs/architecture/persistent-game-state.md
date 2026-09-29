# Persistent game state

Each world owns exactly one server-side savegame. Connecting establishes a
transport session only; the player then explicitly starts a new game or loads
the existing save. Saving happens only through the active game's system menu.
There is no autosave or implicit save on disconnect or quit.

## Ownership and lifecycle

The server owns the authoritative `GameState`, the selected world, and the
savegame. The client receives only view-specific projections and never stores
gameplay state. A new session starts at the world's stable spawn without
deleting an existing save. Loading installs a saved state only after the whole
document has been decoded and validated against the selected world's current
metadata and game-state invariants.

A successful load returns `Loaded(State, View)`. The view retains the exact
map used for validation when indoors and has no interior map outdoors. The
server installs that geometry with the state and reuses it for the session.
The handshake discards both values after checking save availability; an
explicit load reads and validates the save again.

The running rules use `ValidateGameState(View, State)` for local state,
equipment, identity uniqueness, and geometry checks against the supplied
current map. Full placement checks belong to
`Dungeon.Areas.ValidateSavedGame(Metadata, State, Maps)`, which loads no maps.
The save layer supplies no maps before a first visit and the initial map after
it for the current single-dungeon model. Both decoding and writing use this
full check: an unvisited game has no dungeon entities; a visited dungeon has
exactly its original entity identities and kinds, with their mutable state.
Missing or unknown entities remain invalid even while the player is outdoors.
The pure validator already supports multiple supplied visited maps, in any
order, with exactly one map per visit. `Dungeon.Areas.Validation` checks
placement identity and kind, opponent origin areas, floor-item destinations,
and discovery dimensions against the appropriate map, including areas that
the player currently does not occupy. Items may move between visited areas;
opponents remain in their origin area. Duplicate identities and occupied item
fields are rejected by the shared state validator. The current view reuses
the supplied current map. Connecting multiple areas to world storage remains
part of the [14a implementation plan](../plans/14a-generated-dungeons.md).

The post-`hello` welcome reports whether a loadable save exists and whether an
invalid save was removed while establishing the session. In the latter case,
the client explains the removal, offers only `New game`, and remains in the
pre-game state. Until the client selects `New game` or `Load`, the server
rejects movement, turning, transitions, viewport projection, and saving. A
reconnect repeats this choice.

## Savegame contract

Savegame format `7` is an exact JSON object containing the selected world ID,
current area kind and stable area ID, an explicit player-position variant, and
the return location, `visited_areas`, persistent discovered-area state, the complete
server-owned item state, the player's health, every opponent, and the
dice generator state. Outdoor positions use signed world coordinates.
First-person positions contain the local field coordinate and cardinal facing;
their return location contains the exact outdoor area and coordinate.

`visited_areas` is a strictly sorted array of nonempty dungeon identities with
no duplicates. A new game starts with an empty list, no items, and no opponents.
First entry materializes the map's placements and records the visit. Loading
restores the list and entities together; revisiting never recreates taken items
or defeated opponents. Interior discovery and dungeon entities may reference
only visited areas. Saves without the required field are rejected; the format
remains 7 as this feature branch's single savegame version bump.

Outdoor discovery is stored sparsely as canonically ordered signed chunk
records. Each record contains `chunk_x`, `chunk_y`, and exactly 128 rows of 128
bits. Interior discovery is stored as canonically ordered records containing a
stable `area_id`, dimensions, and a matching bit mask. `0` means undiscovered
and `1` means discovered. Currently visible and remembered are not stored as
separate states: visibility is derived after start or load, and remembered
means discovered but not currently visible.

Every item record contains its stable ID, kind, and location. The current item
location is either a validated field in a visited dungeon or the player's
inventory. After the first visit, the fixed Ancient coin must occur exactly once, so malformed,
missing, duplicate, unknown, or misplaced item state rejects the complete
savegame. There is no separate client inventory file.

Each opponent record contains its stable ID, kind, area, field, health, and
alert status. A destroyed opponent stays recorded with zero health. Health
outside its range, an unknown or missing opponent, an opponent on a wall,
and a dice state outside `0 <= state < 2^31` invalidate the save. Saving
during a fight is allowed; the combat log and a defeat are never saved.

Rendered rows, visible windows, status and message text, pending requests,
overlays, chunk caches, and generated chunk contents are deliberately absent.
The generated world remains in `world.json` and the chunk files.

The single save path is:

```text
worlds/<world-id>/saves/default.json
```

Writes validate the complete state, including discovery ordering, dimensions,
known interior identities, and non-empty masks, then atomically replace
`default.json`. A failed validation or replacement leaves the previous valid
save intact. No backup slot, migration, legacy reader, or stale fallback is
kept.

During development, malformed, incompatible, wrong-world, or otherwise invalid
saves are deleted and then treated as missing. Only `default.json` may be
removed; world metadata, chunks, configuration, and unrelated files remain
untouched. I/O failures remain errors and are not treated as missing or invalid
data.

## Client preferences

Client persistence is limited to its endpoint and presentation preferences in
`config/client.toml`. Context- and message-panel visibility survive a restart
and are written atomically when changed. Command-line endpoint overrides apply
only to the current process. Fog of War and discovered-area persistence belong
exclusively to the server-owned savegame. A new game begins without previously
discovered locations, while an existing save remains unchanged until an
explicit confirmed save replaces it.
