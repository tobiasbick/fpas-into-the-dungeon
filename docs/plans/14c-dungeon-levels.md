# 14c: dungeon levels

Status: planned on 2026-10-17. No 14c changes are implemented.
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

A generated dungeon becomes a stack of three levels connected by paired
stairs. Deeper levels are more dangerous and offer fewer finds, so the
progression from 13b has more opponents to train against. Each level is its own
area. It is generated and stored on its first visit, materialized into the
current game, and keeps its mutable state across stair travel, save, and load.

Success means a player can enter a dungeon, descend to the deepest level and
climb back out. Every level must keep its defeated opponents and moved items,
and the game must save, load, revisit, Start over, and rewind to an earlier
save with exact state. Unvisited deeper levels are never generated in advance.

Outside this slice: new opponent kinds, per-level opponent stat scaling,
opponents following the player across stairs, traps, keys, locked doors,
overall dungeon completion rewards, teleporting, variable dungeon depth, and
level sizes other than 31 by 21.

## Decisions

These were open in the roadmap. They are fixed for this slice.

### Depth

- Every generated dungeon has exactly **three levels**, indices 0, 1 and 2.
  The constant `DungeonLevelCount = 3` lives in the game layer. The player sees
  levels numbered 1 to 3 (`Level 2 of 3`). Indices stay 0-based everywhere
  else, including in identities, files and the protocol.
- The depth is the same for every dungeon and is not a world parameter. Later
  variable depth would be a new decision, with its own format bumps.

### Area identity and storage path

- Every level, level 0 included, uses
  `<world>:dungeon:<rx>:<ry>:<level>`, where `<level>` is a canonical
  non-negative integer below `DungeonLevelCount`. The old four-segment form is
  rejected. A single identity form keeps parsing uniform. Its effect on
  level-0 item and hostile IDs is covered by the generator, level format and
  save format bumps below.
- `ParseDungeonAreaId` returns region and level. It rejects a missing level,
  leading zeros, a plus sign, negative zero and indices of 3 or more.
- Level files move from `0.json` to `dungeons/<rx>_<ry>/<level>.json`. The path
  is built from parsed integers, never from the raw identity.

### Stairs as terrain

- Two new interior cell kinds: `StairsDown` (code `>`) and `StairsUp`
  (code `<`). They are walkable and occupy no item or hostile placement field.
  The exit stays `x`.
- Each level has a fixed set of endpoints. Validation enforces exactly these
  counts:

  | Level | Exit `x` | Stairs up `<` | Stairs down `>` |
  | --- | ---: | ---: | ---: |
  | 0 | 1 | 0 | 1 |
  | 1 | 0 | 1 | 1 |
  | 2 | 0 | 1 | 0 |

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

### Generation

- Geometry seeds add the level: the existing attempt seed derivation gains a
  `level * 15485863` term inside the same normalized modulo arithmetic, so the
  term is zero for level 0. Level-0 rooms and corridors therefore keep their
  14b geometry; the pinned fingerprints change only through the new identity
  form and the stairs.
- **Stairs down** goes to the top-left floor field of the room farthest from the
  start, using the existing distance order and tie-breaker, excluding the
  arrival room. The field east of it must be floor, otherwise the next room in
  the same order is tried. If no room qualifies, the attempt fails. Stairs and
  landing count as endpoints, so item corners skip them. Opponents keep their
  room-center rule and may share the stairs room, so a guard on the way down is
  possible.
- **Stairs up** replaces the exit position on levels 1 and 2. The first room's
  top-left field becomes `<` instead of `x`.
- Opponents per level, all of the existing kinds with unchanged statistics.
  They take the farthest safe rooms in the order shown. An attempt with too few
  safe rooms is rejected, as today:

  | Level | Hostile slots in order | Total health |
  | --- | --- | ---: |
  | 0 | skeleton, rat | 18 |
  | 1 | skeleton, rat, rat | 24 |
  | 2 | skeleton, skeleton, rat | 30 |

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

- `level` is an integer 0..2 and must match the identity's level.
- `rows` may contain `<` and `>`. Endpoint counts follow the table above.
- `exit` is removed; all endpoints are derived from `rows`. `start` stays and
  must be the field east of the arrival endpoint, facing east.
- `items` and `hostiles` follow the per-level slot tables above. IDs use the
  new five-segment area identity.

## Module ownership

- `Dungeon.Areas.Identities` owns the level-aware identity, parsing, the level
  count and "previous/next level" helpers.
- `Dungeon.Interior` owns the new cell kinds, their codes and the endpoint
  lookup helpers (arrival endpoint, stairs down, descent landing).
- `Dungeon.Interior.Generation` already has 460+ lines. Move the per-level
  content tables (hostile slots, item slots, domains) into a new unit,
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

- Five-segment identities with parsing, formatting, level bounds and
  previous/next helpers. Update all identity producers in game code.
- `StairsUp`/`StairsDown` cells, their codes, and walkability.
- Endpoint helpers and per-level structural validation in
  `Generation.Validation`: endpoint counts, start relation, descent landing.
- Tests:
  - Positive: every level 0..2 and negative region coordinates.
  - Negative: four segments, level 3, `-0`, `01`, `+1`, extra segments, unknown
    cell codes, wrong endpoint counts, a stairs down without a valid landing,
    a placement on stairs.
  - Edge: stairs adjacent to a wall, and a landing on the map border column.

### 03. Generator 8

- Level-aware geometry seed, stairs placement, the new
  `Generation.Levels` tables, and per-level hostile and item placement with
  the new content domains.
- Raise `WorldGeneratorVersion` to 8. Deliberately update the three pinned
  region fingerprints and add level 1 and level 2 fingerprints for the same
  regions. The fingerprints include name, geometry, endpoints, and every
  placement kind, identity and position.
- Prove that level-0 rooms and corridors equal the 14b geometry, and that
  generating level 2 neither reads nor needs level 1.
- Measure generation time per level and record it here.
- Negative tests: an invalid level index, and an attempt without a valid
  stairs room or with too few safe rooms rejects that attempt.

### 04. Level file format 3

- Codec, the `<level>.json` path, and validation against the expected level
  index.
- `OpenLevelForEntry` creates only the requested transition target. Reading
  never generates.
- Tests:
  - Round trip for all three levels.
  - Rejection of format 2, `exit` present, `level` mismatching the identity,
    a level-0 file stored under `1.json`, and bad endpoint counts.
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
- Tests: every direction, a round trip L0→L2→L0 with exact poses, outdoor
  return only from L0, rejections (stairs not ahead/occupied, a target map
  with the wrong ID or level, an exit on a deeper level), alerted opponents
  left behind, and a state unchanged on every rejection.

### 06. Savegame format 10

- New identity form throughout. Full validation checks every visited level
  against its map and the `ReturnLocation` invariant for any current level.
  Items may lie on any visited level.
- Tests: save/load on each level, an item carried from level 2 and dropped on
  level 0 of another dungeon, rejected format-9 saves with the bytes
  preserved, and a missing deeper level file reported as a level failure
  without deleting the save.

### 07. Server stair handling

- Reuse the existing transition ordering for stairs: validate, then open or
  create the level, then build the candidate, then project, then install.
- Repeat the existing failure regressions for a stair target: read failure,
  generation failure, atomic-write failure, a file published followed by a
  candidate failure, and a send failure. Assert the pose, visited areas,
  discovery, level files and previous save bytes.
- The dashboard shows the current level.

### 08. Protocol 16 and client

- Wire codes for both stairs cells and `level`/`level_count` in the interior
  area projection. The strict decoder rejects levels out of range.
- First-person rendering: stairs fields get a distinct floor treatment like the
  exit, with an up or down marker. The exploration map uses `<` and `>`. The
  title reads `<Name> — Level n of 3`. The Environment panel shows the hint
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
  with 1/10/100 dungeons × 3 visited levels.

### 10. Complete TCP play and documentation

- A complete TCP session goes from the outdoors down to level 2 and back out.
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
| 01 | open | |
| 02 | open | |
| 03 | open | |
| 04 | open | |
| 05 | open | |
| 06 | open | |
| 07 | open | |
| 08 | open | |
| 09 | open | |
| 10 | open | |
| 11 | open | |
