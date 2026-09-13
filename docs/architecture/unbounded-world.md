# Unbounded outdoor world

The first outdoor region is practically unbounded. The server generates and
persists it in fixed 128 by 128 cell chunks while clients receive only bounded
visible windows. Chunks are an internal storage and cache seam, never a player
visible transition.

## Ownership and modules

`Dungeon.Game` owns signed world coordinates, terrain layers, deterministic
generation, passability, and player movement. A world cell separates base
terrain (`grass`, `sand`, `rock`, or `water`) from an optional feature and a
water classification. This lets paths and later bridges remain independent of
the material below them.

`Dungeon.World` owns world and chunk files, validation, missing-chunk creation,
coordinate lookup, visible-window composition, prefetching, and a bounded LRU
chunk cache. The server selects a world and carries the resulting session. The
protocol and client never expose chunk coordinates, generation inputs, or
passability.

## Coordinates

World coordinates and chunk coordinates are signed integers. Conversion uses
mathematical floor division, not truncation toward zero:

```text
world -129 -> chunk -2, local 127
world -128 -> chunk -1, local   0
world   -1 -> chunk -1, local 127
world    0 -> chunk  0, local   0
world  127 -> chunk  0, local 127
world  128 -> chunk  1, local   0
```

These coordinates are authoritative and remain stable across cache eviction,
server restart, and client reconnect. A visible window has its own world origin
and may intersect any number of chunks.

## Persistent files

Each selected world is stored below the runtime data root:

```text
worlds/<world-id>/
├── world.json
└── chunks/
    └── x_<signed-x>/
        └── y_<signed-y>.json
```

World format version `2` records the id, seed, generator version, chunk size,
spawn coordinate, stable outdoor and dungeon identities and labels, and the
initial entrance identity, coordinate, and target in `world.json`. A chunk file
records its format version, world id, coordinates, and three 128-row layers.
Each row uses one compact character per cell for base terrain, feature, or water
classification.

World ids contain only letters, digits, hyphens, and underscores. Unsupported
versions, mismatched ids or coordinates, incorrect dimensions, malformed rows,
unknown codes, and an invalid spawn fail with a useful error. Existing invalid
files are never repaired or overwritten.

Metadata and generated chunks use same-directory atomic replacement. Generation
depends only on the seed, generator version, and absolute coordinates, so two
simultaneous requests produce identical complete files regardless of which
atomic write wins.

## Generation and visible cells

Generator version 5 evaluates several smooth deterministic integer fields from
the seed and absolute world coordinate. Very broad and regional noise establish
continentalness; regional elevation and coast detail shape land and water at
smaller scales. A ridge transform raises narrow connected land bands above sea
level instead of leaving every low-elevation region as disconnected islands.
Separate ruggedness, moisture, and vegetation fields select mountain ranges,
deserts, connected forest interiors, loose tree-lined forest edges, and
occasional individual trees only after the land shape exists.

Seed-varied periodic basins combine elliptical distance with smooth local noise
to produce larger finite lakes with irregular shorelines without attempting
global connectivity analysis over an infinite plane. Slowly changing
world-coordinate offsets produce rivers and paths that continue across chunk
edges. New-world creation searches deterministic candidates for a naturally
generated, temperate, non-mountainous spawn whose surrounding 17 by 17 cells
are traversable. Trees or forest are present within the initial visible area,
and another generated landscape is reachable within 512 horizontal and 256
vertical cells. It also requires a clear natural entrance candidate connected
by exactly three traversable cardinal steps. Generation composes only the
selected entrance feature over that cell and otherwise never overwrites terrain
around the spawn.

The `dungeon-world-preview` tool samples final terrain or continentalness,
land, elevation, ruggedness, moisture, vegetation, lake-shape, and land-bridge
fields around that spawn.
Its field values are normalized from 0 through 1000, making generator changes
visible without coupling the client or protocol to generation internals.

The server reduces each composed cell to one client-safe visible code: `g`
grass, `t` tree, `f` forest, `d` desert, `m` mountain, `o` sea, `r` river, `l`
lake, `p` path, and `e` entrance. These codes carry presentation meaning only.
The richer base, feature, water-classification, entrance relationship, and
passability values remain server-owned.

## Loading and cache policy

For each visible window the server computes every intersecting chunk. It also
loads a one-chunk margin on all sides for near-future movement or resizing. The
margin is not included in the returned window. A session retains at most the
configured number of chunks and evicts the least recently used chunk first.
Requests whose visible range and margin cannot fit the configured cache fail
instead of returning a partial window.

The current runtime defaults to a 64-chunk cache and a maximum requested visible window
of 240 by 120 world cells. The server rejects nonpositive sizes and clamps
larger requests. These values are server configuration, not wire assumptions.

## Deliberately deferred

This slice does not define mutable terrain, persistent player savegames,
settlements, additional locations, bridges, movement costs, weather, seasons,
world time, interior or dungeon geometry, raycasting, or simulated erosion and
hydrology.
