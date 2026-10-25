# 15f running-game verification

The user delegated implementation and self-acceptance. The real FPAS client and
server were played under DAP in a fresh **seed 25, dungeon region size 1** world.
Actions used terminal keys and actual projected choices. Debugger inspection
was read-only; no money, health, items, quest flags or positions were assigned.

The executable was `fpas` from PATH, distribution 0.0.1, SHA-256
`73F9E68D38FAC93A6BC7A29AF15D88DCB66ED3A3E7100BE1642FC68760DD7645`.
Protocol is **22**; generator **13**, save **15**, settlement **3** and
world/chunk/dungeon-level formats **4** retain their accepted versions.

## Observed play

World `world-1` starts at (10912,-10144). The route collected ordinary sword,
jerkin, coin and potion finds, wore the equipment and read ordinary news at
both home NPCs. One Ancient coin sold to Elias earned 10 coins; Nora's confirmed
rest charged 5 and advanced exactly **595 to 1075 minutes**. Full-health rest
was accepted. The compass was then retrieved from the third dungeon level and
returned to Mara through the normal quest dialogue.

| Stage | DAP command | Time | Condition | Coins | Health |
| --- | ---: | --- | --- | ---: | ---: |
| New game | 3 | Day 1, 08:00 | Clear | 0 | 20/20 |
| Ordinary loot equipped | 50 | Day 1, 08:35 | Sheltered | 0 | 20/20 |
| Nora's ordinary news | 104 | Day 1, 09:35 | Clear | 0 | 20/20 |
| Elias' ordinary news | 143 | Day 1, 09:45 | Clear | 0 | 20/20 |
| Paid eight-hour rest | 190 | Day 1, 17:55 | Clear | 5 | 20/20 |
| Compass retrieved on level 3 | 348 | Day 1, 20:25 | Sheltered | 5 | 15/20 |
| Compass returned to Mara | 484 | Day 1, 22:39 | Clear | 5 | 10/20 |
| Elias acknowledges completion | 517 | Day 1, 22:44 | Clear | 5 | 10/20 |
| Nora acknowledges completion | 556 | Day 1, 22:54 | Clear | 5 | 10/20 |
| Save, restart both processes, Continue at Nora | 563 | Day 1, 22:54 | Clear | 5 | 10/20 |
| Repeated completed news after Continue | 592 | Day 1, 22:54 | Clear | 5 | 10/20 |
| Save/restart/Continue outdoors | 610 | Day 1, 23:05 | Clear | 5 | 10/20 |
| Ordinary travel through a rainy night | 670 | Day 2, 22:40 | Rain | 5 | 10/20 |
| Enter Fernhollow | 833 | Day 3, 15:16 | Rain | 5 | 10/20 |
| Save/restart/Continue in Fernhollow | 853 | Day 3, 15:25 | Rain | 5 | 10/20 |
| Start over through world selection | 864 | Day 1, 08:00 | Clear | 0 | 20/20 |
| Fresh ordinary home news and initial stock | 964 | Day 1, 08:50 | Clear | 0 | 20/20 |
| Unsaved restart restores completed save | 968 | Day 3, 15:25 | Rain | 5 | 10/20 |

Normal combat caused the injury; outdoor travel did not heal. The route used
no debug grants or extra supplies. Both home NPCs changed their greetings/news
only after hand-in. Repeated news preserved time, health and purse. The completed
journal and saved quest remained completed after full process restarts.
Fernhollow's Orin retained his own first greeting and four village topics.
Final saved ownership contains exactly two carried reward potions and the
returned compass. Elias retains six goods including the sold coin, while
Fernhollow's separate merchant retains its five initial goods.

Travel followed the existing ordinary Fernhollow route, recording at most 64
accepted outdoor steps between weather observations. Clear, rainy night, clear
again and daytime village rain were observed. Dungeons explicitly projected
shelter instead of retaining the former outdoor condition.

## Reset and data preservation

The controller retained the contents/count of all **24** existing world files,
including metadata, chunks, all three dungeon levels, village definition and
the explicit completed save. Start over reset the clock, weather, wallet,
health, inventory, journal and home recognition. Both NPCs gave first greetings
and ordinary news. Elias had exactly five initial goods and no player sale rows.

No unsaved reset action changed those files. Restart and Continue restored
Fernhollow at (16,8), minute **3805**, rain, 10/20 health, 5 coins and completed
journal. All 24 files were still identical. The controller and both owned
processes then stopped normally.

Separately, the original accepted-15e DAP save loaded at its exact **4064**
minutes, active quest, 20 health and zero coins. All **22** pre-existing files
remained unchanged, proving direct use of format-15 data without migration.

## Acceptance evidence

The complete workspace suite passes **177/177 programs**. This includes the
extended full compass TCP route (seed 12345/region 4), village route, atomic
reply failures, strict weather codecs, layout and palette checks. The largest
tested trade reply is **59,229 UTF-8 bytes**, below 65,536. Formatting and
workspace checks pass; no FPAS runtime/compiler changes were required.

DAP inspected state at acknowledged client stops. Headless TUI tests verify
clock/weather labels, rain/night/knowledge shading, stable markers and shelter.
This is not a desktop screenshot-based visual review. The delegated
self-acceptance is complete; the temporary implementation plan is removed.
The [permanent contract](weather-and-world-response.md) records the rules.
