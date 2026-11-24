# World state and room art

The adventure opens in the pump room. The brass key unlocks the north grate
to the grotto. The campaign spans 200 locations across ten districts, including the
two original rooms. The game owns the map, NPC encounters, reversible lake
levels and the final gate decision. [The Last Shift](the-last-shift.md)

## The game's save

`adventure.json` holds the current room, key and grate state, lake level, discoveries,
ending, world brief and transcript. The brief captures the premise, tone, and objective. Each
completed turn records the command, player-facing narration, room of origin, action
and target. For a local interaction it also stores the authored outcome selected
before the action changed the world, and the person addressed, if any. A second
conversation with Iven at low water therefore preserves a different answer from
the first conversation at high water. The game validates the action and replaces
the save atomically after the ACP prompt completes. An interrupted or rejected turn leaves the previous
save intact.

Each prompt includes the premise, the last four turns and the current scene. The
scene supplies local details, people, available actions and their outcomes,
inventory, exits and obstacles. Rooms and exits have stable IDs and display names
in the player's UI language. Continue restores the save and displays its current
room and conversation. It reopens the saved ACP session when the agent can load it and
starts a replacement conversation when the agent cannot restore it. An older
transcript-only save keeps its transcript and begins with the new adventure's
initial world state. Version 1 two-room saves keep their adventure ID, room, key,
grate, agent session and transcript. They resume with the campaign premise and
empty discoveries. The next save writes version 2.

## Game master tools

The game supplies a local stdio MCP server to the ACP agent on session setup.
The stdio subprocess forwards MCP messages over a per-adventure named pipe.
The [official .NET MCP SDK](https://www.nuget.org/packages/ModelContextProtocol.Core)
serves requests in the running game. The game process owns the save and reads
one player command at a time.

| Tool | Purpose |
| --- | --- |
| `get_room` | Read the current scene, open and blocked routes, and local characters and actions. An open adjacent room can be previewed for arrival narration. |
| `get_journal` | Read the latest 20 completed encounters with their original narration, fact, turn number, location and person. |
| `search_memories` | Search the entire committed transcript, including previous sessions. Filter by text, person and room ID. |
| `find_route` | Find a walk over previously crossed passages to a visited place or a person's last recorded meeting place. |
| `get_history` | Read up to 20 completed turns, optionally filtered by room. |
| `submit_turn` | Stage narration and one validated action for the current turn. |
| `submit_room_art` | Submit a drawing for an active illustration request and its exact dimensions. |

Turn tools use the turn ID provided in the narration prompt. Read tools use the
turn's committed snapshot. A valid submission stages a proposal in memory.
The game accepts one proposal per turn and saves it only after successful
prompt completion. Free-form observation uses `none`. Travel uses `move`
with an open destination ID. Talking, examining a clue, operating a device
and choosing an ending use the action and target supplied by the room.
Only a present character can be addressed. A single-use mechanism disappears
from the available actions after the change commits.

### Recollection and directions

`search_memories` searches the player's words, the GM's original reply, the
recorded fact, the interaction target, and the room and person names. Empty
filters match everything. Results are newest first. Start with `beforeTurn = 0`
and a `limit` of 1–20. Pass the returned `nextBeforeTurn` to continue with
older matches. Zero marks the end. Turn numbers start at one, including the
opening scene. A legacy entry keeps its original narration and any recorded
action and location. Missing facts stay empty.

`find_route` accepts a room ID, an English or German display name, or a person
the player has addressed. For a person, `lastMetTurn` identifies the meeting
that supplied the location. A later meeting updates that location. The route
uses the shortest currently open path among the passages this adventure has
already crossed in either direction. Each step names its direction and
destination. The result is `here` at the destination or `route` for an open
walk. If every known path is blocked, `blocked` includes the steps up to the
first obstruction and its cause. An unrecognised destination returns `unknown`.
A recorded place with no connecting movement history returns `unmapped`.
Asking for directions uses the ordinary narration action and leaves the player
where they are.

## Room illustrations

Entering or resuming a room displays its saved narration immediately. The
adventure checks its own art directory for the **50 × 16** and **65 × 21**
drawings. A background worker asks the selected game master for the missing
sizes, small first. It uses the same agent and model settings in a separate
ACP conversation, so player commands can continue while art is being drawn.
The prompt supplies the room, its district, the narration, and the complete
companion drawing when one exists. The artist keeps the viewpoint, palette
and landmark consistent across both compositions.

Each `submit_room_art` call uses an opaque request ID scoped to one drawing.
A drawing describes a palette of foreground/background RGB colours and
single-cell Unicode glyphs. Its rows index that palette and its zero-based
focus coordinates identify the main landmark. The game validates the drawing,
then publishes it after the ACP prompt finishes. Each size is written
atomically to its own UTF-8 JSON file beside the slot, for example
`art/<adventure-id>/<room-id>-50x16-v1.json`. If play is interrupted after
one drawing, the next visit or Continue can complete the pair. Restart gives
the adventure a fresh ID and its own artwork. Earlier PNG files are ignored.

The TUI selects the large drawing when the art pane has at least 65 columns
and 21 rows. The smaller drawing serves other sizes. A lone drawing can
stand in while its companion is pending. Free space surrounds the centred
drawing with haze sampled from the edge colours. In a smaller pane, the
window crops around the focus and clamps at the drawing's edges. Below
24 columns or eight usable rows for art, the transcript takes the full
width. Resizing uses the loaded cells locally.
