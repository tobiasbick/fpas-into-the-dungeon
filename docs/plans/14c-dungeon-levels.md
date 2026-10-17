# 14c: dungeon levels

Status: checkpoints 01-10 implemented on 2026-10-17; user acceptance (11) is open.
13b is accepted; this is the next gameplay slice.

Implement the checkpoints in order. Each checkpoint must leave an executable,
tested workspace. After each checkpoint, update this plan and the roadmap with
the completed work, the actual commands and results, and the next open step.
Ask before changing the decisions below or reordering checkpoints. Commit or
push only when requested. Delete this plan after the user explicitly accepts
14c; keep its lasting contracts in the permanent documentation
([generated dungeons](../architecture/generated-dungeons.md),
[level storage](../architecture/dungeon-level-storage.md),
[area transitions](../architecture/area-transitions.md)).

## Goal and fixed scope

A generated dungeon becomes a stack of levels connected by paired stairs.
Its depth is a property of each dungeon; this slice gives every dungeon three
levels, and later slices may vary the depth per dungeon. Deeper levels are more dangerous and offer fewer finds, so the
progression from 13b has more opponents to train against. Each level is its own
area. It is generated and stored on its first visit, materialized into the
current game, and keeps its mutable state across stair travel, save, and load.

Success means a player can enter a dungeon, descend to the deepest level and
climb back out. Every level must keep its defeated opponents and moved items,
and the game must save, load, revisit, Start over, and rewind to an earlier
save with exact state. Unvisited deeper levels are never generated in advance.

Outside this slice: new opponent kinds, per-level opponent stat scaling,
opponents following the player across stairs, traps, keys, locked doors,
overall dungeon completion rewards, teleporting, choosing depths other than
three, and level sizes other than 31 by 21.

## Decisions

These were open in the roadmap. They are fixed for this slice.

### Depth

- Depth is **per dungeon**, not a global constant. A pure function
  `DungeonDepth(Metadata, Region)` in `Generation.Levels` decides it and
  currently returns 3 for every region. A later slice may make it depend on the
  seed and region; that changes generated output and raises the generator
  version, but needs no format or protocol change.
- The depth is stored in every level file of the dungeon (`depth`) and carried
  in the interior projection. Rules, validation, storage and the client read
  the depth from the stored map, never from a constant, and never recompute it
  on read.
- `MaxDungeonDepth = 16` bounds parsing, files and the protocol. It is a
  safety bound only, not a gameplay value; `DungeonDepth` must return
  1..`MaxDungeonDepth`.
- The player sees levels numbered from 1 (`Level 2 of 3`). Indices stay
  0-based everywhere else, including in identities, files and the protocol.
- No code path may assume exactly three levels. Tests cover depth 3 from the
  generator plus hand-built stored dungeons of depth 1, 2 and 5.

### Area identity and storage path

- Every level, level 0 included, uses
  `<world>:dungeon:<rx>:<ry>:<level>`, where `<level>` is a canonical
  non-negative integer below `MaxDungeonDepth`; whether the level exists is
  checked against the dungeon's stored depth. The old four-segment form is
  rejected. A single identity form keeps parsing uniform. Its effect on
  level-0 item and hostile IDs is covered by the generator, level format and
  save format bumps below.
- `ParseDungeonAreaId` returns region and level. It rejects a missing level,
  leading zeros, a plus sign, negative zero and indices of `MaxDungeonDepth`
  or more.
- Level files move from `0.json` to `dungeons/<rx>_<ry>/<level>.json`. The path
  is built from parsed integers, never from the raw identity.

### Stairs as terrain

- Two new interior cell kinds: `StairsDown` (code `>`) and `StairsUp`
  (code `<`). They are walkable and occupy no item or hostile placement field.
  The exit stays `x`.
- Each level's endpoints follow from its index and the dungeon depth `D`.
  Validation enforces exactly these counts:

  | Level | Exit `x` | Stairs up `<` | Stairs down `>` |
  | --- | ---: | ---: | ---: |
  | 0 | 1 | 0 | 1 if `D > 1`, else 0 |
  | 1 .. `D-2` | 0 | 1 | 1 |
  | `D-1` (deepest, `D > 1`) | 0 | 1 | 0 |

- The **arrival endpoint** is the exit on level 0 and the stairs up on deeper
  levels. As today, the start pose is the field east of the arrival endpoint,
  facing east.
- The **descent landing** is the field east of the stairs down, facing east.
  It must be ordinary floor, free of placements, and connected.
- Stairs use the existing endpoint interaction rule. Whatever lets `Enter`
  activate the exit today also activates stairs; no new key is added.

### Stair links

- The links are a pure function of the area identity and the target map. No
  link records are persisted.
  - Stairs down on level L lead to level L+1 at its start pose.
  - Stairs up on level L lead to level L-1 at its descent landing.
  - Only the exit on level 0 leads outdoors.
- `ReturnLocation` keeps meaning "the outdoor entrance of the dungeon the
  player is in". It is set when entering level 0 from outdoors and kept
  unchanged on every stair transition. Validation requires it to equal the
  entrance site of the region of the current level's dungeon, for every level.
  This replaces the assumption that every interior returns directly outdoors.
- A stair transition is a free action like the existing transitions and does
  not advance combat. Opponents stay in their own area. Fleeing up or down the
  stairs is therefore allowed. Alerted opponents stay alerted and remain where
  they were.
- Decided during implementation (gap found in TCP play): opponents on a level
  without the player never move, so one standing on an arrival field (start or
  descent landing) would lock the player out of that level and, below level 0,
  out of the exit. The player then arrives on the first free floor field in
  breadth-first order north, east, south, west from the arrival field, keeping
  the facing. This applies to entering from outdoors as well.
- Decided during implementation: combat events identify only a kind, and deeper
  levels hold two opponents of one kind. The client narrows player-blow effects
  to the field directly ahead and attacker effects to fields orthogonally
  adjacent to the player, which are the only fields the rules allow. No
  protocol change is needed.

### Generation

- Geometry seeds add the level: the existing attempt seed derivation gains a
  `level * 32452843` term inside the same normalized modulo arithmetic, so the
  term is zero for level 0. The multiplier differs from the attempt multiplier
  15485863, so level 1 attempt 0 never reuses level 0 attempt 1. Level-0 rooms and corridors therefore keep their
  14b geometry; the pinned fingerprints change only through the new identity
  form and the stairs.
- **Stairs down** goes to the top-left floor field of the room farthest from the
  start, using the existing distance order and tie-breaker, excluding the
  arrival room. The field east of it must be floor, otherwise the next room in
  the same order is tried. If no room qualifies, the attempt fails. Stairs and
  landing count as endpoints, so item corners skip them. Opponents keep their
  room-center rule and may share the stairs room, so a guard on the way down is
  possible.
- **Stairs up** replaces the exit position on every level below 0. The first room's
  top-left field becomes `<` instead of `x`.
- Opponents per level are a formula of the level index `L`, not a table of
  fixed levels, so deeper dungeons need no new rules. All are existing kinds
  with unchanged statistics:
  - count `N = min(2 + (L + 1) div 2, 5)`;
  - skeletons `min(1 + L div 2, N - 1)`, the rest rats (at least one rat);
  - slots list skeletons first, then rats; they take the farthest safe rooms
    in slot order. An attempt with too few safe rooms is rejected, as today.

  For the current depth of three this gives:

  | Level | Hostile slots in order | Total health |
  | --- | --- | ---: |
  | 0 | skeleton, rat | 18 |
  | 1 | skeleton, rat, rat | 24 |
  | 2 | skeleton, skeleton, rat | 30 |

  The difficulty depends on the level index, not on the depth. Levels 3 and
  deeper are covered by formula tests only while generation stops at depth 3.

- Finds per level. Level 0 is unchanged (slots 0..3 guaranteed, optional 4/5).
  Deeper levels have only one guaranteed **healing potion** at slot 0, plus
  optional slots 1 and 2 from the existing loot table. Their content domains are
  `3001 + 100 * level` and `3011 + 100 * level`. Sword and jerkin can only come
  from the optional table there.
- Validation per level keeps today's rules: connectivity, floor share, at
  least four rooms, and no opponent with sight of the start. It adds the
  endpoint counts above and a valid descent landing.
- Every level of a dungeon shares the stored dungeon name. The name stays
  generated from the region only, never from the level.

### Versions

All bumps happen once on this branch.

| Contract | From | To |
| --- | ---: | ---: |
| World generator | 7 | 8 |
| Level file format | 2 | 3 |
| Savegame format | 9 | 10 |
| Protocol | 15 | 16 |
| World format | 3 | 3 (unchanged) |

Older worlds, levels and saves are rejected and preserved, never migrated, and
their catalog entries tell the user to create a new world.

### Level file format 3

These changes apply on top of format 2:

- New key `depth`, an integer 1..`MaxDungeonDepth`.
- `level` is an integer 0..`depth - 1` and must match the identity's level.
- Every level file of one dungeon must store the same `depth` and name. Save
  validation and entry reject a mismatch between visited levels as a
  world-data error; nothing is repaired.
- `rows` may contain `<` and `>`. Endpoint counts follow the depth table above.
- `exit` is removed; all endpoints are derived from `rows`. `start` stays and
  must be the field east of the arrival endpoint, facing east.
- `items` and `hostiles` follow the per-level slot tables above. IDs use the
  new five-segment area identity.

## Module ownership

- `Dungeon.Areas.Identities` owns the level-aware identity and its parsing
  (`DungeonLevelId`). Neighbor levels are formed with `DungeonAreaId` from the
  parsed region and the current map's level; whether a next level exists is
  decided from the current map's depth.
- `Dungeon.Movement` exposes `TransitionTargetOfValid` for callers that have
  already validated the state, so `OpenLevelForEntry` does not validate the
  whole state a second time per transition.
- `Dungeon.Interior` owns `MaxDungeonDepth` (map validation needs it below the
  identity unit), the new cell kinds, their codes, the `Level`/`Depth` map
  fields, and the endpoint lookup helpers (arrival endpoint, stairs down,
  descent landing). The map field `Exit` becomes `Arrival`.
- Save validation additionally requires that a visited level L > 0 has level
  L-1 of the same dungeon visited too.
- `Dungeon.Interior.Generation` already has 460+ lines. Move the per-level
  content rules (`DungeonDepth`, hostile and item slot formulas, domains)
  into a new unit,
  `Dungeon.Interior.Generation.Levels`, instead of growing the existing file.
  Stairs placement stays in the geometry unit.
- `Dungeon.Movement` owns stair targets and landings.
- `Dungeon.World.Interiors` keeps file ownership. `OpenLevelForEntry`
  generates a missing level only when it is unvisited and is the target of the
  player's current transition.

No new project and no dependency from `libs/game` to `libs/world`.

## Checkpoints

### 01. Baseline

Run `fpas check` for all projects and the complete suite on the starting
commit. Record the counts here. Gameplay and versions stay unchanged.

### 02. Level-aware identities and cells

- Five-segment identities with parsing, formatting, level bounds, and
  `MaxDungeonDepth`. Add `Depth` and `Level` to
  `InteriorMap`. Update all identity producers in game code.
- `StairsUp`/`StairsDown` cells, their codes, and walkability.
- Endpoint helpers and per-level structural validation in
  `Generation.Validation`: endpoint counts by level and depth, start relation,
  descent landing.
- Tests:
  - Positive: depths 1, 2, 3 and 5 with every level, and negative region
    coordinates.
  - Negative: four segments, level `MaxDungeonDepth`, level at or beyond the
    depth, depth 0 or above the bound, `-0`, `01`, `+1`, extra segments, unknown
    cell codes, wrong endpoint counts, a stairs down without a valid landing,
    a placement on stairs.
  - Edge: stairs adjacent to a wall, and a landing on the map border column.

### 03. Generator 8

- Level-aware geometry seed, stairs placement, the new `Generation.Levels`
  unit with `DungeonDepth` (returns 3) and the hostile/item formulas, and
  per-level placement with the new content domains.
- Raise `WorldGeneratorVersion` to 8. Deliberately update the three pinned
  region fingerprints and add level 1 and level 2 fingerprints for the same
  regions. The fingerprints include name, geometry, endpoints, and every
  placement kind, identity and position.
- Prove that level-0 rooms and corridors equal the 14b geometry, and that
  generating level 2 neither reads nor needs level 1.
- Exhaustive formula tests for levels 0..`MaxDungeonDepth - 1`: hostile count,
  kinds and order. Generator tests with a depth of 1 (no stairs) and 5 through
  the public depth parameter of `GenerateDungeon`, without changing
  `DungeonDepth`.
- Measure generation time per level and record it here.
- Negative tests: a level index at or beyond the depth, and an attempt without a valid
  stairs room or with too few safe rooms rejects that attempt.

### 04. Level file format 3

- Codec, the `<level>.json` path, and validation against the expected level
  index.
- `OpenLevelForEntry` creates only the requested transition target. Reading
  never generates.
- Tests:
  - Round trip for all three levels, and for hand-built dungeons of depth 1
    and 5.
  - Rejection of format 2, `exit` present, `level` mismatching the identity,
    a level-0 file stored under `1.json`, missing or out-of-range `depth`,
    a level at or beyond its depth, and bad endpoint counts.
  - Level files are never overwritten.
  - A missing level 1 referenced by a visited area is a typed `Missing`
    failure.
  - Entering level 0 creates no files for levels 1 or 2.

### 05. Pure stair transitions

- `AreaTransitionTarget` and `ActivateAreaTransition` for stairs down, stairs
  up and the level-0 exit, landing on the start pose or descent landing.
- `ReturnLocation` is kept across stairs. Transitions are free and leave the
  dice, hostiles and turn state untouched.
- Materialize a level on its first entry. Reveal the destination area.
- Tests: every direction, a round trip from level 0 to the deepest level and
  back with exact poses, depth-1 and depth-5 fixtures, outdoor return only from
  level 0, rejections (stairs not ahead/occupied, a target map with the wrong
  ID, level or depth, an exit on a deeper level, no stairs down on the deepest
  level), alerted opponents left behind, and a state unchanged on every
  rejection.

### 06. Savegame format 10

- New identity form throughout. Full validation checks every visited level
  against its map and the `ReturnLocation` invariant for any current level.
  Items may lie on any visited level.
- Tests: save/load on each level, an item carried from level 2 and dropped on
  level 0 of another dungeon, rejected format-9 saves with the bytes
  preserved, and a missing deeper level file reported as a level failure
  without deleting the save, and visited levels of one dungeon with differing
  stored depth or name rejected as a world-data error.

### 07. Server stair handling

- Reuse the existing transition ordering for stairs: validate, then open or
  create the level, then build the candidate, then project, then install.
- Repeat the existing failure regressions for a stair target: read failure,
  generation failure, atomic-write failure, a file published followed by a
  candidate failure, and a send failure. Assert the pose, visited areas,
  discovery, level files and previous save bytes.
- The dashboard shows the current level.

### 08. Protocol 16 and client

- Wire codes for both stairs cells and `level`/`depth` in the interior area
  projection. The strict decoder rejects a depth outside 1..`MaxDungeonDepth`
  and a level at or beyond the depth.
- First-person rendering: stairs fields get a distinct floor treatment like the
  exit, with an up or down marker. The exploration map uses `<` and `>`. The
  title reads `<Name> — Level n of <depth>`. The Environment panel shows the hint
  `Enter: go down` or `Enter: go up`.
- Tests: protocol positive, negative and bounds tests; headless TUI tests for
  both stairs, the title, the hint, the hidden-sidebar fallback, and the map
  per level.

### 09. Multi-level persistence verification

Real play through the rules:

- Descend, fight, drop and use items on every level, then save and reopen.
- Load on each level, during combat and outdoors. Revisit levels with their
  opponents defeated.
- Start over keeps the level files and resets all levels. Rewinding to an
  earlier save forgets later levels while reusing their files.
- A filesystem trace confirms one read per visited level per save and load.
- Extend the [persistence measurements](../architecture/persistence-measurements.md)
  with 1/10/100 dungeons, each with all of its levels visited.

### 10. Complete TCP play and documentation

- A complete TCP session goes from the outdoors down to the deepest level and back out.
  It includes a reconnect with exact replay of unsaved turns, followed by
  explicit save and Continue.
- Synchronize the generated-dungeons, level-storage, area-transitions,
  overview, world-and-views terminology (stairs, level, arrival endpoint,
  descent landing), UI and roadmap documentation.
- Run formatting, every project check, and the complete suite with
  `fpas test --timeout 600 dungeon.fpasworkspace`.

### 11. Acceptance

Review the finished slice with the user in the running game. Mark 14c done and
delete this plan only after explicit acceptance.

## Progress

| Checkpoint | Status | Verification |
| --- | --- | --- |
| 01 | done | 21/21 projects checked, 122/122 test programs on 2edd12b |
| 02 | done | identities, stairs cells, per-level validation; `dungeon_levels_test` |
| 03 | done | generator 8, `Generation.Levels`, deliberate level-0 repin (only `:0` suffix and `>` differ), level 1/2 fingerprints, 1200 deep levels accepted; `dungeon_level_generation_test` |
| 04 | done | level format 3, `<level>.json`, creation only for the current target; `multi_level_storage_test` |
| 05 | done | stair targets, landings, occupied-arrival rule; `stair_transitions_test` |
| 06 | done | save format 10, upper-level and depth/name invariants; `multi_level_storage_test` |
| 07 | done | server stairs with read/write/invalid/candidate/send failures, dashboard level title; `stair_checkpoints_test` |
| 08 | done | protocol 16 `<`/`>` and level/depth, raycaster steps, map glyphs, same-kind animation narrowing; `stairs_protocol_test`, `stairs_render_test`, `same_kind_animation_test` |
| 09 | done | rewind, Start over, cross-level items, missing/mismatched levels; benchmark in persistence measurements |
| 10 | done | TCP descent, save, reconnect replay, climb, Continue; `dungeon_levels_network_test`; docs synchronized; formatting, all 21 projects checked, 131/131 test programs |
| 11 | open | |
