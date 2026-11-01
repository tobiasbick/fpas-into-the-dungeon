# Set up OpenCode for the Gamemaster

OpenCode provides ACP directly through `opencode acp`. It uses JSON-RPC over
stdio; no separate ACP adapter or running HTTP service is required. See the
[official ACP documentation](https://opencode.ai/v2/docs/cli/acp/).

## Install and configure OpenCode

Install the CLI in the environment that starts the game server. The current
[OpenCode installation guide](https://opencode.ai/v2/docs) uses:

```powershell
npm install -g @opencode/cli
opencode --version
opencode auth login
opencode models
```

Choose and authenticate a provider in OpenCode before opening the game settings.
Credentials and provider configuration belong to OpenCode. The game stores only
the connection name and the exact advertised model ID.

The game resolves a native `opencode` executable on PATH. On Windows it also
resolves the native executable inside the current npm package `@opencode/cli`,
or the Node wrapper in the OpenCode 1 package `opencode-ai`, without invoking
a command shell. Restart the server terminal after changing PATH.

## Select OpenCode in the server

1. Start `fpas run apps/server/server.fpasprj -- --console`.
2. Open **F2 -> Settings -> Gamemaster** and select **OpenCode**.
3. Select an advertised model and press Enter to apply it.
4. Optionally run **Test connection**. This sends a real model request and may
   consume provider quota.
5. Choose **Save** to retain the connection and model for all worlds in this
   server data root.

The game passes its temporary, authenticated HTTP MCP endpoint through ACP.
OpenCode supports HTTP MCP descriptors and forwards their headers. A successful
test requires the actual `gamemaster_probe` callback and a completed model turn.
Model discovery alone does not verify tool access.

If OpenCode cannot start, check its installation in the server's environment.
If no models are offered or authentication fails, run `opencode auth login` and
check `opencode models` independently. Starting `opencode acp` directly in a
terminal waits for protocol messages; it does not open the interactive UI.
