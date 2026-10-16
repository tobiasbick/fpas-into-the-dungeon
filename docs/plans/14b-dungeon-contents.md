# 14b: Dungeon contents

Status: **14b IN REVIEW**. All twelve checkpoints have automated implementation
and verification evidence; independent review findings are corrected. Final user
terminal review and explicit acceptance remain deliberately open because the
review cannot be performed in this cloud environment. Keep this plan; do not
mark DONE or start 13b under this checkpoint.
Prepared on 2026-10-15 after acceptance of 14a and 14s. Follow the
numbered steps in order. Each step is a
small review checkpoint; do not combine the whole feature into one delivery.
Only the game repository belongs to this work. Commit and push require a
separate request; the preceding 14s publication does not authorize publishing
this plan or the later implementation.

## Goal and baseline

Turn the generated dungeon into a repeatable exploration loop: enter a named
dungeon, find equipment and healing, encounter skeletons and giant rats, use a
potion during combat, and continue exactly that state after an explicit save.
No revisit, reconnect or load of that save may duplicate loot or restore a
consumed item or defeated opponent.

Baseline: `feat/generated-dungeons` at `f605c1c`, with protocol 14, world format
3, generator 6, level format 1 and save format 7. The last complete workspace
run passed 68 test programs, zero failures, on 2026-10-15. This is baseline
evidence, not evidence that 14b has been implemented or tested.

At the baseline the generator creates a 31 by 21 dungeon, one or two skeletons
and three fixed items. Its structural validator requires those exact kinds/counts.
Items have floor, carried and equipped locations; saves require exactly one
mutable record per original placement. Combat contains skeleton-specific dice
and death text. The client draws every hostile, including a falling defeated
one, with skeleton art. All of these call sites must change together with their
relevant contracts; adding enum members alone is insufficient.

Read [architecture ownership](../architecture/overview.md),
[world terminology](../product/world-and-views.md),
[generated dungeons](../architecture/generated-dungeons.md),
[level storage](../architecture/dungeon-level-storage.md),
[combat](../architecture/combat.md), [inventory](../architecture/items-and-inventory.md)
and [persistence](../architecture/persistent-game-state.md) before implementation.

## Fixed scope and product decisions

- Two opponent kinds: the existing Restless skeleton and a Giant rat. Both use
  existing dormant/alerted perception, pathfinding and one-action-per-turn AI.
  No new AI system, classes, attributes, experience or levels.
- One new item kind: Healing potion. One item identity means one potion; no
  stacking, empty bottles, cooldowns, charges, shops or equipment rarity.
- Loot means generated **floor finds** in this slice. There are no containers,
  corpses or drops on opponent death. This avoids introducing a second origin
  system and rules for a blocked death field. Later death loot needs its own
  explicit design; do not quietly add it during 14b.
- Every dungeon keeps a guaranteed coin, sword and jerkin and gains one
  guaranteed potion. Two optional floor-find slots use the table below.
- Names and contents depend only on the world seed and numeric entrance
  region, with fixed domain seeds. World ID affects entity IDs, not selection
  of names or kinds. Display names need not be unique; area IDs remain unique.
- Keep geometry dimensions, entrance density, exit/return rules, inventory
  capacity 64, explicit saving, world selection and outdoor step healing.
  No new runtime configuration or settings fields.
- Implement progression as 13b after this feature; deeper levels remain 14c.
  Do not add stairs, NPCs, dialogue or LLM integration here.

### Opponents

| Kind / persisted spelling | Health | Hit roll | Damage | Visible code |
| --- | --- | --- | --- | --- |
| Restless skeleton / `restless_skeleton` | 12 | d20 >= 9 + player armor | d4 | `h` |
| Giant rat / `giant_rat` | 6 | d20 >= 12 + player armor | d2 | `r` |

Keep the existing sight range of six fields, stable hostile-array turn order,
collision rules and combat RNG. Each final generated dungeon contains exactly
two opponents: slot 0 is a skeleton in the farthest eligible room; slot 1 is a
rat in the next farthest. They occupy different rooms outside the exit room.
Neither may initially see the start. Reuse the bounded generation retry policy
when placement fails; never relax this safety rule to obtain a layout.
Use kind-specific display/death text: a rat must not collapse into bones.

### Names and independent generation draws

Add `Dungeon.Interior.Generation.Content` in `libs/game` for the small pure
content interface. It owns the following seed derivation and fixed tables;
geometry and combat must not acquire a dependency on external randomness.

For `M = Dungeon.Random.RandomStateModulus` (2^31), define:

```text
S = PositiveModulo(
      PositiveModulo(world_seed, M) * 7919
    + PositiveModulo(region_x, M) * 104729
    + PositiveModulo(region_y, M) * 1299709
    + domain, M)
```

Normalize inputs before multiplication; intermediate values fit signed 64-bit
integers even for negative/extreme inputs. Do not use Abs, a wall clock, process
hashing, filesystem enumeration or `GameState.RandomState`. Domain 1009 is for
the name; 2003 and 2011 are for optional slots 4 and 5. Draw independently from
each derived seed with existing `Random.DrawBelow`. Optional slots always use
their own domain, including when another slot is empty. Geometry retains its
existing seed/attempt stream; content selection cannot consume geometry draws.

The name uses two draws below 8, the second from the first draw's successor:

- Adjectives in order: Ashen, Silent, Forgotten, Sunken, Broken, Moonlit,
  Hollow, Shrouded.
- Nouns in order: Vault, Crypt, Halls, Sanctum, Catacombs, Keep, Depths, Tomb.
- Join with one space. Store the resulting `InteriorMap.DisplayName` as the
  required level-file `name`; do not recompute it on read, rendering or load.
  Names are nonempty printable ASCII, at most 64 characters, without leading
  or trailing spaces. Fixtures provide explicit names under the same bound.
  Level validation is structural and does not rerun name generation.

The public content interface consists of `DungeonName(Seed, RegionX, RegionY)`
returning a string and `OptionalLoot(Seed, RegionX, RegionY, Slot)` returning
`result of (option of ItemKind, string)`. The latter accepts only slot 4 or 5.
Keep the seed helper and name tables private. Expose `LootForRoll(Roll)` with
the same result type for exhaustive table tests; reject rolls outside 0..99.
Add loot functions only in checkpoint 08. Do not introduce configurable
registries or a general random-stream framework.

### Loot slots, identities and placement

| Original slot | Kind | ID suffix |
| --- | --- | --- |
| 0 | Ancient coin | `:item:0` |
| 1 | Rusty short sword | `:item:1` |
| 2 | Leather jerkin | `:item:2` |
| 3 | Healing potion / `healing_potion` | `:item:3` |
| 4, 5 | Optional result, each rolled below 100 | `:item:4`, `:item:5` |

| Roll | Result | Weight |
| --- | --- | --- |
| 0..29 | No item | 30 |
| 30..59 | Ancient coin | 30 |
| 60..89 | Healing potion | 30 |
| 90..94 | Rusty short sword | 5 |
| 95..99 | Leather jerkin | 5 |

Reuse `ItemPlacementId(area_id, original_slot)`. Store existing placements in
ascending slot order, omitting empty slots. An absent slot 4 never renumbers
slot 5: `[0,1,2,3,5]` is valid. There are 4..6 item placements, not necessarily
contiguous suffixes. Same-kind items from different slots remain separate IDs.

Place in slot order on distinct ordinary floor corners, using the existing
stable corner order and preference for rooms without exit or opponents. Skip
start, exit, occupied corners and hostile placements. If there are insufficient
corners for the selected items, reject that generation attempt instead of
dropping required/rolled items or moving them onto an invalid field.
Stored levels enforce required slot kinds, allowed optional slots/kinds and
ordering, canonical identities, placement lengths, no overlap and all existing
geometry/sight rules. They do not reroll a table to compare against the seed.

### Consumption and turn contract

Extend `ItemLocation` with payload-free `Consumed`. It is a terminal location
for Healing potions only. Retain ID and kind in `GameState.Items`; never remove
the record or create a replacement item. It has no field, owner or slot and is
excluded from inventory capacity, equipment, collision, inspection and visible
rows. Full save validation still matches it to exactly one original placement
of a visited area, even if the player consumed it in another area.

`Dungeon.Consumables.UseItem(State, ItemId)` returns a pure item-use change
(replacement state and message). Its caller supplies validated state. It only
accepts a carried Healing potion while health is below derived maximum health.
Restore `min(6, maximum - health)` points and mark that exact ID consumed in
one replacement state. No RNG draw occurs in the potion rule itself.

`Combat.TurnAction.UseItem(ItemId)` performs this change, records actual healing
in the turn log and then runs the existing hostile phase exactly once. Potion
use works outdoors too; no hostile phase or extra outdoor step healing occurs
there. Preserve the general turn pipeline, including defeat if attackers
overwhelm the healed player. With the final generated pair, combined maximum
damage is six, so a potion at health one protects that particular turn. Test
the defeat branch with an independent valid fixture containing three attackers;
do not invent an impossible two-opponent scenario. Saving remains explicit;
defeat never writes or deletes a save.

Reject unknown IDs, non-consumables, floor/equipped/consumed items and use at
full health. Rejection leaves the entire state, RNG, opponents and session dirty
flag unchanged and consumes no turn. A repeated request for the same consumed
ID must fail even when the client still displays an older inventory.

### Protocol and presentation

- Add strict client intention `use_item`: exactly `type` and nonempty `item_id`
  within the existing 128-character ID bound. The client sends no healing amount,
  item kind, health, position or replacement state.
- Add required boolean `usable` to each visible inventory entry in both view
  families. It describes item capability: true only for a carried Healing potion,
  including at full health. It must be false for worn/slotted items. The server
  still validates current health; the client does not implement the rule.
- Preserve `h` for skeletons; add interior codes `r` for rats and `p` for potions.
  These are view-specific codes; outdoor river/path codes remain unchanged.
  Extend producers, protocol alphabet/validation, map glyphs/colors, Fog of War
  stripping, raycaster sprites and independent cell-code contract tests together.
- Extend game combat facts with the involved `HostileKind`. Extend each wire
  combat event with required `hostile_code` (`h` or `r`): target kind for player
  hit/miss/defeat, acting kind for hostile hit/miss. Keep existing kind/amount
  semantics and limits. A defeated rat is absent from the final rows; the event
  must still let the client draw the correct fallen sprite. No hidden opponent
  IDs, positions or mutable rule values are transmitted.
- Inventory Enter uses a usable item, otherwise keeps existing equip/unequip
  behavior. `D` still drops a carried item. Show the selected action in the
  overlay, preserve pending-request guards and clamp selection after removal.
  Full-health rejection leaves the potion selected and shows the server reason.
  Do not infer capabilities from names or add a second use shortcut.
- Healing reports actual restored points in the existing turn log and updates
  projected health. Do not fabricate a player attack event or weapon swing.
  Existing hostile events may still animate the response. Reuse the existing
  bounded animation clock/cache; render rat and skeleton art at their appropriate
  heights, including fallen sprites, without changing the camera or field of view.
- First-person title, exploration-map label, context location and dashboard use
  the retained map's stored display name. Diagnostics must not read a level or
  regenerate a name. Remove `Identities.GeneratedDungeonLabel` after all callers
  are replaced; identity parsing stays independent of presentation.

## Versions and data protection

| Contract | Baseline | 14b | First changed in |
| --- | --- | --- | --- |
| World metadata/chunk format | 3 | 3 | Unchanged JSON shape |
| World generator | 6 | 7 | Step 02: name becomes generated output |
| Immutable level format | 1 | 2 | Step 02: required `name`, then new contents |
| Protocol | 14 | 15 | Step 03: rat codes and typed combat facts |
| Savegame | 7 | 8 | Step 03: new hostile kind; Step 04 adds consumed |
| Runtime configuration | Current | Unchanged | No new settings |

Bump each changed contract once for the entire 14b feature, not once per step.
Intermediate development worlds are disposable and are not a compatibility
promise; final acceptance covers the complete formats below. Keep each step
compilable/testable and avoid a compatibility reader or unfinished feature flag.

Generator-6 worlds are incompatible with the completed feature even though
world format remains 3. Keep their directories and saves untouched; show a
clear reason in the catalog and instruct recreation/deletion by the user.
Protocol 14, level format 1 and save format 7 are rejected, never migrated.
No automatic recreation, repair or deletion, including for malformed current
files. New compatible worlds can be created and continued normally.

Level format 2 has the previous 12 exact required fields plus required `name`.
Item/hostile placement objects keep their exact four fields. Save format 8 keeps
its root/item object structure and adds `{"kind":"consumed"}` as an exact
one-field location variant; reject extra coordinates, owner or slot fields.
Retain the existing three-phase save loading, once-per-visited-level reads,
65536-character level bound and 65536-byte protocol line bound. Names, tables
and placement changes require deliberate fingerprint updates with generator 7.

## Ownership and implementation surface

Use existing projects; do not create a new library, dependency direction or
test harness. Add exports only where a production caller crosses the interface.

| Concern | Files / interface |
| --- | --- |
| Pure content selection | New `libs/game/src/Dungeon/Interior/Generation/Content.fpas`; `DungeonName`, `OptionalLoot`, bounded table selection |
| Immutable name and placement rules | `Interior.fpas`, `Interior/Generation.fpas`, `Interior/Generation/Validation.fpas`; generic fixtures remain independent of generated counts |
| Kind data and codes | `Items.fpas`, `Hostiles.fpas`; move hostile hit/damage/death text behind kind queries and remove duplicate skeleton constants from `Combat.fpas` |
| Pure use and turn ordering | New `libs/game/src/Dungeon/Consumables.fpas`; `UseItem`; extend `Combat.fpas` actions and facts |
| Mutable invariants | `GameState.fpas`, `Areas.fpas`, `Areas/Validation.fpas`, `Interaction.fpas`, `Equipment.fpas`; every location match handles Consumed explicitly |
| Stored formats | `libs/world/src/Dungeon/World/Names.fpas`, `Interiors/Encoding.fpas`, `Savegame/Entities.fpas`, `Savegame.fpas`; orchestration remains in existing modules |
| Wire contract | `libs/protocol/src/Dungeon/Protocol.fpas` and `Names`, `Validation`, `Fields`, `ClientMessages`, `ServerMessages`; strict encode and decode |
| Authoritative handling | `apps/server/src/Dungeon/Server/Session.fpas`, `Handling.fpas`, `Mapping.fpas`, `Projection.fpas`, `Replies.fpas`, `Diagnostics.fpas`; existing commit/reject seam |
| Client behavior | `Character.fpas`, `Model.fpas`, `Ui/Input.fpas`, `Ui/Events.fpas`, `Ui/Intentions.fpas`, `Ui/Playback.fpas`, `Ui/MapCells.fpas`, `Animation.fpas`, `Raycast.fpas` and `Raycast/Art.fpas`, `Raycast/Sprites.fpas` |
| Fixtures and measurement | `tests/fixtures`, `tests/levels`, existing protocol/render/network fixtures and `tools/persistence-bench`; add names/cases without importing production generation into authored rule fixtures |

Keep concerns focused, normally below 500 lines. Split an affected responsibility
if needed; do not reorganize unrelated modules. No wrappers for obsolete public
helpers. Add purpose comments and document public declarations/invariants.

## Ordered implementation checkpoints

For each checkpoint below, implement only its stated behavior, update its
checkbox/evidence, format changed sources, check every affected project and run
the relevant test projects. Before any handback, run the complete workspace
suite. No skipped/red tests, broadened deadlines or temporary compatibility
paths count as completing a checkpoint. A later generator integration step is
allowed to make earlier fixture-tested kinds naturally reachable in play.

### 01. Recheck baseline and prepare meaningful fixtures

- [x] Recheck branch/diff, compiler snapshot and the versions above. Run baseline
  checks/full suite; distinguish code failures from sandbox loopback restrictions.
- Preserve independent authored geometry; add narrow builders for named maps,
  rat encounters and carried potions only as their production types become
  available. Pin deterministic RNG states for hit/miss/damage tests.
- Positive: current save/revisit/drop and equipment/combat regressions stay green.
  Negative: invalid fixture pose/origin remains rejected. Edge: empty unvisited
  state and two visited areas remain valid independent of array/map order.
- Exit: exact baseline evidence is recorded; no gameplay or format change yet.

Checkpoint 01 evidence (2026-10-15):

- Branch/HEAD rechecked: `feat/generated-dungeons` at `f605c1c`. Initially only
  this plan and its roadmap entry were uncommitted. No production source,
  generated fingerprint or format version changed: protocol 14, world 3,
  generator 6, level 1 and save 7 remain the actual running baseline.
- Before editing tests, formatting and all 20 workspace project checks passed;
  the complete workspace suite passed **68/68 programs, zero failures**.
- Extended `combat_test`, `fixtures_test` and `multi_area_validation_test`.
  Four independently calculated RNG vectors (0, 1, 2, 3) pin hit/miss facts,
  damage, full resulting state and exact final RNG. Negative cases include
  wall/out-of-bounds poses and a canonical but nonexistent placement origin.
  Reverse item/opponent arrays and reversed supplied-map order remain valid;
  revisits preserve that exact state. `VisitedAreas` must still stay sorted.
  Existing empty-new-game, save/revisit/drop and equipment regressions remain.
- Added the test-only `Dungeon.Test.StateComparison` interface and fixture
  export: every state field, array element and discovery bit is compared
  without validation, normalization or storage. Real indoor/outdoor discovery
  exercises idempotence and detection of a single changed bit. Authored
  geometry is unchanged. Named-map, rat and potion builders wait for their
  production types in steps 02, 03 and 04, as required above.
- An initial authoring check failed with `error[FP3006]: Equality requires
  compatible operands whose values all compare`. Whole-state/array `=` was
  not permitted in these tests; element comparisons now follow the existing
  language rules. No FPAS defect was found and no compiler/library source changed.
  After correction, the affected game test project passed **19/19 programs**;
  final verification also includes the subsequently added discovery assertions.
- Compiler: existing ignored `.temp-data/dashboard-toolchain/fpas.exe`,
  `fpas 0.0.1`, SHA-256
  `14b48f0140f18c622a2258d6440c582a4520581d53aeda16511b0fa088bd4c96`.
  Its matching copied library has 131 source/project files; SHA-256 of the
  relative-path/file-hash manifest is
  `ae98bc4629c7c48f203725c111d7940108268270e82e7e4c20d9527299fe7a4f`.
  Its `--version` output contains no source Git revision; that revision was not
  recorded with the copy and remains unknown, rather than being inferred from
  a concurrently edited checkout.
- Commands use that compiler with `--std-lib .temp-data/dashboard-toolchain/lib`
  for workspace checks and tests. Baseline/final commands are `fmt --check apps
  libs tests tools`, `check dungeon.fpasworkspace` and `test --timeout 600 --jobs
  1 dungeon.fpasworkspace`; the focused run used `tests/game/game-tests.fpasprj`.
  Changed sources were formatted before checking. Full TCP suites ran outside
  the sandbox socket restriction, in the background. Final formatting and
  all 20 project checks passed; the complete suite with all new assertions
  passed **68/68 programs, zero failures**. `git diff --check` and documentation
  link checks also passed. This completes the checkpoint 01 baseline.

### 02. Generate, store and project dungeon names

- [x] Add the pure name/domain-seed implementation, `InteriorMap.DisplayName`,
  exact level field, generator 7/level format 2 and name validation. Update
  authored map constructors and the level-storage contract in this checkpoint.
- Project stored names into all current labels and dashboard; remove the generic
  label constant. Existing-only reads/diagnostics must not invoke generation.
- Positive: named map round trip; all labels agree; same seed/region reproduces
  the name; two different world IDs keep the same name with distinct area IDs.
  Negative: missing/extra/duplicate/mistyped/blank/control-containing/overlong
  name, old level/generator, mismatched area and missing visited level reject
  without replacement. Edge: exactly 64 characters; negative region coordinates,
  zero and signed-32-bit seed extrema; repeated names are valid, not collisions.
- Extend `dungeon_generation_test` fingerprint serialization to include stored
  names and explicit hostile kinds; record why expected output changes.
- Exit: first entry, re-entry and load show the stored name and preserve bytes.

Checkpoint 02 evidence (2026-10-15):

- Implemented `Content.DungeonName` and required stored `DisplayName`/`name`.
  Generator is now 7 and level format 2. World format 3, protocol 14, save 7
  and runtime configuration remain unchanged; older data is rejected intact.
- New `dungeon_names_test` pins eight independent vectors, including negative
  regions and signed-64-bit extremes, same names across different identities,
  repeated names and 1/64/65-character, whitespace, ASCII/control bounds.
- New `dungeon_name_storage_test` verifies named first entry, structurally valid
  stored overrides, revisit/load, twenty malformed/obsolete-file cases with
  byte preservation, missing visited levels with an untouched save and
  non-destructive rejection of generator-6 world metadata.
- Session-map, real client/TUI, loopback and dashboard TCP regressions prove
  retained names in primary/context titles, exploration map and diagnostics,
  including save/reconnect/load. No generic production label remains.
- Dungeon fingerprints deliberately gain name and explicit hostile kind;
  existing geometry/placements and the outdoor fingerprint are unchanged.
- Same game-local compiler/library snapshot as checkpoint 01. Final
  `fmt --check apps libs tests tools` and all 20 workspace checks pass.
  Focused projects passed 20/20 game and 8/8 world programs. Final
  `test --std-lib .temp-data/dashboard-toolchain/lib --timeout 600 --jobs 1
  dungeon.fpasworkspace` passed **70/70 programs, zero failures** outside the
  socket sandbox. Diff, purpose comments and documentation links pass.
  No FPAS files changed; no commit/push. This evidence predates checkpoint 03.

### 03. Support a giant rat through combat, storage and rendering

- [x] Add the rat kind, stats/name/death text and kind-to-code mapping. Replace
  skeleton-only combat constants with kind queries; keep AI and RNG ownership.
- Move save format to 8 when introducing the persisted rat kind. Move protocol
  to 15; add rat code and mandatory typed hostile facts, including
  the involved kind on game events. Update codecs, projection, animation and
  sprites together; fixtures can exercise rats before generation selects them.
- Positive: exact rat health/hit/damage, rat/skeleton mixed turns, persistence
  round trip, correct visible and falling art. Negative: unknown kind/code,
  invalid event kind/amount/code, rat health 7 and obsolete handshake reject;
  rat death text/art cannot use skeleton behavior. Edge: rat health 0/1/6,
  armored hit threshold boundaries, occluded/remembered rat, both enemies acting
  in stable order, tiny viewports and death already absent from final rows.
- Exit: real TCP fixture combat and client animation tests distinguish both
  kinds without adding monster statistics or AI rules to the client.

Checkpoint 03 evidence (2026-10-16):

- `Dungeon.Hostiles` owns rat health 6, d20 threshold 12 plus armor, d2 damage,
  `giant_rat` persistence mapping, visible `r`, inspection and death text.
  Combat facts retain the target/actor kind and mixed kinds act in stored order.
- Save format is 8 and protocol 15 requires `hostile_code` on every combat
  event. Unknown/missing/duplicate codes and invalid hit/miss/defeat amounts
  reject. Level format 2, generator 7, world format 3 and generation output
  are unchanged; automatic rat placement remains checkpoint 09.
- Six new programs protect independent combat vectors and armored thresholds,
  rat level/save round trips and rejected-save preservation, strict wire fields,
  kind-specific standing/fallen sprites and effects, masked/remembered fields,
  mixed-kind TCP replies and a production handshake/load/attack session.
  Empty-width/height rendering returns an empty grid rather than invalid clamp
  bounds. The existing independent field-code contract now exercises both kinds.
- Validation used the ignored `.temp-data/rat-toolchain` release compiler and
  copied matching library, originally built from FPAS `33814ef3`. Compiler
  SHA-256: `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  No FPAS repository files changed.
- `fpas fmt --check apps libs tests tools`,
  `fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace`
  (all 20 members), and `git diff --check` pass. The complete
  `fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1
  dungeon.fpasworkspace` run passed **76/76 programs, zero failures**.
  After review added explicit occlusion/memory and named-code checks to two
  programs, their focused rerun passed **2/2**, and formatting/workspace checks
  passed again. No production code changed after the full suite started.
- Intermediate focused runs exposed the zero-height renderer issue and stale
  event/version fixtures; both were corrected before the full green run.
  Independent subagent review requested documentation version corrections and
  the two explicit edge checks. All were addressed; follow-up review found no
  remaining blockers. No commit or push. This evidence predates checkpoint 04.

### 04. Add potion identity and persistent consumed state

- [x] Add Healing potion, `Consumed` and strict shared kind/location mappings
  within this feature's save format 8. Update every location match in game,
  world, server, tests and tools.
  Potions use visible code `p`; update its producer, alphabet and floor art now.
- Positive: floor/carried/consumed potion round trips; consumed origin matches
  its visited placement; it is absent from inventory, floor and equipment.
  Negative: consumed coin/weapon/armor, equipped potion, missing/duplicate/foreign
  origin, extra consumed-location fields and save format 7 reject. Edge: 64
  carried/worn items plus consumed records remains within capacity; 65 carried
  items rejects; consuming in a different visited dungeon retains original ID.
- Exit: full save/load and materialization validation retain terminal records;
  there is no usable-item intention yet and no temporary migration path.

Checkpoint 04 evidence (2026-10-16):

- Added `HealingPotion`, persisted as `healing_potion`, without an equipment
  slot, and the payload-free terminal `Consumed` location. Only potions can
  use it. The exact location JSON is `{"kind":"consumed"}`; missing/unknown
  kind, duplicate keys and extra coordinates/area/slot/owner fields reject.
  Full saved-state validation retains every original identity and kind,
  including consumed records, rather than removing or rematerializing them.
- Updated every location match in game, persistence, server and tests. Consumed
  records appear in neither inventory, worn slots, floor codes nor interaction
  targets and do not use capacity. Existing inspection/pickup/drop can handle
  an ordinary potion; consumed potions reject those operations.
- Added visible code `p`, a crimson flask sprite and map `!`; both masked
  projections strip all remembered floor-item markers. Outdoor path codes
  remain unchanged. The independent field-code contract covers the potion.
- Stored level validation accepts three required base placements plus optional
  exact slot 3 `healing_potion`, enabling real full-save fixtures. The generator
  still emits three base items and its fingerprints remain unchanged. World 3,
  generator 7, level 2, protocol 15 and save 8 remain current. No use intention,
  healing rule, usable flag, random loot or generated potion placement is added.
- New `potion_state_test` covers terminal validation, interaction exclusion,
  inspection/pickup/drop, materialization, missing/duplicate/foreign origin and
  64/65 inventory bounds. `potion_storage_test` covers real floor/carried/consumed
  round trips, consumption-state fixtures in another visited area, immutable
  level bytes, malformed saves preserved intact, and complete save/load of
  17 visited levels with 64 carried/worn plus four consumed records.
  `potion_projection_test` covers wire rows, inventory exclusion and both
  remembered-field projections. Existing floor-render, map UI and named-code
  contract tests were extended.
- Reused the ignored `.temp-data/rat-toolchain` release compiler/library from
  FPAS `33814ef3`, SHA-256
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  `fpas fmt --check apps libs tests tools`,
  `fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace`
  (all 20 members), and `git diff --check` pass. Final complete
  `fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1
  dungeon.fpasworkspace` passed **79/79 programs, zero failures**.
  An intermediate check caught incompatible bindings in grouped case arms;
  unused payloads now use `_`, and all subsequent checks/tests pass.
- Independent subagent review compared this checkpoint with the preserved
  checkpoint-03 source snapshot and found no actionable defects or missing
  required coverage. Documentation and roadmap are updated. FPAS files remain
  unchanged; no commit/push. This evidence predates checkpoint 05.

### 05. Resolve item use as one authoritative turn

- [x] Add `Consumables.UseItem` and `TurnAction.UseItem`, with heal-before-hostiles
  ordering, actual-healing log, kind-safe validation and no potion RNG draw.
- Positive: health 10 becomes 16 before enemy action; health 18 heals only 2;
  a potion is consumed once, freeing capacity; outdoors use heals without a
  hostile phase. Negative: unknown/non-carried/consumed/non-consumable item and
  full health return Error with whole-state/RNG equality and no enemy action.
  Edge: health 1, two carried potions with identical names, stale repeated ID,
  enemy hit/miss after healing and defeat in the three-attacker fixture.
- Add `tests/game/consumables_test.fpas`; retain independent expected health/RNG
  outcomes and count hostile actions rather than only inspecting the log text.
- Exit: accepted use follows the same continued/defeated turn outcomes as attack.

Implementation evidence on 2026-10-16:

- `Dungeon.Consumables.UseItem` accepts only a carried Healing potion below the
  derived maximum. It restores at most six points, reports the actual amount,
  marks only the selected ID consumed and draws no dice. The unit remains an
  internal game-library implementation; no test-only export was added.
- `Combat.TurnAction.UseItem` applies that change before the existing single
  hostile phase and returns the existing continued/defeated outcomes. Outdoors
  it adds no hostile phase or step healing. Rule errors return before any
  opponent acts. Protocol/session, inventory controls and generation are
  unchanged; those remain checkpoints 06 onward.
- New `consumables_test.fpas` covers health 10->16, 18->20 and 1->7, complete
  expected state and RNG, capacity 64->63, two identically named potions used
  by separate IDs, stale repeats, outdoors with stored alerted opponents, and
  unknown/floor/consumed/non-consumable/full-health rejection. Independently
  pinned hit/miss vectors assert exact hostile events and random state. The
  health-one mixed encounter survives after healing before two hits; a fully
  validated three-attacker authored fixture reaches defeat after damage 1+2+4.
- Reused the ignored `.temp-data/rat-toolchain` compiler/library from FPAS
  `33814ef3`, SHA-256
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  Formatting, `fpas fmt --check apps libs tests tools`,
  `fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace`
  (all 20 members), and `git diff --check` pass. The focused new test passes;
  the complete `fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600
  --jobs 1 dungeon.fpasworkspace` passed **80/80 programs, zero failures**.
  The initial focused run caught an incorrect expected existing combat-log
  suffix in the test; its expectation was corrected before the successful runs.
- Independent read-only subagent review against the checkpoint-04 source
  snapshot found no relevant defects or missing required coverage. Architecture,
  product terms, README and roadmap are updated. The FPAS repository remains
  unchanged; no commit/push. This evidence predates checkpoint 06.

### 06. Expose strict use intentions and server projections

- [x] Add `use_item` and required inventory `usable`, update exact encode/decode
  and validation for both visible-state families. Handle via existing active
  session/turn commit path; stable rule rejection code is `item_use_rejected`.
- Positive: client-message and both inventory-state round trips, session use,
  actual healed health/log, successful use marks unsaved progress and updates
  dashboard state. Negative: missing/extra/duplicate/null/wrong-type fields,
  empty/129-character ID, client-supplied heal amount, inconsistent usable+worn
  or slotted entry, use before active session and stale ID reject. Edge: ID
  length 1/128, 0/64 inventory entries, full-health capability remains true but
  server rejects, repeated same-ID wire request consumes only once.
- Check UTF-8 transport at 65536 bytes and rejection at 65537, with escaped text;
  prove the generated 31-by-21 view plus full inventory/log/events still fits
  the existing line budget. Exercise full inventory in outdoor projections too.
  Do not silently omit inventory or raise the limit for oversized messages.
- Extend protocol/server/internal tests. On rejected/preparation-failed requests,
  retain installed state, map, RNG, dirty flag and last successful save time.
- Exit: real TCP use obeys the rule and no client state mutation is trusted.

Implementation evidence on 2026-10-16:

- Protocol 15 now encodes/strictly decodes `use_item` with only `type` and a
  1..128-character `item_id`. Both inventory projections require boolean
  `usable`; usable entries cannot be slotted or worn. Projection derives the
  flag from the authoritative kind, including at full health. Existing message
  case arms and authored inventory values explicitly include the new contract.
- The server requires an active session and dispatches through `PlayTurn` with
  `item_use_rejected`. Turn preparation reveals and projects the candidate and
  checks its encoded UTF-8 size before sending. Only a successful send installs
  state/world cache and marks progress dirty; rule/preparation failures return
  the original session, retaining map, RNG, dirty flag and last save timestamp.
  Send failures still return an error and close the connection. Dashboard facts
  and the client adapter's state/defeat response classification use this path.
- New `item_use_protocol_test` covers exact encoding, strict field/type and
  duplicate rejection, ID bounds, both state families, required capability,
  slot/wear consistency and 0/64/65 inventory entries. `transport_limits_test`
  exercises actual TCP framing at 65536 UTF-8 bytes with Unicode and JSON
  escapes, rejects 65537-byte reads/writes, and proves rejected writes emit no
  prefix. `item_use_projection_test` checks a generated 31-by-21 view with full
  inventory, log and event counts within the existing budget, plus full outdoor
  inventory projection and full-health capability.
- New internal `item_use_session_test` pins heal-before-hit health/RNG and
  events, consumed identity, dashboard facts and stale/full-health rejection.
  Blocked outdoor storage and an oversized candidate response both preserve the
  installed session. `item_use_network_test` drives the production client
  adapter and server through handshake, premature use, load, partial healing,
  repeated ID rejection and refresh; stored level/save bytes remain unchanged.
- Reused the ignored `.temp-data/rat-toolchain` compiler/library from FPAS
  `33814ef3`, SHA-256
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  Formatting, `fpas fmt --check apps libs tests tools`,
  `fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace`
  (all 20 members), and `git diff --check` pass. Focused protocol, projection,
  session and TCP tests pass. The complete
  `fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1
  dungeon.fpasworkspace` passed **85/85 programs, zero failures**.
- Independent read-only subagent review against the checkpoint-05 snapshot
  found no relevant defects or missing required coverage. Documentation is
  updated. World format 3, generator 7, level format 2, protocol 15 and save
  format 8 remain unchanged, as does the FPAS repository. No commit/push;
  this evidence predates checkpoint 07.

### 07. Make inventory use playable with existing controls

- [x] Enter chooses use/equip/unequip from projected capability and wear state;
  keep D/drop, modal isolation, pending guards and overlay ownership. Rename
  obsolete equipment-only request helpers instead of retaining wrappers.
- Positive: actual headless Enter queues exactly one UseItem; accepted state
  removes the selected potion and shows health; rejection keeps the potion and
  reason. Negative: coin Enter, invalid selection, disconnected/inactive/pending
  session, closed/full request channel and unrelated overlay queue no use.
  Edge: empty inventory, first/middle/last/only item consumed, stable selection
  after authoritative refresh, two same-name potions, resize/narrow/zero-size
  views, animation interruption and late ticks after defeat/disconnect.
- Extend `inventory_ui_test`, `equipment_ui_test` and client network adapter tests.
  No optimistic healing, pickup announcement on consumption or inferred rules.
- Exit: potion use is reachable through real keyboard routing and server replies.

Implementation evidence on 2026-10-16:

- `SelectedItemRequest` replaces the equipment-only helper without a wrapper.
  Inventory Enter selects `UseItem` from projected `usable` before existing
  equip/unequip actions. It uses neither item names nor a client healing rule.
  The overlay shows current health and the selected Enter action; `D` still
  drops the same selected identity. Requests need an active visible session,
  no pending request and a writable channel. Only server replies replace
  inventory and health; rejection leaves the selected potion and server reason.
- Authoritative refreshes retain the selected item by stable ID, including
  identical names and reordered entries. A removed ID clamps its previous
  index to the remaining list; an empty inventory selects zero. Explicit
  navigation continues to wrap.
- Extended `inventory_ui_test` covers first/middle/last/only removal, unchanged
  and reordered identities and invalid-selection recovery. `equipment_ui_test`
  retains equip/unequip and drop tests, adding use capability at full health,
  rejection, action labels and dropping the same potion. New
  `item_use_ui_test` drives headless I/Enter in both view families, asserts one
  exact item-ID request, pending guards, accepted/rejected model and screen
  updates, no optimistic changes or pickup announcement, lookalike names,
  inactive/invalid/empty/modal/closed/full-channel cases and 60/1/0-size views.
- The existing `item_use_network_test` now injects headless I/Enter through the
  production client adapter and server, then installs the real reply in the
  model. It verifies pending unchanged health/inventory, partial healing,
  removal with the overlay retained, stale wire rejection and unchanged stored
  save/level bytes.
- Lifecycle tests cover interrupted hostile playback and late ticks after
  defeat/disconnect. They exposed incorrect focus when closing a defeat report
  during a pending catalog refresh; focus now targets Cancel. Disconnect and
  server-error events return to the start screen with no active visible state.
  Independent review found an additional reachable transport-failure path:
  resize during pending use, hostile animation in its reply, deferred viewport,
  then `BackgroundFailed`. That handler now also stops playback and returns to
  the start screen. The regression exercises this sequence and proves late
  ticks neither resume playback nor schedule ticks; confirmed state is retained.
- Formatting, all 20 workspace project checks, `git diff --check`, all 18 client
  test programs and the focused real keyboard/TCP test pass. The independent
  subagent rechecked the lifecycle correction and found no remaining relevant
  defects or missing required coverage. The final complete
  `fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1
  dungeon.fpasworkspace` passed **86/86 programs, zero failures** after that
  correction. `fpas fmt --check apps libs tests tools` and
  `fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace`
  also pass for the final source.
- Reused the ignored `.temp-data/rat-toolchain` compiler/library from FPAS
  `33814ef3`, SHA-256
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  Documentation and roadmap are updated. World format 3, generator 7, level
  format 2, protocol 15 and save format 8 remain unchanged, as does the FPAS
  repository. No commit/push; this evidence predates checkpoint 08.

### 08. Implement bounded loot selection with independent draws

- [x] Add the fixed roll table and two slot-specific draws to the content module.
  Do not wire it to placement until its deterministic contract is proven.
- Positive: exhaust all 100 rolls and verify exact weights/outcomes; pin hand
  checked seed/region/domain vectors and reproducible optional outcomes.
  Negative: roll -1/100 and slot 3/6 reject rather than clamp or wrap.
  Edge: every range endpoint, signed seed extrema, negative regions, slot 4
  empty while slot 5 exists, same seed under different world IDs, repeated
  queries and changed query order leave geometry/combat RNG unchanged.
- Add `tests/game/dungeon_contents_test.fpas`; compare independent expectations,
  not only two calls to the same implementation or probabilistic distribution.
- Exit: exact table/seed behavior is testable without filesystem or combat.

Implementation evidence on 2026-10-16:

- `Dungeon.Interior.Generation.Content` now provides `LootForRoll` and
  `OptionalLoot` with the planned result types and strict roll/slot bounds.
  The fixed table returns empty/coin/potion/sword/jerkin with weights
  30/30/30/5/5. Slots 4 and 5 each draw once from their own domain (2003/2011).
  A private normalized seed helper is shared with the unchanged name domain
  1009; name tables remain private. No geometry/combat draw, world identity,
  filesystem state or query order participates in selection.
- New `dungeon_contents_test.fpas` checks every roll against a literal
  100-entry expectation and counts the actual outcomes. Invalid -1/100 and
  signed extremes reject; slots 3/6 and other invalid values reject. Thirteen
  literal seed/region vectors pin both slot outcomes, including negative regions,
  signed 32/64-bit extrema, modulus normalization and a rare armor outcome.
  Independent domain-seed/successor/roll anchors document the arithmetic.
  Slot 4 empty with slot 5 present, reversed/repeated queries, name isolation,
  distinct world IDs, unchanged layout and full game-state/RNG preservation
  are covered without filesystem or combat-rule calls. Existing independent
  name and generation fingerprints also pass unchanged.
- Reused the ignored `.temp-data/rat-toolchain` compiler/library from FPAS
  `33814ef3`, SHA-256
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  The focused test, formatting, `fpas fmt --check apps libs tests tools`,
  `fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace`
  (all 20 members), and `git diff --check` pass. The complete
  `fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1
  dungeon.fpasworkspace` passed **87/87 programs, zero failures**.
- Independent read-only subagent review compared the checkpoint-07 snapshot,
  recalculated all 13 vectors and verified the signed-64-bit intermediate bound.
  It found no relevant defects or missing required coverage. Documentation and
  roadmap are updated. Production changes are confined to the content unit;
  placement, generator fingerprints, world format 3, generator 7, level format 2,
  protocol 15 and save format 8 remain unchanged, as does the FPAS repository.
  No commit/push; checkpoint 09 has not started.

### 09. Integrate final opponent and floor placements

- [x] Generate the guaranteed four items, optional slots and two fixed-kind
  opponents. Adapt strict generated-level validation to this final contract;
  never impose generated counts on generic authored maps used by rule tests.
- Positive: valid maps across a fixed seed/region matrix, expected counts/kinds,
  stable slot identity, no initial aggro, unchanged terrain/endpoints for the
  same successful geometry attempt. Negative: missing required kind/slot,
  duplicate/out-of-order/unknown slot, mismatched IDs, overlap, unsafe start or
  insufficient corners reject. Edge: optional 0/1/2 finds, gap at slot 4,
  same-kind optional finds, room-count minimum, negative regions and retry limit.
- Pin final fingerprints covering name, geometry, endpoints, hostile kinds/IDs
  and item kinds/IDs/positions. Explain changes from the intermediate name
  checkpoint; generator stays 7 for 14b. Never refresh a hash merely to go green.
- Exit: newly generated playable dungeons naturally expose every new feature.

Checkpoint 09 implementation notes (2026-10-16):

- The generator selects slots once outside geometry attempts, retains original
  suffixes, fills free corners in the existing room/corner order, and returns
  an error instead of silently dropping a selected item if corners run out.
  Opponents use the first two safe centers in farthest-first walking order,
  outside the exit room. No safe pair rejects the attempt; no safety relaxation.
- Strict stored validation requires exactly skeleton slot 0 and rat slot 1,
  required item kinds 0..3 and ascending optional original slots 4/5. It accepts
  all four supported optional kinds and zero/one/two optional placements without
  rerolling. Generic authored maps and their three-item/one-opponent fixture
  remain valid under generic validation.
- The three final full-text fingerprints were calculated with an independent
  integer/geometry reference, first checked against all three old fingerprints.
  Each uses the same attempt 0, terrain, start and exit as checkpoint 02.
  Differences add rat slot 1, guaranteed potion 3 and optional finds, while
  retaining the first three item positions. Generator 7 was already raised
  once for 14b; no further version bump or geometry-stream change is made.
- Reachability clarification of the fixed contract: domains 2003/2011 differ
  by 8, so successor states differ by 238187368 modulo 2^31. The possible raw
  differences are 3634/3635/-29134/-29133, hence roll differences modulo 100
  are 34/35/66/67. Both optional slots cannot be empty or of the same kind.
  Tests cover zero optional finds and equal optional kinds through explicit
  structurally valid stored fixtures; generator cases cover one/two finds,
  missing slot 4 with slot 5 retained, and optional kinds matching guaranteed
  finds. The mandated domains/table stay unchanged.
- At least four non-touching rooms of minimum size 3 by 3 supply sixteen
  distinct corners. Start/exit exclude at most two; hostile centers are never
  corners. Thus valid generated geometry always has at least fourteen free
  corners for at most six finds. The shortage guard remains explicit; forcing
  it would require invalid generator internals or a test-only production API.
  The four-room minimum, 40 placement tries and 16-attempt bound are unchanged.
  A pinned seed-80 retry case verifies attempt 0 floor-share rejection and
  attempt-1 placements; seed 9188 proves that an unsafe second-ranked room is
  skipped for the next safe center without changing the successful attempt.
  Seed 132 pins optional potion/jerkin placement, and placement-ID length
  boundaries exercise accepted identities and the exhausted retry path.
- Existing potion storage tests keep their intended four-item level fixtures
  by omitting optional placements explicitly, while rat storage/network and
  potion client/server tests now use natural guaranteed generated placements.
  Two existing drop/revisit save assertions now compare entity counts with
  the immutable source level, preserving their no-duplication check with optional
  finds. The first full run exposed their old expected-three assumptions; both
  focused corrections pass. No production change was needed.
- Independent read-only review against the checkpoint-08 snapshot found one
  stale documentation field-schema count; it is corrected. The reviewer also
  independently checked the unsafe-room fixture, optional kinds, all 32768
  upper RNG values with both carry cases, and the corner-count invariant.
  The two later save-count corrections were independently rechecked. No relevant
  defects or required test gaps remain.
- Final verification passed: formatting, all 20 workspace project checks,
  `git diff --check` and the complete suite (88/88 programs, zero failures),
  including both corrected save tests. The new placement test also passed
  separately after its safety, optional-kind and ID-boundary additions.
  README, roadmap, canonical terms and relevant architecture/storage docs now
  describe final generation. World format 3, generator 7, level format 2,
  protocol 15 and save format 8 remain unchanged, as does the FPAS repository.
  No commit/push; checkpoint 10 has not started.

### 10. Prove immutable levels and resumable cross-area item state

- [x] Extend `level_storage_test`, `visited_savegame_test`,
  `dropped_item_savegame_test`, `persistence_failure_test` and catalog tests.
- Positive: generated format-2 round trip, first-entry atomic publication,
  kill/pickup/use/save/restart/load; carry/drop/pick up a potion in another
  dungeon, consume there, save outdoors and revisit both without duplication.
  Negative: malformed/old/missing visited levels, invalid save origin/count,
  storage path/I/O errors, corrupt optional slot and incompatible versions fail
  without state installation, file repair, deletion or replacement. Edge: saved
  consumed optional slot 5 with slot 4 absent, all potions consumed, destroyed
  enemies, save during combat, zero visited areas and earlier-save rewind.
- Re-enter/read/load never rerolls names/items or invokes GenerateDungeon;
  assert stored bytes unchanged. Starting over materializes original items
  afresh in a new game but preserves the old explicit save and stored levels.
- Exit: full validation still requires every original mutable entity exactly
  once, including terminal consumed/defeated records, with one read per level.

Checkpoint 10 implementation notes (2026-10-16):

- Added `dungeon_contents_storage_test`: two naturally generated stored levels,
  including an actual entrance whose optional potion has original slot 5 with
  slot 4 absent. It calls production pickup, combat, drop, use and transition
  rules; pose setup omits route walking and one-health targets with seed 1
  make kills deterministic. Full TCP routing remains checkpoint 11.
- Save/reopen/load compares every state field during combat and outdoors.
  Tests transfer a potion to another dungeon, drop/save/load/pick up/consume it,
  consume all remaining potions, retain defeated opponents, revisit both areas,
  Start over without writing the old save, and rewind to an earlier explicit
  save while retaining newer immutable levels. Counts and original IDs remain
  exact through optional-slot gaps and terminal records.
- Missing/duplicate consumed slot 5, invented slot 4, wrong item kinds and
  missing/duplicate/wrong-kind defeated opponents reject both save and load;
  rejected writes preserve the good save and rejected loads preserve bad bytes.
  Existing drop/revisit tests now compare more complete state and verify
  fresh original placements, health and RNG retention.
- Extended level storage with a valid stored name/content fixture deliberately
  different from generation and explicit corrupt optional-slot cases. Extended
  the persistence-failure matrix and catalog with malformed/old levels,
  old saves/world metadata, corrupt optional identities, missing levels and
  wrong path types. No failed operation repairs, deletes or replaces data.
- The existing production paths needed no change. Code inspection confirms that
  reads never call generation, full validation uses supplied maps, and the load
  result reuses its already read current map. An isolated `strace -f -e
  trace=openat` probe independently measured exactly `[1,1]` level reads for
  each of save and load in a two-visited-area indoor state with a consumed
  potion. The temporary program was removed; no production counters or exports
  were added. The first standalone probe invocation lacked project imports;
  invocation through the owning world-test project passed.
- Independent read-only review against the checkpoint-09 snapshot found no
  relevant defects or required coverage gaps. It checked the real-rule fixtures,
  every field of the state comparison, terminal-origin rejection, preserved
  bytes, the no-generation path and the filesystem trace independently.
- Final verification passed on 2026-10-16: all 11 world-test programs,
  formatting, all 20 workspace project checks, the complete suite (89/89
  programs, zero failures) and `git diff --check`. Commands used:

  ```text
  .temp-data/rat-toolchain/fpas fmt --check apps libs tests tools
  .temp-data/rat-toolchain/fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace
  .temp-data/rat-toolchain/fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1 tests/world/world-tests.fpasprj
  .temp-data/rat-toolchain/fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1 dungeon.fpasworkspace
  git diff --check
  ```

  The matching game-local compiler/library from earlier checkpoints were reused;
  compiler SHA-256 remains
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  README, roadmap and storage/persistence/generated-dungeon docs are updated.
  World format 3, generator 7, level format 2, protocol 15 and save format 8
  remain unchanged. No FPAS repository edits, commit or push; checkpoint 11
  has not started.

### 11. Exercise the complete client/server loop and failure paths

- [x] Add `tests/server/dungeon_contents_network_test.fpas` using existing
  `Dungeon.Test.Levels`, `Routes` and `Wire` helpers; keep real-process session
  coverage. Add focused cases to client/server internal tests where needed.
- Positive: create current world, enter named dungeon, collect/equip/use,
  fight both kinds, save, stop/restart, Continue and revisit. Prove the client
  projection, map label, combat art and dashboard match authoritative state.
  Negative: version-14 handshake, unsupported old world/level/save, full-health
  use, unauthorized item ID, repeated use, save I/O failure and failed load
  preserve existing files/state or yield the existing explicit session failure.
  Edge: full inventory then consume/pickup, two equal display names, defeat on
  a later combat turn after use, reconnect before saving, restore an earlier
  save and explicit overwrite/discard guards. No automatic save on disconnect
  or shutdown.
- A rejected intention preserves exact pre-request state; a failed network
  send follows current session-lifecycle policy and never writes progress.
- Exit: end-to-end assertions check health, IDs, RNG, files and dirty state,
  not just successful message exchange. Existing response limits stay intact.

Checkpoint 11 implementation notes (2026-10-16):

- Added `dungeon_contents_network_test`, reusing Levels/Routes/Wire and the
  production TCP connection loop. Seed 9462 creates a fresh world through the
  protocol, collects/equips its generated sword and jerkin, collects the potion,
  meets the skeleton, drinks when injured, fights both original opponents and
  resumes/revisits the explicit save. No natural-play health/hostile/item edits.
  The only save-file replacement restores bytes of an actual earlier save.
- Independent literal LCG accounting checks each potion-turn hit/miss, capped
  healing, damage and final persisted RNG. Reconnecting before saving restores
  the carried potion and replays the whole response byte for byte. Repeated or
  foreign use plus discard/overwrite refusals are followed by a save whose
  health, item and RNG assertions confirm that rejections did not take turns.
- The actual network projections supply named title/map labels and kind-carrying
  animation/raycaster inputs. Standing sprite heights and fallen event markers
  distinguish rat/skeleton. Typed dashboard checks cover world, generator,
  stored area name, dirty state and save timestamps. Existing
  `item_use_network_test` retains real client-adapter and headless I/Enter
  keyboard coverage; existing client tests retain pending/modal checks.
- Added `dungeon_contents_failures_test`: real TCP rejection of world format 2,
  generator-6 worlds/levels, level format 1 and save format 7 without installation
  or file changes; full-health/foreign use and failed save with unchanged
  installed projection/RNG/items and preserved bytes. Existing
  `server_contract_test` verifies the old version-14 handshake;
  `save_failure_test` retains genuine save-path I/O coverage.
- Extended `item_use_session_test`: full 64-entry local inventory, rejected
  pickup, consumption freeing one entry and successful pickup; later fatal
  combat turn after drinking; refused active load, failed idle load and failed
  prepared send. Whole-session rejection comparisons include every state/map
  field, selection/lifecycle flags, dirty/save facts, metadata and cache cells.
  Capacity extras and the no-autosave sentinel are explicit local test fixtures;
  full real-origin capacity/save checks remain in the world tests.
- Extended `two_dungeon_test` with two equal stored display names and distinct
  IDs through map projection, load, transfer and revisit. Extended the actual
  listener/dashboard test to cancel with active dirty progress and retain the
  previous save bytes. Disconnect/shutdown never implicitly save.
- Focused development runs caught test-only mistakes: an incorrect sprite type,
  the world metadata version key, the missing state projection after a save
  acknowledgement, and an unexported cache-codec import. They were corrected
  using the actual public records and existing projection request; no production
  export, compatibility relaxation or timeout increase was added. The five
  changed/new test programs then passed focused verification (the internal
  session case was rerun separately after its correction).
- Independent read-only review against the checkpoint-10 snapshot found one
  test gap: deriving the number of potion-turn dice only from reported events
  would allow a completely omitted hostile phase. The corrected test pins the
  natural Before fixture (HP 17, RNG 1756806705), exactly one skeleton hit for 4,
  healing 3, After HP 16 and final RNG 842764951. The focused TCP test passed;
  independent follow-up review confirmed the fix and no other relevant findings.
  Queue ordering, fallen-art isolation, complete session comparison and the
  remaining coverage were independently checked. The production logic needed
  no change.
- Final verification passed on 2026-10-16: formatting, all 20 workspace project
  checks, `git diff --check` and the complete suite (91/91 programs, zero
  failures). The initial complete run also passed 91/91; after the review fix,
  both the focused TCP case and a fresh complete run passed. No review findings
  remain open. Commands used for the final run:

  ```text
  .temp-data/rat-toolchain/fpas fmt --check apps libs tests tools
  .temp-data/rat-toolchain/fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace
  .temp-data/rat-toolchain/fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --file tests/server/dungeon_contents_network_test.fpas tests/server/server-tests.fpasprj
  .temp-data/rat-toolchain/fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1 dungeon.fpasworkspace
  git diff --check
  ```

  The matching game-local compiler/library remain unchanged; compiler SHA-256
  is `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
  README, roadmap and relevant architecture/persistence docs are updated.
  World format 3, generator 7, level format 2, protocol 15 and save format 8
  remain unchanged. No FPAS repository edits, commit or push; checkpoint 12
  has not started. Final bench smoke checks and user terminal review remain
  that next checkpoint; this does not mark 14b accepted or DONE.

### 12. Finish documentation, verification and user review

- [x] Update roadmap, product terms/UI, README controls/current-version warning,
  generated-dungeon/level-storage/persistence/combat/inventory/equipment docs and
  this plan. Remove stale current-behavior claims about three fixed items,
  skeleton-only combat, the generic dungeon title and deletion of obsolete data.
  Historical phase descriptions may remain clearly historical.
- Positive: all linked documents describe the same final versions/controls.
  Negative: search for obsolete production constants, unhandled enum cases,
  old current-format claims and broken links. Edge: describe repeated names,
  optional slot gaps, terminal items and earlier-save/Start-over behavior.
- Format all changed FPAS sources, verify public documentation, check all 20
  workspace projects and run the complete suite. Record actual test-program
  count/results, exact commands, compiler identity and any failed runs.
- Smoke-check the existing persistence bench at 1/10/100 visited dungeons with
  new/consumed items; compare to its baseline and investigate a material
  regression before adding any optimization or changing expectations.
- [ ] User terminal review (deliberately open; unavailable in this cloud):
  names, distinct rat/skeleton sprites and death frames,
  potion discovery/inspection, I/Enter use, partial/full-health behavior, combat
  response, save/restart/Continue and 14s dashboard/menu responsiveness.
  The user explicitly deferred this gate on 2026-10-16. Automated/headless
  coverage does not replace it; do not request cloud acceptance or mark DONE.
- Exit: mark 14b IN REVIEW only after all implementation gates pass; mark DONE
  only after explicit acceptance. Remove this plan after acceptance under the
  project policy. 13b is then the next gameplay slice, before 14c.

Checkpoint 12 automated evidence (2026-10-16):

- Updated README controls/current versions, canonical turns and inventory terms,
  client UI, roadmap and architecture documents. Historical 13a fixture
  coordinates and 14a measurements are explicitly historical. Older screenshots
  do not count as the open 14b terminal review. Removed stale current-version,
  fixed-coin-count and world-data deletion instructions; runtime configuration
  retains its required delete/recreate instruction. Repeated names, original
  slot gaps, terminal records and earlier-save/Start-over behavior stay documented.
- The existing persistence tool now marks alternating guaranteed potions as
  consumed in its constructed fixture, retains other fresh finds, reports
  consumed/opponent counts and compares the complete encoded state after each
  load, outside the timing intervals. No production rules, exports, manifests,
  format versions or runtime settings changed in this checkpoint.
- [Persistence measurements](../architecture/persistence-measurements.md) record
  exact commands, compiler identity, 1/10/100 visits, raw ranges/medians, peak
  RSS and investigation. Final common-filesystem controls pass all 36 save/load
  rounds; current 100-visit medians are 558.5 ms save / 542 ms load, with 539
  items, 50 consumed and 200 opponents. Baseline controls and public-API phase
  probes locate added work in decoding/full validation of more entities.
  Initial overlap/RAM-filesystem comparisons are excluded from final timings.
  No cache, optimization, relaxed validation or performance expectation changed.
- Formatting and format verification pass; all 20 workspace projects check and
  the final serial suite passes **91/91 test programs, zero failures**. All 87
  changed/new FPAS files have purpose comments; all 317 public declarations
  have preceding documentation. All 83 local Markdown targets/anchors resolve.
- Exact final verification commands:

  ```text
  .temp-data/rat-toolchain/fpas fmt apps libs tests tools
  .temp-data/rat-toolchain/fpas fmt --check apps libs tests tools
  .temp-data/rat-toolchain/fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace
  .temp-data/rat-toolchain/fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1 dungeon.fpasworkspace
  git diff --check
  ```

  Compiler source FPAS `33814ef3`, SHA-256
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`,
  with its copied matching library. The compiler repository remains clean.
- Failed development checks: a benchmark draft attempted a private-unit import
  (FP4116), then retained a stale alias/incorrect metadata field (FP3003). The
  final fixture uses the existing public item model and `Metadata.Id`, without
  adding exports. The optional system `time` executable was absent (exit 127);
  peak RSS uses Python `os.wait4`. A temporary phase-probe workspace initially
  listed uncopied members (FP4106); its temporary manifest was narrowed to the
  copied libraries/tool. These corrected setup/draft checks produced no
  production change or test relaxation. The workspace suite has no failed run.
- Independent subagent review found two documentation errors: free corners in
  rooms without opponents are preferred, not exclusive; optional finds may add
  coins, so persistence guarantees one record per original ID. Both are fixed.
  Follow-up review recalculated the final medians/ranges, counts and size/RSS
  comparisons and checked IN REVIEW with acceptance open. Its phase-label
  finding is corrected: `DecodeSaveGameState` includes parsing plus
  self-contained shape/identity validation, not isolated decoder time. No
  benchmark-code defect or open relevant review finding remains.
- World format 3, generator 7, level format 2, protocol 15 and save format 8
  remain final. The user explicitly leaves terminal review/acceptance open;
  14b is IN REVIEW, not DONE. No FPAS repository edits, commit, push or 13b work.

## Verification commands and execution rules

Use a release compiler with its matching source standard library. While FPAS
is edited elsewhere, use an ignored game-local snapshot as in dashboard work;
record its compiler SHA-256 and source revision. Do not build, format, clean,
commit or otherwise change the FPAS repository. Avoid source-cache writes to
its library by selecting the copied library with `--std-lib`.

With that compiler selected as `fpas`, run:

```text
fpas fmt --check apps libs tests tools
fpas check --std-lib <game-local-library> dungeon.fpasworkspace
fpas test --std-lib <game-local-library> --timeout 600 tests/game/game-tests.fpasprj
fpas test --std-lib <game-local-library> --timeout 600 tests/world/world-tests.fpasprj
fpas test --std-lib <game-local-library> --timeout 600 tests/protocol/protocol-tests.fpasprj
fpas test --std-lib <game-local-library> --timeout 600 tests/server/internal/server-internal-tests.fpasprj
fpas test --std-lib <game-local-library> --timeout 600 tests/server/server-tests.fpasprj
fpas test --std-lib <game-local-library> --timeout 600 tests/client/client-tests.fpasprj
fpas test --std-lib <game-local-library> --timeout 600 --jobs 1 dungeon.fpasworkspace
git diff --check
```

The angle-bracket library value is an explicit placeholder, not shell syntax.
Use focused projects according to the checkpoint; the complete workspace is
mandatory before handback. Format changed files with `fpas fmt` before checking.
Run long commands in the background and report that they are running. Windows
sandbox socket error 10013 requires an unrestricted loopback run; do not raise
timeouts or weaken tests to hide it. Report actual failures and their output.
If a language/runtime/library defect appears, stop with a minimal reproduction
and obtain agreement before an FPAS fix; never silently work around it here.

## Completion checklist

- [x] All twelve checkpoints have automated implementation and verification evidence.
- [x] Names and contents are deterministic; visited immutable files stay fixed.
- [x] Both opponents have correct rules, persistence, projections and art.
- [x] Loot identities survive empty slots, transfer, consume and save/load.
- [x] Accepted potion use heals once before one enemy phase; rejection is inert.
- [x] Strict protocol/level/save versions reject old and malformed data intact.
- [x] Positive, negative and edge cases pass through pure, storage, wire and UI seams.
- [x] Complete suite is green; final counts and bench observations are recorded.
- [ ] User accepts the running feature; only then remove this plan and mark DONE.
