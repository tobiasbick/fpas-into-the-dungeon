# Weather and Hearthmoor's response

Weather changes the atmosphere of travel. Hearthmoor remembers a completed
compass quest. Both use existing authoritative state; neither adds a saved flag,
background simulation or client-side game rule.

## Weather schedule

`Dungeon.Weather.At(seed, worldMinutes)` is a pure query returning `Clear` or
`Rain`. Each day has four six-hour windows: 00:00, 06:00, 12:00 and 18:00.
Exactly one window is rainy. Its index is
`Terrain.Noise.CoordinateHash(seed, dayIndex, 0, 2203) mod 4`, where `dayIndex`
is the zero-based day derived by `Dungeon.Time`. The current window comes from
the minute of day divided by 360.

The whole world shares the condition at the same canonical minute. World ID
and position do not affect it; signed seeds use the established positive-modulo
hashing. The supported clock range remains 0 through 1,000,000,000 minutes.
No combat random draw or wall-clock timestamp participates.

The query uses the resulting candidate time after an accepted action. A step
or transition across a window boundary returns the new condition. Rest jumps
directly to the final minute, without visiting intermediate windows or running
offscreen turns. Adjacent windows may have the same weather; rain can continue
across midnight. Eight-hour rest does not promise clear skies.

Outdoor regions and settlements are open air. Dungeons are sheltered. Weather
changes no visibility, discovery, passability, action duration, combat roll,
health, stock, price or NPC availability. No weather action, timer, forecast
control, survival statistic or configuration option is added.

## Presentation

Context shows `Weather: Clear`, `Weather: Rain` or `Weather: Sheltered` below
the world clock. When Context cannot dock or is hidden, the primary title
begins with the clock and short condition before the area name. Context reserves
twelve fixed rows and needs seventeen panel rows to dock. Inventory summaries
retain their omitted-item count; small terminals clip safely.

Rain tints map backgrounds. For original RGB `(R,G,B)`, the rain color is
`(3R div 4, 3G div 4, min(255, 3B div 4 + 12))`. Night shading follows, then
Fog of War. Clear daytime colors retain their previous values. Player markers,
other glyphs and foregrounds remain readable. Unknown cells stay identical
blank cells, and remembered fields keep their knowledge distinction.

Primary and exploration maps share the transformation. Underground primary
and exploration views retain their existing lighting. The exploration-map
message uses the latest primary model's condition, as it does for day phase;
it carries no duplicate weather. A sheltered state clears the former outdoor
condition. Rendering, animation, menus and real elapsed time never advance it.

## Recognition in Hearthmoor

Nora and Elias offer the root topic `news`, labelled `Any news around here?`.
Before compass hand-in, their answer is ordinary local news. After the
successfully installed `QuestState.Rewarded`, their greetings and news
acknowledge that Mara has her compass back. Nora speaks of travelers at her
inn; Elias of the people who trade with him.

The rules use each NPC's exact authored home identity from world metadata.
Generated innkeepers and merchants retain their village dialogue. An accepted
quest, a carried compass or a failed hand-in is insufficient for recognition.
The completed journal adds `Hearthmoor remembers your help.` as its fifth line.
Returning a compass does not claim that the dungeon is cleared or safe.

Recognition and meeting memory are independent. An unmet NPC still gives a
first greeting after completion; returning the compass does not mark other
NPCs met. News itself changes no state, time, money, health, items, random
state, dirty flag or save. It grants no extra reward, discount or free room.
Starting a first conversation retains its ordinary meeting effect.

News is offered only at a current home root. Rest offers, quest nodes and
trade retain their modal guards. Exact reach and retained/fresh choice checks
reject foreign, forged or unavailable choices. A failed prepared hand-in
cannot expose recognition before its rewarded candidate is installed.

## Wire and persistence

Protocol **22** requires the `weather` scalar in both visible-state families:

| Value | Meaning | State family |
| --- | --- | --- |
| `"clear"` | Clear open-air weather | Map |
| `"rain"` | Rain in the open air | Map |
| `null` | Sheltered underground | First-person |

The in-memory projection is an optional protocol enum. Null is explicit;
missing weather is invalid. The common names/field codec rejects unknown names,
wrong types, duplicates and extra fields. State-family validation rejects null
on maps and an outdoor condition underground. Map states have 22 root fields;
first-person states have 23. State, dialogue, dialogue-ended and trade replies
share these codecs. `news` enters the bounded choice vocabulary without
increasing the six-choice limit. Nora and Elias each offer five root choices.

The client receives the condition and never derives it from seed or time.
Protocol-21 peers fail at the handshake. Replies retain the 65,536-byte UTF-8
limit and existing trade pagination. The largest tested full-capacity trade
envelope, including the longest weather and clock text, is **59,229 bytes**.

Savegame **15**, generator **13**, world/chunk **4**, dungeon-level **4** and
settlement-definition **3** remain unchanged. Weather is derived from seed and
saved clock, recognition from the saved quest. No weather file, saved condition,
event flag or reputation counter is needed. Accepted 15e data loads directly
without migration or rewriting; older incompatible schemas remain rejected
and preserved.

Continue restores the exact condition and quest response at the saved time.
Loading an earlier save rewinds them together. Start over recomputes the seed's
08:00 condition and resets the quest and meetings. Until explicit overwrite,
the prior save and immutable definitions remain intact. Weather, news, hand-in
and disconnect do not autosave.

## Ownership and proof

`Dungeon.Weather` owns the pure query; `Server.Mapping` converts its result and
supplies shelter. `Projection` uses candidate state. `Protocol.Names`, `States`
and `Validation` share exact encoding and bounds. `Client.Ui.Events` installs
the condition, `Playback` retains it, `GameView` labels it and `MapCells` shades
backgrounds. The existing dialogue facade owns private home-news rules;
`Quests.Journal` owns its completed text. Generic village prose remains separate.

`weather_test` owns schedule boundaries, signed seeds and clock limits.
`news_test` uses legal active/rewarded quest fixtures to protect exact-home
recognition, independent meetings and complete-state preservation for news.
Existing codec, TUI, palette, storage and session tests protect their distinct
transport/rendering/failure contracts. The complete compass and village TCP
routes cover actual gameplay and listener restarts.

The [running-game report](weather-and-world-response-acceptance.md) records the
seed-25/region-1 DAP route and the self-acceptance delegated by the user.
