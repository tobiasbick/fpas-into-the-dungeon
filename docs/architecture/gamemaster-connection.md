# Gamemaster connection

The server stores one agent connection and model for every world in its data
root. 16a supports Codex through `codex-acp` and Pi through `pi-acp`. It provides
configuration and an explicit read-only connection test. Event-driven dungeon,
village and NPC creation follow in later roadmap steps.

## Setup

Install an adapter in the environment that starts the server. For Codex:

```powershell
npm install -g @openai/codex @agentclientprotocol/codex-acp
codex login
```

For Pi, follow [Set up Pi](../setup/pi.md). Authentication and provider settings
belong to the installed agent. The server neither downloads adapters on startup
nor stores provider credentials. Windows npm launchers are resolved to their
installed Node entrypoints; executables and arguments remain separate.

Start `fpas run apps/server/server.fpasprj -- --console`, open **F2 -> Gamemaster
settings** and choose a connection. The server queries the agent's model catalog
without sending a model prompt. Arrow keys browse models; Enter applies the
highlighted exact model ID. Previous/Next page through long catalogs.

**Refresh models** queries again. If a saved model disappears, the new catalog
remains available and the missing model requires an explicit replacement.
**Test connection** sends a real model request and may consume provider quota.
**Save** stores the acknowledged selection; it does not run that test. **Clear**
prepares an unconfigured selection, which is published only by Save. Escape or
Cancel discards the draft and cancels its work. The world-default controls have
their own Save action; each edit preserves the other's stored fields.

## Configuration and status

The current `config/server.toml` schema requires:

```toml
gamemaster_connection = "none"
gamemaster_model = ""
```

Connection names are `none`, `codex` and `pi`. A configured connection requires
a nonempty printable model ID of at most 256 characters. The ID retains its
exact case and spelling. A file missing either field is obsolete and is rejected
with recreate-config guidance. There is no automatic migration. Model lists,
transcripts, tokens and readiness are never stored in this file.

The dashboard shows Not configured, Configured, Testing or Ready. Ready requires
a successful tool test for the exact selection in this server lifetime; restart
returns to Configured. Errors stay in the settings draft without changing the
saved pair. A fresh unconfigured server still listens and warns in console and
headless modes. The warning contains the complete console command and a reminder
to reuse a custom `--data-dir`.

## ACP, MCP and ownership

`Dungeon.Server.Gamemaster` subunits own immutable operation messages, installed
presets, model catalogs, the single ACP reader, the operation lifetime and the
shared MCP tool. Configuration belongs to `Dungeon.RuntimeData.Gamemaster`.
`Console.Application` owns the listener, admission permit, event channels and
subscriptions for either the native terminal or a normal-worker TUI host.
The console's Gamemaster Model/Input/View units retain only draft presentation.

An operation creates a private directory under `cache/gamemaster`, a fresh nonce
and an authenticated loopback MCP publication. Codex receives its HTTP descriptor
through ACP. Pi receives native `.pi/mcp.json` in that directory. The game builds
and caches `tools/pi-launcher` with PATH FPAS on first Pi use, then rebuilds it
when its source or compiler changes. The launcher verifies the session marker
before passing process-scoped `--approve` to Pi and inheriting its RPC pipes.
Personal Pi provider, credential, MCP and global trust files are preserved.

Both adapters call `gamemaster_probe` with the operation's nonce. Its handler
returns the nonce and `service: dungeon`; it has no world, save or character
resource. Success requires both the observed matching handler receipt and an
ACP `end_turn` completion from the exact acknowledged model. Text claiming a
tool call, a wrong nonce, an unfinished turn or a changed model cannot pass.
ACP file/terminal permission requests are rejected on this diagnostic connection.

One cancellable TUI subscription owns provider work. Replacements wait for the
previous operation to join. Revision-tagged results use a separate bounded inbox
and cannot update a superseded or closed draft. Setup/model acknowledgement
shares a 60-second budget; the explicit prompt has 180 seconds. Agent shutdown
has a five-second grace before process-group cleanup. Every terminal path closes
the ACP connection and MCP endpoint, joins serving work and removes session
credentials. Agent transcripts and HTTP authentication never enter console logs.

See [acceptance evidence](gamemaster-connection-acceptance.md), the
[server console](../product/server-console.md) and
[runtime layout](runtime-data.md).
