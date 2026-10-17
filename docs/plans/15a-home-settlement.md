# 15a: home settlement and Mara

Status: planned on 2026-10-17. No 15a changes are implemented.
14c is accepted and merged; this is the first slice of stage 15.

Work belongs to `codex/15a-home-settlement`. Implement the checkpoints in
order. Each checkpoint must leave an executable, tested workspace. After each
checkpoint, update this plan and the roadmap with the completed work, the actual
commands and results, and the next open step. Ask before changing the decisions
below or reordering checkpoints. Commit or push only when requested. Delete this
plan after the user explicitly accepts 15a; keep its lasting contracts in the
permanent documentation.

## Goal and fixed scope

Every world gets one **home settlement** a short walk from the spawn. The player
enters it through a **settlement gate** on the outdoor map and walks its square
in the first-person view. Mara, the old adventurer, lives there again. Talking
to her opens the deterministic dialogue that 14a removed: she remembers whether
she has met the player, answers questions about herself, the nearby dungeon and
the Ancient coin, and tends the player's wounds for free.

Success means a player can walk from the spawn to the gate, enter, talk to Mara,
get healed, leave through the gate, and find the same greeting state after an
explicit save, server restart, and Continue. Dialogue never leaks into saves,
and the client never decides which choices exist.

Outside this slice: further settlements (15c), quests (15b), trade and prices
(15d), time and resting (15e), moving NPCs, schedules, building interiors,
free-text input, scripting, and LLM involvement (stage 16).

## Decisions

### Settlement site and gate

- The **settlement gate** is a new outdoor terrain feature with map code `s`.
  It is walkable, like an entrance, and appears on the map once discovered.
- The gate lies exactly **six** traversable cardinal steps from the spawn,
  found by the same deterministic search that places the spawn entrance at three
  steps, with the spawn entrance, its neighbors, and all ordinary entrance sites
  excluded. A world without such a field fails creation, like a world without a
  spawn entrance.
- The world metadata stores the gate position as `settlement_gate`, validated
  on load exactly like `spawn_entrance`. This changes the metadata schema and
  chunk content: **world format 3 → 4** and **generator 8 → 9**. Existing worlds
  stay untouched and are listed as incompatible.

### Settlement area

- The area identity is `<world>:settlement:home`. Its kind is the existing
  `AreaKind.Settlement`; it uses the first-person view family. 15c will add
  region-based identities next to `home`.
- The layout is **authored**, not generated: one fixed 23 by 15 map in game code
  named `Hearthmoor`, with an outer wall, a few house blocks as walls, an open
  square, and the gate field `x` on the south wall row's inner side. The start is
  one field north of the gate, facing north. The map is validated by the
  existing interior map validation (depth 1, level 0) at startup in tests and
  never stored as a world file.
- The return location of a settlement state is the outdoor gate site. Leaving
  through the gate returns there. Entering and leaving are free actions.
- The settlement contains no opponents and no floor items. Dropping items there
  is rejected in 15a; it needs no mutable item storage.
- Entering marks the settlement visited (`VisitedAreas`) so its discovery can be
  saved. Save validation resolves the settlement map from code, never from a
  file, and rejects settlement identities other than `home`.

### Mara and her dialogue

- `Dungeon.Npcs` owns NPC kinds, identities, and records. Mara has identity
  `<world>:settlement:home:npc:mara`, a fixed position inside the square, and
  blocks her field. She never moves.
- The NPC record is `{ id, kind, area_id, has_met_player }`. A new game contains
  Mara's record with `has_met_player = false`; it changes when the first
  dialogue starts and is saved only by an explicit save.
- `Enter` starts the dialogue only while Mara stands directly ahead. A dialogue
  frame contains the NPC identity, speaker name, text, and at most six ordered
  choices with stable IDs:

  | Choice ID | Text | Available | Effect |
  | --- | --- | --- | --- |
  | `identity` | Who are you? | always | text only |
  | `dungeon` | What lies beneath the hills? | always | names the spawn dungeon and its depth |
  | `coin` | What do you know about this coin? | an Ancient coin is carried | text only; the coin is unchanged |
  | `wounds` | Could you tend my wounds? | health below maximum | restores full health |
  | `goodbye` | Goodbye. | always | ends the dialogue |

- The first greeting differs from the repeat greeting. The `dungeon` answer
  uses the spawn dungeon's generated name and `DungeonDepth`, so it is correct
  before the dungeon is first visited, without reading or creating level files.
- `Dungeon.Dialogue` owns the typed graph as ordinary Functional Pascal data and
  functions: start, choose, and end. Choosing a choice that is not in the current
  authoritative frame is rejected.
- While a dialogue is active, the server accepts only a dialogue choice, an
  explicit end, a viewport update, or disconnect; everything else receives
  `dialogue_active`. Healing does not consume a turn. The active dialogue and the
  client selection live only in the connection and are never saved; reconnecting
  never resumes a conversation.

### Versions

All bumps happen once on this branch.

| Contract | From | To |
| --- | ---: | ---: |
| World format | 3 | 4 |
| World generator | 8 | 9 |
| Savegame format | 10 | 11 |
| Protocol | 16 | 17 |
| Level file format | 3 | 3 (unchanged) |

Obsolete worlds and saves are rejected and preserved, never migrated.

### Protocol and client

- Protocol 17 adds the outdoor map code `s`, the interior NPC code `n` (visible
  only on currently visible fields, never remembered), the intentions
  `dialogue_choice` and `end_dialogue`, and the server messages `dialogue` and
  `dialogue_ended`, with exact field sets and bounded IDs, texts, and choice
  counts.
- The first-person renderer draws Mara as an upright figure; the exploration map
  and outdoor map get distinct markers. The Environment panel shows
  `Mara — Enter: Talk` while she stands ahead and `Press Enter to enter
  Hearthmoor.` on the gate.
- The client opens a framed modal dialogue overlay: W/S or arrows select with
  wrap-around, Enter submits, Escape asks the server to end. Pending requests
  suppress repeated input; other overlays and movement are blocked until the
  dialogue ends. `Alt+X` still exits cleanly.
- The server dashboard shows `Hearthmoor` as the current area.

## Module ownership

- `Dungeon.Terrain.Placement` and `Dungeon.Terrain.Entrances` own the gate
  search and the gate feature; `Dungeon.Terrain` owns the metadata field.
- A new unit `Dungeon.Settlements` owns the settlement identity, the authored
  Hearthmoor map, and gate/return rules. `Dungeon.Movement` uses it for entry and
  exit next to dungeons; `Dungeon.Areas` resolves its map for area views.
- New units `Dungeon.Npcs` (records, placement, blocking, visibility) and
  `Dungeon.Dialogue` (graph and effects) in `libs/game`.
- `Dungeon.World.Savegame` gains an NPC codec unit; `Dungeon.World.Interiors`
  resolves the settlement map from code in `ReadVisitedLevels`.
- The server keeps the active dialogue in its session record; the client keeps
  only the projected frame and its selection.

No new project and no dependency from `libs/game` to `libs/world`.

## Checkpoints

### 01. Baseline

Run formatting checks, `fpas check` for all projects, and the complete suite on
the starting commit; record the counts here.

### 02. Settlement gate and world format 4

- Gate search, the `SettlementGate` feature and `s` code, metadata field
  `settlement_gate`, world format 4, generator 9.
- Fingerprints: deliberately update the outdoor chunk fingerprints that contain
  a gate; prove that every other chunk and every dungeon fingerprint stays equal.
- Tests: six-step distance and reachability for several seeds; exclusion of the
  spawn entrance and entrance sites; metadata round trip; rejection of a wrong,
  missing or moved gate and of world format 3.

### 03. Authored settlement and transitions

- `Dungeon.Settlements` with the Hearthmoor map, identity, and area view
  resolution; entry from the gate and exit through `x` in `Dungeon.Movement`,
  including the occupied-arrival rule from 14c.
- Validation of settlement states: return location equals the gate, settlement
  visited, no dungeon-only rules applied.
- Tests: map validation, enter/leave round trip with exact poses, rejected entry
  away from the gate, rejected foreign settlement identities, drops rejected,
  interaction targets from inside and outside.

### 04. NPC records

- `Dungeon.Npcs`: Mara's record in new games, blocking, current-visibility-only
  projection, and validation (unique, known kind, own area, fixed position).
- Tests: blocking steps, no NPC under the player, hidden from remembered fields,
  invalid and duplicate records.

### 05. Dialogue rules

- `Dungeon.Dialogue`: start only with Mara ahead, first and repeat greetings,
  conditional `coin` and `wounds`, the `dungeon` answer without level access,
  healing without a turn, goodbye, rejection of unavailable choices, at most six
  choices.
- Tests for every choice, every availability condition, unchanged dice and
  items, and `has_met_player` changing exactly once.

### 06. Savegame format 11

- NPC codec and settlement visits; the settlement map is resolved from code
  during save validation.
- Tests: round trip, missing/duplicate/unknown/extra NPC data, foreign
  settlement identities, format 10 rejected and preserved, Start over resetting
  the met flag, no dialogue in saves.

### 07. Protocol 17

- New codes, intentions, and messages with strict validation.
- Tests: round trips, bounds, unknown and duplicate choice IDs, exact field sets,
  `n` never in remembered rows.

### 08. Server session

- Gate and settlement transitions through the existing transition ordering;
  dialogue start, choice, end, gating with `dialogue_active`, disconnect without
  persistence, dashboard area name, Environment hints.
- Tests through the network adapter, including failure paths and reconnect.

### 09. Client

- Outdoor and map markers, Mara's sprite, dialogue overlay and input gating,
  hints.
- Headless TUI tests for the overlay, selection wrap, Escape, pending requests,
  narrow terminals, and the sprite and markers.

### 10. Complete TCP play and documentation

- One TCP session walks from the spawn to the gate, talks to Mara, is healed
  after taking damage in the dungeon, leaves, saves, restarts the server,
  continues, and sees the repeat greeting.
- Restore an architecture document for NPCs and dialogue, add the terms
  settlement, settlement gate, home settlement, NPC, and dialogue to
  [world and views](../product/world-and-views.md), and synchronize the other
  architecture, UI and roadmap documentation.
- Formatting, all project checks, and the complete suite with
  `fpas test --timeout 600 dungeon.fpasworkspace`.

### 11. Acceptance

Review the finished slice with the user in the running game. Mark 15a done and
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
