# DAP acceptance controller

This FPAS tool owns a normal game server and a DAP-launched client. Gameplay uses
terminal key events over the debugger protocol and the ordinary client/server
connection. The controller reads the client view model at its view breakpoint;
it never assigns debugger values or writes world definitions or saves directly.
Single keys and resize events are followed by the game's unbound Ctrl+G key.
The controller stops as that marker is routed, after earlier framework messages
have been handled, then inspects its no-op view and waits for pending replies.
This avoids mistaking a focus or timer frame for an acknowledged key.

Use the current FPAS distribution from PATH, including interactive `Std.Os.Proc`
pipes and the queue-only terminal acquisition fix. From the repository root:

```text
fpas run tools/dap-acceptance/dap-acceptance.fpasprj -- .temp-data/dap-acceptance-25-1
```

The directory holds an isolated `game/` data root. The server uses loopback port
44661; the client starts at 4 by 4 virtual cells to keep debugger walking cheap.
Startup waits for the server's listening message before launching the client;
startup output and failed focus snapshots are retained for diagnosis.
Resize for map and dialogue inspection. Both children are closed on `stop`,
normal controller completion or runtime failure. Starting the controller again
retains the data root and ignores the previous command file.

Publish one JSON object to `<directory>/command.json` with an increasing integer
`id`. Wait for that ID in `commands.jsonl` before publishing another command.
`state.json` then holds the completed view-model snapshot. Terminal output and
diagnostics are retained beside it. `Acceptance.Commands` publishes command files
with an atomic rename and waits for the acknowledgement.

| `op` | Fields and behavior |
|------|---------------------|
| `new-world` | From the disconnected start screen, connects and creates seed 25, region size 1 through the editor. |
| `continue` | From the disconnected start screen, selects the first world and chooses Continue. |
| `key` | `key` is a DAP key name, `text` is one character or empty, `ctrl` is Boolean. |
| `focus` | `control` is the decimal control ID as text; navigates with Tab. |
| `batch` | Sends up to 64 movement keys, then a menu marker. Stops after the marker, settles the reply and closes the menu; callers count the actual accepted displacement. |
| `save` | Opens the system menu, chooses Save and confirms an overwrite when needed. |
| `variables` | Expands a current-stop debugger `reference` into `variables.json`. References expire on resume. |
| `resize` | Resizes the terminal to the integer fields `width` and `height`. |
| `restart` | Restarts both owned processes, preserving the data root. |
| `stop` | Closes the client, server and controller. |

Send individual commands with the FPAS command helper, while no route helper is
running. It uses the last acknowledged ID and prints the completed state:

```text
fpas run tools/dap-acceptance/command.fpasprj -- <directory> key Enter
fpas run tools/dap-acceptance/command.fpasprj -- <directory> key Character w
fpas run tools/dap-acceptance/command.fpasprj -- <directory> keys "i Down Enter Escape"
fpas run tools/dap-acceptance/command.fpasprj -- <directory> choice settlement
fpas run tools/dap-acceptance/command.fpasprj -- <directory> resize 60 22
fpas run tools/dap-acceptance/command.fpasprj -- <directory> save
```

`dialogue fresh`, `dialogue repeat`, and `dialogue rested` read and check the
current dialogue text. `choice <id>` reads the offered choices and selects the
matching one through arrow keys and Enter. It never submits a dialogue intention
directly. Inspected dialogue frames are also appended to `dialogues.jsonl`.
State descriptions include the clock, day phase and optional weather. Expand
the weather reference to inspect Clear/Rain; None denotes shelter. The
[15f report](../../docs/architecture/weather-and-world-response-acceptance.md)
records the complete compass, weather and reset route.

The finite-area planner reuses the existing test pathfinder. It reads stored
geometry, avoids stationary NPCs and executes its path through acknowledged
client key events. It does not create or regenerate area files:

```text
fpas run tools/dap-acceptance/planner.fpasprj -- <directory> <area-json> <x> <y> <last-command-id>
fpas run tools/dap-acceptance/planner.fpasprj -- <directory> <area-json> npc <slot> <last-command-id>
fpas run tools/dap-acceptance/planner.fpasprj -- <directory> <area-json> item <array-index> <last-command-id>
fpas run tools/dap-acceptance/planner.fpasprj -- <directory> <area-json> down 0 <last-command-id>
fpas run tools/dap-acceptance/planner.fpasprj -- <directory> <area-json> arrival 0 <last-command-id>
```

The `npc` and `item` forms interact after arrival. Their indices are zero-based
positions in the stored arrays; an item's ID suffix can differ from its index
when optional placements are absent. A blocking dungeon opponent
is fought through Space and movement keys; failure or an unmet destination
stops the helper. Low health pauses automatic fighting so the operator can use
a potion through the inventory before resuming. The caller owns equipment
selection and subsequent dialogue. `arrival` finds the actual exit or stairs up
from the stored cells, while `down` finds the stairs down.

The reproducible route and expected behavior are documented in
[generated settlements](../../docs/architecture/generated-settlements.md#reproducible-acceptance).

For long outdoor routes, the travel driver checks accepted coordinates after
each packet and retries only the remaining distance. It saves after at least
64 acknowledged steps and at the end. Keys ignored by a pending client do not count as progress.
Reduce the virtual terminal for long walks; restore a useful size for checking
the rendered map and conversations. A quiet packet may take up to five minutes
under the debugger without producing terminal bytes:

```text
fpas run tools/dap-acceptance/travel.fpasprj -- <directory> "N289 E1 N3" <last-command-id>
```

Append `no-save` to the travel arguments when checking Start over's preservation
of the previous explicit save. That mode performs movement without checkpoint
or final saves.
Append `reverse` to walk a route back in the opposite order and direction.

Planner and travel accept `last` in place of the numeric command ID. This reads
the last acknowledged ID; run only one command/route helper at a time.

## Trade and inventory

Use an actionable window of at least 40 columns by 12 rows before trading:

```text
fpas run tools/dap-acceptance/command.fpasprj -- <directory> resize 40 12
fpas run tools/dap-acceptance/command.fpasprj -- <directory> choice trade
fpas run tools/dap-acceptance/command.fpasprj -- <directory> trade inspect
fpas run tools/dap-acceptance/command.fpasprj -- <directory> trade buy <item-id>
fpas run tools/dap-acceptance/command.fpasprj -- <directory> trade sell <item-id>
fpas run tools/dap-acceptance/command.fpasprj -- <directory> keys "Escape Escape"
fpas run tools/dap-acceptance/command.fpasprj -- <directory> inventory <item-id>
fpas run tools/dap-acceptance/command.fpasprj -- <directory> inventory <item-id> drop
```

The trade helper expands the projected quote, navigates by exact item ID and
presses Enter once. It searches up to four pages through ordinary Page Up/Down
keys; it does not manufacture a quote, price or intention. A disabled row stays
disabled when selected. `inventory` opens the normal inventory, selects an ID
and presses Enter to use/wear/remove it, or D to drop it, then closes the window.
Close dialogue/trade first. Debugger expansion is read-only throughout.

Inspected quote frames are appended to `trades.jsonl`. The completed seed-25/
chunk-1 route and observed balances/identities are in
[15d verification](../../docs/architecture/economy-acceptance.md).
