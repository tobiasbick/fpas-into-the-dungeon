# Roadmap

This roadmap records the intended development order without defining the
complete game in advance. Work proceeds as small end-to-end slices that leave
the client and server executable and tested.

`DONE` means the current acceptance criteria are met. `PARTIAL` means that a
stage contains a completed substage and explicitly deferred later work. `NEXT`
is the only stage that should be detailed enough for immediate implementation.
`LATER` gives an ordering direction and may change as the project teaches us
more. `IN REVIEW` means implementation is complete and final user acceptance
is pending. `OPEN` marks a question that has not been decided.

## 1. Project foundation — DONE

The repository has separate client, server, library, and test projects,
architecture and product documentation, and an external runtime-data layout.
Functional Pascal source and public interfaces have documentation rules.

## 2. Connected outdoor slice — DONE

The authoritative server supplies a fixed outdoor region. The TUI client
connects over the versioned protocol, renders the visible state, sends cardinal
movement intentions, and handles accepted and rejected movement. Unit,
headless-TUI, protocol-contract, and loopback tests cover the slice.

See the [initial client-server slice](architecture/initial-client-server.md).

## 3. Client UI foundation — DONE

The stable presentation and interaction shell is implemented with the states,
layout, controls, and small-terminal behavior described in the
[client UI](product/client-ui.md) document. Headless tests cover the shell and
its connection lifecycle.

This stage is complete when connecting, active, pending, rejected, failed, and
disconnected states have deliberate presentation and test coverage; map sizes
remain server-defined; and a terminal smaller than the content does not crash
the client. Final styling and gameplay-specific panels remain outside this
stage.

## 4. Unbounded outdoor region — DONE

Create the first deterministic, chunked outdoor region with signed stable world
coordinates. The server persists versioned 128 by 128 chunks, loads every chunk
required by a bounded visible window, prefetches one surrounding margin, and
retains a bounded cache. The client reports its available map size and renders
the server projection as a two-column, truecolor `TuiCellGrid`.

This stage is complete when invalid existing data fails without modification,
missing chunks are atomically generated, restart and chunk-edge movement are
covered end to end, viewport resizing crosses arbitrary chunk ranges, and the
client contains presentation mappings but no world rules.

Mutable objects, savegames, settlements, broader world simulation, and
simulated erosion and hydrology remain outside this stage.

## 5. Area transitions — DONE

Add one server-authoritative transition from an outdoor location into one
interior or dungeon and back. Define stable area identities, entrances, return
locations, and the protocol seam between map and first-person views.

This stage is complete when the server validates both directions of the
transition and the client selects the requested view family without inferring
area rules.

The first implementation places one deterministic dungeon entrance exactly
three traversable steps from spawn. `Enter` changes between the outdoor map and
a distinct first-person state while the server retains the exact return
location. World, protocol, TUI, and loopback tests cover both directions.

See [area transitions](architecture/area-transitions.md).

## 6. First-person interior slice — DONE

Render one small entered interior with terminal raycasting and grid-based
first-person movement. The player always occupies one whole field. A movement
intention advances by at most one field, and turning changes the cardinal
facing direction in 90-degree steps without changing position. Free,
continuous movement and arbitrary view angles are explicitly outside the game
model. The same view family will later serve houses, castles, and dungeons.

This stage is complete when the interior can be entered, navigated one field at
a time, turned through all four facing directions, blocked by solid fields, and
left in an end-to-end test. Final visual style, combat, and generated dungeons
remain outside this stage.

The implemented slice uses one validated 11 by 9 dungeon, server-authoritative
relative steps and cardinal turns, a visible exit field, and a pure truecolor
terminal raycaster. Unit, protocol, headless-TUI, loopback, full-session, and
real-process smoke tests cover the complete path. See
[first-person interior](architecture/first-person-interior.md).

The current presentation checkpoint uses one rearward rendering eye and a
90-degree horizontal projection for both near and distant walls. Immediate
lateral fields are visible so junctions can be read without moving or turning.
Visibility also includes partly projected fields along the forward cone edges,
preventing false dark slabs at the screen margins. Range and wall occlusion
still apply; fields behind the player and farther sideways stay hidden.
This changes presentation, not grid-based movement or interaction reach.

## 7. Persistent game state — DONE

Give each selected world one server-owned, versioned savegame below the
configured runtime-data root. Connecting keeps the client on the start screen
until the player explicitly starts a new game or loads the existing save.
Saving is manual, atomic, and confirmed before overwriting; disconnect and quit
never save implicitly. Client persistence remains limited to endpoint and panel
preferences.

This stage is complete when outdoor and first-person state survive a server
restart with exact position, facing, area identity, and return location;
invalid saves are classified and preserved without touching other world data; and
unit, protocol, headless-TUI, restart, and real-process tests pass. A database
is introduced only if concrete access or recovery requirements make the
file-based approach insufficient.

See [persistent game state](architecture/persistent-game-state.md).

## 8. Exploration and map — DONE

Fog of War and an exploration map now show only places the player has
discovered. Discovery is server-owned game state and survives explicit
save and load. The exploration map exists only as an overlay; the context panel
is not split to contain another map. It shows the current area and can pan
independently of the player without issuing movement intentions.

World knowledge has three states: currently visible, discovered but no longer
visible, and undiscovered. Outdoor visibility initially uses a fixed radius
without terrain occlusion. Interior visibility uses line of sight and does not
reveal fields through walls. Fog of War also masks the outdoor primary view so
a large terminal cannot reveal distant cells automatically.

The overlay uses one terminal cell per world field, opens and closes with `M`,
pans with WASD or the arrow keys, recenters on the player with `Home`, and closes
with `Escape`. Zoom is outside this stage. A new game begins with no discovered
area; an existing save remains unchanged until explicit confirmed saving.

This stage is complete when all three knowledge states have deliberate
presentation, outdoor and interior discovery survive a server restart, opening
and panning the overlay cannot move the player, and protocol, persistence,
client/server, and headless-TUI tests cover the complete behavior.

The implemented slice uses a non-occluded outdoor sight radius of eight fields
and facing-aware interior line of sight. Protocol version 8 masks hidden
terrain, savegame format 2 persists sparse outdoor and bounded interior
discovery masks, and the one-cell-per-field overlay serializes and coalesces
pan requests. Unit, protocol, persistence, headless-TUI, loopback, restart, and
real-process smoke tests cover the complete path. See
[exploration and map](architecture/exploration-and-map.md).

## 9. First RPG interaction — DONE

`Enter` is one generic server-authoritative interaction with the occupied field
or the field directly ahead. Existing entrance and exit behavior uses that
seam. A fixed stone tablet in the initial dungeon proves a read-only inspection
result without introducing inventory, dialogue, or mutable object persistence.
Inspection descriptions open a framed overlay with wrapped, scrollable text
and Enter/Escape dismissal.

The interaction semantics, tablet placement, and presentation are accepted.
Game, protocol, client, server, raycasting, map-overlay, and end-to-end tests
cover descriptive and state-changing outcomes. See
[interaction](architecture/interaction.md).

## 10. Items and inventory — DONE

Build the smallest mutable item loop on top of the generic interaction seam.
The initial dungeon contains one fixed **Ancient coin**. The server owns its
stable identity and whether it lies in the dungeon or is carried by the player;
the client only renders the projected state and sends interaction intentions.

### 10a. Item model and visibility

- [x] Add one stable item identity and one server-owned location state.
- [x] Place the item deterministically in the initial dungeon.
- [x] Include visible inventory entries and visible item cells in the protocol.
- [x] Render the item in the first-person view and exploration map.
- [x] Complete model, protocol, projection, and rendering edge-case tests.

### 10b. Inspection, pickup, and inventory presentation

- [x] Inspect the item with `Enter` while it is directly ahead.
- [x] Pick up the item with `Enter` while occupying its field.
- [x] Remove a picked-up item from the area projection.
- [x] Replace the context panel placeholder with the carried item list.
- [x] Show examine/pickup hints and pickup confirmation in a fixed-height
  Environment panel above Context, with a non-blocking in-view fallback when
  the sidebar is hidden or cannot dock. Render one small coin instead of
  covering its floor field.
- [x] Prove that repeated interaction and reconnects cannot duplicate or lose
  the item.

### 10c. Persistence and completion proof

- [x] Persist the item location or carried state in the current savegame
  format.
- [x] Restore the initial placement when starting a new game.
- [x] Prove pickup, explicit save, server restart, and load end to end.
- [x] Cover malformed, missing, duplicate, and incompatible item state with
  negative and edge-case tests.
- [x] Synchronize the architecture, interaction, persistence, product, and UI
  documentation with the accepted behavior.
- [x] Run the complete workspace and real-process test suite.

Phase 10 is complete only when every item above is checked and game, protocol,
persistence, client, server, rendering, and end-to-end tests cover the complete
path.

The Phase 10 checkpoint introduced protocol version 9 and savegame format 3;
the current versions advance with Phase 11. Unit,
negative, edge-case, protocol, persistence, headless-TUI, loopback, restart,
full-session, and real-process smoke tests cover the complete path. See
[items and inventory](architecture/items-and-inventory.md).

Dropping, equipping, using, stacking, capacity limits, random loot, containers,
shops, and an economy remain outside this phase.

### Presentation follow-up — ACCEPTED FOR THIS CHECKPOINT

The current dungeon projection and split sidebar are accepted as an intermediate
checkpoint, not a final visual design. The item loop remains complete; further
visual work may be discussed separately without reopening Phase 10.

- [x] Use one coherent wall/floor projection and cover lateral openings with tests.
- [x] Separate environment hints from character and inventory information.
- [x] Cover fixed panel height, text wrapping, hidden-sidebar fallback, and
  narrow/short-terminal behavior.
- [x] Accept the current first-person presentation and Ancient coin appearance
  as sufficient for the first playable checkpoint.

## 11. NPCs and simple dialogue — DONE

Introduce one server-owned NPC and one deterministic conversation without LLM
involvement. The first implementation places **Mara, the old adventurer** at a
fixed blocking field in the initial dungeon.

- [x] Give the NPC a stable identity, validated placement, blocking collision,
  and current-visibility-only projection.
- [x] Start dialogue with `Enter` only while the NPC is directly ahead.
- [x] Keep the typed dialogue graph and available choices server-authoritative.
- [x] Offer first/repeat greetings and a conditional Ancient coin question
  without taking or changing the item.
- [x] Present dialogue in a framed client overlay with wrapping selection,
  answer, and explicit leave controls.
- [x] Block unrelated client input and server intentions while dialogue is active.
- [x] Persist only whether the NPC has met the player; never persist an active
  conversation or client selection.
- [x] Hide dynamic NPC presence from remembered Fog of War fields.
- [x] Cover success, malformed input, unavailable choices, bounds, collision,
  visibility, persistence, reconnect, narrow TUI, network adapter, and complete
  TCP session behavior.
- [x] Synchronize architecture, product terminology, UI, persistence, and
  roadmap documentation.
- [x] Review the complete NPC and dialogue slice with the user and obtain
  explicit acceptance.

The implemented slice uses protocol version 10 and savegame format 4. It uses
ordinary Functional Pascal data and functions rather than a scripting system.
Stage 14a removed this dialogue feature; stage 15 will restore NPCs and dialogue in settlements.

Moving NPCs, schedules, quests, general dialogue scripting, free-text input,
branching world effects, and LLM-generated behavior remain outside this phase.
The user accepted the complete slice, including the upright first-person figure
that replaced the initial floor marker.

## 12. Combat — DONE

Introduce one small server-authoritative combat loop with one opponent. The
design keeps the grid-based first-person presentation of classic dungeon
crawlers but advances time only through player actions, so the request-response
protocol stays sufficient and every fight is reproducible.

- [x] Design turns, dice, the opponent, defeat, and persistence before
  implementation in [combat](architecture/combat.md).
- [x] Place the **restless skeleton** in the inner passages of the initial
  dungeon, hidden from the main route, with blocking collision and
  current-visibility-only projection.
- [x] Consume a turn only for a successful step, `Space` attack, or `Z` wait;
  keep turning, interaction, dialogue, and saving free.
- [x] Let the skeleton notice the player through line of sight, chase along a
  shortest path, and attack from orthogonally adjacent fields.
- [x] Roll hits and damage with a seeded generator stored in the game state.
- [x] End the game session on defeat with a dedicated message and a client
  overlay that leads back to loading or starting a game.
- [x] Let Mara tend the player's wounds while the player is hurt.
- [x] Project health in both views, the turn's combat log, and a red damage
  frame; draw the skeleton as a first-person figure and map marker.
- [x] Persist health, the opponent, and the dice state in savegame format 5.
- [x] Cover perception, pursuit, deterministic fights, victory, defeat,
  healing, validation, protocol bounds, persistence, TUI behavior, and a
  complete TCP fight.
- [x] Review the complete combat slice with the user and obtain explicit
  acceptance.

The implemented slice uses protocol version 11 and savegame format 5.
Multiple opponents, loot, experience, ranged attacks, spells, real-time combat,
and equipment remain outside this phase.
The user accepted the slice after `Space` was mapped to the terminal's
dedicated space key kind.

## 13. Character progression — DONE

Progression starts with equipment because it changes the existing fight at
once, while experience and levels need more opponents than the initial dungeon
provides. Named attributes such as strength or dexterity are introduced only
when a rule needs them; until then the character has derived values.

### 13a. Equipment, character sheet, and combat animation — DONE

- [x] Design derived values (attack, damage, armor, maximum health), equipment
  slots, and turn costs before implementation in
  [equipment](architecture/equipment.md).
- [x] Derive the character's values from base values plus equipment; let the
  combat rules read the derived values instead of fixed numbers. Unarmed
  damage drops to d3 so a weapon matters; the deterministic combat
  expectations change accordingly.
- [x] Offer a weapon slot and a body slot.
- [x] Let an interior hold several floor items instead of one fixed item field.
- [x] Place a **rusty short sword** (damage d6+1 instead of unarmed d3) and a
  **leather jerkin** (armor +2, raising the skeleton's hit threshold from 9 to
  11) as floor items in the initial dungeon. Both lie off the main route and
  outside the skeleton's sight, so exploring before the fight pays off.
- [x] Open an inventory overlay with `I`: select with W/S or the arrow keys,
  equip or unequip with `Enter`, close with `Escape`. Each change consumes one
  turn so gear cannot be swapped for free during a fight.
- [x] Validate on the server that an item is equippable, owned, and fits its
  slot.
- [x] Show a character sheet overlay on `C` with the derived values, their
  sources, and the equipment; list equipped items in the context panel.
- [x] Persist equipment in the next savegame format and project it in the next
  protocol version.
- [x] Animate a resolved combat turn on the client only: a weapon swing, a hit
  flash or dodge on the skeleton, its lunge before the damage frame, rising
  damage numbers, and its collapse. The server adds only structured turn
  events; a client subscription with a timer supplies the animation frames, so
  Functional Pascal needs no change.
- [x] Measure first-person frame cost first; cache the wall image if a full
  raycast per animation frame is too slow.
- [x] Keep animations short; a further key press completes the running
  animation at once and is not lost.
- [x] Cover derivation, validation, turn costs, combat effects, persistence,
  TUI behavior, individual animation frames, and a complete TCP fight with
  equipment.
- [x] Synchronize architecture, product terminology, UI, persistence, and
  roadmap documentation.
- [x] Review the complete equipment slice with the user and obtain explicit
  acceptance.

The implemented slice uses protocol version 12 and savegame format 6.
Item rarity, durability, shops, loot tables, two-handed weapons, and further
slots remain outside this slice.
The user accepted the complete equipment, character-sheet, and combat-animation
slice.

### 13b. Experience and levels — DONE

All thirteen checkpoints were implemented with positive, negative and
edge-case tests; formatting, all workspace checks and the complete suite pass
(122/122 programs). The user accepted 13b on 2026-10-16, and its temporary plan
is removed. The lasting contract is [progression](architecture/progression.md).
Acceptance also covered a tabular world catalog with one wrapped reason and a
fix for the client exit on `Refresh worlds` (focus on a control that the waiting
screen does not render).

The character learns by doing, with independent Unarmed and Blades skills.
Only health actually removed by a successful player attack earns experience
for the skill used. Misses and non-combat actions grant none; overkill cannot
inflate the award. Each skill starts at level 1, reaches levels 2/3/4/5 at
12/36/72/120 cumulative experience, and caps at 120. Its total hit/damage
bonuses are 0/0, 0/+1, +1/+1, +1/+2 and +2/+2 respectively. Only the active
skill contributes, starting with the next attack after a level increase.
Maximum health, armor, opponents and generated content remain unchanged.

- [x] Detail the rules, state/storage boundaries and ordered checkpoints in a
  temporary implementation plan, with exact thresholds and test expectations.
- [x] Establish the permanent progression contract and canonical terminology;
  implement and test the pure skill model.
- [x] Add validated progress to GameState and savegame format 9. Preserve older
  saves without migration; compatible world and level files remain usable.
- [x] Derive weapon-dependent benefits, isolate existing hostile navigation,
  and award practice once per resolved hit with bounded level-up messages.
- [x] Prove full server commit/rollback, save/replay, Start over and reconnect
  behavior, including invalid data, overkill and mastery.
- [x] Project both skills as six entries in the existing character array on
  protocol 15; provide a bounded, scrollable read-only character sheet on C.
- [x] Verify complete TCP play, deterministic pacing, formatting, all workspace
  checks and the complete suite; synchronize permanent documentation.
- [x] Review the finished slice with the user and obtain explicit acceptance
  before marking it DONE and removing its temporary plan.

The slice adds no overall character level, classes, allocated skill points,
defensive training, ranged combat or spells. World format 3, generator 7 and
immutable level format 2 stay unchanged. Implement 13b before deeper dungeon
levels (14c), so progression is established against the current opponent kinds.

## 14. Generated game content — DONE

Expand beyond the fixed initial dungeon with generated interiors, dungeons,
locations, and their contents. Generation remains deterministic and
server-owned. The stage is split so each slice stays reviewable: 14a builds the
infrastructure, 14s adds world management and the server console, 14b adds
contents, then 13b adds progression before 14c adds deeper levels.

### 14a. Generated dungeons — DONE

- [x] Design entrance sites, the area view, the dungeon generator, and
  persistence before implementation in
  [generated dungeons](architecture/generated-dungeons.md).
  The [level storage contract](architecture/dungeon-level-storage.md) fixes
  file schema, final interfaces, error classes, and transition ordering.
- [x] Place at most one ordinary deterministic entrance per entrance region on
  walkable land, replacing the spawn region's candidate with its guaranteed
  entrance three steps from spawn. This special entrance may cross a region
  border and remains assigned to the spawn region. Entrances appear on the map
  once revealed. Raise the world generator version to 6.
- [x] Make the entrance region size a world parameter: default from
  `server.toml` (4 chunks), stored in the world metadata at creation.
- [x] Remove the hand-authored initial dungeon, its tablet, Mara, and the
  complete dialogue feature until stage 15; heal one health point per outdoor
  step instead. Raise the protocol version to 13.
- [x] Resolve interior maps by area identity; pass an area view with the
  resolved map to the rules and keep the current area's map in the server
  session.
- [x] Generate a 31 by 21 rooms-and-corridors dungeon from the world seed and
  the entrance region, with one or two restless skeletons far from the start
  and the coin, sword, and jerkin in room corners.
- [x] Validate generated maps (connectivity, exit, room count, floor share, no
  opponent in sight of the start); retry with derived seeds; pin a fingerprint
  of fixed regions; measure the generation time.
- [x] Generate each dungeon's level on first entry and atomically store its
  immutable geometry and original placements as versioned world data. Load
  that file on revisits; keep the current map in memory. Invalid files fail
  without replacement; missing files referenced by a save fail without deleting
  the save. Do not regenerate levels during save/load validation.
- [x] Materialize opponents and items on entry in the current game and persist
  mutable state and visited areas only through explicit saving. Validate item
  origins separately from current locations in savegame format 7. Starting
  over or loading an earlier save keeps the immutable level files.
- [x] Limit carried and equipped items together to 64; reject pickup when full
  without changing state. Allow dropping carried items on an empty ordinary
  dungeon floor field and picking them up again, including in another dungeon.
  Persist their locations without duplicating their original placements.
- [x] Return the player to the entrance they used when leaving a generated
  dungeon.
- [x] Cover entrance placement, generator determinism and validation,
  materialization, persistence, and a complete TCP visit to a generated
  dungeon.
- [x] Measure complete save and load operations with 1, 10, and 100 visited
  dungeons, including reading and validating stored levels; report timings and
  peak memory. Measure first-time generation and storage separately.
- [x] Synchronize architecture, product terminology, persistence, and roadmap
  documentation.
- [x] Correct false dark screen-edge fields by including partly visible fields
  at the sight cone's edges. Cover all four facings and multiple terminal widths;
  the user confirmed the rendering in the running game on 2026-10-06.
- [x] Review the generated-dungeon slice with the user and obtain explicit
  acceptance.

The rendering correction passed `fpas check` and the complete workspace suite
(56/56 tests). The user accepted the complete 14a slice on 2026-10-14.

Dungeon names, further opponent kinds, loot tables, and consumables belong to
14b; stairs and deeper levels to 14c.

### 14s. World management and server console — DONE

- [x] The server supplies defaults and allowed ranges for world parameters (seed,
  entrance region size, later more); the client's new-world dialog shows them
  and may override them within the ranges. The server validates and creates a
  new world with its own identity; earlier worlds are kept.
- [x] Separate `Create world`, `Continue`, and `Start over` actions. Continue loads
  the selected world's last explicit save when world format, generator, and
  savegame versions match the running server. A compatible world without a
  save can be started at its spawn. Start over begins a fresh game in the same
  world; its earlier save remains until an explicitly confirmed overwrite.
- [x] List existing worlds with parameters and save status. Incompatible worlds
  remain visible with an instruction to delete or recreate them; do not migrate
  or delete them automatically. Client-side deletion is deferred.
- [x] Returning to world selection with unsaved progress requires confirmation to
  discard it or cancellation; never save implicitly. Prepare and validate the
  selected world before installing it as the active session world.
- [x] `world_id` in `server.toml` preselects a world at server start. A missing or
  incompatible selection leaves world selection available and shows the
  reason; storage I/O failures are reported separately, never treated as a
  missing world. The server still admits only one player at a time.
- [x] `dungeon-server --console` fills the terminal with Server, Session and World
  panels, a bounded UTC live log (connections, created and loaded worlds,
  rejected requests, errors), severity filters, scrolling/follow and shortcuts.
  Typed server snapshots provide real session and save status. The
  settings view edits the server defaults such as the entrance region size and
  later the LLM connection; it validates each value and writes `server.toml`.
  World parameters changed there apply to new worlds only. Without `--console`
  the server stays headless.
- [x] Uses protocol 14; world format 3, generator 6 and save format 7 remain
  unchanged.

New worlds accept signed 32-bit seeds and entrance regions of 1 through 16
chunks. Catalogs are strict bounded pages with a transport byte budget;
inspecting them never generates content.
Formatting and workspace checking pass; the complete workspace suite passed
68/68 test programs with positive, negative, and edge-case coverage on
2026-10-15. The start-menu backdrop is retained for the current terminal size,
so focus navigation no longer regenerates it; the regression covers resize and
return from gameplay.

The user approved a full-terminal dashboard on 2026-10-14; its implementation
was verified on 2026-10-15. It replaces the
centered menu with Server, Session and World panels, a large timestamped,
scrollable/filterable live log, and a shortcut footer. Settings remain an
overlay. Typed server snapshots supply real status; responsive layouts and
positive, negative and boundary tests cover the dashboard. Startup
errors, failed saves, reconnects, native keyboard routing and very small windows
are covered. The user accepted the running server console on 2026-10-15,
closing the final terminal review for 14s. See the
[server console documentation](product/server-console.md) for operation and
controls.

### 14b. Dungeon contents — DONE

The twelve implementation checkpoints have positive, negative and edge-case
tests. The user accepted 14b on 2026-10-16, and its completed plan is removed.
It adds stored,
deterministic dungeon names, a Giant rat alongside the Restless skeleton,
generated floor finds and a Healing potion. Opponent death drops remain deferred.

- [x] Recheck the baseline and prepare independent regression fixtures and
  deterministic combat vectors (14b checkpoint 01). On 2026-10-15, formatting,
  all 20 project checks and the final complete suite passed (68/68 programs).
  This baseline checkpoint left gameplay and format versions unchanged.
- [x] Generate and store a bounded dungeon name; use it in the game, exploration
  map and server dashboard without regeneration during rendering or load.
  Checkpoint 02 passed formatting, all 20 project checks and the complete
  workspace suite (70/70 programs) on 2026-10-15, with positive, negative and
  boundary coverage. That checkpoint retained protocol 14 and save format 7.
  Generator 7, level format 2 and world format 3 remain current.
- [x] Support both opponent kinds through rules, strict storage/wire mappings,
  Fog of War, sprites and kind-correct combat/death animation.
  Checkpoint 03 introduces protocol 15 and save format 8. The generator still
  places skeletons until checkpoint 09. Formatting, all 20 project checks and
  the full suite pass (76/76 programs); independent subagent review and its
  follow-up corrections are complete on 2026-10-16.
- [x] Add Healing potion identity and the terminal consumed location, with
  full origin validation in save format 8, inventory exclusion, visible `p`
  and distinct floor/map art (checkpoint 04). Stored levels can include the
  explicit potion slot 3; generation still emits three base items until 09.
  Formatting, all 20 project checks and the complete suite pass (79/79 programs)
  on 2026-10-16; independent subagent review found no actionable defects.
- [x] Resolve carried-potion use as one authoritative turn (checkpoint 05):
  capped healing before the hostile phase, actual healing log, exact item
  consumption and unchanged state/dice on rejection. Checkpoint 06 adds the
  protocol/session path below; checkpoint 07 adds player controls. All 20 project
  checks and the complete suite pass (80/80 programs) on 2026-10-16;
  independent subagent review found no relevant defects or missing coverage.
- [x] Expose strict `use_item` and required inventory `usable` in both visible
  state families (checkpoint 06). The server uses the existing turn path;
  accepted use marks unsaved progress, while rule/preparation failures retain
  the installed session. Checkpoint 07 adds inventory keyboard use.
  Formatting, all 20 project checks and the complete suite pass (85/85 programs)
  on 2026-10-16; independent subagent review found no relevant defects or
  missing required coverage.
- [x] Make inventory `Enter` use a projected consumable before equip/unequip
  (checkpoint 07), show its action and health, retain selection by item ID and
  preserve pending/modal guards and `D` dropping. Only server replies change
  health or inventory. Generated potion placement remains checkpoint 09.
  Formatting, all 20 project checks and the final complete suite pass (86/86
  programs) on 2026-10-16. Independent subagent review found a transport-failure
  animation lifecycle issue; it is fixed, regression-tested and rechecked with
  no open relevant findings.
- [x] Implement bounded optional loot selection independently of geometry and
  combat (checkpoint 08): exhaustively tested fixed 100-roll table, private
  normalized seed derivation and separate domains for slots 4/5. Placement
  integration remains checkpoint 09.
  Formatting, all 20 project checks and the complete suite pass (87/87 programs)
  on 2026-10-16. Independent subagent review recalculated all 13 pinned vectors
  and found no relevant defects or missing required coverage.
- [x] Integrate final generated contents (checkpoint 09): one skeleton and one
  rat in the farthest safe rooms, four guaranteed floor finds and optional
  original slots 4/5 without renumbering. Strict stored validation accepts 4..6
  finds without rerolling; generic authored maps retain their own counts.
  The three final fingerprints retain their previous geometry and endpoints.
  Formatting, all 20 project checks and the final complete suite pass (88/88
  programs) on 2026-10-16. Independent review and follow-up review are complete;
  the stale schema count and old expected-three save assertions are corrected.
  No relevant findings remain.
- [x] Use a carried potion from inventory to heal up to six health points before
  the opponents act once. Reject use at full health or of an invalid item without
  changing state, dice, time or unsaved-progress status.
- [x] Verify immutable levels and resumable cross-area item state (checkpoint 10):
  real pickup/drop/use and attacks, save/reopen/load during combat and outdoors,
  optional slot-5 potion with slot 4 absent, all potions consumed, defeated
  opponents, revisit, Start over and earlier-save rewind. Stored bytes stay
  unchanged; corrupt origins/slots, obsolete formats and I/O failures preserve
  saves and levels. A filesystem trace confirms one read per visited level on
  save/load. All 11 world-test programs, formatting, all 20 project checks and
  the final complete suite pass (89/89 programs) on 2026-10-16. Independent
  review found no relevant defects or required coverage gaps. The complete
  client/server and reconnect sequence follows in checkpoint 11 below.
- [x] Exercise the complete client/server contents loop (checkpoint 11): natural
  TCP play with gear, potion use and both opponents; exact unsaved-turn replay
  after reconnect; explicit save/Continue/revisit and earlier-save rewind.
  Actual network combat facts drive kind-correct client death art; stored names
  match map labels and dashboard facts. Old formats, rejected use, capacity,
  later defeat, failed load/send, duplicate names and dirty shutdown are covered.
  Formatting, all 20 project checks and the final complete suite pass (91/91
  programs) on 2026-10-16. Independent review found a missing explicit enemy-phase
  assertion; fixed literal health/damage/RNG anchors close it, and follow-up
  review confirms no open findings. Checkpoint 12 closes automated verification
  below. The later user acceptance closes the terminal-review gate.
- [x] Use protocol 15, generator 7, level format 2 and save format 8; keep world
  format 3 and runtime settings unchanged. Preserve incompatible files and report
  why their worlds/saves cannot continue; do not migrate or delete them.
- [x] Cover pure rules, stored formats, protocol rejection, real keyboard input
  and TCP play. Final checkpoint 12: formatting, all 20 project checks and the
  complete suite pass (91/91 programs) on 2026-10-16. The
  [persistence measurements](architecture/persistence-measurements.md) cover
  1/10/100 visits with fresh and consumed items, baseline controls and phase
  investigation. Documentation is aligned; independent review corrected two
  stale placement/coin claims and clarified the phase timings to include
  self-contained validation. Follow-up review confirms no open relevant findings
  or benchmark-code defect.
- [x] The user explicitly accepted 14b on 2026-10-16. The prior deferred terminal
  review no longer blocks completion, and the accepted implementation plan is
  removed. 13b followed as the next gameplay slice, before 14c. The client/server review
  is complete: R03/R04
  connection isolation/socket cleanup, R05 recoverable preparation errors,
  R06 bounded inventories, R07 bounded catalog inspection, R09 detailed
  persistence diagnostics and R10 exploration-map continuity are complete on
  2026-10-16, with 107/107 tests and all
  21 projects checked using the fixed compiler. Failed Move/Viewport preparation
  preserves the session; actual send
  failures remain fatal. Inventory windows
  follow selection and retain controls; quick summaries fit the panel and count
  omitted items. Catalogs fully inspect at most 64 page entries plus an existing
  off-page selection; Continue still validates the complete save and its levels.
  Save/load failures retain their original cause in server logs and preserve
  sanitized client replies. Viewport replies retain the open exploration map
  and its independent projection/request; explicit close stays respected.
  R11-R15 are complete: focused lifecycle owners, shared interior knowledge
  projection, normal disconnect publication after socket cleanup, verified
  dead-code cleanup and explicit lifecycle/animation contracts. All **15/15**
  review items are closed. The user authorized two FPAS compiler repairs with
  tests: imported constants as native-call receivers and native enum aliases
  used by record fields. Both minimal reproductions pass, and the complete Rust
  workspace suite is green. Independent compiler and game Standards/Spec reviews
  have no remaining findings. Final game verification is **107/107 programs**,
  all **21 projects** checked, with unchanged generator fingerprints and formats.
  The user accepted the review on 2026-10-16, and its temporary plan is removed.
  Lasting contracts remain in the [architecture overview](architecture/overview.md)
  and product documentation. Progression (13b) followed as the next gameplay slice before
  14c.

Generated loot has stable identities derived from its source and is created
only once. Persist consumed items as consumed rather than deleting their
identities, so loading or revisiting cannot restore them. Validate item origins
separately from current locations or consumed state. Using a consumable costs
one turn when successful; rejected use changes nothing. Outdoor step healing
remains available; consumables provide healing inside a dungeon. Revise the
savegame, protocol, and generator versions where their contracts change.

### 14c. Dungeon levels — DONE

Stairs between levels and deeper, harder levels of a generated dungeon.
Depth is stored per dungeon (currently three levels, later dynamic); deeper
levels hold more opponents of the existing kinds and fewer guaranteed finds;
paired stairs are terrain cells; only level 0 leads outdoors.

Checkpoints 01-10 are implemented with positive, negative and edge-case tests:
generator 8, level format 3, save format 10 and protocol 16. Formatting, all 21
project checks and the complete suite (131/131 programs) pass on 2026-10-17.
An opponent left on an arrival field shifts the arrival to the nearest free
floor field, and same-kind combat animation is narrowed to the affected field.
The user accepted 14c on 2026-10-17, and its temporary plan is removed. The
lasting contracts are in [generated dungeons](architecture/generated-dungeons.md),
[level storage](architecture/dungeon-level-storage.md) and
[area transitions](architecture/area-transitions.md).

13b is complete. Each level is a separate area with an identity derived
from the dungeon and level index. Generate and permanently store its immutable
layout and original placements on first visit, then materialize its game state.
Revisits load the same level file; deeper unvisited levels remain ungenerated.
Paired stairs have deterministic destination areas, landing fields, and facing;
travel works in both directions and retains each level's state. Only leaving
the top level returns to the outdoor entrance. An area transition need not
change view family. Replace the assumption of a single interior-to-outdoor
return with explicit stair links, and cover multi-level save/load and revisits.
Choose the initial finite depth and difficulty curve when detailing this slice.

## 15. Settlements and a living world — PARTIAL

Settlements, NPCs, deterministic quests, an economy, time, and weather follow
the vertical slice in `DUNGEON_RPG_IDEAS.md`: enter a settlement, talk to an
NPC, take a solvable quest into a dungeon, and return to a character that
remembers the outcome. Every substage is deterministic and server-owned and does
not depend on LLM integration (stage 16). Stages 15a through 15d are accepted.
Later substages give an ordering direction and are planned when they become next.

### 15a. Home settlement and Mara — DONE

One authored settlement near the spawn, entered through a gate like a dungeon
entrance and shown in the map view. Entered houses use the first-person view;
building interiors follow later. Mara returns as its first NPC with
the deterministic dialogue removed in 14a: greetings that remember the player,
questions about herself, the nearby dungeon and the Ancient coin, and free
healing while the player is hurt. Outdoor-step regeneration remains available.
Answers keep the dialogue window open with refreshed topic choices. The user
accepted 15a on 2026-10-17.

Implemented and verified on 2026-10-17. Hearthmoor has bounded map movement,
visible-only Mara markers, deterministic dialogue with refreshed choices, free
healing and explicit persistence of her meeting state. The server gates other
intentions during dialogue and commits replies atomically; the client owns only
the projected modal, selection and scroll position. Settlement projection uses
no outdoor chunk I/O. Houses remain closed until building interiors are added.

At 15a acceptance, versions were world format 4, generator 9, savegame 11 and
protocol 17; level-file format stayed 3. Obsolete data is rejected and preserved. Formatting,
all 21 project checks and the complete suite pass: **146/146 test programs**.
A natural TCP play test takes dungeon damage, reaches Mara still hurt, heals,
saves, restarts the complete listener and verifies Continue and her repeat
greeting. Final review also closed a save-validation gap for settlement floor
items while the player is outdoors.

All eleven checkpoints are complete. The implementation plan was removed
after acceptance; the permanent contract is documented in
[NPCs and dialogue](architecture/npcs-and-dialogue.md).

### 15b. First deterministic quest — DONE

Mara offers one quest to recover her lost compass from the deepest level of
the spawn dungeon. Read-only preflight proves the route and target before the
offer. Earlier retrieval counts on explicit acceptance; hand-in returns the
compass and grants two Healing potions atomically, once per game. A full
inventory defers the whole exchange. The journal on `J` follows carried
ownership and remembers the completed outcome.

The user accepted 15b, including server world administration, on 2026-10-17
after testing the running feature. All nine gameplay checkpoints are complete.
A natural TCP test covers active, ready and rewarded saves over four listener lifetimes.
Final verification, including world administration, passes on 2026-10-17:
formatting, all 21 project checks and the complete suite (**154/154 test programs**).
At 15b acceptance, versions were world metadata 4, generator 10, level file 4, savegame 12
and protocol 18; obsolete
data is rejected and preserved. The lasting contract is documented in
[quests](architecture/quests.md). The accepted implementation plans are removed.

The server-administration follow-up adds **Worlds (F4)** to the console, with
paged compatibility/save status and confirmed deletion of a complete world,
including obsolete data. It excludes admitted connections through the listener's
shared admission permit. Current workspace verification, including both new
programs, passes **154/154 tests** and all 21 project checks. Stored formats and
the client world-selection flow are unchanged. See the
[console guide](product/server-console.md#deleting-worlds).

### 15c. Generated settlements — DONE

The user accepted 15c on 2026-10-24, including the server-console presentation.
All nine implementation checkpoints are complete, and the complete workspace
suite passes **161/161 test programs**. The accepted implementation plan is
removed; the [acceptance report](acceptance/generated-settlements-dap.md) records
the real-client play and final verification.

Occasional small villages, about 23 by 15 through 31 by 21 fields, contain
residents, guards and healers with deterministic dialogue and free healing.
Houses stay closed until building interiors are planned separately.

Hearthmoor, Mara and the compass quest remain the authored starting point.
Additional villages spread across the outdoor world with stable gate/area/NPC
identities and immutable stored names, layouts and placements. NPC meeting
state and discovery belong to explicit saves; revisits and Continue reuse the
same definitions.

Current versions are generator 11, settlement format 1, savegame 13 and protocol
19; world format 4, dungeon level format 4 and runtime configuration remain.
Obsolete worlds and saves are preserved without migration. Trade follows in
15d; time/rest, weather, LLMs and multiplayer remain later work.

The natural seed-25 TCP play visits two villages and verifies injury/healing,
inside/outdoor Continue, independent meetings, unchanged definitions and Start
over over four listener lifetimes. The full compass play visits generated NPCs
before returning to Mara and verifies remembered completion. The permanent
[settlement contract and review route](architecture/generated-settlements.md)
describe the implementation and manual review.

### 15d. Trade and economy — DONE

A merchant buys and sells for coins, giving the Ancient coin and loot a use.
Prices, stock, and capacity rules are deterministic and persistent.

Hearthmoor and every generated village have a merchant with finite stock, a
64-item limit and fixed prices. The player has a separate coin balance and trades
through a dedicated Buy/Sell window. All ten checkpoints are complete, including
real TCP proofs and the full seed-25/chunk-1 DAP route. Formatting, all workspace
project checks and the complete suite pass (171/171 programs).

The user accepted 15d on 2026-10-25, and its temporary plan is removed. The
[economy contract](architecture/economy.md) and
[running-game verification](architecture/economy-acceptance.md) record the result.

### 15e. Time and rest — DONE

A world clock advances with turns and outdoor travel, with a day/night
presentation and resting at an inn as an alternative way to heal.

The rules follow the user's delegation: action-based time, day/night colors and
5-coin, eight-hour inn rest with full healing. Innkeepers replace generated healers; outdoor-step
and free NPC healing are removed. All nine checkpoints are complete in order.
Formatting, workspace checks and **175/175 test programs** pass. The seed-25,
region-size-1 DAP route verifies ordinary loot-funded rest in both inns,
day/night progression, process restarts and preservation of the explicit save
after unsaved Start over. See the [time/rest contract](architecture/time-and-rest.md)
and [running-game report](architecture/time-and-rest-acceptance.md).
The user accepted 15e on 2026-10-25. Its temporary implementation plan is removed.

### 15f. Weather and changing world state — LATER

Weather and world changes caused by quest outcomes, such as cleared dungeons or
altered settlement dialogue, once a concrete gameplay requirement is known.

## 16. LLM integration — LATER

LLM integration is explicitly postponed. Its authority boundaries, failure
behavior, cost controls, and effect on deterministic game rules will be
designed separately before implementation begins.

## 17. Multiplayer behavior — LATER

Multiple simultaneous players require separate authority, visibility,
conflict-resolution, lifecycle, and persistence decisions. The current
single-player client-server model does not imply those rules. Multiplayer is
deliberately the last stage.
