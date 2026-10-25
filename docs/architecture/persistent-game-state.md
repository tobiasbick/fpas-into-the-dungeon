# Persistent game state

Each world owns exactly one server-side savegame. Connecting establishes a
transport session only; the player then selects an existing world and chooses Continue or Start over,
or creates a world with a server-allocated unique identity. Saving happens only through the active game's system menu.
There is no autosave or implicit save on disconnect or quit.

## Ownership and lifecycle

The server owns the authoritative `GameState`, the selected world, and the
savegame. The client receives only view-specific projections and never stores
gameplay state. Start over starts at the world's stable spawn without
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
The save layer reads every visited dungeon and generated settlement through
`Dungeon.World.Areas`, resolves Hearthmoor from code and supplies those maps.
Both loading and writing use this full check: an unvisited game has no dungeon entities; a visited dungeon has
exactly its original entity identities and kinds, with their mutable state.
A visited merchant additionally requires its five original stock records;
a rewarded quest retains its two unique reward items. Items can be held by a
visited merchant regardless of which visited dungeon, shop or quest supplied
their origin. The bounded coin balance is saved independently of this ledger.
Missing or unknown entities remain invalid even while the player is outdoors.
The pure validator accepts the supplied visited maps in any order, with exactly
one map per visit. `Dungeon.Areas.Validation` checks
placement identity and kind, opponent origin areas, floor-item destinations,
and discovery dimensions against the appropriate map, including areas that
the player currently does not occupy. Items may move between visited areas;
opponents remain in their origin area. Duplicate identities and occupied item
fields are rejected by the shared state validator. The current view reuses
the supplied current map.

The protocol-21 welcome supplies a bounded catalog with world identities,
original parameters, compatibility, save classifications and creation defaults.
Continue loads a valid explicit save or starts at spawn when no save exists.
An incompatible or unreadable save rejects Continue and remains on disk. Start
over keeps that save; `overwrite_save` is required to replace any existing save.
An ordinary `save_game` against an existing path returns `overwrite_required`.
Until a game begins, movement, transitions, viewport projection and saving are
rejected. Returning to selection with unsaved progress requires `list_worlds`
with an explicit discard flag. Catalog/storage preparation failures retain the
installed game, geometry and dirty state. No selection operation saves progress.

## Savegame contract

Savegame format `15` is an exact JSON object containing the selected world ID,
current area kind and stable area ID, an explicit player-position variant, and
the return location, `visited_areas`, persistent discovered-area state, the complete
server-owned item state, NPC meeting records, the accepted quest/objective and
rewarded outcome, the player's health and required integers `coins` and
`world_minutes`, every opponent, the
dice generator state, and the `progression` object with the two cumulative
skill experience counters (see [progression](progression.md)). Outdoor positions use signed world coordinates.
The clock is bounded from 0 through 1,000,000,000 minutes and starts at 480.
Continue restores it exactly; disconnected time does not advance it. See
[time and rest](time-and-rest.md).
First-person positions contain the local field coordinate and cardinal facing;
their return location contains the outdoor area and the exact entrance site of
the dungeon's region.

`visited_areas` is a strictly sorted array of canonical dungeon level identities
(`<world>:dungeon:<rx>:<ry>:<level>`) and settlement identities
(`<world>:settlement:home` or `<world>:settlement:<sx>:<sy>`), with no duplicates. A visited level deeper than 0
requires the level above it in the same dungeon to be visited, and all visited
levels of one dungeon must store the same depth and name. A new game starts with an empty list, no items, no opponents, and Mara
with `has_met_player = false`.
First entry materializes the map's placements and records the visit. Loading
restores the list and entities together; revisiting never recreates taken items
or defeated opponents. Interior discovery and dungeon entities may reference
only visited areas. Saves without a required field are rejected. Merchant-held
locations have exactly `{kind:"merchant",npc_id}`. Each merchant's five stock
origins remain required after selling, dropping or consuming its goods.
NPC rosters are complete and canonically ordered for every visited settlement;
immutable names/positions remain in settlement definitions. Unknown, missing
or unvisited NPC records are invalid. The authored settlement map is resolved
from code, never read or generated as a level file. Dialogue/trade frames,
page indexes and connection revisions are absent. See [economy](economy.md).
The version is checked before the
payload, so an obsolete save reports its version. Format 13 and older saves
remain intact and cannot be continued; recreate progress explicitly
through Start over.

Outdoor discovery is stored sparsely as canonically ordered signed chunk
records. Each record contains `chunk_x`, `chunk_y`, and exactly 128 rows of 128
bits. Interior discovery is stored as canonically ordered records containing a
stable `area_id`, dimensions, and a matching bit mask. `0` means undiscovered
and `1` means discovered. Currently visible and remembered are not stored as
separate states: visibility is derived after start or load, and remembered
means discovered but not currently visible.

Every item record contains its stable ID, kind, and location. The current item
location is a validated field in a visited dungeon, carried inventory, a worn
slot, the terminal consumed state or the returned compass state. Only `healing_potion` may be consumed:
its location must be exactly `{"kind":"consumed"}`, with no payload fields.
The ID and kind stay in the item array, even after consumption in another area.
Consumed records do not count toward the 64 carried/worn limit and are not
projected. The returned compass similarly retains its original ID/kind and its
quest identity without occupying a field or capacity. Every item placement of every visited dungeon must occur exactly
once; a rewarded quest also requires exactly its two reward potion records.
Malformed, missing, duplicate, unknown, or misplaced item state
rejects the complete savegame. There is no separate client inventory file.
Revisit and save/load retain terminal records and never create replacements.
The pure healing rule marks the selected carried potion consumed before the
hostile phase. Accepted use marks progress
unsaved and retains the last successful save timestamp. Rejections, including
failed response preparation, preserve the installed session. The rule never
saves or deletes files, including when the resulting turn ends in defeat.

Each opponent record contains its stable ID, kind, area, field, health, and
alert status. A destroyed opponent stays recorded with zero health. Health
is bounded by kind: `restless_skeleton` accepts 0..12, `giant_rat` accepts 0..6.
Unknown kind strings are rejected. Health
outside its range, an unknown or missing opponent, an opponent on a wall,
and a dice state outside `0 <= state < 2^31` invalidate the save. Saving
during a fight is allowed; the combat log and a defeat are never saved.

Rendered rows, visible windows, status and message text, pending requests,
overlays, chunk caches, and generated chunk contents are deliberately absent.
The generated world remains in `world.json`, the chunk files, and the immutable
dungeon level files.

The single save path is:

```text
worlds/<world-id>/saves/default.json
```

Loading runs three phases: decode the save's self-contained fields
(`DecodeSaveGameState`), read every visited area once (`Dungeon.World.Areas.ReadVisitedAreas`),
and validate the state against those maps (`ValidateSavedGame`). Save and load
never generate a level or settlement definition. Writes run the same validation, including discovery
ordering, dimensions, known interior identities, and non-empty masks, then
atomically replace `default.json`. Failures are typed (`PersistenceFailure`):
invalid state, an area-data failure, or I/O. A failed validation or replacement leaves the previous valid
save intact. No backup slot, migration, legacy reader, or stale fallback is
kept.

Malformed, incompatible, wrong-world or otherwise invalid saves return
`Invalid(Reason)` without writes or deletion. A missing, invalid or unreadable
referenced level is a world-data or storage error; the save is kept and Continue
is rejected (`world_data_error`, `storage_error`). The catalog remains usable.
A wrong path type is an I/O failure, including a file occupying the `saves`
directory. Only explicit replacement or explicit local maintenance removes
saved data. See the [level storage contract](dungeon-level-storage.md).

## Cross-area resume and rewind

Checkpoint 10 verifies storage with the final generated contents. The same
original potion ID survives pickup, transfer, dropping and consumption in a
second dungeon, including optional slot 5 when slot 4 is absent. Terminal
consumed items and defeated opponents must remain present exactly once.
Complete-state comparisons after reopening a world cover health, RNG,
discovery, visits, item locations and opponent state, including a save made
with a living alerted rat.

Revisit does not restore terminal records. Start over materializes original
floor placements and full dormant opponents for a new game while preserving
the previous explicit save and level bytes. Loading an earlier explicit save
rewinds the mutable state and visited list; a later-created level file is
reused and materialized only when that earlier game enters it.

Storage tests use controlled poses and one-health opponents to isolate these
rules. Checkpoint 11 adds a natural TCP play sequence with world creation,
equipment, both opponent kinds and potion use, without preparing player health
or opponent state. Disconnecting after unsaved consumption and continuing
replays the same potion turn byte for byte, including combat facts and dice.
An explicit earlier save can restore the carried potion and living opponents
after later progress was saved. Start over and overwrite/discard guards retain
the earlier file until replacement is explicitly requested.

Separate session cases cover full inventory then consume/pickup, defeat on a
later turn after drinking, failed loads, preparation errors and failed sends.
TCP rejection cases retain health, items, RNG and the old explicit save. A real
listener test stops with an active dirty game and confirms that shutdown keeps
the save bytes. No autosave, migration, format change or additional cache is
introduced by these verification cases.

The final persistence smoke benchmark retains consumed records alongside fresh
floor finds at 1, 10 and 100 visits, and verifies the complete encoded state
after every load. See [persistence measurements](persistence-measurements.md)
for the baseline comparison, timing boundaries and compiler identity.

## Client preferences

Client persistence is limited to its endpoint and presentation preferences in
`config/client.toml`. Context- and message-panel visibility survive a restart
and are written atomically when changed. Command-line endpoint overrides apply
only to the current process. Fog of War and discovered-area persistence belong
exclusively to the server-owned savegame. A new game begins without previously
discovered locations, while an existing save remains unchanged until an
explicit confirmed save replaces it.
