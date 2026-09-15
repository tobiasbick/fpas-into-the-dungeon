# Exploration and map

Exploration is authoritative, persistent game state. The server derives what
is currently visible from the current area, player position, and interior
facing, merges visible fields into the discovered area after accepted game
events, and sends only client-safe projections. The client owns only the map
overlay's presentation state.

## Ownership and representation

`Dungeon.Exploration.Model` defines persistent discovery masks and the three
knowledge states. Outdoor discovery is sparse: one boolean mask is retained
for each signed 128 by 128 chunk containing at least one discovered field.
Interior discovery uses a stable area ID and one mask with the authoritative
area dimensions. Both collections are unique and canonically ordered before
they can be saved.

Discovery masks contain no terrain, generated chunks, player position,
currently visible fields, or rendered cells. A field is classified when a
projection is built:

- `visible` means it is inside the currently derived sight field;
- `remembered` means it was discovered earlier but is not currently visible;
- `undiscovered` means it is in neither set.

`Dungeon.Exploration` owns sight calculation, discovery updates, and field
classification. Low-level mask validation lives beside the representation so
the game and persistence layers can enforce the same invariants without
depending on server integration. `Dungeon.Game` retains exploration in every
authoritative state transformation. `Dungeon.World.Savegame` owns only the
exact persistence representation. The server connects these modules to the
session lifecycle and creates the client-safe projections.

## Visibility lifecycle

A new game starts with empty discovery. Before the first state is sent, the
server reveals the current outdoor sight circle. Loading validates persisted
discovery and then derives the current sight again. An accepted move, interior
step, 90-degree turn, or area transition derives sight from the resulting
authoritative state and merges it into discovery before the next projection is
sent. A rejected action changes neither discovery nor current visibility.

Outdoor sight is a Euclidean circle with radius eight world fields. Terrain
does not occlude it. Interior sight has a maximum range of eight fields and a
90-degree cardinal field of view. Line of sight includes the first blocking
wall and excludes fields behind it. Currently visible fields are derived and
are never persisted.

## Projection and information boundary

Protocol version 6 represents knowledge with one code per projected field:
`u` for undiscovered, `r` for remembered, and `v` for visible. Terrain and
interior row data use `?` wherever knowledge is `u`. The primary outdoor view
and the first-person geometry therefore cannot disclose a hidden field to the
client. The client styles `v` normally, dims `r`, and renders `u` as dark fog.

The exploration-map request names an origin and a positive window size. The
server limits a window to 240 by 120 fields and bounds signed origins so adding
the dimensions cannot overflow. Outdoor origins may address any signed world
coordinate. Interior windows use the same rectangular response contract;
fields outside the finite current floor are returned as undiscovered `?`
padding. Only the current area's map can be requested.

A map request is read-only. It does not move the player, update discovery, or
load or generate unknown terrain. For an outdoor field, the server obtains
terrain only after discovery proves that the field may be disclosed. This
keeps overlay panning, viewport changes, and terminal resizing outside the
discovery lifecycle and prevents exploring the world by requesting distant
windows.

## Client overlay

The client derives the requested overlay size using the responsive layout in
[client UI](../product/client-ui.md#exploration-map), clamped to at least one
field and to the protocol maximum. Requested dimensions remain separate from
the last complete projection. One terminal cell represents one area field. The first request and
`Home` center this window on the authoritative player position. WASD and the
arrow keys move its desired origin by one field; `M` and `Escape` close it.

Only one map request is in flight, including across closing and reopening the
overlay. Further pan input updates the desired origin
and is coalesced into the next request after the response arrives. Until the
first response the overlay displays `Loading map...`. During a later request it
keeps the previous valid projection and displays `Updating map...` in the
status view so the overlay retains its size and position; a
recoverable rejection also keeps that projection and reports the error in the
status view. Overlay input never becomes a movement or transition intention.

## Persistence

Savegame format 2 stores accumulated discovery in the authoritative game
snapshot. Outdoor masks are records containing signed `chunk_x`, `chunk_y`,
and exactly 128 strings of 128 `0` or `1` characters. Interior records contain
`area_id`, `width`, `height`, and exactly one equally sized `0`/`1` row per
field row. Missing, extra, duplicate, unordered, empty, malformed, unknown, or
wrong-sized records invalidate the complete save.

There is no format-1 reader or migration. An obsolete or invalid development
save follows the existing removal path and only the selected world's
`saves/default.json` is deleted. Explicit atomic saving is the only operation
that persists newly discovered fields.
