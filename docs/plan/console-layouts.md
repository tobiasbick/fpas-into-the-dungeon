# Console game screen

The first playable version is a small text adventure in the style of classic
terminal games. The player types commands, and the LLM game master describes
what happens. A single framed screen in the FPAS TUI keeps the scene, the
conversation and the current command in view.

## Layout at 80 × 25

- The left pane takes about two thirds of the upper area and shows the current
  room illustration. The game master draws missing room art in the background.
- The right pane takes the remaining third and shows player commands and game
  master replies in order. Text wraps to the pane width, and the player can
  reach the conversation with Tab or Shift+Tab and scroll with Page Up or
  Page Down.
- The command input spans the full width below both panes. Three rows are
  visible at a time. Longer input wraps and scrolls inside the field. Enter
  inserts a line break, and F2 sends the command.
- The status bar sits below the input and shows `F9 Back` and `F10 Exit`.

```text
+- Room view ---------------------------------------+- Adventure log ----------+
|                                                   | > look                   |
|                                                   | A stone passage leads    |
|                                                   | north.                   |
|                                                   |                          |
|                Drawing the room…                  |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
|                                                   |                          |
+- F2 Send command ------------------------------------------------------------+
| go north                                                                     |
|                                                                              |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                            F9 Back  F10 Exit |
+------------------------------------------------------------------------------+
```

## Starting and continuing

- **Start** or **Restart** creates a new ACP session using the current game
  master settings. Once the new session is ready, it becomes the game's sole
  resumable session and begins with the game master's opening scene.
- **Continue** is available when the game has a saved adventure. It restores
  the world, current room art, and conversation, and starts the game master
  from `settings.json` so the player can enter the next command.

The game stores the session ID, game master selection, world state, and each
completed turn in `adventure.json` beside `settings.json`. F9 lets the current
turn finish, saves the adventure, and returns to the main menu after the
session closes. F10 exits the game and may interrupt an active turn. See
[world state and room art](world-state.md) for the save and tool details.
