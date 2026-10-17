# NPCs and dialogue

Every world has one home settlement, Hearthmoor. Its outdoor gate is exactly
six traversable cardinal steps from spawn, excluding dungeon entrances and
the spawn entrance's neighbors. World format 4 stores `settlement_gate` as
`{x,y}`; generator 9 overlays it with feature code `s`. Invalid or obsolete
world data is rejected and preserved.

## Geometry and state

`Dungeon.Settlements` owns `<world>:settlement:home` and its authored 23 by 15
map. The server resolves this map from code; it never writes a settlement
level file. Shared finite-grid geometry uses depth 1 and level 0 only to reuse
validation. The settlement has its own local player-position variant without
facing. WASD and arrows send absolute cardinal `move` intentions. Walls,
house blocks and Mara block movement. Houses cannot be entered in 15a; future
building interiors use first-person views.

Entry starts at (11,12), one field north of the exit at (11,13). Activating the
exit returns to the exact outdoor gate. Entry records the visit and the return
location. Settlement steps do not regenerate health; accepted outdoor steps
still restore one point. There are no floor items or opponents, and dropping
items is rejected.

`Dungeon.Npcs` owns Mara's stable identity
`<world>:settlement:home:npc:mara`, kind, area and `HasMetPlayer` flag. Her
position (11,7) is derived from her kind. A new game has exactly this record,
with the flag false, even before visiting the settlement. Validation rejects
unknown, duplicate, missing and foreign records, and player overlap.

Settlement visibility uses the non-occluded outdoor radius of eight, clipped
to the map. Discovery uses the existing bounded-area masks. Primary windows
are clipped and centered; exploration windows may pan beyond the layout and
receive unknown padding. Neither projection loads outdoor chunks. Map codes
are `#` for walls/houses, `.` for the square, `x` for the exit, and `n` for Mara.
Only a currently visible NPC projects `n`; remembered fields show geometry.

## Dialogue rules

`Dungeon.Dialogue` owns a deterministic typed graph. Enter starts Mara's
conversation from any cardinally adjacent field; no facing is required.
The occupied exit has precedence. The first greeting changes `HasMetPlayer`
to true; later greetings use that flag without changing progress.

Each frame contains the NPC ID, speaker, text and ordered choices:

| ID | Available | Result |
| --- | --- | --- |
| `identity` | Always | Mara's background. |
| `dungeon` | Always | Spawn dungeon name and depth, derived without level access. |
| `coin` | Ancient coin carried | Information about its crescent mark. |
| `wounds` | Health below maximum | Free healing to maximum health. |
| `goodbye` | Always | End the conversation. |

Every answer refreshes the same frame. Healing removes `wounds`; only goodbye,
explicit end or disconnect closes the dialogue. Rules check both the active
frame and currently available choices. Talking consumes no turn and changes
no items, opponent state or dice. Only a first meeting or healing marks new
progress unsaved.

## Connection and protocol

`Dungeon.Server.Dialogue` owns dispatch and `ServerSession.ActiveDialogue`
retains the authoritative frame. While active, only `dialogue_choice`,
`end_dialogue`, `viewport` and disconnect are accepted. Other intentions,
including world selection and saves, receive `dialogue_active`. A foreign NPC
or unavailable topic receives `dialogue_rejected`; an inactive conversation
receives `dialogue_not_active`.

Protocol 17 has exact message fields. `dialogue_choice` contains `type`,
`npc_id` and `choice_id`; `end_dialogue` contains only `type`. A `dialogue`
reply contains `type`, `dirty`, `state` and `dialogue`; `dialogue_ended`
contains `type`, `dirty` and `state`. The embedded state is the complete
resulting visible projection. The frame has `npc_id`, `speaker`, `text` and
`choices`; each choice has `id` and `text`. IDs, text lengths and choice count
are bounded, duplicate and unknown topic IDs are rejected, and NPC markers
are forbidden in remembered rows. `Dungeon.Protocol.States` provides the
shared state codec for ordinary and dialogue replies.

Replies prepare state, frame, projection and the bounded UTF-8 line before
installation. Preparation failure retains the entire old session; a failed
write terminates the connection without installing the candidate. Resize is
read-only and retains the frame, dirty flag and discovery. The dashboard names
the current area Hearthmoor. Map states carry server-projected titles and
Environment hints, including `Mara — Enter: Talk`.

The client retains only the projected frame, selection and scroll offset.
W/S and arrows wrap the selection, Enter submits its stable ID, and Escape
requests an explicit end. Pending input is suppressed, other overlays and
movement are blocked, and Alt+X retains normal cancellation. Text wraps to
the terminal; Page Up/Down scrolls long frames. A new answer resets selection;
a viewport reply preserves it.

## Persistence and verification

Savegame 11 stores settlement positions as `{kind:"settlement",x,y}` and exact
NPC records as `{id,kind,area_id,has_met_player}`. It resolves settlement
visits and discovery against the authored map. A met NPC requires a visited
home settlement. Active frames, choices, scroll positions and speaker text
never enter a save. Explicit saving after ending the dialogue persists the
flag; disconnect and server shutdown never autosave. Start over resets it and
keeps the prior save. Obsolete save versions are rejected without migration.

Game tests own topic availability, reach and effects. World tests own exact
NPC decoding, settlement discovery and file preservation. Protocol tests own
bounds and wire shapes. Server tests cover real adapter gating, reconnect,
projection and atomic failures. Headless TUI tests cover modal input, pending
requests, narrow terminals, refreshed choices, resize and native Escape.
