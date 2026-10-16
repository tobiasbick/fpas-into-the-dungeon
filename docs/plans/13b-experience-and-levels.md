# 13b: experience and skill levels

Status: planned on 2026-10-16. No 13b gameplay changes are implemented.
The user accepted 14b and the completed client/server review. This is the next
gameplay slice, before dungeon levels (14c).

Work belongs to `codex/13b-character-progression` in the game repository only.
The starting game commit is `df5acea`; its verification passed all 21 project
checks and 107/107 test programs with the fixed release FPAS compiler. These
counts describe the baseline, not a test result for future 13b changes.

Implement the checkpoints in order. Each checkpoint must leave an executable,
tested workspace. Update this plan and the roadmap after each checkpoint;
record completed work, actual commands and results, and the next open step.
Ask before changing the decisions below or reordering checkpoints. Commit or
push only when requested. Delete this plan after implementation is verified
and the user explicitly accepts 13b; retain its contracts in the permanent docs.

## Goal and fixed scope

The character improves the fighting skill it actually uses. A successful blow
earns experience from the opponent's lost health, and accumulated experience
raises that skill's level. A skill level gives a small, deterministic hit or
damage bonus. Equipment still determines the weapon's base damage.

The first slice has two independent skills, **Unarmed** and **Blades**, each at
levels 1 through 5. There is no overall character level, class selection,
attribute allocation, skill-point editor, defensive training, or experience
for movement, taking damage, healing, item handling, or idle actions. Ranged
combat and magic remain separate future features. Maximum health stays 20;
armor, opponent values, terrain, and generated placements stay unchanged.

Success means the player can train both skills through real fights, understand
their progress in the character sheet, switch equipment without losing either
skill, and save and continue the exact state. Rejections and failed candidate
preparation must retain experience along with every other installed fact.

## Rules to implement

### Skill selection and experience

- An attack with no weapon equipped uses Unarmed. The equipped Rusty short
  sword uses Blades. Carrying a sword does not select Blades. Equipping,
  unequipping, replacing, or dropping an item never grants experience.
- Capture the active skill from the valid state before the attack. Use that
  same skill for damage and its experience award. Armor has no effect on this
  selection. Different copies of the sword share the same Blades progress.
- Award one experience point for each health point actually removed from the
  standing target by this player attack:
  `award = target health before - target health after`.
- A blow that rolls 7 damage against 2 remaining health awards 2 experience.
  Keep the existing combat log and `PlayerHit.Amount` reporting the rolled
  damage, 7 in this example. Do not change animation damage semantics.
- Misses award zero. Attacks without a standing target remain rejected and
  consume neither dice nor a turn. There is no additional defeat reward.
- Each skill stores cumulative experience in 0..120. Saturate gains at 120,
  using the remaining capacity before addition to avoid overflow. Experience
  never decays or transfers between skills. A capped skill discards further
  awards rather than training the other skill or increasing hidden counters.
- The current opponents never heal or respawn in an active game. Their finite
  health and retained destroyed records bound the available training without
  adding a per-hit or per-opponent reward ledger. A rat supplies at most 6
  points and a skeleton at most 12, shared across whichever skills damage it.
- Loading restores opponent health, both experience counters, and dice
  together. Replaying from an earlier save replaces the later state; it does
  not add experience to an account outside that save. Start over and a new
  world both start the two counters at zero.
- A repeated attack request is another ordinary intention. It can earn only
  health removed from the target's current state. This slice adds no request
  IDs, retransmission scheme, or network idempotency promise.

### Levels and benefits

The thresholds are cumulative, with equality reaching the new level.

| Skill level | Total experience | Hit bonus | Damage bonus | Next threshold |
|---|---:|---:|---:|---:|
| 1 | 0..11 | 0 | 0 | 12 |
| 2 | 12..35 | 0 | +1 | 36 |
| 3 | 36..71 | +1 | +1 | 72 |
| 4 | 72..119 | +1 | +2 | 120 |
| 5 | 120 | +2 | +2 | none |

Only the active skill contributes. The player hits on
`d20 >= 6 - hit bonus`, so the five levels give 75%, 75%, 80%, 80%, and 85%
hit chances. Unarmed damage is `d3 + skill damage bonus`; sword damage is
`d6 + 1 + skill damage bonus`. Armor remains 0 or 2 and maximum health remains
20. No benefit changes the die count, adds a random draw, or heals the player.

Resolve the current attack with the skill level at its start. After applying
the target's damage, award experience and derive the new level. The new bonus
first affects a subsequent attack. Then run the existing hostile phase in its
existing order. Level changes do not consume a second turn.

Log a level increase once, with the final level, for example
`Blades reached level 2.` The order is player hit, opponent death if any,
level increase if any, then hostile actions. Do not log every experience point.
Do not add a combat-event kind or a client timer for progression. A turn ending
in player defeat keeps the existing state-less defeat outcome: unsaved progress
cannot be continued or saved, and the last explicit save remains intact.

### Authoritative state and module boundary

Add a leaf game unit `Dungeon.Progression`. It must not depend on GameState,
Equipment, Combat, the protocol, storage, or the client. It owns:

- `SkillKind` with Unarmed and Blades, and their display names.
- `ProgressionState` with `UnarmedExperience` and `BladesExperience` integers.
- The cap, threshold table, and a derived benefits record with level, hit
  bonus, and damage bonus. Levels and bonuses are never persisted.
- Creation, strict validation, experience lookup, level/benefit lookup, and
  the optional next cumulative threshold.
- `AwardDamage(Progress, Skill, BeforeHealth, AfterHealth)`, returning a result
  with a new progression value. It validates both counters and requires
  `0 <= AfterHealth <= BeforeHealth`; invalid input returns an error. Equal
  health, including 0/0, returns unchanged progress. Subtract only after
  checking these bounds, and cap the delta before adding it to experience.

Query helpers take validated inputs; document that precondition. Validation
and awarding must never silently repair invalid counters. Public names may
follow the surrounding code's naming style, but keep this ownership and these
error contracts. Do not create a configurable skill registry or new project.

`GameState` gains one `Progression` field and delegates its shape validation
to the leaf unit. `NewGame` installs zero counters. Equipment owns the mapping
from the worn weapon to the active skill and adds its benefits to the derived
values. Combat awards experience in the player-attack resolution only.

Before extending Combat, move its existing `Blocked` and `NextStepToward`
pathfinding into `Dungeon.Combat.Navigation`. Preserve neighbor order north,
east, south, west and every collision rule. This is a separate refactor
checkpoint so the progression work does not enlarge a mixed combat file.
Keep the existing exported `Dungeon.Combat` interface.

Server preparation, commit, dirty-state, socket and save ownership remain as
documented in the [architecture overview](../architecture/overview.md).
`Dungeon.Test.StateComparison.SameState` must compare the new progression field
before any rollback test can rely on it. Do not expand server exports for tests.

## Persistence and compatibility

Raise `SaveGameFormatVersion` from 8 to **9**, once for the whole slice. Add
exactly one top-level field, `progression`, to the existing save object. It is
an exact two-field object:

```json
{
  "unarmed_experience": 0,
  "blades_experience": 12
}
```

Both values are required integers in 0..120. Unknown, missing, duplicate, or
wrongly typed fields are errors under the existing strict JSON policy. Do not
store level, active skill, bonuses, next threshold, training notifications, or
a second experience file. Update the top-level exact field count from 12 to 13
and require the named fields; count alone is not sufficient validation.

Add `Dungeon.World.Savegame.Progression` for the nested encoding and decoding.
It depends on the game leaf unit and existing JSON helpers. The Savegame facade
continues to own version checking, full validation and atomic publication.
Reject an obsolete version with a clear unsupported-version reason before
interpreting its current-version payload. Continue through the current
catalog/load failure paths; preserve invalid files byte-for-byte.

| Format or contract | Before | After 13b | Reason |
|---|---:|---:|---|
| Savegame format | 8 | 9 | Persist the two experience counters |
| Protocol | 15 | 15 | Reuse bounded server-formatted character lines |
| World metadata/chunks | 3 | 3 | No world schema change |
| World generator | 7 | 7 | No generated output change |
| Immutable dungeon level | 2 | 2 | No geometry or placement schema change |
| Runtime configuration | current | unchanged | No new setting |

Existing compatible worlds and immutable levels remain usable. Their format-8
saves cannot Continue after this change and are never migrated or deleted.
The catalog reports an incompatible save with an actionable reason. Start over
creates fresh mutable progress in that same world, retaining its old save until
the user explicitly confirms overwrite; it retains the stored dungeon layout.
New worlds and absent saves start at level 1 in both skills. Same-version
format-9 saves continue exactly, including mixed skills and mid-fight progress.

## Projection and character sheet

Use the existing `character` array in both map and first-person state messages.
The server sends six lines, in order: Maximum health, Hit chance, Damage,
Armor, Unarmed, Blades. The last two show total experience and its next
cumulative threshold, not experience earned within the current level.

Examples for a sword-wielding character with Unarmed 0 and Blades 12:

| Label | Value | Source |
|---|---|---|
| Maximum health | `20` | `Base` |
| Hit chance | `75% (d20 ≥ 6)` | `Base` |
| Damage | `d6+2` | `Rusty short sword; Blades L2 +1` |
| Armor | `0` | `None` |
| Unarmed | `L1 XP 0/12` | `Next: damage +1` |
| Blades | `L2 XP 12/36` | `Active; next: hit +1` |

Retain the existing hit-chance glyph. For levels 3 through 5, the
hit-chance source names the active skill's total hit bonus, for example
`Base; Blades L3 +1 hit`. A level-1 damage source retains the existing weapon
name or Unarmed. Later unarmed sources can use `Unarmed L2 +1`; later sword
sources follow the example. The next benefit is damage +1 at level 1,
hit +1 at level 2, damage +1 at level 3, and hit +1 at level 4. These are the
increments at the next level, not new total bonuses. At level 5 use
`L5 XP 120/120` and `Mastered` or `Active; mastered`.

The six entries fit `MaximumCharacterValues = 8`; every label, value and source
must fit `MaximumCharacterTextLength = 64`. Reuse the existing validators and
strict encoders/decoders. Experience is not added to client intentions or
combat events. The client displays the supplied lines without parsing their
labels or calculating levels, thresholds, percentages, awards, or bonuses.
The context panel does not gain more rows in this slice.

Extract the character-sheet rendering into `Dungeon.Client.CharacterSheet`;
keep the current Character entry point as a forwarding facade if needed by
callers. Inventory selection and actions stay in their current owner. The
new owner provides read-only rendering and scroll handling:

- Keep health, the visible row range and close/navigation hints outside the
  scrolling body. Render each projected character line as a label/value row
  and a source row; follow these with the equipment rule and equipment lines.
- Minimum useful size is 32 by 8 terminal cells. Reserve six rows for frame,
  health, range and two footer rows; body capacity is `height - 6`. Limit body
  width to `min(width - 4, 76)`, using existing terminal-cell-aware clipping.
  Verify the actual TUI frame dimensions rather than relying only on arithmetic.
- Store one UI-only `CharacterSheetOffset` in ClientModel. Up/Down or W/S scroll
  one body row, clamped without wrapping. Other navigation keys send nothing.
  C/Escape closes; I opens inventory. Gameplay keys cannot reach the game while
  this overlay owns input. Opening, closing and scrolling consume no turn.
- Below the minimum, show `Resize to 32x8` and a close hint. Close and the
  existing I switch still work. No negative body sizes or gameplay requests.
- Clamp the offset after resizing or an authoritative refresh, preserve it
  while the sheet stays open, and reset it when opening a fresh sheet or
  clearing/replacing the game session. Pending viewport/state replies must
  not reopen an explicitly closed sheet or revive old experience lines.
- Level notices reuse the normal combat log. Keep combat animations and their
  skip-on-key behavior; progression adds no modal popup or animation delay.

## Source and document ownership

The following paths are the intended production changes. Test files listed in
the checkpoints are new unless explicitly called existing.

| Path | Purpose |
|---|---|
| `libs/game/src/Dungeon/Progression.fpas` | Pure counters, validation, thresholds and awards |
| `libs/game/game.fpasprj` | Export the Progression unit |
| `libs/game/src/Dungeon/GameState.fpas` | One field, initialization and shape validation |
| `libs/game/src/Dungeon/Equipment.fpas` | Active skill, derived bonuses and six character lines |
| `libs/game/src/Dungeon/Combat/Navigation.fpas` | Existing hostile pathfinding, moved without behavior changes |
| `libs/game/src/Dungeon/Combat.fpas` | Use navigation owner; award damage practice and log level changes |
| `libs/world/src/Dungeon/World/Savegame/Progression.fpas` | Strict nested save encoding/decoding |
| `libs/world/src/Dungeon/World/Savegame.fpas` | Format 9 and nested field integration |
| `apps/client/src/Dungeon/Client/CharacterSheet.fpas` | Read-only paged sheet and scrolling |
| `apps/client/src/Dungeon/Client/Character.fpas` | Forward sheet rendering; retain inventory ownership |
| `apps/client/src/Dungeon/Client/Model.fpas` | UI-only sheet offset |
| `apps/client/src/Dungeon/Client/Ui/Layout.fpas` | Sheet bounds and row capacity |
| `apps/client/src/Dungeon/Client/Ui/Input.fpas` | Overlay-owned scrolling and existing close/switch keys |
| `apps/client/src/Dungeon/Client/Ui/Events.fpas` | Reconcile sheet offset after authoritative updates |
| `apps/client/src/Dungeon/Client/Ui/Session.fpas` | Reset sheet offset with session/overlay lifecycle |
| `tests/fixtures/src/Dungeon/Test/StateComparison.fpas` | Complete state comparisons including progress |

Do not add a second progression owner in server projection, the protocol or
client. Existing `ProjectCharacter` already maps the Equipment lines. Production
server/protocol files need changes only if a regression proves an actual
integration defect; keep this plan's wire and commit contracts. Update direct
GameState constructors and serialized test fixtures wherever the new required
field reaches them. Avoid unrelated refactors and enlarged public interfaces.

Permanent documentation will be updated incrementally:

- Add `docs/architecture/progression.md` as the lasting rule and storage contract.
- Update `docs/architecture/equipment.md`, `combat.md`,
  `persistent-game-state.md`, and `overview.md` at their owning checkpoints.
- Add the canonical terms experience, skill, skill level, active skill and
  mastery to `docs/product/world-and-views.md`. Keep skill level distinct from
  a dungeon's spatial level; derived values now include active skill benefits.
- Update `docs/product/client-ui.md` for the sheet and progression display.
- Update README and `docs/roadmap.md` when the complete feature is verified;
  planned behavior must not be presented as already implemented.

## Verification policy

Use the fixed release FPAS executable and its matching standard library. Do not
modify or rebuild the compiler repository as part of this plan. An exposed
FPAS defect requires a minimal reproduction and user notification under
AGENTS.md; fixing it in FPAS needs fresh explicit authorization. Do not hide a
compiler problem with a redundant import or changed language spelling.

For each source checkpoint, format the changed sources, check every affected
project and run its relevant test projects. Before handing a source checkpoint
back, run the complete workspace suite. Run long commands in the background
and report their outcome. Do not mark a checkpoint complete while a required
check is red. A successful earlier run does not cover later source changes.

```powershell
fpas fmt --check apps libs tests tools
fpas check dungeon.fpasworkspace
fpas test --timeout 600 --jobs 1 tests/game/game-tests.fpasprj
fpas test --timeout 600 --jobs 1 tests/world/world-tests.fpasprj
fpas test --timeout 600 --jobs 1 tests/protocol/protocol-tests.fpasprj
fpas test --timeout 600 --jobs 1 tests/server/internal/server-internal-tests.fpasprj
fpas test --timeout 600 --jobs 1 tests/client/client-tests.fpasprj
fpas test --timeout 600 --jobs 1 tests/server/server-tests.fpasprj
fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace
git diff --check
```

Select targeted projects from this list rather than rerunning every targeted
suite before every full run. If the executable's default library does not
match, supply `--std-lib <matching-lib>` to check/test. A sandbox TCP denial is
an environment failure: rerun the affected command with the required permission;
never weaken network assertions or replace them with arbitrary sleeps.

Tests use authored fixtures for independent rules and failure cases, generated
stored levels for world/TCP coverage, and literal expected tables/dice for the
oracle. Never derive the expected result with the production helper being
tested. Extend comparison helpers before using them as rollback evidence.
Use isolated temporary roots, retain relevant failure reproductions, and clean
only test-owned data. No runtime user worlds or saves may be touched.

No generator fingerprints change in this slice. Re-pin combat results only
where new skill benefits deliberately change later hit/damage decisions, with
an explicit explanation; do not adjust expected values just to pass.

## Ordered implementation checkpoints

### 01. Establish permanent contracts and baseline

- [ ] Add `docs/architecture/progression.md` from the fixed decisions above.
  Mark the feature planned; record rule ordering, table, cap, version policy,
  lifecycle and ownership. Add canonical progression terms as planned terms
  in `docs/product/world-and-views.md` without claiming current runtime support.
- [ ] Link the contract from the architecture overview and this plan. Confirm
  the fixed compiler/toolchain selection and rerun the unchanged game baseline
  before the first source edit. Retain current generator fingerprints.
- [ ] Positive checks: every threshold, formula, field name and module owner
  agrees across the contract, plan and roadmap; all local links resolve.
- [ ] Negative checks: no compiler, gameplay, configuration or schema source
  changes belong to this documentation checkpoint.
- [ ] Edge checks: the written contract covers old saves in reusable worlds,
  mixed skills, mastery, lethal overkill, and a turn ending in player defeat.

Exit: the next agent can implement step 02 without making a gameplay decision.

### 02. Add the pure progression model

- [ ] Add `Dungeon.Progression`, export it from the existing game project and
  add `tests/game/progression_rules_test.fpas`. Do not attach it to GameState yet.
- [ ] Positive tests: new counters 0/0; independent skill gains; the complete
  level/benefit table; next-threshold lookup; damage deltas and multiple gains.
- [ ] Negative tests: either counter -1 or 121, negative health, or after-health
  greater than before-health returns Error without changing the input value.
- [ ] Edge tests: XP 0, 11, 12, 35, 36, 71, 72, 119, 120; identical 0/0 and
  6/6 health; overkill represented by 2 to 0; crossing several thresholds in
  one helper award; award at cap and just below it; maximum representable
  non-negative health delta without overflow. Derived queries use valid values.
- [ ] Verify all literal bonuses and next thresholds, not just level names.

Exit: pure game tests and the unchanged workspace pass; gameplay is unchanged.

### 03. Persist a validated progression field in save format 9

- [ ] Add `GameState.Progression`, initialize it in NewGame, validate it in
  `ValidateStateShape`, and update every direct state constructor. Extend
  `SameState`; prove it detects a difference in either experience field.
- [ ] Add the nested save owner and switch once to format 9. Decode the version
  before requiring the current payload shape. Keep full saved-area validation,
  atomic writes, catalog classifications and overwrite ownership intact.
- [ ] Add `tests/game/progression_state_test.fpas` and
  `tests/world/progression_storage_test.fpas`; adjust current-format fixtures in
  existing world, catalog, server and benchmark tests. Training is still inactive.
- [ ] Positive tests: new outdoor/indoor states; save/decode/full-load equality
  for mixed values; state comparison catches each field; format-9 catalog status.
- [ ] Negative tests: missing/extra/renamed/duplicate progression keys; object
  replaced by null, string or array; boolean/string/fractional/out-of-range
  counters; absent top-level field; injected derived `level`; top-level field
  substitution with the same count; save versions 8 and an unknown future version.
- [ ] Edge tests: 0/120 and 120/0, both 120, invalid file preserved byte-for-byte,
  bad progress rejected in the map-free load phase before level I/O, and valid
  existing world/level files still open without generation or rewriting.
- [ ] Update persistence docs to format 9 only when source and tests switch.

Exit: savegames require the current field; all existing tests pass at zero XP.

### 04. Derive combat values from the active skill

- [ ] Add Equipment's active-skill query and apply the table to hit threshold
  and damage bonus. Do not award experience or add character-sheet lines yet.
- [ ] Add `tests/game/progression_equipment_test.fpas`. Keep the existing
  equipment turn rules and base values. Update equipment/combat rule docs.
- [ ] Positive tests: every level unarmed and with a sword; cumulative weapon
  and skill damage bonuses; switching equips selects the trained skill.
- [ ] Negative tests: carrying a sword, wearing armor, or changing the inactive
  skill never substitutes for the active skill or changes the other benefits.
  Existing invalid equip/unequip/drop intentions retain both experience values.
- [ ] Edge tests: opposite skills at levels 1 and 5; swapping two sword copies;
  a maximum-level unarmed character equipping an untrained sword; unchanged
  health 20, armor 0/2, dice sides and RandomState during derivation/equipping.

Exit: authored trained states affect fights, while ordinary new games still
play with zero practice until step 06.

### 05. Isolate the existing hostile navigation

- [ ] Move Blocked and NextStepToward into the focused Navigation subunit,
  called by Combat. Retain the Combat exports and all current algorithm rules.
- [ ] Use existing combat, rat, movement and TCP tests; add focused cases to
  existing tests only where current path-order coverage is missing.
- [ ] Positive tests: an alerted opponent takes the same shortest-path step;
  walls, other standing opponents, and the player retain their collision roles.
- [ ] Negative tests: an unreachable player does not move the hostile through
  a wall or another opponent; an unalerted hostile without line of sight and an
  inactive-area hostile stay unchanged. First sight still alerts without moving.
- [ ] Edge tests: equal-length paths retain N/E/S/W ordering; corridor corners,
  a destroyed opponent's traversable field and adjacent-attack behavior remain
  identical. No extra dice draws, experience changes or fingerprint changes.

Exit: this is a behavior-preserving refactor with the full suite green.

### 06. Award practice inside the resolved attack

- [ ] Call AwardDamage once after a successful player hit has its final target
  health. Use the pre-attack skill and benefits. Append one bounded level-up
  log entry in the specified order; retain the existing combat events.
- [ ] Add `tests/game/progression_combat_test.fpas` and
  `tests/game/progression_action_test.fpas`; extend existing exact combat tests
  only for deliberate newly reached levels.
- [ ] Positive tests: sword and fist hits train the correct skill; a nonlethal
  hit trains before the hostile phase; a lethal hit grants its remaining HP;
  crossing a threshold logs the final level and changes the next attack.
- [ ] Negative tests: misses, air/dead-target/outdoor attacks, turning, waiting,
  steps, inspection, pickup, wear/remove/drop, potion use, saving and map queries
  do not train. Distinguish accepted non-training turns from rejected intentions.
- [ ] Edge tests: 11 to 12, 35 to 36, 71 to 72, 119 to cap; overkill logs rolled
  damage but awards only lost health; switching skills while fighting one target;
  repeated attacks at cap; an opponent already at zero; level-up plus kill plus
  the other hostile's action; level-up followed by player defeat.
- [ ] Pin RNG progression for a hit and a miss. A useful existing independent
  seed is 1: d20=19, d3=2, hostile d20=14, rat d2=2. Progression adds no draw.

Exit: one complete authoritative fight trains the player without changing
action costs, combat event schema, defeat lifecycle or hostile values.

### 07. Prove server commit and rollback ownership

- [ ] Add `tests/server/internal/progression_session_test.fpas`, exercising the
  real Handling/Replies path and existing SessionAssertions on real connections.
  Prefer existing production seams; add no test-only public production hook.
- [ ] Positive tests: an accepted threshold-crossing attack installs opponent
  health, RandomState and XP together, marks Dirty and retains LastSavedAt.
  A repeated legal attack awards only the newly removed health.
- [ ] Negative tests: no active session, invalid target and invalid progress
  reject without changing installed facts. A failed state preparation after the
  candidate earns XP must retain both counters, health, items, geometry, cache,
  dirty/save facts and RNG; the rejection itself must remain writable.
- [ ] Use a valid independent oversized interior to trigger the existing
  encoded-line bound after combat resolution, for example 240 by 140 fields
  with two row planes. Validate the fixture and independently prove its encoded
  response exceeds MaximumLineBytes; do not depend on malformed progression.
  Keep this local rule-view fixture out of stored/generated world tests.
- [ ] Edge tests: both original Dirty states, an award crossing a level during
  preparation failure, unchanged prior save bytes, and a later successful
  representable fixture from the same retained combat facts. A failed actual
  socket write remains fatal and never writes a save or publishes an installed
  candidate. A repeated rejected candidate never accumulates hidden experience.

Exit: rollback assertions compare the new field, not just old state members.

### 08. Project progress through the existing protocol

- [ ] Extend Equipment.CharacterValueLines to the six specified lines and
  sources. Reuse ProjectCharacter in both view families. Add
  `tests/server/internal/progression_projection_test.fpas` and
  `tests/protocol/progression_protocol_test.fpas`.
- [ ] Positive tests: literal expected text for mixed skills, active markers,
  next benefit, mastery and hit/damage sources; both view families round-trip
  through current server message encoding/decoding with no new payload field.
- [ ] Negative tests: an added client `experience`/`skill` field is rejected by
  the exact intention decoder; malformed character entries, extra nested keys,
  overlong labels/values/sources and more than eight lines retain existing errors.
- [ ] Edge tests: exactly 8 generic character entries and 64-character text
  accepted by the protocol, 9/65 rejected; zero and capped counters; escaped
  text and UTF-8 line-byte bounds; read-only viewport/exploration refreshes
  neither award practice nor emit old level-up messages.
- [ ] Confirm ProtocolVersion remains 15, combat-event fields remain exact and
  no client-facing structure exposes hidden opponents or server state.

Exit: a stock protocol-15 client can carry the new display values as text.

### 09. Make the character sheet readable at bounded sizes

- [ ] Add CharacterSheet, the UI-only offset, bounds and overlay input wiring
  described above. Preserve the current inventory facade and actions. Update
  client UI documentation. Add `tests/client/progression_ui_test.fpas` and
  `tests/client/character_sheet_window_test.fpas`.
- [ ] Positive tests: C opens from either view family; the real rendered cells
  show the supplied skill values and sources; scrolling reaches every skill
  and equipment row; C/Escape closes and I switches to inventory.
- [ ] Negative tests: scrolling, Space, Enter and unrelated navigation keys
  send no game intention from the character sheet. Below-minimum sizes show
  the hint without indexing content or changing experience. The client never
  fabricates an award, changes displayed XP before a reply, or parses skill text.
- [ ] Edge tests: 31/32/33 columns and 7/8/9 rows; zero dimensions; 80x24 and
  wide windows; first/last scroll rows; long Unicode source text and graphemes;
  empty and maximum generic character arrays; both worn slots and no equipment;
  resize while scrolled; refreshed lines while open; pending reply after close;
  new session/load/disconnect resets versus in-place viewport preservation.
- [ ] Retain animation key-skip behavior and request gating; no new timer,
  autosave, context-panel row or client game-rule dependency.

Exit: every progression value is reachable with a bounded overlay and all
navigation stays local to the UI.

### 10. Verify save/replay and world lifecycle together

- [ ] Add `tests/world/progression_replay_test.fpas` and extend the existing
  `tests/server/internal/lifecycle_owners_test.fpas` and
  `tests/world/world_catalog_test.fpas` where their contracts already apply.
- [ ] Positive tests: save during a fight after training both skills; load full
  state equality; replay identical intentions gives identical HP, XP, dice and
  events. Cross dungeon boundaries, save outdoors, reconnect and Continue.
- [ ] Negative tests: failed save or malformed format-9 progression preserves
  the prior save and session. Continue on format 8 rejects and preserves bytes.
  Revisit and repeated load never reward already lost health again.
- [ ] Edge tests: Start over in a compatible world with an old save starts 0/0
  without replacing it; normal save requests overwrite confirmation, cancellation
  preserves bytes, explicit overwrite writes format 9; new world and missing
  save start 0/0; load at mastery; defeat restores only the earlier explicit
  save. Retained immutable level bytes and original placements remain identical.
- [ ] Verify catalog inspection remains bounded and full Continue validation
  still checks every referenced level rather than treating XP as a shortcut.

Exit: progress belongs to the selected world's resumable game, with no separate
account state, migration, implicit file deletion or autosave.

### 11. Exercise the complete path over TCP

- [ ] Add `tests/server/progression_network_test.fpas` using existing Wire,
  route and stored-level helpers. Use generated content for the complete
  scenario, not a client-synthesized state or production test hook.
- [ ] Positive scenario: connect, start, enter, collect the sword and protective
  gear, and land one unarmed hit on the full-health rat. Equip the sword, finish
  the rat and skeleton, and observe Blades level 2 in decoded character lines.
  The first fist hit removes 1..3 HP, leaving 15..17 points for Blades. Save,
  disconnect/reconnect, Continue, and confirm both exact counters and equipment.
  Unequip and confirm the active skill switches to the retained Unarmed level.
- [ ] Negative scenario: send an unsupported skill/experience field, attack
  without a target, and reject invalid/obsolete saves. Confirm the connection
  remains usable where the current protocol permits recovery and prior state
  and files remain unchanged.
- [ ] Edge scenarios: mixed-skill damage against one opponent; a surviving
  threshold-crossing turn; a lethal overkill; repeat a defeated-target attack;
  revisit the dungeon; save/load at cap; discard unsaved progress and start
  over. Observe sheet refresh during a pending viewport request in headless UI
  coverage rather than introducing transport timing sleeps.
- [ ] Assert server outcomes against decoded responses and persisted state.
  Do not use displayed damage as the experience oracle when it is overkill.
  Existing reconnect, listener lifetime and dashboard suites remain required.

Exit: training, projection and persistence work through the actual protocol.

### 12. Pin pacing and deterministic progression limits

- [ ] Add `tests/game/progression_balance_test.fpas` with independent literal
  tables and bounded deterministic fight scenarios; retain a focused permanent
  pacing note in the progression architecture document.
- [ ] Positive tests: a full-health rat plus skeleton supplies 18 points to
  one uncapped skill, regardless of hit grouping; successive complete dungeon
  budgets are 18, 36, 54, 72, 90, 108, 120, reaching levels 2, 3, 3, 4, 4, 4, 5.
  Assert those budgets with actual resolved attacks as well as pure awards.
- [ ] Negative tests: misses cannot increase the health budget, overkill cannot
  inflate it, inactive skills receive no spillover, and mastery cannot increase
  maximum health, armor or opponent strength. No auto-scaling or generator
  changes are permitted to make progression appear necessary.
- [ ] Edge tests: divide a target's remaining health between the two skills;
  cap one skill mid-fight while retaining the other's exact total; compare
  rank-1/rank-5 gear values (unarmed d3/d3+2, sword d6+1/d6+3, hit 75%/85%).
  Complete representative deterministic fights from valid starting states;
  fixture health recovery between fights must not itself award experience.
- [ ] Record actual deterministic outcomes, not a flaky wall-clock threshold
  or broad random win-rate assertion. Balance decisions are the fixed table;
  propose a plan change before changing them in response to subjective pacing.

Exit: improvements remain bounded, equipment matters, and current opponents
provide a verifiable route to the cap before deeper levels are added.

### 13. Final verification, documentation and user acceptance

- [ ] Reconcile README, roadmap, architecture, canonical terms and UI docs with
  the final behavior. Remove planned/current contradictions and obsolete save
  version claims; retain clearly labeled historical versions where useful.
- [ ] Run formatting, all workspace checks and the complete test suite with
  the fixed release compiler. Record actual counts and any failures. Validate
  local Markdown links and examples, purpose comments, public interface docs,
  diff whitespace, unchanged generator fingerprints and intended Git scope.
- [ ] Positive acceptance: new game, both skills, first level increase, active
  skill switch, character-sheet scrolling and save/reconnect/Continue all work.
- [ ] Negative acceptance: an old or invalid save explains its problem without
  losing data; rejected actions grant nothing; failed preparation never installs
  candidate experience; local UI cannot forge training or derived values.
- [ ] Edge acceptance: small terminal, capped skill, overkill, mixed-skill
  target, mid-fight reload, defeat and Start over behave as specified.
- [ ] Mark 13b IN REVIEW only after every automated requirement is green.
  Present a short manual checklist to the user: train unarmed and armed, see a
  level notice and the updated C sheet, scroll at a small size, save/reconnect,
  and deliberately test an incompatible save in disposable test data.
- [ ] Wait for explicit user acceptance before marking 13b DONE or starting
  14c. Then delete this temporary plan and repair its incoming links. Do not
  claim manual acceptance from automated test results.

Exit: accepted progression is documented permanently and 14c can be planned.

## Progress record

Planning validation on 2026-10-16 checked all thirteen checkpoint numbers and
their positive, negative and edge-case coverage, 17 local Markdown links,
the JSON example, command manifest paths and whitespace. Runtime verification
belongs to implementation; this planning change modifies documentation only.

| Checkpoint | Status | Verification |
|---|---|---|
| Plan creation | Complete | Source and documentation inspected; plan decisions fixed |
| 01 | Open | Permanent contract and fresh implementation baseline |
| 02 | Open | Pure progression model |
| 03 | Open | State and save format 9 |
| 04 | Open | Active-skill derived values |
| 05 | Open | Existing hostile navigation extraction |
| 06 | Open | Damage practice and level notices |
| 07 | Open | Atomic server installation and rollback |
| 08 | Open | Six character lines on protocol 15 |
| 09 | Open | Bounded read-only character sheet |
| 10 | Open | Persistence replay and world lifecycle |
| 11 | Open | Full TCP scenarios |
| 12 | Open | Pacing and deterministic limits |
| 13 | Open | Final verification and user acceptance |

Next action: implement checkpoint 01 only when the user requests implementation.
