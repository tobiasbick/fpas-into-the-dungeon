# 15c: Generated settlements

Status: **implementation complete; ready for user acceptance** on 2026-10-18. Planning date: 2026-10-18.
Branch: `codex/15c-generated-settlements`, based on accepted and published 15b
(`f89a545`). The user confirmed Q1-Q3 and subsequently requested implementation
in the checkpoint order below. On 2026-10-18 the user authorized committing and
pushing this feature branch before acceptance. User acceptance and merging remain pending.

## Goal and acceptance

Explore beyond Hearthmoor, find additional named villages, enter their map
areas, meet distinct residents, guards and healers, and return to the same
places and remembered NPCs after explicit Save, listener restart and Continue.
Generation and all gameplay remain deterministic and server-owned.

Acceptance uses ordinary client intentions over TCP, not direct state edits:
visit two generated villages in a fixed test world, meet their NPCs, receive
healing while hurt, leave through the exact source gates, Save, restart and
Continue both outdoors and inside a generated village. Names, layouts,
placements, discovery and independent meeting flags must survive. Return to
Hearthmoor and verify Mara's existing quest and remembered outcome still work.

The 15b baseline has world metadata 4, generator 10, dungeon level format 4,
savegame 12 and protocol 18. Its recorded verification on 2026-10-17 is all 21
project checks and 154/154 test programs. A planning-only rerun of the complete
suite on 2026-10-18 also passes 154/154 programs. These checks cover the unchanged
15b code, not an implementation of 15c. Recheck the matching compiler and standard
library before implementation. Some older documentation, including the version
table in `docs/architecture/runtime-data.md`, predates this baseline.

## Confirmed product decisions

- Q1: Occasional small villages, approximately 23 by 15 through 31 by 21 fields.
- Q2: Residents, guards and healers with fixed deterministic dialogue. A healer
  restores health without payment. Trade belongs to 15d.
- Q3: Houses stay closed in 15c. Entered building interiors retain the agreed
  first-person view family, but their implementation needs a separate plan.

Hearthmoor remains the authored home settlement, with its current gate,
geometry, Mara, free healing and single compass quest. Generated villages
extend this model; they do not replace Mara or duplicate her quest.

Excluded: trading, currency changes, inns/resting, building interiors, NPC
movement/schedules, additional quests, reputation, world time, weather, LLMs,
multiplayer and runtime settings for settlement density.

## Initial technical choices

These choices make the plan concrete; they are not measured gameplay results.
Freeze their exact vectors in checkpoint 01. Later changes to this contract or
checkpoint order require a discussion before implementation deviates.

### Sites and identities

- A settlement region is one existing 128 by 128 outdoor chunk in this stage.
  It is independent of the configurable dungeon entrance-region size.
  Eligibility and candidate order do not resize with that setting; the accepted
  site may differ when exclusion checks encounter different actual dungeon sites.
- A private seeded hash makes one third of settlement regions eligible.
  Eligibility does not guarantee a village: inspect at most 16 seeded candidate
  fields and use the first valid one, otherwise the region has no village.
- Candidates stay at least 16 fields inside the region border. This separates
  generated gates by at least 32 fields across adjacent regions. Require a
  Manhattan distance of at least 32 from spawn and Hearthmoor's gate too.
- A gate needs clear walkable land without water, at least one walkable cardinal
  approach, and no dungeon entrance on the candidate or its cardinal neighbors.
  Keep Hearthmoor and the three-step spawn entrance unchanged. Add no roads,
  terrain clearing or global reachability promise across arbitrary wilderness.
- Use independent domain seeds for eligibility, candidate order, layout, names
  and NPC placement, based on world seed and signed region/slot coordinates.
  Allocated world-ID text is an identity prefix, not extra generation entropy.
  Never consume combat dice or depend on visit, cache or chunk generation order.
  Bound work per touched region; chunk generation computes its site once rather
  than repeating all candidate searches for every field.
- Canonical area IDs are `<world>:settlement:<sx>:<sy>`; the existing home ID
  stays `<world>:settlement:home`. Signed coordinates use canonical integers,
  including across negative chunk borders. Reject foreign IDs, extra segments,
  alternate number spellings and coordinates whose world arithmetic overflows.
- Resolve the outdoor gate back to its region through the same pure site rule.
  Chunk markers and single-cell generation must agree exactly. Looking at a
  marker or refreshing a viewport creates no settlement file or mutable NPC.

There is no guarantee of an additional village beside spawn. Before acceptance,
record a reproducible seed and ordinary outdoor route to two villages so the
manual review does not depend on searching unexplored terrain.

### Village definitions and layouts

- A generated village chooses one of three map sizes: 23 by 15, 27 by 19 or
  31 by 21. It contains a bounded plaza, connected walks, closed house blocks,
  one exit field and a walkable player start beside it. It has no floor items
  or opponents.
- Reuse bounded settlement coordinates and the map view. Settlement steps do
  not heal, consume combat dice or run an opponent phase. Existing outdoor-step
  healing and dungeon rules remain as they are.
- Validate geometry and NPC placement together. Treat NPC fields as blocked
  when proving that the player can leave and reach every interaction position.
  Keep NPCs off the start and exit; give each a reachable cardinal talk field.
  Require at least four Manhattan fields between NPC positions so a player
  never has to select between two adjacent NPCs. The occupied exit has priority.
- Names are bounded printable ASCII, derived deterministically and then stored.
  Display names may repeat in different villages; identity never depends on a
  name. NPC names within one village must distinguish its three characters.
- Each definition has exactly three immutable NPC placements: slot 0 resident,
  slot 1 guard and slot 2 healer. IDs are `<area>:npc:<slot>`. Each placement
  holds its role, display name and local position. Mara retains her existing ID.
- Constructive generation uses bounded work and shared structural validators.
  An invalid generated definition is a reported generation failure; do not
  switch seeds, drop a required NPC or publish a partially valid village.

### Immutable world data and mutable saves

- Store generated village definitions at
  `worlds/<world-id>/settlements/<sx>_<sy>.json`. Hearthmoor still resolves from
  authored code and needs no new file.
- The new exact settlement format stores its own version, world/generator
  identity, original seed and entrance-region parameter, region/area identity,
  gate, display name, map dimensions and rows, start/exit, and all three immutable
  NPC placements. Validate the header against the selected world's metadata.
  Bound text to 64 KiB,
  names to the existing title/speaker limits, and dimensions to the three sizes.
  Static rows accept only wall, floor and the single exit; NPC markers are
  projections, not stored cells. Reject missing/unknown fields, roles, duplicate
  IDs, invalid text and geometry.
- A world-layer operation opens the definition only for a validated current
  entry target. Reuse an existing valid file. Only a missing, unvisited village
  may be generated, round-trip validated and atomically written. Existing
  unusable files and missing visited files are errors, never regeneration.
- Stored layouts, names and placements are authoritative on revisit and load.
  Validate structure, identities and site consistency without regenerating a
  second layout for comparison. Save/Continue never create definitions.
- A new game keeps Mara's existing initially unmet record. On first entry in
  that game, add exactly the three NPC records of that village, initially unmet.
  Files left by a previous game do not create mutable NPCs in unvisited areas.
- Save only NPC identity, role, area and meeting flag. Position/name belong to
  the immutable definition. Keep all NPC records in canonical identity order;
  look up Mara explicitly rather than relying on `Npcs[0]`.
- Full save validation resolves every visited generated village even when the
  player is outdoors or in a dungeon. Require its complete, matching NPC roster,
  valid discovery, and exact current position/return gate. Reject missing,
  duplicate, invented, wrong-role and foreign NPCs, including unmet records for
  unvisited generated villages. Mara is always present, initially unmet. Any
  met NPC, including Mara, requires its own settlement to have been visited.
- Continue restores the last explicit save. Start over resets generated NPC
  records, meeting flags and discovery, retains immutable definitions and the
  previous save, and recreates each visited roster on fresh entry.
- Distinguish missing, invalid, generation and I/O failures; preserve the save
  and installed session. A failed entry reply may leave a fully published
  immutable file, but must not install visits, NPC records, discovery, position,
  dirty state or changed cache facts. Keep prepare/send/install ordering.
- World administration continues deleting the complete world directory,
  including its settlement files, under the existing admission permit.

### NPC interaction and presentation

- Generalize reach, collision and visible markers to the selected NPC's
  immutable placement in the current settlement. Retain its exact identity in
  the active frame. An NPC from another village is never interchangeable.
- Residents explain themselves and their village; guards explain their role
  and local safety; healers explain their role and offer `wounds` only while
  health is below maximum. Healing restores full health, changes no inventory,
  XP or dice, and marks progress unsaved only when health changes.
- All three roles have `identity`, `settlement` and `goodbye` topics. The text
  varies by role and settlement. The healer additionally offers `wounds`.
  Add only the `settlement` choice ID to the wire vocabulary; keep Mara's topics,
  quest frames and existing payload limits. No dialogue reveals hidden geometry.
- First greeting marks only that NPC met and dirty. Repeated greetings remember
  that NPC, consume no turn, and do not dirty the game. Read-only answers do not
  change progress. Frames remain connection-local and are never serialized.
- Quest offer/report/preflight remain restricted to Mara's stable identity,
  current home settlement and current quest node. A healer cannot claim her
  reward or use her quest choices. Generic NPC lookup must not widen this rule.
- Reuse current dialogue gating and atomic replies. Forged/stale NPC IDs,
  inappropriate roles or choices, and unavailable healing leave state intact.
  Save still requires closing dialogue; disconnect and shutdown never autosave.
- Reuse `s` gates and visible-only `n` markers. Generated villages show the stored
  name and authoritative talk hint. Outside a generated gate, a generic entry
  hint suffices; do not read or generate layouts for every outdoor projection.
- Keep radius-eight settlement visibility, independent discovered-area masks,
  bounded map/exploration windows and unknown padding. Map and resize projection
  reuse retained validated area facts without outdoor chunk or settlement I/O.
- Remove exposed Mara-only UI/diagnostic assumptions, including the client's
  pending-dialogue label. The client renders projected names/text and never
  determines placement, role permissions, healing or completion.

## Ownership and compatibility

Keep the existing projects. Use focused modules behind small interfaces:

| Owner | Responsibility |
| --- | --- |
| `libs/game`, settlements | Canonical identities, pure sites, authored/generated definitions, generation and structural validation; split these concerns under `Dungeon.Settlements` rather than expanding its facade. |
| `libs/game`, NPCs/dialogue | Independent role/placement facts, mutable meeting records, lookup/reach/collision and deterministic role dialogue; keep Mara's quest-specific module. |
| `libs/game`, areas/state | Validated area facts, first-visit roster materialization and complete state validation. Supply NPC definitions with current geometry through a checked construction path; pure rules never load files. |
| `libs/world` | Focused `Dungeon.World.Settlements` loading/first-entry publication and exact encoding; integrate settlement definitions with visited-area/save validation. Reuse existing atomic file operations and common validators. |
| `apps/server` | Resolve entry through the world layer, retain current geometry and NPC definition facts together, prepare projections and atomically install accepted changes. |
| `libs/protocol`, `apps/client` | Strict new choice-ID vocabulary; reuse bounded DTOs, map/dialogue rendering and native input. |

Do not add a generic area plugin registry, arbitrary NPC scripting, a second
world catalog or new projects. Remove single-Mara assumptions only where this
feature needs general NPC behavior. Keep unrelated refactoring out of scope.

| Format | Planned version | Reason |
| --- | --- | --- |
| Generator | 10 to 11, once | Additional gates, village layouts, names and NPC placements change generated output. |
| Settlement file | New version 1 | Immutable generated village definition and NPC roster. |
| Savegame | 12 to 13, once | Expanded NPC kinds and canonical identities plus complete visited-settlement validation. |
| Protocol | 18 to 19, once | New `settlement` dialogue choice; both endpoints change together. |
| World metadata/chunks | Remain format 4 | No new metadata field or terrain code; the generator version rejects old worlds. |
| Dungeon level file | Remain format 4 | Its schema and original placement rules do not change. |
| Runtime configuration | Unchanged | Density and map sizes are versioned generation rules, not settings. |

No migration. Generator-10 worlds and format-12 saves remain preserved but
incompatible; create a new world. Raise each changed format once on this
feature branch. Update generator fingerprints deliberately with the added
content; never replace an expected value merely because a test fails.

## Ordered implementation checkpoints

Each checkpoint leaves the workspace functional and all new reachable states
saveable. Update constructors, codecs and callers in the same checkpoint when
their shared model changes. Ask before changing this order.

### 01. Freeze the contract and verify the baseline

- Record the already confirmed Q1-Q3, the site parameters, identities, three
  map sizes/roles, choice IDs and version table above. Freeze generation domain
  constants and fixed seed inputs for generation vectors. Derive acceptance
  routes after the generator exists in checkpoint 03.
- Verify matching FPAS/stdlib, formatting, all project checks and the complete
  baseline suite. Reproduce any compiler/runtime gap minimally and report it;
  obtain agreement before fixing FPAS or changing language/specification.

### 02. Generalize definitions while preserving Hearthmoor

- Introduce independent settlement identity/definition and NPC placement facts
  without a GameState dependency. Adapt current area facts and all callers so
  Mara's existing behavior uses explicit identity and placement lookup.
- Retain Hearthmoor's geometry, initial NPC and quest behavior. Add no generated
  gates to ordinary play yet. Verify home entry/return, collision, met flags,
  save/load, healing and the natural compass quest against the generalized path.

### 03. Implement pure sites and village generation

- Add bounded region eligibility/candidate selection, independent seeds, names,
  layouts and complete three-role rosters with shared validators. Select
  generator 11 once and update affected compatibility fixtures deliberately.
- Verify negative/border coordinates, region-size independence, site exclusion,
  size/name bounds, connected exit/talk routes with NPCs blocking, stable IDs,
  generation-order independence and literal generator vectors. Do not expose
  generated gates through production chunk composition yet.
- Find a reproducible seed and normal outdoor routes to two villages. Include
  a village close enough to a dungeon exit to arrive hurt despite outdoor-step
  healing; one-chunk dungeon entrance regions are an ordinary supported world
  parameter for this test. If no suitable route can be demonstrated, report it
  before proceeding rather than bypassing health or movement rules.

### 04. Persist definitions and complete mutable NPC state

- Add strict settlement format 1 with read and first-entry operations. Extend
  visited-area loading and current-area facts to carry validated definitions.
- Add multiple-role NPC materialization, complete validation and exact save
  codec support together under savegame 13. Keep state saveable throughout.
- Test immutable bytes across revisit/load, existing unvisited files, missing
  visited files, malformed definitions, bad rosters and save versions, Start
  over, I/O failures and saves made while outdoors. No client-visible new gate yet.

### 05. Generalize dialogue and both wire endpoints

- Add resident/guard/healer frames, independent greetings and conditional free
  healing. Retain exact selected NPC authority and Mara-only quest eligibility.
- Apply protocol 19 and the `settlement` topic to server/client together. Reuse
  DTOs and input; replace Mara-only waiting text and dynamic area diagnostics.
- Verify wrong/stale NPCs, cross-village IDs, role-specific choices, repeated
  healing, unchanged dice/items/XP, active-dialogue gating and failed reply
  preparation/write behavior. Keep the existing Mara route green.

### 06. Connect generated gates, entry and map presentation

- Compose settlement markers consistently in chunks and single-cell generation;
  use one site computation per region and update affected chunk fingerprints
  deliberately with these markers. Route Enter to the world-layer opener,
  materialize a roster once and return to that village's exact outdoor gate.
- Retain current geometry/NPC facts across viewport refreshes. Project stored
  names and visible NPCs through the primary map, exploration map, hints and
  dashboard, without opening outdoor chunks inside a settlement.
- Verify entry/exit on negative chunk borders, separate discovery, multiple
  visits, names shared by different IDs, native dialogue/resize behavior and
  rejected candidates preserving the complete installed session.

### 07. Prove strict storage and failure semantics

- Exercise missing/corrupt current and off-screen visited village files, partial
  or forged NPC rosters, impossible positions/returns, old generator/save/wire
  versions and absent/duplicate definitions. Rejections preserve existing saves.
- Prove no generation on catalog/viewport/save/load, no mutable NPC creation for
  merely stored unvisited villages, and retained file bytes through Start over.
- Keep whole-world administration compatible with the new settlement directory;
  extend its existing deletion fixture rather than duplicating the permit tests.

### 08. Verify the natural multi-village play loop

- Use real TCP movement/interaction to visit two generated villages, meet
  distinct roles and demonstrate healing while hurt, respecting outdoor-step
  healing when choosing the damage/return route. Reuse existing route helpers;
  do not add teleport, damage or test-only production controls.
- Save/restart/Continue inside a generated village and later outdoors; verify
  position, exact return gate, names/placements, discovery, meeting memories,
  health and all immutable bytes. Start over resets mutable memories only.
- Verify Hearthmoor and Mara's quest after visiting generated NPCs; a non-Mara
  identity cannot accept/report it. Use distinct rule/storage/transport tests
  for their own observable contracts, not repeated copies of one play script.

### 09. Document, verify and prepare acceptance

- Update canonical terms in `docs/product/world-and-views.md`, ownership and
  runtime data layout, NPC/dialogue and persistence contracts, client/server
  guides, README and roadmap. Correct stale version tables against the code.
- Check purpose/public interface comments, format changed sources, check every
  affected project and run the complete workspace suite with matching stdlib:

  ```powershell
  fpas fmt --check apps libs tests tools
  fpas check --std-lib ../functional-pascal/lib dungeon.fpasworkspace
  fpas test --std-lib ../functional-pascal/lib --timeout 600 --jobs 4 dungeon.fpasworkspace
  ```

- Run long commands in the background; report failures and their output. Present
  the fixed seed, outdoor routes and running-client review instructions. Keep
  acceptance pending until the complete suite and user review pass.
- Commit, merge and push only on request. Delete this plan after the user
  accepts 15c; retain the lasting contracts in architecture/product documents.

## Progress

- Product decisions Q1-Q3: confirmed on 2026-10-18.
- 01: Complete. Current FPAS/stdlib checks all 21 projects; the unchanged baseline
  suite passed 154/154 during planning. The newer structural formatter required
  whitespace-only changes in 47 files, applied before functional edits. Domain
  salts are reserved as 1601 (eligibility), 1607/1609 (candidate X/Y), 1613
  (layout), 1619 (names) and 1621 (NPCs). Fixed vector seeds: -1, 1 and 12345.
- 02: Complete. Immutable NPC placements travel with existing map placements;
  explicit Mara lookup replaces positional assumptions. All 21 project checks
  and seven existing home/NPC/save/natural TCP quest programs pass.
- 03: Complete. Generator 11 has pure sites/layouts/names, four literal layout
  vectors and NPC-blocked reach validation. Four focused programs pass. A bounded
  development probe found seed 25 with one-chunk dungeon regions: village
  (85,-83), gate (10951,-10539),
  adjacent dungeon (85,-83), entrance (10955,-10539), four outdoor steps away;
  a second village is (87,-85), gate (11238,-10820). Ordinary routes from spawn
  to the first village and onwards have 476 and 568 steps. The probe is retained
  only as ignored development data, not a permanent test program.
- 04: Complete. Shared typed area failures, strict settlement format 1, savegame
  13 and complete canonical rosters persist two villages independently. All 21
  project checks, six focused programs and seven integration programs pass;
  the two-village missing-entry fixture was corrected to use its actual gate.
- 05: Complete. Protocol 19 and role-specific dialogue pass six focused programs,
  handshake compatibility and the extended atomic-reply program. All 21 project
  checks pass. Generic quest choices cannot start Mara's world preflight.
- 06: Complete. Generated gates and strict chunk decoding share the site rule.
  The fingerprint deliberately adds the gate at (-1369,-3531). Existing home
  travel, new atomic village entry and retained-map projection programs pass.
- 07: Complete. Four storage/administration/transition programs pass with malformed
  headers, geometry, placements and complete-roster negatives; deleting an obsolete
  world removes its settlement directory and preserves siblings.
- 08: Complete. Natural TCP injury/healing and two-village travel pass across
  four listener lifetimes, including inside/outdoor Continue and Start over.
  The full compass quest passes after two generated-village visits. Navigation
  helpers select actual free talk neighbors and sample complete chunks once.
  The quest fixture uses connected regions (120,-45) and (116,-45), with a
  demonstrated 612-step route; the separate seed-25 acceptance routes remain fixed.
- 09: Complete. Documentation, formatting and all 21 project checks pass. Final review
  reproduced and fixed an exit-only talk-position validation gap; its negative
  control fails before the fix, and three focused programs pass afterward.
  The first full run had 158/159 passes: the existing empty-dungeon-area negative
  exposed a lost structural check in AreaViewFor. It is reproduced and restored;
  all four focused area/generation/dialogue/storage programs pass. The complete
  suite on the final stable source state passes **159/159 programs**. Permanent
  architecture/product documentation and the seed-25 running-client review
  route are ready. The user authorized commit and push before acceptance;
  this plan stays on the feature branch until user acceptance. Merging remains pending.
- 2026-10-24: The [DAP gameplay acceptance](../acceptance/generated-settlements-dap.md)
  passes with seed 25 and one-chunk regions through real client key events:
  two villages, injury/healing, inside/outdoor Continue, fresh meetings after
  Start over without replacing the save, and Mara's complete compass quest
  across active, ready and completed restarts. The full suite passes 161/161.
  Server-console presentation has automated coverage but was not visually
  reviewed in this headless server run. User acceptance and merging remain pending.
