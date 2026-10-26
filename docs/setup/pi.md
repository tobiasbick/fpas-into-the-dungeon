# Set up Pi for the Gamemaster

The game connects to Pi through
[`svkozak/pi-acp`](https://github.com/svkozak/pi-acp). Pi connects to the model
provider; Into the Dungeon supplies the game tools through embedded MCP.

The server's **F2 -> Gamemaster settings** select an agent and advertised model
for all worlds. The game prepares its MCP endpoint automatically. See the
[connection contract](../architecture/gamemaster-connection.md) and
[verified adapter combination](../architecture/gamemaster-connection-acceptance.md).

## 1. Install Pi and its ACP adapter

Install Node.js 22.19 or newer, then run:

```powershell
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
npm install -g pi-acp
pi --version
npm list -g --depth=0 pi-acp
```

Use a current stable Pi release with built-in MCP. The ACP adapter also needs
the `pi` command on PATH. Install both in the environment that will run the
game server. See the [Pi quickstart](https://pi.dev/docs/latest/quickstart)
and [pi-acp installation](https://github.com/svkozak/pi-acp#install).

The package listing verifies that the adapter is installed. Starting `pi-acp`
directly opens its ACP stdio service; it is not an interactive Pi session.

For native Windows, follow [Pi's Windows setup](https://pi.dev/docs/latest/windows).
Git for Windows provides the Bash environment used by Pi's shell tool. A Pi
installation inside WSL is separate from a native Windows installation.

## 2. Connect Pi to a model

Start Pi independently of the game:

```powershell
pi
```

For a supported hosted provider, use `/login`, follow the provider's setup,
then choose an available model with `/model`. Provider credentials remain in
Pi's own configuration. The game stores the chosen connection and model ID,
not a copy of those credentials. See
[Choose a Model](https://pi.dev/docs/latest/models).

### Local models through llama.cpp

Pi has a built-in llama.cpp router connection. Start a current router using
the [local-model guide](https://pi.dev/docs/latest/llama-cpp), including a
compatible tool-calling template, then run these commands inside Pi:

```text
/login llama.cpp
/llama
/model
```

Enter the router URL when requested. `/llama` loads a model when the router
has not loaded one yet; `/model` selects it. Keep that model server running
while the game uses Pi. Choose a model and context size that fit your machine.

### Other OpenAI-compatible local endpoints

For an existing Ollama service, for example, add a provider to Pi's
`~/.pi/agent/models.json`. Merge it with existing providers rather than
replacing the whole file:

```json
{
  "providers": {
    "local-ollama": {
      "baseUrl": "http://127.0.0.1:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        { "id": "replace-with-installed-model-id" }
      ]
    }
  }
}
```

Replace the example ID with the exact ID of a model installed in your local
service. The `ollama` key is a placeholder for an unauthenticated local
Ollama endpoint. Other services may require a different URL and credentials.
Open `/model` in Pi again to reload the model configuration. The
[compatible-endpoint guide](https://pi.dev/docs/latest/models#configure-a-compatible-endpoint)
and [models.json reference](https://pi.dev/docs/latest/models-configuration)
describe those fields.

A working text response is the first check. The game also needs the selected
model to call tools correctly; the server connection test checks that.

## 3. Use Pi's built-in MCP support

Current Pi supports stdio and Streamable HTTP MCP servers. An additional
`pi-mcp-adapter` package is not required. Pi's native configuration uses
`~/.pi/agent/mcp.json` and trusted project `.pi/mcp.json` files. An extension
that replaces `/mcp` also replaces the built-in support. See
[Pi MCP servers](https://pi.dev/docs/latest/mcp).

The current `pi-acp` adapter stores MCP descriptors received through ACP but
does not forward them to Pi. Its source also advertises HTTP MCP as unsupported.
This is an adapter limitation, separate from Pi's native MCP support. See the
[adapter limitations](https://github.com/svkozak/pi-acp#limitations) and
[initialization implementation](https://github.com/svkozak/pi-acp/blob/main/src/acp/agent.ts).

The game prepares its own native Pi MCP connection automatically.
You should not add a permanent game-tool URL or token to your personal MCP
configuration. It creates `.pi/mcp.json` in a temporary game-owned directory,
then removes the endpoint credentials when the operation ends.

Project configuration needs a trust decision. Pi's RPC mode cannot show the
interactive trust prompt, so a game-owned native FPAS launcher verifies that
directory's marker and starts Pi with process-scoped `--approve`. The game builds
and caches the launcher with PATH FPAS on first use; start from the repository
so its source is available. Do not change the global trust policy to trust every
directory. See [Pi project trust](https://pi.dev/docs/latest/security#project-trust-without-an-interactive-prompt).

## 4. Select Pi in the game server

Use the server console:

1. Start the server from the game repository root:

   ```powershell
   fpas run apps/server/server.fpasprj -- --console
   ```

2. Open **F2 -> Settings -> Gamemaster** and select **Pi**.
3. Browse models with arrows, use Previous/Next for more pages, and press Enter
   to apply the exact highlighted model.
4. Use **Test connection** to check the selected model and a harmless game-tool
   call. This sends a real model request and can consume provider quota.
5. Save the settings. They apply to all worlds served from this data directory
   and are restored on server restart.

The user configures the agent and model. The game owns the tool endpoint,
its temporary connection details and cleanup. No separate MCP server process
or manual game-tool setup is part of this workflow.

Without a configured connection, the server warning points back to
`fpas run apps/server/server.fpasprj -- --console`. Headless operation uses
the configuration saved through that console.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Pi or pi-acp cannot start | Verify the commands in the same environment that starts the server; restart that terminal after changing PATH. |
| No models are offered | Open Pi directly, check `/login` and `/model`, and verify the provider or local endpoint. |
| A local model disappears | Keep its model service running and its configured model loaded. Refresh the server's model list afterward. |
| Text works but the tool test fails | Check the model's tool-calling support and the managed MCP connection. An ACP handshake alone does not prove tool access. |
| Native MCP is unavailable | Check for an extension replacing `/mcp` or settings disabling built-in MCP; use the native configuration described above for the game connection. |
| RPC skips project MCP configuration | Check the integration's directory-scoped trust decision; see the trust documentation above. |

External setup details were checked against the linked documentation on
2026-10-26. Pi 1.4.0 and pi-acp 0.0.34 passed the live native-MCP route with a
local llama.cpp model; the [acceptance report](../architecture/gamemaster-connection-acceptance.md)
records the tested scope.
