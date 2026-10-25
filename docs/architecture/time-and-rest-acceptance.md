# 15e running-game verification

The real FPAS client and server were played under DAP in a fresh **seed 25,
dungeon region size 1** world. The FPAS controller sent terminal keys and
selected actual projected choices; debugger inspection was read-only. Money,
damage, movement and elapsed game time came from ordinary play.

The executable was `fpas` from PATH, distribution version 0.0.1, SHA-256
`73F9E68D38FAC93A6BC7A29AF15D88DCB66ED3A3E7100BE1642FC68760DD7645`.
Versions: generator **13**, settlement **3**, savegame **15**, protocol **21**;
world/chunks and dungeon levels retain format **4**.

## Observed route

The allocated world was `world-1`, with spawn (10912,-10144), home gate
(10910,-10148) and spawn dungeon entrance (10914,-10143). The route collected
the ordinary sword, jerkin, Ancient coin and potion in the Forgotten Catacombs,
wore the equipment and took normal hostile damage. Walking back did not heal.

| Stage | DAP command | Projected time | Coins | Health |
| --- | ---: | --- | ---: | ---: |
| New game | 1 | Day 1, 08:00 | 0 | 20/20 |
| Ordinary loot and equipment | 48 | Day 1, 08:35 | 0 | 20/20 |
| Dungeon injury | 90 | Day 1, 09:08 | 0 | 15/20 |
| Enter Hearthmoor after outdoor travel | 141 | Day 1, 10:28 | 0 | 15/20 |
| Open unaffordable offer, Back and Escape | 169 | Day 1, 10:37 | 0 | 15/20 |
| Sell coin, accept Mara's quest, pay Nora and rest | 244 | Day 1, 18:57 | 5 | 20/20 |
| Save, restart both processes, Continue inside | 248 | Day 1, 18:57 | 5 | 20/20 |
| Save, restart both processes, Continue outdoors | 293 | Day 1, 19:18 | 5 | 20/20 |
| Walk naturally past dusk | 299 | Day 1, 21:33, night | 5 | 20/20 |
| Continue travelling across midnight | 309 | Day 2, 21:38, night | 5 | 20/20 |
| Enter Fernhollow | 356 | Day 3, 11:29, day | 5 | 20/20 |
| Pay the village innkeeper at full health | 381 | Day 3, 19:38 | 0 | 20/20 |
| Save, restart both processes, Continue in village | 406 | Day 3, 19:44 | 0 | 20/20 |
| Start over through the world catalog | 412 | Day 1, 08:00 | 0 | 20/20 |
| Visit home with fresh meeting and stock state | 455 | Day 1, 08:50 | 0 | 20/20 |
| Restart without saving, Continue previous save | 457 | Day 3, 19:44 | 0 | 20/20 |

Nora's paid confirmation advanced **657 to 1137 minutes**, charged exactly 5
coins and restored 15/20 to 20/20 health. The village confirmation advanced
**3578 to 4058 minutes**, charged the remaining 5 coins and accepted full
health. Opening either offer consumed no resources. The unaffordable offer had
no confirmation; Back and Escape preserved clock, health and wallet.

The one Ancient coin sold to Elias funded both rests. His finite stock retained
the purchased coin: six goods before and after Nora's rest and process restart.
Fernhollow's separate merchant still had its five initial goods after village
rest. No stock replenishment or extra money was used.

Travel used the ordinary [Fernhollow route](generated-settlements.md#reproducible-acceptance),
returning from Hearthmoor to spawn first. Night/day fields were inspected at
acknowledged client stops. Terminal sizes included 4x4 for travel and 40x12 for
dialogue, inventory and trade. Palette readability and exact clock labels are
also covered by headless rendering tests; DAP field inspection is not a visual
desktop sign-off.

## Persistence and reset

Every Save/Continue comparison checked the exact canonical saved minute count,
projected clock, health, wallet and position after restarting both server and
client. NPC greetings retained meeting memory. Mara's quest was accepted
through her dialogue before the home save.

Before Start over, the controller retained the contents of all **22** existing
world files, including metadata, chunks, dungeon and settlement definitions and
the explicit save. Start over reset the clock, empty inventory, wallet and
health. A new visit to Nora gave her first greeting; Elias again had five
initial goods. None of these unsaved actions changed any of the 22 files.
Restart and Continue returned to Fernhollow at (21,7), day 3, 19:44. All file
contents and the file count still matched exactly, preserving the saved quest,
item owners, clock and stock. The controller then stopped its owned processes.

## Automated verification

The complete workspace suite passes **175/175 programs**. Existing natural TCP
home/village routes cover paid recovery, exact time and listener restarts; the
compass route still completes the quest. Focused rules, persistence, protocol,
rendering and session tests cover clock boundaries, cancellation, replay,
invalid fields, overflow and failed reply preparation/write. The largest tested
trade envelope with the widest valid clock is **59,211 UTF-8 bytes**, below the
65,536-byte limit.

Formatting and workspace project checks pass. The user accepted 15e on
2026-10-25; the temporary implementation plan is removed. The authoritative rules
and ownership are in [time and rest](time-and-rest.md).
