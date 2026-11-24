Into the Dungeon will be a console-based text adventure with Unicode terminal art and a large language model (LLM) as the game master.

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
The [world state and room art](world-state.md) describe the campaign,
the game master tools, and the data that survives a restart.

## Game settings

The `Dungeon.Settings` project creates `settings.json` with an empty JSON object
on first launch. The game loads the saved agent, model, thinking level and
room art preference at startup. The base directory comes from .NET's
`Environment.SpecialFolder.ApplicationData`.

- Windows uses `%APPDATA%\into-the-dungeon\settings.json`.
- Linux uses `$XDG_CONFIG_HOME/into-the-dungeon/settings.json` when
  `XDG_CONFIG_HOME` is an absolute path, otherwise
  `~/.config/into-the-dungeon/settings.json`.

Open **Settings** from the start menu. At 80 × 25, the provider list is on the
left and the model and thinking selectors are on the right. **Generate room art**
is off by default, including for older settings files. Use the arrow keys to
choose the provider, Tab to move among fields and actions, and Space to toggle
the checkbox. Enter opens a selector or activates a button. Save writes the
preferences and returns to the start menu. Back or Escape discards edits.
Escape closes an open picker first.

The game uses [dotacp.client](https://www.nuget.org/packages/dotacp.client/)
to read ACP session configuration from locally installed agents. Install and
sign in to the agents with their own tools. The game looks for these commands
on `PATH`:

- Codex: [`codex-acp`](https://github.com/agentclientprotocol/codex-acp)
- Claude Code: [`claude-agent-acp`](https://github.com/agentclientprotocol/claude-agent-acp)
- Cursor: [`agent acp`](https://cursor.com/docs/cli/acp)
- Antigravity: [`agy acp`](https://antigravity.google/docs/cli/acp)
- OpenCode: [`opencode acp`](https://opencode.ai/docs/cli/acp)
- Pi (ACP): [`openma-pi-acp`](https://www.npmjs.com/package/@openma/pi-acp)

Install the Pi adapter with `npm install -g @openma/pi-acp` alongside a
compatible Pi installation. The adapter registers the game's MCP tools for
each ACP session.

Loading runs in the background. The model list and thinking levels come from
the selected agent's current session. Changing the model requests its updated
thinking options. When an agent omits a selector, the corresponding field shows
**Unavailable**.

## Diagnostics

`errors.log` is created in the settings directory when the game encounters an
error. Each entry has a UTC timestamp, a source and an agent identifier. The log
records ACP startup and prompt failures, recognized adapter error categories,
and rejected or missing turn and illustration submissions. It keeps prompts,
conversation contents, credentials and raw adapter output out of the file.
At 256 KiB the game moves the current log to `errors.log.1` and starts a new one.
