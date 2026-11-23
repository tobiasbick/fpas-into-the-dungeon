# World state and room art

The first adventure starts in the pump room. The brass key there opens the
north grate into the grotto. The player can return south. Each room has a
stable ID, and each new adventure gets its own ID.

## The game's save

`adventure.json` holds the current room, key and grate state, the world brief,
and the transcript. The brief captures the premise, tone, and objective. Each
completed turn records the command, narration, room of origin, and accepted
action. The game validates the action and replaces the save atomically after
the ACP prompt completes. An interrupted or rejected turn leaves the previous
save intact.

The game sends the brief, current facts, and the last four turns with each
prompt. Continue restores the save and displays its current room and
conversation. It reopens the saved ACP session when the agent can load it and
starts a replacement conversation when the agent cannot restore it. An older
transcript-only save keeps its transcript and begins with the new adventure's
initial world state.

## Game master tools

The game supplies a local stdio MCP server to the ACP agent on session setup.
The stdio subprocess forwards MCP messages over a per-adventure named pipe.
The [official .NET MCP SDK](https://www.nuget.org/packages/ModelContextProtocol.Core)
serves requests in the running game. The game process owns the save and reads
one player command at a time.

| Tool | Purpose |
| --- | --- |
| `get_room` | Read a room's description, exit, key and grate state, and saved art availability. |
| `get_history` | Read up to 20 completed turns, optionally filtered by room. |
| `submit_turn` | Stage narration and one validated action for the current turn. |

Each request uses the turn ID provided in the prompt. Read tools use the
turn's committed snapshot. A valid submission stages a proposal in memory.
The game accepts one proposal per turn and saves it only after successful
prompt completion.

## Room illustrations

The pump room and grotto use the ember illustrations from the terminal design
previews. On first entry, the adventure worker copies the relevant packaged
PNG to `art/<adventure-id>/<room-id>-ember-v1.png` beside the save. On return or
Continue it reads the existing PNG. The room keeps its illustration when the
key or grate state changes.

The TUI scales the stored pixels inside the room pane. It uses the same
half-block packing as the start screen, with the upper pixel as foreground
and the lower pixel as background. The terminal can resize using the same
stored illustration. A missing or unreadable image leaves a placeholder
while the game remains playable.

A future image generator can supply the original illustration through the
same art lookup. It would receive the room brief, an ember palette and start
screen reference. The game owns the image key and file publication.
