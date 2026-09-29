# Generated dungeons

Stage 14a replaces the single hand-authored dungeon with generated ones. The
outdoor world gains rare, deterministic dungeon entrances, and each entrance
leads to a dungeon whose geometry is generated from the world seed and the
entrance region when it is needed.

The hand-authored initial dungeon is removed together with its stone tablet,
Mara, and the complete dialogue feature (rules, protocol messages, client
overlay, and tests). NPCs and dialogue return with settlements in stage 15.
Mara was the only way to heal; until consumables arrive in stage 14b, every
accepted outdoor step restores one health point.

Generation stays deterministic and server-owned. Names, stories, and LLM
content remain outside this stage.

## Entrance regions and sites

- The outdoor world is divided into square **entrance regions** of
  `dungeon_region_chunks` by `dungeon_region_chunks` chunks (default 4, that is
  512 by 512 fields, allowed 1 through 16). Region coordinates are the floor
  division of a world coordinate by the region size in fields.
- The region size is a world parameter: `server.toml` supplies the value for
  new worlds, the world metadata stores it at creation, and an existing world
  keeps it regardless of later configuration changes.
- The **spawn region** is the region containing the spawn. Its entrance site is
  the **spawn entrance**, found exactly as the initial entrance is today: three
  traversable steps from the spawn, so it is in sight at the start of a game.
- Every other region has one **candidate field** derived from the world seed
  and the region coordinate, at least 16 fields away from the region border.
  The candidate becomes the region's **entrance site** only when its natural
  cell is walkable land without water or another feature and differs from the
  spawn entrance; otherwise the region has no dungeon.
- Entrances are terrain features of their chunks. A region is a whole number of
  chunks, so a chunk contains at most its own region's candidate plus possibly
  the spawn entrance. They appear on the map once Fog of War reveals them.
- Identities are derived from the region: `<world>:dungeon:<rx>:<ry>` names the
  dungeon area. World identities contain no colon, so the identity parses back
  into its region.

Entrances change chunk content and the metadata schema, so the world generator
version rises from 5 to 6 and the world format version from 2 to 3. Existing
worlds are rejected with the usual instruction to delete or recreate them.

## Area view instead of a global map

Game rules no longer fetch a map; `InitialDungeonMap()` is removed. The new unit
`Dungeon.Areas` resolves a dungeon area identity to its generated map and
builds an **area view**: the world metadata plus the map of the interior the
player occupies, or none outdoors.

Rules receive the area view instead of bare metadata. A transition into a
dungeon generates the target map once and returns the new state together with
its new area view. The server session keeps the current interior map, so a turn
never regenerates it.

`InteriorMap` gains its area identity and a list of opponent placements; its
tablet, NPC, and single opponent fields are removed. Item placements carry
their item kind.

## Dungeon generator

A generated dungeon is a grid of 31 by 21 fields built by
`Dungeon.Interior.Generation` from a linear congruential generator seeded with
the world seed, the region coordinate, and an attempt number. The generator is
shared with combat dice through `Dungeon.Random`, so both use the same,
already persisted algorithm.

1. Try up to 40 times to place a room of 3 to 7 by 3 to 5 floor fields, keeping
   at least one wall between rooms; stop at eight rooms.
2. Connect each room to the previous one with an L-shaped corridor, then add
   one or two extra corridors between random rooms so the dungeon has loops.
3. Make the top-left floor field of the first room the exit; the player starts
   on the field east of it, facing east.
4. Place one or two restless skeletons at the centers of the rooms farthest
   from the start by walking distance.
5. Place the ancient coin, the rusty short sword, and the leather jerkin on
   room corners, taking rooms that hold neither the exit nor a skeleton first.

A layout is accepted when it passes the existing map validation (bounds, a
single exit, every walkable field connected to the start) and has at least four
rooms, a floor share between 25 % and 60 %, and no skeleton that could see the
start. Otherwise the next attempt runs; after 16 failed attempts generation
reports an error, which is a generator defect.

A fingerprint test pins the output of fixed regions. Changing generator output
requires raising the world generator version.

## Materialization and persistence

Geometry is never stored. The first entry into a dungeon **materializes** it:
the area identity is added to the game state's **visited areas**, and its item
and opponent placements become game items and opponents. Defeated opponents
and carried items stay recorded, so re-entering never restores them.

- Item and opponent identities are `<area>:item:<n>` and `<area>:hostile:<n>`.
- Savegame format 7 drops the NPC and adds the visited areas.
- Loading or writing a savegame runs the complete validation: every visited
  area is generated once, and every item and opponent must match exactly one
  placement of a visited area. Per-intention validation checks only the
  current area against the map in the area view.
- Interior discovery stays keyed by area identity; every generated dungeon has
  the same dimensions.
- The return location records the entrance field; it must equal the entrance
  site of the dungeon's region.

## Protocol and client

Protocol version 13 removes the dialogue messages and the NPC and tablet field
codes. Generated dungeons are titled `Forgotten dungeon` until stage 14b adds
names. The raycaster, the exploration map, and the context panel already work
with any interior size; tests cover a 31 by 21 dungeon.

## Ownership

`Dungeon.Terrain.Entrances` owns entrance regions and sites.
`Dungeon.Interior.Generation` owns dungeon geometry and placements.
`Dungeon.Areas` owns area identities, map resolution, area views,
materialization, and complete game-state validation. `Dungeon.Random` owns the
random number generator. The server keeps the current interior map in its
session.

## Deferred

Stage 14s lets the client create worlds with overridden parameters, list and
continue existing worlds, and adds the server console. Stage 14b adds several
opponent kinds, loot tables, a first consumable item, and deterministic dungeon
names. Stage 14c adds stairs and deeper levels. Settlements with NPCs and
dialogue belong to stage 15; LLM-generated content to stage 17.
