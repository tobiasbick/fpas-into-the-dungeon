# NPCs and dialogue

Hearthmoor is the authored home settlement; generated villages add residents,
guards, innkeepers and merchants. All use a bounded map view. Houses stay closed; entered
building interiors need a separate plan. See [generated settlements](generated-settlements.md)
for site rules, identities, immutable files and the reproducible review route.

## Geometry and state

`Dungeon.Settlements` owns Hearthmoor's unchanged 23 by 15 map and
`<world>:settlement:home` identity. Its gate is six traversable cardinal steps
from spawn. Entry starts at (11,12), beside the exit at (11,13). Mara occupies
(11,7), with ID `<world>:settlement:home:npc:mara`. Home geometry and her
placement resolve from code without a settlement file. Elias, the merchant,
stands at (6,7), with ID `<world>:settlement:home:npc:merchant`. Neither his
addition nor the generated merchant changes gates or existing role placements.
Nora, the innkeeper, stands at (16,7), with ID
`<world>:settlement:home:npc:innkeeper`.

Generated maps have 23 by 15, 27 by 19 or 31 by 21 fields. Immutable geometry
and `NpcPlacement` records travel together in `InteriorMap`; the server retains
this checked map for the active area. A placement supplies stable ID, kind,
display name and local position. Generated IDs are `<area>:npc:0` (resident),
`:npc:1` (guard), `:npc:2` (innkeeper) and `:npc:3` (merchant). Names may repeat across villages, but
identity never depends on a name. NPCs block movement, stay away from start
and exit, and leave connected routes to every talk position.

A new game has one unmet Mara record before its first visit. First entry into
a generated village adds exactly its four initially unmet records. First home
entry adds Elias and Nora; every visited merchant materializes five stock items once. Every
mutable record stores ID, kind, area and `HasMetPlayer`; records are sorted
canonically. Rules find Mara by exact ID, even when generated NPCs sort before
her. Validation rejects missing, duplicate, foreign, wrong-role and unvisited
village records, including invented unmet ones. Met NPCs require their own
settlement to have been visited.

WASD/arrows send absolute cardinal movement. Settlement steps take one minute;
outdoor steps take five. Neither heals or runs combat. Enter on local `x`
returns to that village's exact source gate. Settlements have no floor items
or opponents; dropping items is rejected. Radius-eight map visibility is
clipped to each map, with independent finite discovery masks. Primary windows
are clipped; exploration windows may pan into unknown padding. `n` appears
only for currently visible NPC placements; remembered fields retain geometry.
Map and resize projection use retained facts without area-file or outdoor I/O.

## Dialogue rules

Enter from a cardinally adjacent field starts the selected NPC's conversation.
The occupied exit takes precedence. Its exact ID remains in the active frame;
a character of the same role in another village cannot replace it. First
greeting marks only that character met and unsaved. Repeat greetings remember
that flag without changing progress. Talking consumes no time, opponent phase,
XP or dice. Read-only answers change no items or health. Paid rest is the
explicit time-consuming exception described in [time and rest](time-and-rest.md).

Each frame contains speaker, text and ordered choices. The server additionally
retains the private node and any preflighted quest objective. Mara keeps her
existing root topics:

| ID | Available | Result |
| --- | --- | --- |
| `identity` | Always | Mara's background. |
| `dungeon` | Always | Spawn dungeon name and depth, without reading levels. |
| `coin` | Ancient coin carried | Information about its crescent mark. |
| `quest` | Always | Proved offer, progress or remembered outcome. |
| `goodbye` | Always | End conversation. |

Residents, guards and innkeepers offer `identity`, `settlement` and `goodbye`,
with fixed role-specific text using their stored name and village. An innkeeper
also offers `rest`, followed by a private offer with `rest_confirm` when funds
and clock capacity suffice, and `rest_back`. Rest costs 5 coins, advances eight
hours and restores full health; free healing is unavailable. Quest offer,
preflight, acceptance and report remain restricted to Mara's stable home ID,
reach and active node. Generic NPCs never trigger world quest preflight. Quest
hand-in still returns the compass and grants two potions atomically; see
[quests](quests.md).

## Connection and protocol

`Dungeon.Server.Dialogue` owns conversation dispatch; `ServerSession.ActiveInteraction`
retains either the authoritative dialogue frame or a trade frame. While talking,
`dialogue_choice`, `end_dialogue`, `viewport` and disconnect are accepted. Other intentions, including Save,
receive `dialogue_active`. Foreign/stale NPC IDs and unavailable topics receive
`dialogue_rejected`; absent conversations receive `dialogue_not_active`.
The four trade intentions receive `trade_not_active` until an offered merchant
root choice opens trade. `Dungeon.Server.Trade` then owns its intents; see
[trade and economy](economy.md) for revision, page and refusal rules.

Protocol 21 includes `settlement`, `trade`, `rest`, `rest_confirm` and `rest_back`
in the bounded topic vocabulary. The removed `wounds` ID is invalid.
`dialogue_choice` contains exactly `type`, `npc_id`, `choice_id`; `end_dialogue`
contains only `type`. Replies contain the complete resulting visible state and
dirty flag, plus the projected frame for `dialogue`. A frame has `npc_id`,
`speaker`, `text`, `choices`; each choice has `id`, `text`. Existing bounds,
unique choices and exact field validation remain in force.

Replies prepare state, frame, discovery, projection and bounded wire text
before sending and installing. Preparation failures preserve the complete
installed session; write failures terminate the connection without installing
a candidate. Resize retains conversation, selection, dirty state and discovery.
Area titles, talk hints and console status use the retained stored names.

The client renders the supplied frame and pending speaker name. W/S/arrows
wrap selection, Enter sends the stable choice ID, Escape requests explicit
end, and Page Up/Down scrolls. Pending input and other overlays are gated.
Alt+X keeps normal cancellation. New answers reset selection; resize preserves it.

## Persistence and verification

Savegame 15 stores local positions as `{kind:"settlement",x,y}`, the canonical
`world_minutes` clock and exact NPC
records as `{id,kind,area_id,has_met_player}`. It validates every visited
settlement's complete roster against authored or immutable stored definitions,
including while the player is elsewhere. Positions/names belong to those
definitions. Frames, choice state and scroll position are never saved.

Save explicitly after ending dialogue. Continue restores that snapshot;
disconnect and shutdown never autosave. Start over resets meetings and visits,
retaining definitions and the prior save. Obsolete saves remain preserved and
incompatible, without migration.

Game tests own reach, role permissions, independent meetings and effects.
Storage tests own exact decoding, complete rosters, off-screen validation and
file preservation. Protocol and native TUI tests own wire/input behavior.
Server tests exercise atomic failures and natural TCP travel, healing,
inside/outdoor Continue and the full compass quest after generated NPC visits.
