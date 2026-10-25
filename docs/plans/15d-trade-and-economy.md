# 15d: Trade and economy

Status: **implementation complete; awaiting user acceptance**.
Planning date: 2026-10-24. Branch: `codex/15d-trade-and-economy`.
Base: accepted 15c on `main`, commit `1d1dad9`.
The user authorized implementation in checkpoint order on 2026-10-24.
Keep the confirmed contract below; record implementation evidence at the end.

## Goal and acceptance

Enter Hearthmoor or a generated village, speak to its merchant, sell ordinary
loot for coins and buy individual goods. Each merchant retains an independent,
finite stock. Save, restart and Continue restore the exact balance and item
owners. Start over resets the economy without replacing the previous save or
rewriting immutable village and dungeon definitions.

The server owns prices, availability, ownership, capacity and every transfer.
The client displays quotes and sends intentions. Mara's compass quest, free
healing, equipment, ordinary loot and exploration continue to work.

## Confirmed product decisions

The user confirmed Q1-Q9 in this planning conversation on 2026-10-24.

| ID | Decision |
| --- | --- |
| Q1 | One merchant in Hearthmoor and one additional merchant in every generated village. |
| Q2 | A separate integer coin balance; Ancient coins remain physical collectibles sold to merchants. |
| Q3 | Finite initial goods; purchases remove goods and player sales add them. No automatic replenishment. |
| Q4 | Existing item kinds only; no better weapons or armor in 15d. The compass is excluded from trade. |
| Q5 | Merchants have unlimited purchase funds; there is no merchant purse or insufficient-merchant-money rule. |
| Q6 | Equipped items must be removed manually before selling. Trading never unequips automatically. |
| Q7 | Start with zero coins; each merchant initially owns three potions, one sword and one jerkin. All merchants use the price table below. |
| Q8 | A merchant holds at most 64 individual items, including purchased player loot. A sale into a full stock is rejected atomically. |
| Q9 | A dedicated trade window has Buy/Sell sides. Tab switches sides, arrows select, Enter performs one transaction immediately, Escape returns to dialogue. No extra confirmation per transaction. |

Prices are from the player's perspective and use whole coins:

| Item | Player buys for | Player sells for | Initial units per merchant |
| --- | ---: | ---: | ---: |
| Ancient coin | 20 | 10 | 0 |
| Healing potion | 8 | 3 | 3 |
| Rusty short sword | 12 | 5 | 1 |
| Leather jerkin | 12 | 5 | 1 |
| Mara's compass | unavailable | unavailable | 0 |

An Ancient coin sold by the player becomes an ordinary stock item and can be
bought back for 20. Sale prices stay below purchase prices at every merchant;
moving an item between merchants or repeatedly buying it back cannot create money.

Excluded: stacking, bulk quantities, baskets, bargaining, regional prices,
restocking, new loot kinds, merchant purses, interest, credit, reputation,
building interiors, world time, settings for economic rules, LLMs and multiplayer.
Later time/rest work must explicitly define any future replenishment rule.

## Verified baseline and existing interfaces

- The accepted code has generator 11, settlement format 1, savegame 13 and
  protocol 19. World/chunk and dungeon level formats are 4.
- The latest complete workspace run passes 161/161 test programs. This is the
  15c baseline, not a new run performed for this documentation-only change.
- [`Dungeon.Items`](../../libs/game/src/Dungeon/Items.fpas) gives every item one
  stable ID and one location: dungeon floor, carried, equipped, consumed or
  returned to Mara. It has no currency or merchant ownership.
- [`Dungeon.GameState`](../../libs/game/src/Dungeon/GameState.fpas) retains all
  mutable items. Carried and worn items together have a limit of 64.
- [`Dungeon.Areas.Validation`](../../libs/game/src/Dungeon/Areas/Validation.fpas)
  currently expects exactly the visited maps' original item placements, plus
  two quest reward records after hand-in. Adding shop items requires extending
  this origin proof, not merely relaxing the count or accepting arbitrary IDs.
- [`Dungeon.Npcs`](../../libs/game/src/Dungeon/Npcs.fpas) initially retains Mara
  and adds three complete NPC records per visited generated village. Home-map
  validation currently permits only Mara. Both rules must change together.
- [`Dungeon.Server.Replies`](../../apps/server/src/Dungeon/Server/Replies.fpas)
  already prepares bounded responses before sending and installing candidates.
  [`ServerSession`](../../apps/server/src/Dungeon/Server/Session.fpas) retains
  one connection-local dialogue; dialogue blocks other gameplay and saving.
- See the permanent [item](../architecture/items-and-inventory.md),
  [settlement](../architecture/generated-settlements.md),
  [dialogue](../architecture/npcs-and-dialogue.md),
  [quest](../architecture/quests.md) and
  [save](../architecture/persistent-game-state.md) contracts. Some historical
  paragraphs describe older format numbers; current source constants govern.

## Planned model and invariants

### Currency and item ownership

- Add `Coins` to `GameState`, initially 0. Use integer arithmetic only, with a
  planned storage/wire bound of 0 through 1,000,000,000. Reject negative,
  fractional, out-of-range and overflowing balances; never clamp or wrap.
- The balance occupies no inventory slot. The Ancient coin remains the same
  item kind, including Mara's carried-coin information topic.
- Extend `ItemLocation` with `HeldByMerchant(MerchantId)`. Store that location
  exactly as `{kind:"merchant",npc_id:"..."}`. It contains no duplicate area,
  position, price, player owner or equipment slot.
- Keep one `GameState.Items` array as the ownership ledger. Merchant stock is
  derived from those locations. Do not add a second mutable stock inventory,
  duplicate item records, sold tombstones or a separate shop save file.
- Transfer an existing record by changing its location. Buying back retains
  the original ID, whether its origin was a dungeon, merchant or quest reward.
  Two items with the same displayed name remain distinct throughout trade.
- Merchant-owned goods use neither player capacity nor floor fields and have
  no visible dungeon marker. Existing pickup, drop, equip, use and projection
  code must explicitly handle the new location without treating it as carried.
- Every location still matches one valid origin. The compass may never have
  merchant ownership. Consumed and returned records cannot be traded.
- Quest reward potions can be sold and bought back. Reward validation still
  requires both original reward IDs and the completed quest; selling a reward
  changes neither the quest nor its once-only reward entitlement.

### Merchant identity, generation and initial goods

- Add the stationary `Merchant` role. Generated slots 0/1/2 retain resident,
  guard and healer; slot 3 is merchant, with ID `<area>:npc:3`.
- Extend the existing constructive placement formula to slot 3: X is center
  plus 10, Y uses the existing slot-specific seeded offset. Preserve the site,
  map sizes, house geometry and slots 0..2. Prove all four NPCs leave the exit
  and ordinary talk positions reachable and remain at least four fields apart.
- Add the disjoint merchant name set `Darin`, `Esme`, `Finn`, `Vera`, selected
  with the existing slot-indexed hash. Names are labels, never identities.
  Freeze vectors for all three sizes and negative region coordinates.
- Hearthmoor gains `Elias` at local (6,7), ID `<home-area>:npc:merchant`.
  Mara stays at (11,7); start, exit, house geometry and quest identity stay fixed.
- A new game retains only the existing unmet Mara exception before visiting
  home. First home entry adds its merchant; generated entry adds all four roles.
  Records remain canonically sorted. Met NPCs require their own area visit.
- On first settlement entry, materialize five goods once, alongside its roster:
  slots 0/1/2 Healing potion, slot 3 sword, slot 4 jerkin. IDs are
  `<merchant-id>:stock:<slot>`; initial location is that merchant.
- This fixed catalogue is a versioned rule, not a second mutable definition.
  It needs no stock field in `InteriorMap.Items`: settlements retain no floor
  loot. Maps supply merchant placements; catalogue rules supply initial origins.
- Revisits, quotes, resizing, catalog inspection and load never refill stock.
  Seeing a village gate creates neither merchant state nor goods.

### Pure trading rules

- A transaction moves one individual item and adjusts the balance once. No
  quantity, price, discount, replacement balance or replacement state comes
  from the client. Prices are uniform constants from one game-owned table.
- Require a living active game in the merchant's settlement, cardinal reach,
  that exact validated merchant placement and its materialized NPC record.
  Conversation/quote authority additionally belongs to the server session.
- Buying requires the selected item to be held by this merchant, enough coins
  and fewer than 64 carried/worn items. Success subtracts its purchase price
  and sets `CarriedByPlayer`.
- Selling requires a carried tradable item, fewer than 64 items at the merchant
  and a balance that can accept the proceeds. Success adds its sale price and
  sets `HeldByMerchant` for that merchant. Worn items stay worn on rejection.
- A rejection preserves the complete state, including all other merchants,
  item order, health, equipment, quest, visits, discovery, progression and dice.
- Opening, reading, paging and closing trade consume no turn, XP, combat phase
  or random draw. Successful transfers change only ownership and coins and
  mark progress unsaved. First greetings retain their existing meeting behavior.
- A new pure rule validates the selected transfer; map loading and filesystem
  work stay outside it. Quote construction scans items once, selects the two
  bounded owner lists and sorts by ID; it does not scan all items per row.

### Full save validation and rewind

- Preserve all dungeon placement and quest checks. Full expected item count is
  original visited dungeon items, plus two rewarded quest items when applicable,
  plus five initial goods for every merchant in a visited settlement.
- Each item must match exactly one origin ID and original kind. Reject unknown
  stock slots, duplicate/missing goods, premature goods from an unvisited area,
  forged kinds and a stock-origin compass. Terminal potions retain origin checks.
- Distinguish origin from current owner: an item from merchant A can be carried,
  consumed if a potion, dropped on valid visited dungeon floor, or held by B.
  Resolve the definitions for every visited area, including off-screen owners.
- Every merchant destination must be the exact Merchant placement and NPC
  record of a visited settlement. Reject wrong-role, missing and foreign owners,
  more than 64 stock items, and inconsistent home/generated rosters.
- Keep map-free shape decoding separate from full supplied-map validation.
  Neither phase generates or repairs missing definitions. Save and Continue
  validate the same ownership proof before installing state or replacing a file.
- Persist the coin balance and complete item ledger in the one explicit save.
  Quotes, selections, pages and interaction revisions are connection-local.
- Continue restores its snapshot, including sold-out stocks and cross-merchant
  transfers. Restoring an earlier save rewinds both money and every item owner.
  A later-created village file does not import another game's stock.
- Start over returns to zero coins and no merchant goods before settlement
  entry. Entry then materializes a fresh catalogue once. Keep immutable files
  and the previous save unchanged until explicitly confirmed replacement.

## Server interaction and atomic responses

Use one optional `ActiveInteraction` with mutually exclusive Dialogue and Trade
payloads in the server session. Replace the old dialogue-only field at the same
checkpoint as its callers; do not maintain two independently active windows.

A merchant's root topics are `identity`, `settlement`, `trade`, `goodbye`.
Selecting `trade` opens a quote for that exact NPC. It must be a current offered
choice, not a way to open trade from Mara or a forged NPC/old dialogue frame.
Escape sends `end_trade`, returning to that merchant's root conversation. A
second Escape ends dialogue through the existing acknowledgement. No auto-save.

While trading, permit only buy/sell, trade paging/refresh, end trade, viewport
and disconnect. Reject movement, attack, items, journal/map requests and saving
through the same interaction gating used for dialogue. Closing trade does not
remove already committed transfers; disconnect discards unsaved progress only
when the later Continue restores the explicit save.

Each quote carries a positive connection-local revision. A monotonic counter
survives closing/reopening trade and changing worlds in the same connection.
Use a planned maximum of 1,000,000,000; exhaustion rejects without changing game
state. A new connection has a fresh counter and its existing new request queue.

Buy/sell requests must match the current merchant, revision, side and an item
on that quoted page. Recheck actual ownership, funds and capacity at execution.
Every accepted transfer or page/refresh response publishes a new revision.
Read-only viewport responses preserve the interaction and its current revision.
An old buy/sell request fails after a trade or after closing/reopening, even for the
same NPC. Repeated requests cannot perform the same transfer twice.

1. Validate lifecycle, interaction and request identity against the installed session.
2. Build a pure candidate transfer, or retain game state for page/end operations.
3. Prepare its complete visible state, refreshed quote/dialogue and bounded text.
4. Encode and check the complete UTF-8 line, including the 65,536-byte limit.
5. Send successfully, then install state, frame, revision, dirty flag and cache.

Any rule, projection, quote or encoding failure returns `trade_rejected` and
keeps the original session, old quote/counter, balance, item ledger, retained
map, cache/LRU facts and last-save timestamp. Absent trade uses `trade_not_active`;
other gameplay while trading uses `trade_active`; inactive games keep
`session_not_started`. A failed write remains fatal without installing a candidate.
This is the established game reply contract, not an exactly-once network protocol.
Trades never write a save as part of this response sequence.

## Wire and client presentation

- Add required integer `coins` to both visible-state families. The trade window,
  inventory and context render that projection; money is never a fake inventory row.
- Extend `dialogue_choice` with the `trade` topic; it remains the opening intention.
- New exact requests: `trade_buy`/`trade_sell` with `npc_id`, `item_id`, `revision`;
  `trade_page` with `npc_id`, `side` and `page`; `end_trade` with `npc_id`.
  Every request also has `type`; unexpected fields are rejected. Page is read-only
  and can refresh the current page without an old revision. The NPC must still
  match the active trade. Negative/out-of-range pages reject without mutation.
- Add a `trade` response containing visible state, dirty flag and quote. End
  trade returns the existing `dialogue` response with a refreshed merchant root.
  Do not add redundant response types for the same transition.
- Quote fields: `npc_id`, `speaker`, `revision`, `merchant_capacity`,
  `buy_page`, `sell_page`, `buy_total`, `sell_total`, `buy_items`, `sell_items`.
  Each side contains at most 16 rows. Totals stay within 0..64; an empty side
  uses page 0. Clamp retained page indexes after a successful transfer.
- A row contains exactly `id`, `name`, nullable integer `price`, boolean
  `enabled`, and `reason`. Enabled rows have a positive price and empty reason;
  disabled rows explain the server-owned refusal. The compass has no price.
  Sell lists include worn and quest items as disabled rows; buy lists can show
  insufficient funds or player capacity without making the client infer rules.
- Reuse existing identity/text limits and printable-text rules; planned reason
  limit is 160 characters. Prices stay in 1..20, revision/coins in their bounds.
  Reject duplicates, contradictory capability fields, invalid page/count shapes
  and malformed state before the client can queue an action.
- Keep the line limit. Exercise 64 player items, 64 stock items, both 16-row
  pages, a largest village and maximum valid identities/text in budget tests.

The trade window keeps merchant name, coins, active Buy/Sell side, selection,
price, refusal reason and page controls visible. Tab switches sides; arrows
select; Page Up/Down request the adjacent stock/inventory page when available.
Enter sends exactly one enabled selected item with the displayed revision;
held/repeated input cannot enqueue another request while pending. Do not group
equal names or merge item identities. Keep a surviving selection by ID after a
response, otherwise clamp its previous index. Page changes reset to a valid row.

Planned actionable minimum is 40 columns by 12 rows. Below it, show a short
size hint and suppress buy/sell/page intentions; Escape and quitting remain
available. At usable sizes derive the visible row window from the actual height;
all 16 page entries must remain reachable by local scrolling. Resize preserves
side/selection, clamps the row window and never closes or submits trade. Reuse
the existing viewport-intent tagging so a viewport state cannot erase this modal.
Rejected requests retain the window and show the server's bounded reason.
Other overlays and gameplay shortcuts cannot steal input while it owns focus.

## Ownership and planned module interfaces

Keep the existing workspace projects and direction of dependencies. New module
names below are planned owners; keep files focused and normally below 500 lines.

| Owner | Responsibility and test interface |
| --- | --- |
| `libs/game`, `Dungeon.Trade.Model` and `.Items` | Independent catalogue, prices, coin bounds, merchant item identities and origin validation. No `GameState` dependency that would create a validation cycle. |
| `libs/game`, `Dungeon.Trade` | Small pure quote/buy/sell interface taking the validated view/state and exact IDs, returning a candidate or typed rule failure. Reuses NPC reach, item and equipment facts. |
| Existing `Items`, `GameState`, `Areas`, NPC/settlement modules | One ownership variant, coin state, one-time goods materialization and complete local/full-map proofs. Extend existing validators instead of a separate trade-only truth. |
| `libs/world`, settlement and save codecs | Current-only formats, exact coin/location decoding and the existing complete visited-area read. No shop file or hidden stock regeneration. |
| `apps/server`, `Dungeon.Server.Trade` | Connection-local authority, quote revisions, gating and mapping of pure outcomes. Integrate with the existing session/reply interfaces and shared preparation logic. |
| `libs/protocol` | Bounded exact DTOs and codecs shared by client/server. No item-price table or game trade rules duplicated here. |
| `apps/client`, focused trade model/view/input modules | Quote display, ID selection, local scrolling, page and keyboard intentions. No imports of game rules. |

Reuse `Replies` projection, rejection and send/install policy. Replace its
dialogue-specific response switch with explicit supported interaction outcomes
when needed; do not add a generic transaction framework, plugin registry or
forwarding layers. Full persistence validation stays at load/save trust points;
opening/paging trade uses retained facts and does not reload all visited maps.
Keep runtime contracts high in the call chain and scalar/bounded. Add no deep
whole-state `requires`/`ensures` traversal to every offer row or key event.

## Compatibility

Raise each affected version once, when its change first becomes reachable.

| Format | Accepted 15c | Planned 15d | Reason |
| --- | ---: | ---: | --- |
| Generator | 11 | 12 | Additional merchant placements and initial merchant goods change world content. |
| Settlement definition | 1 | 2 | Four generated NPC roles and the new Merchant role in the exact roster. |
| Savegame | 13 | 14 | Required coin balance, merchant item origins/locations and complete rosters. |
| Protocol | 19 | 20 | Required balance and bounded trading messages/quotes. |
| World metadata/chunks | 4 | 4 | Same schema; generator identity rejects obsolete worlds. |
| Dungeon levels | 4 | 4 | No new dungeon item kinds or placement schema. |
| Runtime/client settings | current | unchanged | Economic constants belong to versioned rules, not configuration. |

Preserve old worlds and saves, reject them clearly and use a new 15d world.
No migration, repair, mixed three/four-NPC fallback or silent regeneration.
Update fingerprints deliberately for changed merchant content. Preserve fixed
site/gate vectors and existing NPC identities; do not reroll routes to hide errors.

## Ordered implementation checkpoints

Each checkpoint leaves current reachable gameplay saveable. Do not expose the
`trade` choice until both server handling and client presentation are ready.
Record completed checks and findings here during a later authorized implementation.

### 01. Freeze the contract and verify the accepted baseline

- Confirm Q1-Q9, catalogue slots, names/placement, arithmetic and quote limits,
  DTO fields, format table and the no-replenishment/explicit-save lifecycle.
- Record the PATH `fpas` identity and matching distribution; verify formatting,
  all 21 project checks and the complete baseline. The recorded 161/161 result
  is advisory until rechecked at implementation start.
- Read current source before changing it. Freeze generation/name vectors and
  full-state comparison fixtures before adjusting their expected results.

### 02. Add currency, merchant ownership and complete origin support

- Introduce the independent catalogue/identity modules, `Coins`, merchant role
  and location, and map-free/full origin validation. Extend all exhaustive
  location consumers, quest reward checks, constructors and comparisons together.
- Move the save codec to 14 with required exact coin/location fields in the same
  checkpoint. Existing reachable games still have zero coins and no merchants
  until their definitions are connected; forged unsupported owners stay invalid.
- Test price directions, the 0/maximum bounds, canonical IDs and rejection of
  invented/duplicate/foreign/consumed/quest merchandise without weakening old checks.

### 03. Connect merchant definitions, entry and persistence

- Add the authored merchant and generated slot 3; change generator to 12 and
  settlement format to 2. Update complete roster validation, names, visibility,
  collision, reach and ordinary role dialogue together. Keep home exceptions explicit.
- Materialize exactly five goods once on first entry and preserve them on
  revisit. Existing settlement `Items` remain empty: these are owned shop goods.
- Prove all map sizes, negative regions, unchanged gates/old NPC identities,
  complete save/load while elsewhere, missing definitions and Start over.

### 04. Implement pure quotes and single-item transfers

- Implement current-merchant quotes and candidate buy/sell using existing reach
  and validated item facts. Gather counts/ownership once and sort bounded lists.
- Cover all prices, correct deltas, same-name distinct IDs, buyback, another
  merchant's item, worn gear, compass and reward potion behavior.
- At every refusal compare complete states: insufficient funds, both capacities,
  integer bounds, wrong world/NPC/area/reach, floor/consumed/returned items and replay.

### 05. Add exact wire contracts and authoritative session handling

- Move both endpoints to protocol 20, add projected coins and all strict trading
  DTOs/codecs. Update exhaustive dispatch, network and client event cases together.
- Replace the dialogue-only session field with one interaction variant. Implement
  quote revisions, read-only paging/refresh, close-to-dialogue and gating.
- Reuse bounded reply preparation/send/install and preserve original sessions
  on rejection; activate the merchant topic only with the usable client in 06.
- Test stale revisions across trade/page/reopen/world changes, duplicate requests,
  invalid DTOs, maximum wire payloads, preparation/encoding failures and failed writes.

### 06. Build and activate the client trade window

- Add the dedicated keyboard model/view/input, coin presentation and tagged
  network events, then enable the merchant `trade` choice on both ready endpoints.
- Verify Buy/Sell focus, 16-row pages, local scrolling, stable ID selection,
  disabled reasons, empty/full lists and one request while pending. No GUI-only prices.
- Exercise wide/narrow/too-small windows, viewport refresh during trade, resize
  while pending, rejection, Escape back to dialogue, end dialogue and disconnect.

### 07. Prove storage, rewind and cross-merchant ownership

- Round-trip dungeon-origin, shop-origin and rewarded potions in every valid
  location, including merchant A's item owned by B and consumed/dropped shop goods.
- Reject malformed balances, wrong item kinds/counts/slots, forged owner roles,
  off-screen missing definitions, unvisited origins/owners and old format versions.
- Verify old save bytes on validation/I/O failures, exact earlier-save rewind,
  unsaved disconnect and Start over. Preserve all immutable bytes and overwrite guards.

### 08. Exercise TCP authority and reply failure semantics

- Drive normal messages through the existing listener with prepared legal
  fixtures for capacity/overflow edges. Cover active-interaction and lifecycle
  precedence, stale pages/quotes, forged price/quantity fields and cross-world IDs.
- Reuse existing server-internal failure fixtures for complete candidate/session
  comparisons and fatal writes; add no production fault switches or public test hooks.
- Cover two merchants and exact balance/ownership after accepted, rejected and
  repeated requests. Confirm no XP, RNG, turn, healing or save side effects.

### 09. Verify natural play and the acceptance route

- Use real client intentions over TCP and then the FPAS DAP controller. Record
  the new-world seed/region, merchant names, exact item IDs, balances and stock counts.
- Follow the route below without money grants, teleporting, direct item edits or
  debugger assignment. Extend existing quest/village play coverage where it fits;
  do not duplicate a whole long quest script to prove the same contract twice.
- Confirm explicit save/restart/Continue inside/outside, independent merchants,
  same-ID buyback, reward sales, read-only resize, and the reset/old-save proof.

### 10. Document and prepare user acceptance

- Update canonical terms, items, NPC/dialogue, persistence, protocol, client UI,
  server console/diagnostics, versions, README and roadmap from the implemented state.
  Add a lasting economy contract and a concise actual-play acceptance report.
- Verify purpose/public-interface comments and use `fpas` from PATH. Run
  `fpas fmt --check apps libs tests tools`, `fpas check dungeon.fpasworkspace`
  and `fpas test --timeout 600 dungeon.fpasworkspace`; report the actual final count.
- Run long checks in the background. Investigate actual bottlenecks with
  `fpas run --profile` before adding benchmark variants; retain the existing
  debug-target profiling limitation when interpreting DAP controller measurements.
- Report and reproduce any FPAS gap; obtain agreement before language/runtime
  changes and record forced fallbacks in its dogfooding gaps. Rebuild with its
  distribution script and restart owned server/client processes after FPAS changes.
- Keep acceptance pending until the complete suite and running-game review pass.
  Commit/merge/push only on request; delete this plan after explicit 15d acceptance.

## Acceptance scenarios and evidence

Start a new generator-12 world, seed 25, dungeon region size 1. Verify that the
existing route to Fernhollow and Brackenford is still valid; gate generation is
not intentionally changed. Use the [15c route](../architecture/generated-settlements.md#reproducible-acceptance)
and existing FPAS route helpers rather than embedding a second navigation system.

1. At spawn, confirm zero coins. Visit Hearthmoor and meet Elias. Five goods
   appear only after entry. The buy side is readable but unavailable with no
   money; the empty sell side remains navigable. Closing a quote adds no dirty change.
2. Obtain the guaranteed Ancient coin, sword, jerkin and potion through normal
   spawn-dungeon exploration. Return to the merchant without altering state externally.
3. Sell the coin: balance 10, its ID belongs to Elias. Buy one initial potion:
   balance 2, that stock-origin ID is carried. Record stock and player capacities.
4. Sell the unworn dungeon sword and jerkin: balances 7 then 12. Buy back the
   exact sold sword for 12: balance 0 and its original ID is carried. Do not
   confuse it with the merchant's identically named initial sword.
5. Equip that sword normally. Its sell row is disabled. Close trade/dialogue,
   remove it through inventory and sell it: balance 5. Confirm
   Mara's compass remains unavailable whenever carried, irrespective of money.
6. Travel to Fernhollow. Its untouched merchant still has five independent goods.
   Sell the potion bought from Elias: the same home-origin ID now belongs to
   this village merchant, balance 8. Save inside, restart both processes and Continue.
   Verify exact coins, both affected owners/stocks, position and meeting memories.
7. Visit Brackenford and confirm another independent five-item initial stock.
   Buy one of its potions for 8, leaving balance 0, and save outdoors; restart and
   Continue, then revisit to prove it did not replenish or copy another stock.
8. Verify a purchased potion can be consumed while naturally injured in a
   dungeon, or dropped/picked up under existing rules, with its stock-origin ID
   retained. At full health, rejection keeps both potion and balance unchanged.
9. Obtain further gear/coins through ordinary play as needed, then complete
   Mara's existing quest. A merchant cannot accept or
   report it. Sell a reward potion, save/restart and verify Completed and both
   retained reward records without duplicating the reward.
10. Save changed stocks/balance, retain save/definition hashes, then Start over.
    The balance is 0; visited merchants get fresh initial goods once and fresh
    meetings. The old explicit save and immutable definitions remain byte-identical.
    Disconnect without saving and Continue to restore the saved economy exactly.

Capacity and forged-message negatives use focused rule/storage/protocol/server
fixtures, not 64-item farming in every full play test. Native client review checks
readable prices, coins, page/focus, resize, disabled reasons and rejected/pending
behavior. The server console must retain correct area, connection, dirty/save
facts and bounded logs; displaying it cannot read/refill merchant inventories.

## Test responsibilities and current status

| Surface | Distinct evidence |
| --- | --- |
| Game rules | Exact transfer/delta, ownership, price spread, bounds, reach and unchanged unrelated facts. |
| Generation/NPCs | Four roles, immutable identities/names, accessible talk/exit fields and once-only materialization. |
| Storage | Strict complete origin/owner proofs across all visited areas, rewind/reset and preserved bytes on failure. |
| Protocol | Exact shapes, limits, nullable prices, capabilities, revisions and real full-capacity wire size. |
| Client | Keyboard/selection/page/resize/pending behavior and intentions derived only from projected capabilities. |
| Server/transport | Authority, interaction lifecycle, stale/repeated requests and prepare/send/install behavior. |
| Natural play/DAP | The joined player-visible loop, persistence across process restarts and the final user review. |

Q1-Q9 and the technical contract above govern the authorized implementation.

## Implementation progress

- 01: Complete. PATH resolves to the FPAS distribution in its project's bin
  directory, version 0.0.1, SHA-256
  `8AB0359AA208AA0E328ED9F803D3ADC3710E72BE9165DCCFE467835984D27511`.
  Formatting and all project checks passed; the full baseline passed 161/161.
  The four literal village vectors in `generated_settlement_test.fpas` freeze
  existing gates, names, layouts and healer placements; slot 3 adds new evidence.
- 02: Complete. The user authorized repairing the confirmed FPAS cache
  defect on 2026-10-25 and then continuing this checkpoint.
  Catalogue, merchant location/role, coin field, origin/ownership checks, save
  format 14, exhaustive consumers and focused tests are present. Game/world
  project checks passed. The workspace check exposed FP4134 in the server and
  server-internal tests; the repaired distribution passes all project checks,
  41/41 game tests, 24/24 world tests and candidate_preparation_test.
  An independent three-unit reproduction grows a leaf record behind an
  imported option: cached compilation fails with an incompatible debug record
  projection; identical source in a fresh directory passes. The reproduction
  and control are retained in `.temp-repros/15d-projection-min` and
  `.temp-repros/15d-projection-fresh`. FPAS now records the transitive interface
  dependency closure. Its regression failed before the fix and passes after;
  all 111 build/unit tests, formatting and scoped Clippy passed. Distribution
  rebuild completed, including 123 standard-library units. PATH FPAS SHA-256 is
  `7E1256FE4974CFD26F5D7B441D6BB25C8745902DEF760C358C15E3EFC3CBB8AC`.
  The original reproducer now passes. No cache-deletion workaround was used.
- 03: Complete. Generator 12 and settlement format 2 connect Elias and slot 3
  merchants, complete rosters, once-only five-item ledgers and saved origin
  proofs. The pre-merchant FPAS helper retained all three existing NPC names
  and positions for the four frozen village vectors; the extended vectors
  preserve these and cover each merchant. All 41 game and 24 world tests pass,
  including off-screen definitions/reset, plus village_transition_test and
  settlement_session_test. The settlement decoder now requires four roles.
- 04: Complete. Pure QuoteFor/Buy/Sell share one catalogue and refusal path,
  scan ownership once and retain exact item IDs. Bounded scalar contracts cover
  quote sizes, wallet direction and unchanged health/RNG. All 43 game and 24
  world tests pass, including prices, same-name goods, buyback, independent
  merchants, worn/quest/returned/consumed goods, reward potion sales/buyback,
  full capacities at 63/64, wallet bounds and wrong contexts. Legal prepared
  quest fixtures use the real accept/reward rules; natural play is still 09.
- 05: Complete. Protocol 20 and required projected coins, strict paged quotes,
  monotonic connection revisions and the single active interaction are wired
  through server and client transport. Preparation failures retain the complete
  session; write failures terminate the connection. All workspace project checks,
  13 protocol tests, the settlement session, trade session, quote budget and three
  client-internal tests pass. The largest tested UTF-8 reply is 59,152 bytes,
  below the unchanged 65,536-byte line limit. The merchant menu awaits client 06.
- 06: Complete. The merchant topic opens the keyboard trade window. Buy/Sell,
  local scrolling, remote pages, exact-ID retention, disabled reasons and one
  pending intention pass real headless-TUI tests, including 40x12, smaller
  windows, deferred viewport replies, rejection, closing and disconnect.
  Coins remain visible in context and inventory; context docking reserves the
  additional wallet row. All 31 client tests, all 43 game tests and the real
  merchant-root server session test pass after the focused layout corrections.
- 07: Complete. All 25 world tests pass. The new persistence proof uses a
  generated, codec-validated 31x21 one-level dungeon fixture, two merchants and
  real save/load. It retains dungeon/shop/reward origins through carried, worn,
  floor, consumed and merchant locations where allowed, including cross-merchant
  ownership. Malformed origins/owners/counts/kinds and missing or unreadable
  off-screen definitions preserve prior save/definition bytes. Reload and fresh
  once-only materialization retain the older explicit economy exactly.
- 08: Complete. The real TCP listener and client adapter pass home and village
  trades, viewport tagging, stale/repeated/cross-world requests, interaction
  gating and exact final saved-state comparisons. Fourteen generated visited
  villages supply genuine origins for 64-item inventory/stock edge cases;
  wallet overflow and forged price/quantity/coins fail without changing saves.
  The existing internal trade session and shared storage regression pass again.
  Prepared listener fixtures include the normal current sight field before
  Continue, isolating trade effects from its regular discovery initialization.
- 09: Complete. Existing natural village/quest TCP routes now prove same-ID
  cross-merchant transfers and reward sales across restarts. The real client
  completed the seed-25/chunk-1 DAP route through Hearthmoor, Fernhollow and
  Brackenford, all three spawn-dungeon levels and Mara's reward. Observed home
  balances were 10/2/7/12/0/5, then 8 at Vera, 0 after Esme's potion and 13
  after a further natural coin and reward sale. Full-health use refused without
  loss; the purchased potion survived drop/pickup. Worn gear and the compass
  stayed unsellable. Inside/outdoor saves, both-process restarts, no refill,
  fresh Start over and restoration of the unchanged completed save passed.
  The old save and every existing world JSON file remained byte-identical.
  DAP command 1133 restored 13 coins and Completed. The resulting save SHA-256
  is `3F1E8F74A6C27DFCD33CC42EECCFDBE7DA948992B4028079F9C7AEDE2B24CD27`.
  Review also covered all 31 client tests, bounded scrolling of 160-character
  refusals at 40x12 and positive first-person wallet projection.
- 10: Complete. Permanent economy and running-game verification documents,
  canonical terms, items, NPCs, protocol, persistence, client UI, console,
  versions, controller usage and README match the implemented feature.
  Formatting and all workspace project checks pass. The final complete run
  passes **171/171** programs. Older TCP fixture expectations now follow the
  current handshake and selected-world generator; their dedicated version
  contract tests remain pinned. Rejection text paging and independent map/trade
  intentions have focused TUI coverage. Both repositories pass diff whitespace
  checks; FPAS still resolves to the rebuilt distribution recorded in 02.
  All ten checkpoints are complete. User acceptance remains pending; retain
  this plan until the feature is accepted.
