Into the Dungeon will be a console-based text adventure with ASCII graphics and a large language model (LLM) as the game master.

## Start screen

The frame follows the terminal edges. A centered copper and ember forest fills
the interior at 80 × 25. The FPAS cell grid packs two vertical RGB pixels into
each Unicode upper half block. On larger terminals, a stationary haze samples
the colors at the edges of the forest and fades into the dark background.
Smaller terminals use a compact scene from 60 × 18 and a menu-only layout below
that size. Resizing preserves the selected action.

The artwork is sampled from the selected Glut unter Wurzeln mockup. The
embedded row-major RGB files use three bytes per pixel. The full scene uses
78 × 46 pixels and the compact scene uses 58 × 32 pixels.

The menu shows Start on a first launch and Continue and Restart when a saved
adventure exists. Arrow keys move the selection, and Enter or a click activates
an entry. Exit closes the terminal session.

The menu follows the system's UI culture. The game project owns the English
fallback in `Resources/Strings.resx` and the German translation in
`Resources/Strings.de.resx`.

The local feed in `.tmp/feed` needs matching packages for `Fpas.NET.Sdk`,
`Fpas.Ui`, `Fpas.Ui.Mvu`, and `Fpas.Ui.Tui`.

## Game screen

The [console game screen](console-layouts.md) defines the first playable layout
and how the start menu creates or resumes the single saved adventure.

## Game settings

The `Dungeon.Settings` project creates `settings.json` with an empty JSON object
on first launch. The game loads the saved agent, model and thinking-level IDs
at startup. The base directory comes from .NET's
`Environment.SpecialFolder.ApplicationData`.

- Windows uses `%APPDATA%\into-the-dungeon\settings.json`.
- Linux uses `$XDG_CONFIG_HOME/into-the-dungeon/settings.json` when
  `XDG_CONFIG_HOME` is an absolute path, otherwise
  `~/.config/into-the-dungeon/settings.json`.

Open **Settings** from the start menu. At 80 × 25, the provider list is on the
left and the model and thinking selectors are on the right. Use the arrow keys
to choose the provider, Tab to move among fields and actions, and Enter to open
a selector or activate a button. Save writes the selection and returns to the
start menu. Back or Escape discards edits. Escape closes an open picker first.

The game uses [dotacp.client](https://www.nuget.org/packages/dotacp.client/)
to read ACP session configuration from locally installed agents. Install and
sign in to the agents with their own tools. The game looks for these commands
on `PATH`:

- Codex: [`codex-acp`](https://github.com/agentclientprotocol/codex-acp)
- Claude Code: [`claude-agent-acp`](https://github.com/agentclientprotocol/claude-agent-acp)
- Cursor: [`agent acp`](https://cursor.com/docs/cli/acp)
- Antigravity: [`agy acp`](https://antigravity.google/docs/cli/acp)

Loading runs in the background. The model list and thinking levels come from
the selected agent's current session. Changing the model requests its updated
thinking options. When an agent omits a selector, the corresponding field shows
**Unavailable**.
