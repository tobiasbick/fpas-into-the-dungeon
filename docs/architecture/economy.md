# Trade and economy

Every settlement has one merchant. Hearthmoor's Elias stands at (6,7), with
ID `<world>:settlement:home:npc:merchant`. Generated villages retain resident,
guard and innkeeper slots 0..2 and merchant slot 3. The merchant offers
`trade` in the root conversation. Only Mara offers her compass quest; merchants
cannot heal, accept the quest or report it.

## Money, prices and stock

The player starts with **0 coins**. `GameState.Coins` is an integer from 0
through 1,000,000,000, independent of inventory capacity. An Ancient coin is
still a physical item: picking it up does not change this balance.

Prices are fixed for all merchants, from the player's perspective:

| Item | Buy | Sell |
| --- | ---: | ---: |
| Ancient coin | 20 | 10 |
| Healing potion | 8 | 3 |
| Rusty short sword | 12 | 5 |
| Leather jerkin | 12 | 5 |
| Mara's compass | Unavailable | Unavailable |

A merchant starts with three potions, one sword and one jerkin. The five
identities are `<merchant-id>:stock:0` through `:4`, with potions at slots
0..2, sword at 3 and jerkin at 4. First entry in that game materializes them
once. Buying removes one item from stock; selling adds that exact item.
There is no automatic replenishment, stock reroll or finite merchant wallet.
Inn rest costs 5 coins, advances eight hours and restores health; it does not
refill or otherwise change stock. See [time and rest](time-and-rest.md).
Stock can contain at most 64 individual items. The player's existing 64-item
inventory limit includes worn equipment. Selling worn equipment requires
manually removing it first. Reward potions can be sold; the compass cannot.

Same-name items remain separate. Buying back a dungeon sword retains its
dungeon ID, and selling Elias' potion to another merchant retains its home
stock ID. A purchased potion uses the existing use/drop/pickup rules.

## One item ledger

There is one `GameState.Items` array. `HeldByMerchant(MerchantId)` is an item
location alongside carried, worn, dungeon floor and the existing terminal
locations. Stock is derived from this location, not stored in another array
or file. Consumed shop goods retain their original records and cannot refill.

An item's origin and owner are independent. Full save validation requires:

- Every original placement from every visited dungeon.
- Every one of the five original goods from each visited merchant.
- Both reward records after the quest reward, including used or sold rewards.
- Exact IDs and kinds, with no invented slots, missing records or duplicates.
- A merchant owner that is the actual merchant of a visited settlement.
- Existing definitions for all visited origins and destinations, including
  off-screen villages and dungeons.

Save format **15** requires `coins` and `world_minutes`. Merchant locations have exactly
`{"kind":"merchant","npc_id":"..."}`. Neither quotes nor revisions are saved.
Save/Continue read existing definitions and never regenerate missing visited
areas. Start over resets balance, stock and meetings for the new game, retaining
immutable definitions and the prior explicit save. See
[persistent state](persistent-game-state.md).

## Pure rules and session authority

`Dungeon.Trade.Model` owns prices, bounds, offers and typed failures.
`Dungeon.Trade.Items` owns stock identities and ownership validation without
depending on `GameState`. `Dungeon.Trade` owns pure `QuoteFor`, `Buy` and `Sell`.
Quote construction gathers ownership once, counts inventory/stock once and
sorts offers by ID. A transfer changes one location and the coin balance.
It changes no health, XP, discovery, dice state or world time.
Scalar postconditions check the public transfer and quote boundaries.

The server retains one optional `ActiveInteraction`: dialogue or trade.
A trade frame has NPC ID, revision and buy/sell page indexes. Its connection
counter starts at zero; published revisions are 1..1,000,000,000 and increase
on every accepted transfer or page refresh. Closing, reopening, Start over
and world selection do not reset the counter on that connection. A new
connection has a new counter. Exhaustion still permits closing trade.

Opening requires the current merchant root to have actually offered `trade`,
with that met merchant still in reach. A transfer requires the exact merchant,
current revision, correct side, enabled item on the current quoted page and
current ownership, capacity and funds. Item IDs or prices supplied elsewhere
cannot authorize it. The rules recheck the actual state before transferring.

`Dungeon.Server.Trade` prepares a candidate. The existing reply path prepares
the entire projection and bounded wire line, sends it and only then installs
the session. A business or preparation rejection retains the complete original
game, interaction, revision, cache, dirty flag and save timestamp. A failed
write terminates the connection without installing its candidate. Accepted
transfers mark progress dirty; quotes, pages and closing do not save it.

## Protocol 22

Both visible state families require bounded integer `coins` and the common
validated `time` and required `weather` projections. A trade reply is
one atomic envelope with exactly `type`, `dirty`, `state` and `trade`.

| Intention | Fields besides `type` |
| --- | --- |
| `trade_buy`, `trade_sell` | `npc_id`, `item_id`, `revision` |
| `trade_page` | `npc_id`, `side` (`buy`/`sell`), `page` |
| `end_trade` | `npc_id` |

There is no client price, quantity, wallet delta or revision on `trade_page`.
Unknown, duplicate, missing or wrongly typed fields are invalid messages.

The quote has exactly `npc_id`, `speaker`, `revision`, `merchant_capacity`,
`buy_page`, `sell_page`, `buy_total`, `sell_total`, `buy_items` and `sell_items`.
Each side has at most 64 entries, in pages of **16**. Empty sides use page 0;
successful transfers clamp retained page indexes. A row has exactly `id`,
`name`, nullable `price`, `enabled` and `reason`. Prices are 1..20; enabled
rows have a price and an empty reason. Disabled rows have a nonempty bounded
reason, at most 160 printable ASCII characters. Worn gear retains its price;
the compass has no price. IDs cannot repeat within or across the two sides.

The LF-delimited UTF-8 limit remains **65,536 bytes**. Preparation checks the
complete encoded line without discarding fields. The largest tested reply,
including a largest village and both full pages with maximum identities and
escaped text, widest valid clock and longest weather name, is **59,229 bytes**.

During trade, only its four intentions, viewport updates and disconnect are
allowed. Other valid gameplay/lifecycle intentions receive `trade_active`.
Trade intentions without active trade receive `trade_not_active`, including
while a dialogue is active. Before a game exists, `session_not_started` takes
precedence. Semantic refusal or reply preparation uses `trade_rejected`.
Malformed wire messages close that connection with `invalid_message`.

## Client and verification

The client imports protocol projections, not price or game rules. Its trade
window shows the merchant, coins, selected price, Buy/Sell side, page, items
and refusal. Tab switches sides, Up/Down selects, Page Up/Down changes the
server page and Enter requests one enabled item. Escape returns to dialogue;
Alt+X quits. Long reasons scroll with Left/Right while controls stay visible.

At **40x12** and above, local scrolling reaches every row of a 16-item page.
Smaller windows show a resize hint and suppress transfer/page intentions.
Only one primary intention can be pending. Transfer replies retain a surviving
selection by exact ID, otherwise clamp its old index; page replies start at
row zero. Tagged viewport replies preserve the quote, revision and selection.
Rejections keep the window and show the server reason. Other overlays and
gameplay shortcuts cannot take its input.

Rule tests own arithmetic/ownership refusals; storage tests own complete
origins and byte preservation. Protocol and budget tests own exact wire
shapes and limits. Headless TUI tests own real keys, resize, pages and focus.
Internal session tests compare full candidates on rejection and fatal writes.
Listener/client-adapter tests use genuine visited stock origins for capacity
and overflow boundaries. Existing natural village/quest tests and the
[15d acceptance route](economy-acceptance.md) join these paths through normal play.
