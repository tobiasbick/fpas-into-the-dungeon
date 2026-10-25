# 15d running-game verification

The implementation was played through with the real FPAS client and server
under DAP, using a new **seed 25, dungeon region size 1** world. All actions
used terminal keys and projected choices. The controller read debugger fields;
it did not assign state, grant money, teleport or edit game files.

The executable came from PATH and was the rebuilt FPAS distribution, version
0.0.1, SHA-256 `7E1256FE4974CFD26F5D7B441D6BB25C8745902DEF760C358C15E3EFC3CBB8AC`.
Current versions are generator 12, settlement 2, save 14, protocol 20 and
world/chunks/dungeon-level format 4.

## Observed route

The new world's allocated identity was `world-1`. Spawn was (10912,-10144),
the home gate (10910,-10148) and spawn entrance (10914,-10143).

| Action | Coins | Observation |
| --- | ---: | --- |
| Meet Elias in Hearthmoor | 0 | Five goods; unavailable buys, empty sell side. Enter caused no transfer. |
| Explore the start dungeon | 0 | Collect coin, sword, jerkin and potion through normal movement/pickup. |
| Sell its Ancient coin | 10 | Original dungeon ID moves to Elias. |
| Buy Elias' first potion | 2 | Home-origin stock ID becomes carried. |
| Sell dungeon sword | 7 | Individual item joins stock. |
| Sell dungeon jerkin | 12 | Individual item joins stock. |
| Buy back that exact sword | 0 | Dungeon ID is retained, separate from Elias' initial sword. |
| Wear it and attempt a sale | 0 | Disabled; no transfer. |
| Close, remove it, reopen and sell | 5 | Normal manual removal enables its sale. |
| Accept Mara's quest | 5 | Merchant did not offer quest acceptance. |
| Reach Vera in Fernhollow | 5 | Independent initial five goods. |
| Sell Elias' potion to Vera | 8 | Same home-origin ID, new merchant owner. |
| Save inside; restart client/server; Continue | 8 | Same position, stock, wallet and meeting. |
| Reach Esme in Brackenford; buy first potion | 0 | Independent initial five goods fall to four. |
| Save outdoors; restart; Continue; revisit | 0 | Still four goods; no refill. |
| Obtain more gear in Fernhollow's nearby dungeon | 0 | Regular floor finds are worn through inventory. |
| Use purchased potion at full health | 0 | Rejected without consumption. |
| Drop and pick up purchased potion | 0 | Its Brackenford stock ID remains unchanged. |
| Recover compass from spawn-dungeon level 3 | 0 | All three levels traversed; ordinary combat damage, no external state changes. |
| Sell a further naturally found coin to Elias | 10 | Ordinary loot funds the balance. |
| Attempt compass sale | 10 | Unpriced and disabled, also with money available. |
| Report to Mara; sell reward potion | 13 | Completed quest; both reward records remain, one now merchant-owned. |
| Save and restart both processes; Continue | 13 | Completed, exact stock, owners, position and health restored. |
| Start over | 0 | Empty inventory and fresh home stock on first visit. |
| Restart without saving; Continue | 13 | Previous completed economy restored. |

The Fernhollow and Brackenford gates are (10951,-10539) and
(11238,-10820). Their outdoor route is unchanged from
[generated settlements](generated-settlements.md#reproducible-acceptance).
The nearby dungeon entrance is (10955,-10539).

Important exact identities:

| Item | ID |
| --- | --- |
| First sold coin | `world-1:dungeon:85:-80:0:item:0` |
| Sold, bought back, worn, removed and sold sword | `world-1:dungeon:85:-80:0:item:1` |
| Sold jerkin | `world-1:dungeon:85:-80:0:item:2` |
| Elias' potion subsequently owned by Vera | `world-1:settlement:home:npc:merchant:stock:0` |
| Purchased, dropped and picked up Esme potion | `world-1:settlement:87:-85:npc:3:stock:0` |
| Returned compass | `world-1:dungeon:85:-80:2:item:6` |
| Sold reward potion | `world-1:quest:mara-compass:reward:0` |

At command 1133, Continue had restored **13 coins, 19/20 health**, Hearthmoor
position (6,8), Completed and the complete 33-item ledger. Start over and the
subsequent unsaved restart preserved the old save and every existing world JSON
file byte-for-byte. That save's SHA-256 is
`3F1E8F74A6C27DFCD33CC42EECCFDBE7DA948992B4028079F9C7AEDE2B24CD27`.
The owned verification processes were then closed without saving implicitly.

## Repeating the checks

Use the [DAP controller](../../tools/dap-acceptance/README.md), start a fresh
directory and follow the route above. `choice trade` selects an actually offered
topic; `trade buy <id>` and `trade sell <id>` navigate by exact identity through
keys. `trade inspect` reads the quote; `inventory <id>` selects a normal item
action and `inventory <id> drop` drops it. Planner/travel accept `last` for the
last acknowledged command ID. Keep actionable trade windows at least 40x12.

Automated natural play extends the existing `village_play_test` and
`quest_play_test`, including process/listener restarts, cross-merchant ownership
and reward sales. Focused tests cover 64-item capacities, overflow, hostile
wire fields, stale revisions, preparation failures and bounded text without
requiring 64-item farming in the DAP route.

This is agent verification. The user's final 15d acceptance remains pending.

Final checks: `fpas fmt --check apps libs tests tools`, every project through
`fpas check dungeon.fpasworkspace`, and the complete
`fpas test --timeout 600 dungeon.fpasworkspace` all pass: **171/171 programs**.
The FPAS cache repair separately passes all 111 build/unit tests, formatting
and scoped Clippy; the distribution was rebuilt before the running-game route.
