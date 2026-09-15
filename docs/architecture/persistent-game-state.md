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

The post-`hello` welcome reports whether a loadable save exists and whether an
invalid save was removed while establishing the session. In the latter case,
the client explains the removal, offers only `New game`, and remains in the
pre-game state. Until the client selects `New game` or `Load`, the server
rejects movement, turning, transitions, viewport projection, and saving. A
reconnect repeats this choice.

## Savegame contract

Savegame format `2` is an exact JSON object containing the selected world ID,
current area kind and stable area ID, an explicit player-position variant, and
the return location, plus persistent discovered-area state. Outdoor positions
use signed world coordinates.
First-person positions contain the local field coordinate and cardinal facing;
their return location contains the exact outdoor area and coordinate.

Outdoor discovery is stored sparsely as canonically ordered signed chunk
records. Each record contains `chunk_x`, `chunk_y`, and exactly 128 rows of 128
bits. Interior discovery is stored as canonically ordered records containing a
stable `area_id`, dimensions, and a matching bit mask. `0` means undiscovered
and `1` means discovered. Currently visible and remembered are not stored as
separate states: visibility is derived after start or load, and remembered
means discovered but not currently visible.

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
