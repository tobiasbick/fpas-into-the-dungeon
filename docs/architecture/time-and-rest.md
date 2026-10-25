# Time and rest

Game time advances only through accepted player actions. The server owns one
clock in the selected world's game state. Real elapsed time, menus, animation,
network latency and disconnected time never advance it.

## Clock and actions

`GameState.WorldMinutes` counts minutes from day 1 at midnight. New games start
at **480**, or **day 1, 08:00**. The supported range is 0 through 1,000,000,000.
Day number is one-based; minute of day is 0 through 1439. Only the canonical
minute count is saved. `WorldSession.Clock` remains the unrelated chunk-cache
LRU counter.

`Dungeon.Time` owns validation, checked addition, durations and phase derivation.
It has no dependency on the game state, storage, UI or system time. Overflow
rejects the complete action rather than clamping or wrapping the clock.

| Accepted action | Minutes | Opponent phase |
| --- | ---: | --- |
| Outdoor cardinal step | 5 | None |
| Settlement cardinal step | 1 | None |
| Dungeon relative step | 1 | One |
| Attack against an opponent, including a miss | 1 | One |
| Wait, wear/remove/drop an item, use a potion | 1 | One in a dungeon |
| Enter/leave an area or use stairs | 1 | None |
| Confirm inn rest | 480 | None |
| Turn, inspect, pick up an item, speak, trade or choose a quest topic | 0 | None |
| Open/close/pan a window, resize or save/load | 0 | None |
| Rejected intention, including an empty-field attack | 0 | None |

Moving onto an entrance and activating it are separate actions. Rest takes
exactly eight hours, with no extra ordinary turn. A large time advance never
simulates hundreds of enemy turns: only the active dungeon's ordinary combat
actions run its existing opponent phase.

Each pure action advances the clock once. First-person movement helpers do not
advance it a second time inside `Combat.ResolveTurn`. A dirty state is not a
clock event: meeting an NPC, taking an item or trading can change saved facts
without consuming time. Clock capacity is checked before outdoor chunk loading
or area creation as well as before installing a candidate game state.

## Day and night

Day lasts from **06:00 through 19:59**; night from **20:00 through 05:59**.
The server derives the phase. The client displays `Day N HH:MM` in Context,
or in the primary frame's title when Context is hidden or cannot dock.

At night, outdoor and settlement map backgrounds are darker. Marker foregrounds
stay readable, unknown fields stay hidden and remembered fields retain their
separate Fog of War treatment. The exploration map follows the same palette.
Dungeon lighting, visibility range, enemy behavior and NPC availability do not
change with the phase. There are no dawn/dusk transitions or opening hours.

## Inns and healing

Every settlement has one stationary innkeeper. Hearthmoor's **Nora** stands at
(16,7), with ID `<world>:settlement:home:npc:innkeeper`. A generated village's
slot 2 is its innkeeper, retaining that slot's seeded name and position. The
other slots remain resident, guard and merchant. No building interior or extra
inn state is introduced.

An inn offers **eight hours of rest for 5 coins**, restoring full health. The
price is the same everywhere. Rest is allowed at full health to advance time.
There is no credit, free emergency bed, passive regeneration or free NPC healing;
healing potions remain available. Mara retains her compass quest and can point
the player to Nora. An Ancient coin sold for 10 coins funds two rests.

The innkeeper's root topic `rest` opens a free offer showing the duration,
price, full-healing result and current balance. If funds or clock capacity are
insufficient, the offer explains why and contains only `rest_back`.
Otherwise `rest_confirm` pays and rests. Back returns to the root; Escape ends
the conversation. Neither cancellation consumes time or money.

Confirmation checks the current NPC, reach, innkeeper role, private offer node,
retained and fresh choices, funds and clock capacity. It prepares one candidate
that deducts 5 coins, advances by 480 minutes and sets full health. The ordinary
prepare/send/install path commits state and refreshed dialogue together. Failed
preparation preserves the complete original session; a failed write terminates
the connection without installing the candidate.

A completed offer closes. A repeated confirmation against the installed root
is rejected; another rest needs a new offer. Successful rest marks progress
unsaved but never saves automatically. It changes no items, merchant stock,
quest facts, experience, dice or offscreen enemies. Stock does not replenish
and enemies do not respawn.

## Storage and wire contract

Savegame format **15** requires the integer field `world_minutes`. Missing,
extra, wrongly typed, fractional, negative or over-limit values are invalid.
Continue restores the exact clock, health, purse and NPC state. Start over
resets them through normal new-game creation and preserves the prior explicit
save until confirmed overwrite.

Protocol **21** requires one nested `time` object in both visible-state families:

```json
{"time":{"day":2,"minute_of_day":0,"phase":"night"}}
```

`day` and `minute_of_day` are bounded integers; `phase` is exactly `day` or
`night`. Their represented minute count must fit the clock limit. The server
derives all fields from its canonical count. The client formats HH:MM and uses
the supplied phase rather than reproducing daylight or action-duration rules.

The common `Dungeon.Protocol.Clock` and `States` codecs also cover state inside
dialogue and trade envelopes. Unknown, missing, duplicate and extra fields are
rejected. All replies retain the 65,536-byte UTF-8 transport limit; the largest
tested trade response with maximum clock text is **59,211 bytes**.

Current versions are world/chunks 4, generator **13**, dungeon levels 4,
settlement definition **3**, savegame **15** and protocol **21**. The changed
settlement role/roster is immutable world content. Obsolete worlds and saves
are rejected and preserved without migration or regeneration. Runtime
configuration has no new balance settings.

## Ownership and verification

`Dungeon.Movement` and `Combat` own accepted action timing. The dialogue facade
and its private `Rest` module own offers and paid recovery. `Server.Mapping`
derives the shared clock projection. `Client.Ui.Events` installs it;
`GameView` formats the label and `MapCells` applies night backgrounds. Redraws,
animations and other client updates do not advance time.

`time_test` owns arithmetic and phase boundaries; `rest_test` owns ordinary
offers, payment, cancellation, full-health rest, replay and clock limits.
`time_storage_test` covers exact saves, malformed values, file preservation
and rejection before chunk creation. `time_protocol_test` covers both state
families and hostile nested fields. Existing movement, combat, rendering,
dialogue and socket tests cover their distinct interfaces, including rejection
before generated-area creation and failure during prepared rest replies.

The existing home and village play tests earn money through loot sales, buy
rest and restart full listeners. They check exact saved clocks, independent
meetings and stock, Continue and Start over. The compass play still completes
the quest. The [running-game report](time-and-rest-acceptance.md) records the
separate seed-25, region-size-1 DAP verification.
