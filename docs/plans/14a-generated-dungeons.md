# Implementation plan: 14a generated dungeons

This plan implements [generated dungeons](../architecture/generated-dungeons.md)
on branch `feat/generated-dungeons`. It lives only on that branch and is deleted
after the user accepts the slice. Read the architecture document, `AGENTS.md`,
and the [architecture overview](../architecture/overview.md) first.

## Ground rules

- Work through the steps in order. After every step `fpas check` passes for
  every changed project and `fpas test --timeout 600 dungeon.fpasworkspace`
  is green. Do not start the next step with a red suite.
- Do not commit, merge, or push unless the user asks.
- Everything named in this plan is decided. Ask the user before deviating from
  it, before changing a persisted or protocol format beyond this plan, before
  changing gameplay numbers, and whenever Functional Pascal lacks something
  (see `AGENTS.md`). Never work around a Functional Pascal gap silently.
- You decide yourself: names of private helpers, splitting a file that grows
  past about 500 lines, the structure of tests, and error message wording.
- Remove code that a step makes dead in the same step.

## Step 1: shared random generator

Goal: one generator for combat dice and dungeon generation; combat results stay
identical.

- New unit `libs/game/src/Dungeon/Random.fpas`, exported in `game.fpasprj`:
  - `public const RandomStateModulus: integer := 2147483648;` (moved from
    `Dungeon.GameState`; update its users).
  - `public type RandomDraw = record public State: integer; public Value: integer; end;`
  - `public function DrawBelow(State: integer; Bound: integer): RandomDraw;`
    computes `Next := ((State * 1103515245) + 12345) mod RandomStateModulus`
    and returns `State := Next; Value := (Next div 65536) mod Bound`.
- `Dungeon.Combat.Roll` becomes `DrawBelow(State.RandomState, Sides)` plus one.
- Move `HostileSightRange` from `Dungeon.Combat` to `Dungeon.Hostiles`.

Acceptance: the existing combat tests pass unchanged.

## Step 2: remove dialogue, Mara, and the tablet; outdoor healing

Goal: no NPC, dialogue, or tablet remains anywhere.

- Game: delete `Dungeon.Dialogue` and `Dungeon.Npcs` (and their exports);
  remove `GameState.Npc`, `ValidateNpc`, `InteriorMap.Tablet`,
  `InteriorMap.Npc`, `InitialDungeonNpc*`, `StoneTabletDescription`,
  `NpcInteractionHint`, `InteractionOutcome.DialogueStarted`, the NPC checks
  in movement, combat (`Blocked`), validation, and visible codes (`n`, `t`).
- Healing: `Dungeon.Movement.MovePlayer` raises `Health` by one per accepted
  outdoor step, capped at `PlayerMaximumHealth`.
- Protocol: remove `ClientMessage.DialogueChoice`, `ClientMessage.EndDialogue`,
  `ServerMessage.Dialogue`, `ServerMessage.DialogueEnded`, the visible dialogue
  types, their limits, names, and validation, and the interior NPC and tablet
  codes. Raise the protocol version from 12 to 13.
- Server: remove `ServerSession.ActiveDialogueNpcId`, the dialogue rejection
  rules in `Session.fpas`, and the dialogue branches in `Handling.fpas` and
  `Replies.fpas`.
- Client: remove the dialogue overlay, model fields, input, and network
  handling, the NPC sprite, and the tablet texture.
- Savegame: remove the `npc` field; raise `SaveGameFormatVersion` to 7. Later
  steps in this plan change the savegame again at format 7.
- Tests: delete `npc_dialogue_test`, `dialogue_protocol_test`,
  `dialogue_ui_test`, `dialogue_network_test`, and
  `dialogue_network_adapter_test`; update the rest. Add a movement test for
  outdoor healing and its cap.
- Docs: delete `docs/architecture/npcs-and-dialogue.md` and remove Mara,
  dialogue, and tablet from the other documents. In the roadmap, stage 11 keeps
  its history and gains one sentence that 14a removed the dialogue until
  stage 15.

Acceptance: a case-insensitive search for `mara`, `dialogue`, `npc`, and
`tablet` in `libs`, `apps`, and `tests` finds nothing.

## Step 3: area view, visited areas, and materialization

Goal: rules receive maps; mutable dungeon content is created on first entry.
The hand-authored initial dungeon still exists and is resolved through the new
unit, so the suite stays green.

- `Dungeon.Hostiles`: add
  `HostilePlacement = record public Id: string; public Kind: HostileKind; public Position: InteriorPosition; end;`
  and remove `RestlessSkeletonId`.
- `Dungeon.Items`: add `public Kind: ItemKind` to `ItemPlacement`; remove the
  fixed item identities and `KnownItemKind`; rename the name and description
  constants after their kinds (`AncientCoinName`, ...).
- `Dungeon.Interior.InteriorMap`: add `public AreaId: string;` and
  `public Hostiles: array of HostilePlacement;`, remove `Hostile`. Extend
  `ValidateInteriorMap`: opponent placements on floor fields, distinct from
  start, exit, each other, and item fields; distinct identities.
- `Dungeon.GameState`:
  - Add `public VisitedAreas: array of string;` sorted with
    `StringComesBefore`, without duplicates. `NewGame` starts with no items,
    no opponents, and no visited areas.
  - `ValidateGameState(View: AreaView; State: GameState)` performs the cheap
    per-intention validation: health, dice state, exploration shape, visited
    areas, unique item and opponent identities, slot rules, every interior item
    and every opponent in a visited area, and the current area. Inside a
    dungeon, `View.Interior` must be present with `AreaId = State.AreaId`; the
    pose must be traversable and free of standing opponents; interior items and
    opponents of the current area must lie on non-wall fields of that map.
  - `AreaView` is declared here, because `GameState` needs it and
    `Dungeon.Areas` imports `GameState`:
    `AreaView = record public Metadata: WorldMetadata; public Interior: option of InteriorMap; end;`
- New unit `libs/game/src/Dungeon/Areas.fpas`:
  - `public function ResolveInteriorMap(Metadata: WorldMetadata; AreaId: string): result of InteriorMap, string;`
    (in this step: only the initial dungeon identity; `InitialDungeonMap`
    takes the metadata, sets `AreaId`, and names its placements
    `<area>:item:<n>` and `<area>:hostile:<n>`).
  - `public function AreaViewFor(Metadata: WorldMetadata; State: GameState): result of AreaView, string;`
  - `public function MaterializeArea(State: GameState; Map: InteriorMap): GameState;`
    adds the area to `VisitedAreas` and creates items
    (`InInterior(Map.AreaId, Position)`) and opponents (full health, not
    alerted) from the placements; a visited area is returned unchanged.
  - `public function ValidateSavedGame(Metadata: WorldMetadata; State: GameState): result of GameState, string;`
    resolves every visited area once and requires that items and opponents
    correspond one to one to the placements of the visited areas (same
    identity and kind; an interior item lies exactly on its placement; an
    opponent's area is its placement's area), that interior discovery exists
    only for visited areas with matching dimensions, then runs
    `ValidateGameState` with `AreaViewFor`.
- Rule signatures take `View: AreaView` instead of `Metadata: WorldMetadata`:
  `StepFirstPerson`, `TurnFirstPerson`, `Interact`, `ResolveTurn`,
  `RevealCurrentArea`. They read the map from `View.Interior` and never
  resolve maps themselves.
- Transitions: `ActivateAreaTransition(View, State): result of AreaTransition, string`
  with `AreaTransition = record public State: GameState; public View: AreaView; end;`.
  Entering resolves the target map, places the player on its start, sets the
  return location, and materializes the area. `InteractionOutcome.Transitioned`
  carries an `AreaTransition`.
- Server: `ServerSession` gains `public Interior: option of InteriorMap;`. New
  game, load, and every transition set it; all rule calls build the view from
  the session. Projection receives the view instead of calling
  `InitialDungeonMap`.
- Savegame: encode `visited_areas` as a string array; decoding and writing use
  `ValidateSavedGame`. Opponents and items of a saved state are validated
  against their placements.
- Tests: add a library project `tests/fixtures/fixtures.fpasprj` (add it to the
  workspace) with unit `Dungeon.Test.Fixtures`. It offers `FixtureDungeonMap()`
  (the current 11 by 9 layout as a map literal with a valid generated area
  identity, the coin, sword, jerkin, and one skeleton) and helpers that build
  an `AreaView` and a state standing at a pose inside it. Game tests use the
  fixture instead of the initial dungeon.

Acceptance: re-entering a dungeon keeps defeated opponents and carried items; a
savegame with an item that matches no placement is rejected; the full suite is
green.

## Step 4: dungeon generator

Goal: deterministic generated maps; not yet reachable in play.

- New unit `libs/game/src/Dungeon/Interior/Generation.fpas`:
  - `public const GeneratedDungeonWidth: integer := 31; GeneratedDungeonHeight: integer := 21;`
  - `public function GenerateDungeon(Seed: integer; RegionX: integer; RegionY: integer; AreaId: string): result of InteriorMap, string;`
  - Attempt `A` from 0 to 15 seeds the generator with
    `PositiveModulo(Seed * 7919 + RegionX * 104729 + RegionY * 1299709 + A * 15485863, RandomStateModulus)`.
  - Follow the five generator rules of the architecture document exactly:
    room size `3 + DrawBelow(5)` by `3 + DrawBelow(3)`; room position chosen so
    the room stays inside the outer wall; a room is rejected when the room grown
    by one field on each side overlaps an earlier room; corridor between room
    centers (integer center `X + W div 2`, `Y + H div 2`) goes horizontal first
    when `DrawBelow(2) = 0`, otherwise vertical first; extra corridor count
    `1 + DrawBelow(2)`, endpoints `DrawBelow(RoomCount)`, skipped when equal.
  - Skeleton count `1 + DrawBelow(2)`, ids `<AreaId>:hostile:<n>` from 0; rooms
    ordered by walking distance of their center from the start, farthest
    first, ties by lower room index; never the exit room.
  - Items in the order coin, sword, jerkin, ids `<AreaId>:item:<n>` from 0; free
    corners in room order (rooms without exit and skeleton first, then the
    others), corners top-left, top-right, bottom-left, bottom-right; skip the
    exit, the start, and fields holding a skeleton.
  - Accept only when `ValidateInteriorMap` passes, at least four rooms exist,
    the floor share (non-wall fields over all fields) is between 25 % and 60 %,
    and no skeleton within `HostileSightRange` has line of sight to the start
    in either direction (`HasLineOfSight`).
- Tests (`tests/game/dungeon_generation_test.fpas`): determinism for equal
  input; different regions differ; every region of a 20 by 20 block around the
  origin for three seeds generates successfully; a fingerprint test pins rows
  and placements of three fixed regions. Measure the mean generation time and
  report it to the user; if it exceeds 20 ms, report before optimizing.

## Step 5: entrances, world metadata, and generated dungeons in play

Goal: the world contains generated dungeons; the hand-authored dungeon is gone.

- New unit `libs/game/src/Dungeon/Terrain/Entrances.fpas`:
  - `RegionCoordinate = record public X: integer; public Y: integer; end;`
  - `RegionOf(Metadata, Position): RegionCoordinate` using `FloorDivide` by
    `Metadata.DungeonRegionChunks * WorldChunkSize`.
  - `EntranceCandidate(Metadata, Region): WorldPosition`: offset inside the
    region is `16 + (((H1 * 1000) + H2) mod (RegionFields - 32))` per axis with
    `H1, H2 := CoordinateHash(Seed, Region.X, Region.Y, 307), (…, 311)` for X
    and salts 313, 317 for Y.
  - `CellIsClearEntrance(Cell: WorldCell): boolean` (moved from
    `IsClearEntranceCell` in `Placement`, which then uses it).
  - `EntranceSite(Metadata, Region): option of WorldPosition` and
    `EntranceRegionAt(Metadata, Position): option of RegionCoordinate` as
    defined in the architecture document. `EntranceRegionAt` computes at most
    one natural cell.
  - `EntranceFieldsInChunk(Metadata, Coordinate): array of WorldPosition`:
    the spawn entrance when inside the chunk, plus the chunk region's candidate
    when inside the chunk and the region is not the spawn region.
- `Dungeon.Terrain.WorldMetadata`: remove `DungeonAreaId`, `DungeonAreaLabel`,
  `EntranceId`, `Entrance`, `EntranceTargetAreaId`; add
  `SpawnEntrance: WorldPosition` and `DungeonRegionChunks: integer`. Raise
  `WorldFormatVersion` to 3 and `WorldGeneratorVersion` to 6.
  `NewWorldMetadata(Id, Seed, DungeonRegionChunks)` rejects region sizes
  outside 1 through 16; `ValidateWorldMetadata` recomputes as today.
- Metadata JSON keys: remove `dungeon_area_id`, `dungeon_area_label`,
  `entrance_id`, `entrance_x`, `entrance_y`, `entrance_target_area_id`; add
  `spawn_entrance_x`, `spawn_entrance_y`, `dungeon_region_chunks` (12 keys).
- Generation: `GenerateChunk` marks a field of `EntranceFieldsInChunk` as an
  entrance when its generated cell is clear; `GenerateWorldCell` uses
  `EntranceRegionAt`. Chunk decoding requires an entrance exactly on those
  fields whose stored cell is clear walkable land, and nowhere else.
- `Dungeon.Areas`: `DungeonAreaId(Metadata, Region)` builds
  `<world>:dungeon:<rx>:<ry>`; `ParseDungeonAreaId` reverses it and requires a
  region that has an entrance site; `ResolveInteriorMap` calls
  `GenerateDungeon`. `GeneratedDungeonLabel := 'Forgotten dungeon'`.
- Transitions and validation: entering uses `EntranceRegionAt` on the player's
  field; the return location must equal the entrance site of the current
  dungeon's region.
- Delete `Dungeon.Interior.InitialDungeon`.
- Configuration: `server.toml` gains `dungeon_region_chunks` (default 4); an
  old file without it is rejected with the existing obsolete-configuration
  error. `OpenWorld` takes the value and uses it only for new worlds.
- Tests: world storage and chunk tests for entrance fields; entrance tests
  (spawn entrance three steps away, deterministic sites, no site on water, at
  most one site per region besides the spawn entrance, region size bounds);
  metadata round trip; `Dungeon.Test.Fixtures` gains a route helper that turns
  a generated map and a target into first-person step and turn intentions for
  server tests. Update the loopback and full-session tests to walk through a
  generated dungeon.

## Step 6: complete TCP visit and documentation

- A server test starts a new game, enters the spawn entrance, defeats or
  avoids the skeletons, picks up an item, leaves, saves, loads, re-enters, and
  checks that defeated opponents and taken items stay gone.
- Synchronize documentation: architecture overview, area transitions,
  first-person interior, interaction, items, combat, persistent game state,
  runtime data (`dungeon_region_chunks`), product terminology in
  `docs/product/world-and-views.md` (entrance region, entrance site, spawn
  entrance, generated dungeon, visited area, materialization), client UI, and
  the roadmap checklist.
- Report to the user: test results, generation time, and anything that
  deviated from this plan. Then wait for review.
