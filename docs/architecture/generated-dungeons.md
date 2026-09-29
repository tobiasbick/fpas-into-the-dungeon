# Generated dungeons

The [level storage contract](dungeon-level-storage.md) specifies the exact 14a
file format, public interfaces, failure handling, and transition ordering.

Stage 14a replaces the single hand-authored dungeon with generated ones. The
outdoor world gains rare, deterministic dungeon entrances, and each entrance
leads to a dungeon whose geometry is generated from the world seed and the
entrance region when it is needed.

The hand-authored initial dungeon is removed together with its stone tablet,
Mara, and the complete dialogue feature (rules, protocol messages, client
overlay, and tests). NPCs and dialogue return with settlements in stage 15.
Mara was the only way to heal; every accepted outdoor step restores one health
point. This remains available in 14b; consumables add healing inside dungeons.

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
  It replaces the spawn region's ordinary candidate. It may lie across a region
  border, but always belongs to the spawn region for dungeon identity and
  return validation. The receiving region may also have its ordinary entrance.
  `EntranceRegionAt` checks the exact spawn entrance first and returns the spawn
  region there; otherwise it checks the containing region's ordinary site.
  The configured region size controls ordinary entrance density, not this
  boundary exception.
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
`Dungeon.Areas` validates area identities and supplied maps and builds an
**area view**: the world metadata plus the map of the interior the player
occupies, or none outdoors. `libs/world` loads or creates the stored map;
game rules do not perform filesystem access.

Rules receive the area view instead of bare metadata. A transition into a
dungeon first loads its stored map or generates and atomically stores it if
this is its first visit. Only after that succeeds does the server install the
new state and area view. The server session keeps the current interior map,
so an ordinary turn neither reloads nor regenerates it.

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
2. Connect each room to the previous one with an L-shaped corridor, then try
   one or two extra corridors between random rooms. Equal endpoints are
   skipped and corridors may overlap. Loops are possible, not guaranteed;
   connected rooms are the acceptance requirement.
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

The first entry creates a versioned, immutable **level file** as world data,
containing geometry, start and exit, and original item and opponent placements.
In 14a each dungeon has one level; 14c extends this to separately stored levels
and their stair links. Unvisited levels are not generated ahead of time.
After the file is stored successfully, entry **materializes** the dungeon:
the area identity is added to the game state's **visited areas**, and its item
and opponent placements become game items and opponents. Defeated opponents
and carried items stay recorded, so re-entering never restores them.

- Store level files below `worlds/<world-id>/dungeons/<rx>_<ry>/0.json` in
  14a. Derive paths from validated numeric region coordinates, never raw area
  IDs. Each file records its own format version (initially 1), world identity,
  generator version, area identity, level index, dimensions, geometry, start
  pose, exit, and original placements. Reject incompatible versions; no migration.
- Validate and atomically publish a new file before changing the game state.
  Existing files are loaded and structurally validated, never regenerated for
  comparison or silently overwritten. Invalid files and I/O failures abort the
  operation with a clear error and leave existing world and save data intact.
- Save/load reads existing files only. A missing file referenced by a save or
  an already visited area is a world-data error, never a reason to regenerate
  a map or delete the save. Missing files may be created only for first entry
  into an area not yet visited in the current game.
- Level creation does not save player progress. Loading an earlier save or
  starting over in the same world keeps level files but restores or resets
  mutable game state. An existing file alone does not mark an area visited or
  discovered; its original placements materialize only upon entry in that game.
  A file left after an interrupted first entry is safe to reuse.

- Item and opponent identities are `<area>:item:<n>` and `<area>:hostile:<n>`.
- Savegame format 7 drops the NPC and adds the visited areas.
- Loading or writing a savegame runs the complete validation: every visited
  area's level file is read and validated once, and every item and opponent
  must match exactly one origin placement of a visited area by identity and
  kind. An item's current
  location may differ from its origin, including another visited dungeon.
  Validate its location against that destination map, not its original field.
  Opponents remain in their original area. Per-intention validation checks only
  the current area against the map in the area view.
- Interior discovery stays keyed by area identity; every generated dungeon has
  the same dimensions.
- The return location records the entrance field; it must equal the entrance
  site of the dungeon's region.

## Inventory capacity and dropping

Carried and equipped items together occupy at most 64 inventory entries. The
game rules enforce this bound before pickup; protocol and save validation use
the same bound. A full inventory rejects pickup without changing items or time.

In the inventory overlay, `D` drops the selected carried item on the player's
current ordinary dungeon floor field if it holds no item. Equipped items must
first be unequipped. Dropping outdoors or on the exit is rejected in 14a.
A successful drop costs one turn; a rejection costs none. The item keeps its
identity and kind, is visible under the existing item visibility rules, and can
be picked up again through the existing interaction. One item per floor field
keeps selection and rendering unchanged. Saving, loading, and revisiting must
preserve a dropped item, including one brought from another dungeon, without
restoring it at its origin. Outdoor dropping is deferred until outdoor mutable
item storage and projection are designed.

## Save and load measurement

The current map is retained during play. Complete save validation reads the
stored maps of all visited dungeons to check their contents; this work grows
with the number of visited dungeons, even when the player carries few items. Measure
complete save and load for valid states with 1, 10, and 100 visited dungeons,
including decoding, validation, file access, and peak memory. Read each
visited map at most once per validation, including the player's current map.
Verify that save/load and revisits never invoke the generator. Measure initial
generation and storage separately. Report results before deciding on any
further caching or another optimization. These are
measurement scenarios, not a limit on the number of visited dungeons.

## Protocol and client

Protocol version 13 removes the dialogue messages and the NPC and tablet field
codes and adds the drop-item intention. Generated dungeons are titled
`Forgotten dungeon` until stage 14b adds names. The raycaster, the exploration
map, and the context panel already work
with any interior size; tests cover a 31 by 21 dungeon.

## Ownership

`Dungeon.Terrain.Entrances` owns entrance regions and sites.
`Dungeon.Interior.Generation` owns dungeon geometry and placements.
`Dungeon.Areas` owns area identities, area views, materialization, and pure
game-state validation against supplied maps. `Dungeon.World.Interiors` in
`libs/world` owns level files, their codec, load/create operations, and loading
maps for full save validation. `Dungeon.Random` owns the random number
generator. The server coordinates storage and transitions and keeps the current
interior map in its session. No dependency from `libs/game` to `libs/world` is
introduced.

## Deferred

Stage 14s lets the client create worlds with overridden parameters, list and
continue existing worlds, and adds the server console. Stage 14b adds several
opponent kinds, loot tables, a first consumable item, and deterministic dungeon
names and persistent consumed-item state. Stage 13b follows 14b with progression;
14c then adds separate level areas and paired stairs without changing the
first-person view family. Settlements with NPCs and
dialogue belong to stage 15; LLM-generated content to stage 17.
