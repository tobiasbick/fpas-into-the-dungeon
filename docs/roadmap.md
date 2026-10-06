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

## 13. Character progression — PARTIAL

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

### 13b. Experience and levels — LATER

Experience waits until generated content (stage 14) supplies enough opponents
to make it meaningful. The preferred direction is learning by doing, as in
Dungeon Master: the character improves in what it actually does, which suits a
game without class selection at the start.

Implement this slice after 14b and before 14c, so progression can be balanced
against several opponent kinds before deeper, harder levels are introduced.

## 14. Generated game content — NEXT

Expand beyond the fixed initial dungeon with generated interiors, dungeons,
locations, and their contents. Generation remains deterministic and
server-owned. The stage is split so each slice stays reviewable: 14a builds the
infrastructure, 14s adds world management and the server console, 14b adds
contents, then 13b adds progression before 14c adds deeper levels.

### 14a. Generated dungeons — IN REVIEW

- [x] Design entrance sites, the area view, the dungeon generator, and
  persistence before implementation in
  [generated dungeons](architecture/generated-dungeons.md), with a step-by-step
  [implementation plan](plans/14a-generated-dungeons.md).
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
- [ ] Review the generated-dungeon slice with the user and obtain explicit
  acceptance.

The rendering correction passed `fpas check` and the complete workspace suite
(56/56 tests). Its visual review is complete; final acceptance of the complete
14a slice is still pending.

Dungeon names, further opponent kinds, loot tables, and consumables belong to
14b; stairs and deeper levels to 14c.

### 14s. World management and server console — IN REVIEW

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
- [x] `dungeon-server --console` shows a live log (connections, created and loaded
  worlds, rejected requests, errors), a status line, and a settings view. The
  settings view edits the server defaults such as the entrance region size and
  later the LLM connection; it validates each value and writes `server.toml`.
  World parameters changed there apply to new worlds only. Without `--console`
  the server stays headless.
- [x] Uses protocol 14; world format 3, generator 6 and save format 7 remain
  unchanged.

Implementation and verification are tracked in
[the 14s plan](plans/14s-world-management.md). New worlds accept signed 32-bit
seeds and entrance regions of 1 through 16 chunks. Catalogs are strict bounded
pages with a transport byte budget; inspecting them never generates content.
Formatting and workspace checking pass; the complete workspace suite passed
65/65 test programs with positive, negative, and edge-case coverage on
2026-10-06. The start-menu backdrop is retained for the current terminal size,
so focus navigation no longer regenerates it; the regression covers resize and
return from gameplay. The feature remains in review until accepted.
The user's latest terminal test on 2026-10-06 still found unresolved behavior;
reproduction and correction are the next steps recorded in the plan.

### 14b. Dungeon contents — LATER

Several opponent kinds such as a giant rat, loot tables, a first consumable
item, and deterministic dungeon names.

Generated loot has stable identities derived from its source and is created
only once. Persist consumed items as consumed rather than deleting their
identities, so loading or revisiting cannot restore them. Validate item origins
separately from current locations or consumed state. Using a consumable costs
one turn when successful; rejected use changes nothing. Outdoor step healing
remains available; consumables provide healing inside a dungeon. Revise the
savegame, protocol, and generator versions where their contracts change.

### 14c. Dungeon levels — LATER

Stairs between levels and deeper, harder levels of a generated dungeon.

Implement after 13b. Each level is a separate area with an identity derived
from the dungeon and level index. Generate and permanently store its immutable
layout and original placements on first visit, then materialize its game state.
Revisits load the same level file; deeper unvisited levels remain ungenerated.
Paired stairs have deterministic destination areas, landing fields, and facing;
travel works in both directions and retains each level's state. Only leaving
the top level returns to the outdoor entrance. An area transition need not
change view family. Replace the assumption of a single interior-to-outdoor
return with explicit stair links, and cover multi-level save/load and revisits.
Choose the initial finite depth and difficulty curve when detailing this slice.

## 15. Broader world simulation — LATER

Settlements, changing world state, time, weather, and other simulation systems
will be split further when their first concrete gameplay requirement is known.
The first settlement slice restores NPCs and deterministic dialogue removed in
14a, including interaction, presentation, persistence, and end-to-end coverage.
It does not depend on LLM integration.

## 16. Multiplayer behavior — LATER

Multiple simultaneous players require separate authority, visibility,
conflict-resolution, lifecycle, and persistence decisions. The current
single-player client-server model does not imply those rules.

## 17. LLM integration — LATER

LLM integration is explicitly postponed. Its authority boundaries, failure
behavior, cost controls, and effect on deterministic game rules will be
designed separately before implementation begins.
