# Generated dungeons

The [level storage contract](dungeon-level-storage.md) specifies the exact 14a
file format, public interfaces, failure handling, and transition ordering.

Stage 14a replaces the single hand-authored dungeon with generated ones. The
outdoor world gains rare, deterministic dungeon entrances, and each entrance
leads to a dungeon whose geometry is generated from the world seed and the
entrance region when it is needed. Stage 14c turns each dungeon into a stack of
levels connected by paired stairs; every level is its own area, generated and
stored on its first visit only. Quest preflight may validate missing unvisited
levels through transient generation without storing or materializing them;
see [quests](quests.md).

The hand-authored initial dungeon is removed together with its stone tablet,
Mara, and the complete dialogue feature (rules, protocol messages, client
overlay, and tests). NPCs and dialogue returned with Hearthmoor in stage 15a.
Healing now uses potions or paid inn rest. Outdoor steps take five game minutes
without healing; see [time and rest](time-and-rest.md).

Generation stays deterministic and server-owned. Stage 14b checkpoint 02 adds
stored names; stories and LLM content remain outside this stage.

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
- Identities are derived from the region and level:
  `<world>:dungeon:<rx>:<ry>:<level>` names one dungeon level. World identities
  contain no colon, so the identity parses back into region and level. Levels
  are bounded by `MaxDungeonDepth` (16) when parsing; whether a level exists
  depends on the stored depth.

In 14a, entrances changed chunk content and the metadata schema: generator 5
became 6 and world format 2 became 3. Stage 14b raised the generator to 7 for
dungeon names, and 14c to 8 for dungeon levels; outdoor terrain and entrance
fingerprints stay unchanged. World format remains 3. Incompatible worlds stay intact and cannot be continued with
this server; create a new world for the current version.

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

## Depth and levels

`Dungeon.Interior.Generation.Levels` owns the per-level content rules. The pure
function `DungeonDepth(seed, rx, ry)` decides a dungeon's depth; it currently
returns 3 for every region. Level 0 takes its depth from it on first entry;
deeper levels take the stored depth of the level the player leaves, so one
dungeon never mixes depths. Every level file stores the depth, and rules,
validation, storage and the client read it from there. Changing `DungeonDepth`
later changes generated output and raises the generator version, but no format.

Each level's endpoints follow from its index L and the depth D:

| Level | Exit `x` | Stairs up `<` | Stairs down `>` |
| --- | ---: | ---: | ---: |
| 0 | 1 | 0 | 1 if D > 1, else 0 |
| 1 .. D-2 | 0 | 1 | 1 |
| D-1 (deepest, D > 1) | 0 | 1 | 0 |

The **arrival endpoint** is the exit on level 0 and the stairs up below it; the
start lies one field east of it, facing east. The **descent landing** is the
field east of the stairs down, facing east; it must be ordinary floor free of
placements.

Opponents per level are a formula of L, so deeper dungeons need no new rules:
`N = min(2 + (L + 1) div 2, 5)` opponents, of which `min(1 + L div 2, N - 1)`
are skeletons first and the rest rats. Levels 0/1/2 therefore hold skeleton+rat,
skeleton+2 rats and 2 skeletons+rat (18/24/30 total health). Level 0 keeps its
four required finds and optional slots 4/5. Deeper levels have one required
Healing potion at slot 0 and optional slots 1/2 drawn from the same loot table
with domains `3001 + 100 * L` and `3011 + 100 * L`
(`Content.DeepOptionalLoot`). All levels share the dungeon's stored name.

## Dungeon generator

A generated dungeon level is a grid of 31 by 21 fields built by
`Dungeon.Interior.Generation` from a linear congruential generator seeded with
the world seed, the region coordinate, the level, and an attempt number. The
level adds `level * 32452843` to the attempt seed, which is zero on level 0, so
level 0 keeps the single-level geometry and only gains its stairs down. The generator is
shared with combat dice through `Dungeon.Random`, so both use the same,
already persisted algorithm.

1. Try up to 40 times to place a room of 3 to 7 by 3 to 5 floor fields, keeping
   at least one wall between rooms; stop at eight rooms.
2. Connect each room to the previous one with an L-shaped corridor, then try
   one or two extra corridors between random rooms. Equal endpoints are
   skipped and corridors may overlap. Loops are possible, not guaranteed;
   connected rooms are the acceptance requirement.
3. Make the top-left floor field of the first room the arrival endpoint (exit
   on level 0, stairs up below it); the player starts on the field east of it,
   facing east. Unless the level is the deepest, put the stairs down on the
   top-left field of the farthest room in the order of step 4; rooms are at
   least three fields wide, so its landing is floor of the same room.
4. Order rooms outside the exit room by walking distance from the start,
   farthest first, with room index breaking ties. Skip centers that could see
   the start. Place the level's opponent slots in the eligible rooms in that
   order; reject an attempt with too few safe rooms. Opponents may share the
   stairs room.
5. Place the level's required finds, followed by its selected optional slots,
   on distinct ordinary floor corners. Prefer rooms without exit or
   opponents; keep room order and top-left, top-right, bottom-left, bottom-right
   corner order. Skip occupied corners and endpoints. Reject insufficient
   corners rather than omitting a selected find.

A layout is accepted when it passes the existing map validation (bounds, the
level's endpoint counts, a floor descent landing, every walkable field connected
to the start) and has at least four rooms, a floor share between 25 % and 60 %, and no opponent that could see the
start. Otherwise the next attempt runs; after 16 failed attempts generation
reports an error, which is a generator defect.

Fingerprint tests pin level 0 and levels 1/2 of fixed regions. Changing
generator output requires raising the world generator version. Every region of
a 20 by 20 block yields accepted levels 0..2 for three seeds, including one whose
derived seed wraps the integer range; a depth-5 dungeon generates as well.

## Pure content selection

`Dungeon.Interior.Generation.Content` owns names and the fixed optional-loot
table. Content seeds normalize the world seed and numeric region coordinates
modulo `M = 2147483648` before multiplication:

```text
S = PositiveModulo(
      PositiveModulo(seed, M) * 7919
    + PositiveModulo(region_x, M) * 104729
    + PositiveModulo(region_y, M) * 1299709
    + domain, M)
```

The private helper keeps intermediates within signed 64-bit bounds, including
negative and extreme inputs. Domain 1009 retains the existing two-draw name
selection. `OptionalLoot(seed, region_x, region_y, slot)` accepts only original
slot 4 or 5 and draws once below 100 from domain 2003 or 2011 respectively.
Each slot starts from its own derived seed, including when the other is empty;
query order, world identity, geometry draws and the persisted combat RNG do not
participate. The result is `result of (option of ItemKind, string)`.

`LootForRoll(roll)` exposes the exact bounded table for exhaustive verification:

| Roll | Result | Weight |
| --- | --- | --- |
| 0..29 | No item | 30 |
| 30..59 | Ancient coin | 30 |
| 60..89 | Healing potion | 30 |
| 90..94 | Rusty short sword | 5 |
| 95..99 | Leather jerkin | 5 |

Invalid rolls and slots return errors; they are never clamped, wrapped or
rerolled. Selection happens once before geometry attempts and never advances
geometry or combat state. Slots retain original identities when another is
empty: `[0,1,2,3,5]` is valid. Stored validation accepts four through six finds,
requires the kinds of slots 0..3 and ordered optional slots 4/5, and never
recalculates their selection from the world seed.

The two fixed domains provide independent queries, but their outcomes are
correlated by the specified linear generator: successor states differ by
238187368 modulo 2^31. Raw draws differ by 3634/3635 or -29134/-29133, so rolls
modulo 100 differ by 34/35/66/67. Thus both optional slots cannot be empty or
have the same kind under this table. Generated dungeons have five or six finds;
stored structural validation also permits four finds or two equal optional
kinds. Separate original IDs always distinguish equal-kind finds.

Final 14b fingerprints include the name, geometry, endpoints and every
placement kind, identity and position. The three pinned regions keep their
checkpoint-02 attempt-0 geometry and endpoints exactly; changes add rat slot 1,
potion slot 3 and optional finds. The existing generator-version bump from 6
to 7 covers these changes once for the feature branch. Geometry dimensions,
room/corridor random draws and the 16-attempt seed schedule are unchanged.

## Materialization and persistence

The first entry creates a versioned, immutable **level file** as world data,
containing geometry, start and exit, and original item and opponent placements.
Each level is stored separately; stair links are computed from identities and
maps, never stored. Only the current transition target may be persistently
created. Stage 15b may preview missing unvisited levels in memory to prove a
quest route; existing data and missing visited files are never regenerated.
After the file is stored successfully, entry **materializes** the dungeon:
the area identity is added to the game state's **visited areas**, and its item
and opponent placements become game items and opponents. Defeated opponents
and carried items stay recorded, so re-entering never restores them.

- Store level files below `worlds/<world-id>/dungeons/<rx>_<ry>/<level>.json`.
  Derive paths from validated numeric region coordinates and level, never raw
  area IDs. Each file records its own format version (currently 4), world
  identity, generator version, area identity, immutable display name, level
  index, depth, dimensions, geometry with its endpoints, start pose, and
  original placements. Reject incompatible versions; no migration.
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
- In 14a, savegame format 7 removed the NPC and added visited areas. Format 8
  added rat state and terminal potion locations, format 9 progression, and the
  format 10 level identities. Format 11 adds settlement/NPC records;
  format 12 adds quest state, returned compass ownership and reward origins;
  current format 15 retains complete settlement rosters, a canonical world clock, separate coins and
  merchant-held ownership with five original goods per visited merchant;
  obsolete saves are rejected and preserved.
  A visited level deeper than 0 requires its upper level to be visited, and visited
  levels of one dungeon must agree on depth and name.
- Loading or writing a savegame runs the complete validation: every visited
  dungeon's level file is read and validated once, the home settlement resolves
  from code, generated settlement definitions are read too, and every item and opponent
  must match exactly one origin placement of a visited area by identity and
  kind, one of the five original goods of a visited merchant, or one of the two
  validated reward origins of a rewarded quest. An item's current
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

Measured in 14a with `tools/persistence-bench` (three rounds each, monotonic
millisecond clock, peak working set of the `fpas run` process tree including
compilation): complete save and load each take about 6 and 2 ms with one
visited dungeon, 21 and 17 ms with 10, and 260 ms with 100 (save 144 KB). Work
grows linearly with the visited dungeons, about 2.6 ms each per operation; peak
memory stays between 18 and 46 MB. First entry, generation plus round-trip
check plus atomic storage, takes about 7 to 8 ms per dungeon. No caching or
other optimization was added. These are historical 14a measurements, not a
current timing guarantee. The [14b persistence measurements](persistence-measurements.md)
record final-content smoke runs, same-session controls and the regression
investigation.

## Protocol and client

The 14a slice introduced protocol version 13, removing the dialogue messages
and the NPC and tablet field codes and adding the drop-item intention. The
world-management protocol version 14 was extended to version 15 by 14b
checkpoint 03: rat markers and kind-carrying combat events. Save format is now
8. Generated dungeons place a skeleton and a rat, with four guaranteed items
and optional original slots 4/5. Checkpoint 04 added the potion marker and
terminal item state without another version bump. Consumed potions retain their
original identities and cannot reappear during materialization or load.
Generated dungeons use their stored display name in the
first-person title, context panel, exploration map and server dashboard. The raycaster, the exploration
map, and the context panel already work
with any interior size; tests cover a 31 by 21 dungeon.

Protocol 16 (14c) adds the stairs codes `<` and `>` and the required `level` and
`depth` of first-person states (`0 <= level < depth <= 16`); at most one stairs
of each direction is visible. The server title reads
`<name> — Level n of <depth>` for dungeons with more than one level, and the
status shows `Stairs down — Enter: Go down` or `Stairs up — Enter: Go up` on a
stairs field. The raycaster draws stairs as concentric steps on the floor (pale
and rising for up, dark and sinking for down); the exploration map uses `<` and `>`.

## Ownership

`Dungeon.Terrain.Entrances` owns entrance regions and sites.
`Dungeon.Interior.Generation` owns dungeon geometry and placements;
`Dungeon.Interior.Generation.Levels` owns depth and per-level content rules.
`Dungeon.Areas` owns area identities, area views, materialization, and pure
game-state validation against supplied maps. `Dungeon.World.Interiors` in
`libs/world` owns level files, their codec, load/create operations, and loading
maps for full save validation. `Dungeon.Random` owns the random number
generator. The server coordinates storage and transitions and keeps the current
interior map in its session. No dependency from `libs/game` to `libs/world` is
introduced.

## Deferred

Stage 14s lets the client create worlds with overridden parameters, list and
continue existing worlds, and adds the server console. Stage 14b checkpoints
02 through 09 implement stored dungeon names, both generated opponent kinds,
potion identity, persistent consumed-item state, the authoritative healing
turn with its protocol/session path and inventory controls, and final generated
floor finds with bounded optional selection. Checkpoint 10 verifies immutable
levels and resumable cross-area item state, including consumed optional slot 5,
Start over and earlier-save rewind. Checkpoint 11 verifies the complete TCP
contents loop, actual kind-carrying combat animation, named exploration maps,
authoritative dashboard facts and failure paths. Checkpoint 12 completes
automated verification, documentation and the
[persistence smoke measurements](persistence-measurements.md). All 91 test
programs and 20 project checks passed at that checkpoint. The user explicitly
accepted 14b on 2026-10-16; the completed implementation plan has been removed.
Stage 13b followed 14b with progression; 14c adds separate level areas and
paired stairs without changing the first-person view family. Variable depths,
new opponent kinds, opponents following the player across stairs, and per-level
opponent scaling remain open. Settlements with NPCs and dialogue belong to stage
15; LLM-generated content to stage 16.
