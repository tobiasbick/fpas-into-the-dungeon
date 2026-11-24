# World state and room art

The adventure opens in the pump room. The brass key unlocks the north grate
to the grotto. The campaign spans 200 locations across ten districts, including the
two original rooms. The game owns the map, NPC encounters, reversible lake
levels and the final gate decision. [The Last Shift](the-last-shift.md)

## The game's save

`adventure.json` holds the current room, key and grate state, lake level, discoveries,
ending, world brief and transcript. The brief captures the premise, tone, and objective. Each
completed turn records the command, narration, room of origin, and accepted
action. The game validates the action and replaces the save atomically after
the ACP prompt completes. An interrupted or rejected turn leaves the previous
save intact.

The game sends the brief, current facts, and the last four turns with each
prompt. Continue restores the save and displays its current room and
conversation. It reopens the saved ACP session when the agent can load it and
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
| `get_journal` | Recall discoveries recorded in this adventure, including earlier sessions. |
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
