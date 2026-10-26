# 16a: Gamemaster connection and model selection

Status: **implemented and verified; user acceptance pending**.
Planning date: 2026-10-26. Branch: `codex/16-llm-integration`.
Base: accepted 15f on `main`, commit `347ebe2`.
Implementation and live tests were authorized by the user on 2026-10-26.

## Goal and acceptance

Configure the Gamemaster once in the server console: select Codex or Pi,
retrieve the agent's available models, choose one, test it and save the choice.
Every world served from that data root uses the same connection and model.
A server restart retains the choice. Starting without a configured connection
warns in console and headless modes and explains how to open the console.

The connection test must execute one harmless registered MCP tool through the
chosen model. A text response or ACP handshake is insufficient. Both Codex
and Pi must pass this route; unsupported capabilities must remain visible.

This is the first small stage of roadmap 16. Dungeon, NPC and village generation,
event selection, access to the full game state and transactional content drafts
will be planned in later substages. There is no player chat with the Gamemaster.
16a adds connection infrastructure and an explicit read-only diagnostic only.

## Confirmed product decisions

| ID | Decision |
| --- | --- |
| Q1 | The server starts Gamemaster work when game events need it; the player does not converse with the Gamemaster. Actual event jobs follow 16a. |
| Q2 | Initial connection choices are Codex through `agentclientprotocol/codex-acp` and Pi through `svkozak/pi-acp`. |
| Q3 | Select the connection first, then a model advertised by that connection. Do not hardcode a model catalog or silently substitute another model. |
| Q4 | One saved selection applies across worlds and saves within the server data root. It is not a client preference or a world/save field. |
| Q5 | Configuration is available in the server console started with `--console`. Headless operation loads the same saved settings. |
| Q6 | An unconfigured server warns in both modes and continues listening. Headless output includes the complete `fpas run ... -- --console` instruction. |
| Q7 | The game supplies embedded MCP tools automatically. The user configures the agent connection and model, not tool servers or temporary tokens. |
| Q8 | Use Pi's native MCP support. An additional Pi MCP adapter is not a prerequisite. The current ACP-to-Pi descriptor gap needs a managed native-config route. |
| Q9 | The main README links a permanent Pi setup guide. Clearly distinguish external setup available now from the planned game UI. |

## Baseline and dependencies

- The game is on `codex/16-llm-integration` with the accepted 15f code. Its
  published baseline is 177 test programs and 21 projects; these are prior
  results, not a new verification run recorded by this plan.
- Current versions: generator 13, world/chunks 4, dungeon level 4, settlement 3,
  savegame 15 and protocol 22. This stage requires none of those to change.
- [Runtime configuration](../architecture/runtime-data.md) is current-schema
  only. Its eight server fields and atomic updates are owned by
  [Dungeon.RuntimeData](../../libs/persistence/src/Dungeon/RuntimeData.fpas).
- [Server settings](../product/server-console.md) already use F2 and preserve
  world defaults through a modal. Headless and console output share
  [server logging](../../apps/server/src/Dungeon/Server/Logging.fpas).
- The installed FPAS and its matching standard library must expose `Std.Acp`,
  `Std.Acp.Types`, `Std.Mcp`, `Std.Proc` and `Std.Tasks`. Use `fpas` from PATH.
  Verify the actual public signatures before writing FPAS; do not reimplement
  ACP, JSON-RPC, MCP transport or a second tool-schema validator.
- FPAS documents both ACP convenience `RegisterTool`/`ServeTools` operations
  and standalone MCP publication through `Mcp.Create`, `RegisterTool`,
  `Publish`, `Access` and `Serve`. The latter does not require an ACP peer to
  advertise HTTP MCP.

## Adapter contract and the Pi compatibility gate

| Connection | Launch preset | Model selection | Game-tool connection |
| --- | --- | --- | --- |
| Codex | Installed `codex-acp` command | ACP session configuration | Client-supplied HTTP MCP descriptor during session setup |
| Pi | Installed `pi-acp` command, using installed Pi | ACP session configuration | Native Pi MCP configuration prepared by the game |

Keep launch executable, arguments, cwd and environment as separate values.
Resolve installed commands correctly on Windows, including npm launchers, and
surface a missing command with a setup hint. Do not download packages on server
startup. Existing provider authentication belongs to the agent installation;
16a does not add a credential store or automatic browser-login broker.

Pi supports native Streamable HTTP MCP. The current `pi-acp` source advertises
`mcpCapabilities.http = false` and retains incoming descriptors without passing
them to Pi. Do not attach the ACP convenience MCP server to this peer and
ignore the resulting capability error. Use standalone `Std.Mcp` publication
for the Pi route and keep the ACP session's descriptor list empty where required.

The game prepares `.pi/mcp.json` in its own managed session directory under
the runtime cache. The entry contains only the game's current endpoint and
authentication, with direct exposure for this small diagnostic tool set.
Arrange a supported, directory-scoped startup trust decision before Pi starts;
RPC mode cannot ask interactively. Never weaken the user's global trust policy
or overwrite their existing provider, credential or MCP configuration.

Checkpoint 01 must establish how the installed adapter starts Pi with that
trust decision while retaining the user's model configuration. Choose the
smallest supported launch/bootstrap route and record it before production
implementation. If the published combination cannot support the required
automatic route, bring back the concrete incompatibility before checkpoint 02.
Do not replace it silently with a custom ACP fork, another Pi MCP extension,
a prompt-only JSON tool loop or manual endpoint setup for the user.

## Planned configuration and UI behavior

### Persistent selection

Extend the current server TOML contract with exactly two fields:

```toml
gamemaster_connection = "none"
gamemaster_model = ""
```

- `none` with an empty model is the valid unconfigured default. `codex` or `pi`
  requires a nonempty, bounded model ID returned by that adapter. Preserve its
  spelling and case; display labels never become model identity.
- Reject unknown connection names, mismatched empty/nonempty combinations,
  wrong types, control characters and unknown fields. Missing new required
  fields identify an obsolete server configuration, with the existing clear
  recreate-config error. Do not migrate or silently rewrite it.
- A missing config file is created with the new unconfigured defaults. A valid
  unconfigured file warns; a malformed/obsolete file remains a startup error.
- Persist neither model lists, probe transcripts nor readiness. Save the two
  fields atomically with the other current settings. Updating world defaults
  preserves the Gamemaster selection and updating the selection preserves the
  endpoint, selected-world default and viewport/cache settings.
- Model discovery, cancellation, failed tests and failed writes cannot change
  the published selection. Clearing a connection saves the unconfigured pair.
- On startup, load the saved pair without a paid test request. A configured
  selection is not claimed to be currently reachable until checked. Loading
  validates its shape; catalog membership is rechecked during discovery,
  without contacting the provider merely to parse the configuration.

### Server console

Extend **F2 -> Settings** with a **Gamemaster** section:

1. Choose **Codex** or **Pi**. Start cancellable model discovery in background.
2. Show the advertised model choices once connected. Keep opaque model IDs
   separate from labels and retain the exact saved selection when still offered.
3. **Refresh models** repeats discovery. A removed model becomes unavailable;
   the UI requires another explicit choice rather than selecting a substitute.
4. **Test connection** applies the selected model and runs the diagnostic tool
   round trip. Label that this is a real model request and may consume quota.
5. **Save** publishes a complete selection after successful setup/model
   acknowledgement. A successful tool test is shown separately and is not
   silently performed by Save. **Cancel/Escape** discards the draft.

Changing the connection clears that draft's model and test result. Save is
disabled while discovery or model selection is unresolved. A changed draft
invalidates any older asynchronous result. Closing settings or stopping the
server cancels and joins its owned work. The console remains responsive during
discovery, a slow local-model start and cancellation.

Show **Not configured**, **Configured**, **Testing**, **Ready** or a concise
failure reason. Ready means a successful probe for the current connection and
model in this server lifetime. A saved but unchecked selection is Configured.
Test status is transient; it does not belong to a world or savegame.

### Startup warnings and help

Emit one warning per unconfigured server startup through the shared logging
path, after the console log consumer exists when using the dashboard:

```text
Gamemaster is not configured.
Configure it in the server console:
fpas run apps/server/server.fpasprj -- --console
```

In console mode also show the Not configured status and the F2 setup hint.
Headless output must preserve the complete command, including `-- --console`.
Include a reminder to reuse a custom `--data-dir` so users configure the same
server instance. Extend the warning severity mapping explicitly rather than
misclassifying it as a rejected player action or an info event.

Warnings do not start agent/model processes, change world selection or prevent
ordinary game connections. `--help` still exits before runtime initialization;
its server help explains that Gamemaster settings are edited with `--console`.
Explicit discovery/test failures identify command, authentication, model,
capability, MCP, timeout or process-exit problems without exposing credentials.

## Probe, ownership and lifecycle

- Register one read-only diagnostic tool, `gamemaster_probe`. It accepts a
  bounded nonce and returns that nonce plus a fixed service acknowledgement.
  It reads and writes no world, save, character or gameplay resources.
- For Test connection, allocate a fresh nonce and ask the selected model to
  call that tool. Success requires the server-observed matching callback and
  successful completion of the ACP prompt. Do not match prose or accept a
  claimed tool call in an assistant message as proof.
- Offer the same schema and handler to both adapters. Keep only the endpoint
  delivery route adapter-specific. The eventual game tools will use this seam.
- Own ACP reception, MCP serving and the agent process in a cancellable task
  group. A single task receives ACP events; keep provider I/O out of the TUI
  update function. Bound queues and ignore results from superseded drafts.
- One discovery/test operation runs at a time. Plan defaults of 60 seconds
  for setup/model discovery, 180 seconds for the explicit probe and five
  seconds for graceful cleanup before owned-process termination. An operation
  is not retried automatically and may be cancelled earlier.
- Retire the probe endpoint, invalidate its nonce and clean managed credentials
  on every terminal path, including close, cancellation and failed setup.
  Stale endpoints cannot make a later test succeed. Never log HTTP credentials,
  auth files, environment dumps or complete agent transcripts.
- Use a minimal server-owned cwd, distinct from worlds, saves and the source
  checkout. Existing agent OS capabilities are not a game-data authorization
  mechanism; game state remains owned by the server.

## Ownership and planned files

Follow the [architecture overview](../architecture/overview.md) and keep files
focused. Add no general AI framework or shared client AI library for one server.

| Owner | Work |
| --- | --- |
| `libs/persistence`, `Dungeon.RuntimeData` and a focused settings subunit if needed | Current-schema decoding, defaults and atomic preservation of the global selection |
| `apps/server`, `Dungeon.Server.Gamemaster` and focused connection/model/Pi subunits | Presets, ACP session, standalone MCP diagnostic, Pi bootstrap, cancellation and typed status |
| Existing server console Model/Input/View with a focused Gamemaster settings unit | Draft state, selectors, background commands, result revision checks and status presentation |
| Existing startup and logging units | One shared startup warning, severity mapping and CLI help |
| `tests/runtime` | Config acceptance/rejection and atomic preservation |
| `tests/server` and its internal project where appropriate | Scripted peer, real tool transport, lifecycle, console input/rendering and startup output |
| `docs/setup/pi.md`, server-console/runtime-data guides, README and roadmap | Permanent setup/behavior, current support evidence and acceptance state |

Reuse the installed `Std.Acp`/`Std.Mcp` public APIs. A concrete FPAS defect is
reported with a minimal reproduction under the repository rules, before any
compiler/runtime repair. Do not hide it in game-specific protocol code.

## Ordered implementation checkpoints

Run these in order. Record actual evidence under Implementation progress;
planned checkpoints are not proof that any production behavior exists.

### 01. Verify adapters, native Pi MCP and the accepted baseline

- Inspect the matching PATH compiler/library and record versions of FPAS,
  Codex adapter, Pi adapter and Pi without private machine metadata.
- Prove the automatic Pi native-MCP/trust route and a Codex descriptor route
  with the same harmless tool. Verify model choices and exact model selection.
  Use a small FPAS probe; do not modify the game or user-global configuration.
- Record the selected managed Pi bootstrap and cleanup contract. An installed
  adapter's unsupported route is a reported blocker, not a successful test.
- Run formatting, workspace checking and the complete existing game suite.

### 02. Add the global configuration contract

- Add the two current-schema fields and the typed unconfigured/selected value.
- Cover fresh defaults, malformed and obsolete files, exact model IDs,
  data-root independence, reciprocal settings preservation and write failures.
- Keep every gameplay format and client protocol version unchanged.

### 03. Implement connection and model discovery

- Add the two launch presets and cancellable ACP initialization/session setup.
- Read model choices from advertised configuration, including applicable
  grouped choices/updates; acknowledge an exact selected model before use.
- Surface missing installation/login, unavailable model, peer failure and
  unsupported capabilities. Stop owned work after failure or cancellation.

### 04. Add the shared embedded MCP probe and Pi delivery

- Register the one read-only tool through `Std.Mcp` with a bounded handler.
- Implement the proved Codex and native Pi endpoint-delivery paths, with
  run-owned authentication and no manual user MCP setup.
- Prove a real callback, wrong/stale nonce rejection, tool failure, timeout,
  cancellation and cleanup. An empty/ignored descriptor cannot count as success.

### 05. Build the console selectors and explicit test flow

- Add the Gamemaster settings draft, model list, refresh, test, save and clear.
- Preserve keyboard navigation, log controls and existing world-default fields.
- Test narrow/short layouts, loading/error states, disconnect, Escape/stop,
  delayed results after selection changes and failed settings publication.
- Make test requests explicit; discovery and startup make no model prompt.

### 06. Wire startup status, warning and headless help

- Add the common warning/status path and server help text.
- Exercise fresh unconfigured and configured starts with and without console,
  a custom data root and `--help`. Check the full console-start command.
- Prove that warnings leave listener startup and ordinary game access working.

### 07. Verify integrated behavior without provider accounts

- Use scripted ACP peers and the real embedded MCP transport for model lists,
  selection updates, exact tool calls and process/cancellation failures.
- Exercise atomic Save, restart, both world-selection contexts and switching
  connections while old results are delayed. Compare unrelated settings and
  existing world/save bytes before and after the diagnostic.
- Do not duplicate FPAS's protocol-schema suite. Test game-owned policy and
  integration through existing production boundaries, without test-only APIs.

### 08. Accept Codex and Pi with a local model

- Run the real server-console route with an authenticated Codex installation.
- Run the same route with `pi-acp`, current native-MCP Pi and an existing local
  tool-capable model. No cloud fallback may substitute for the local model.
- Save, stop/restart and verify the exact selection. Cancel a test and stop
  the server during work; confirm processes and endpoint rights are retired.
- Record actual adapter/model versions, outcomes and bounded timing, separating
  live results from scripted tests. A missing local model leaves this check
  pending; both adapters are required for completion.

### 09. Align documentation and prepare user acceptance

- Update the permanent Pi guide and server-console/runtime-data contracts to
  actual implemented behavior; remove their planned-only labels when true.
- Record the supported adapter versions and real acceptance evidence. Update
  README and roadmap without claiming later generation features are present.
- Run `fpas fmt --check apps libs tests tools`,
  `fpas check dungeon.fpasworkspace` and
  `fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace`.
- Retain this plan until the user accepts 16a. Then keep the permanent guides
  and acceptance evidence, replace incoming plan links with those permanent
  documents and delete the temporary implementation plan.

## Acceptance matrix

| Scenario | Required outcome |
| --- | --- |
| Fresh config, headless startup | Listener starts, one warning explains the complete console command |
| Fresh config, console startup | Warning is visible; F2 leads to the unconfigured Gamemaster settings |
| Codex / Pi selection | Agent's model list appears; exact chosen ID is acknowledged |
| Explicit test for either adapter | Matching server-side MCP callback and completed prompt; no gameplay effect |
| Pi with local model | Native MCP works through the managed route; no extra adapter package or cloud substitute |
| Model missing or adapter broken | Specific error, no silent substitution and no changed saved selection |
| Save, restart, another world | Same global selection; existing gameplay data and other settings retained |
| Slow result after edit/cancel | Superseded result cannot alter the draft, readiness or stored config |
| Stop during setup or test | Owned tasks/processes join; old endpoint credentials and nonce are unusable |
| Clear configuration | Defaults restored atomically; status and subsequent startup warning agree |

## Research sources

External adapter details were inspected on 2026-10-26. Recheck them in
checkpoint 01 and pin the actual verified versions in acceptance evidence.

- [Codex ACP adapter](https://github.com/agentclientprotocol/codex-acp): installed
  command, model configuration and client-supplied MCP support.
- [pi-acp](https://github.com/svkozak/pi-acp): setup and adapter limitations.
- [pi-acp initialization and model configuration](https://github.com/svkozak/pi-acp/blob/main/src/acp/agent.ts):
  capability advertisement, retained descriptors and model config options.
- [Native Pi MCP](https://pi.dev/docs/latest/mcp): native server configuration.
- [Pi project trust](https://pi.dev/docs/latest/security): noninteractive startup.
- [Pi setup guide](../setup/pi.md): installation and model preparation for users.

## Planning verification

On 2026-10-26, local Markdown targets and whitespace checks passed. The existing
FPAS documentation audit checked 61 local links across the changed documents.
The complete existing game suite also passed with PATH FPAS:

```text
fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace
Summary: 177 passed, 0 failed (177 total)
```

This verifies the unchanged gameplay baseline during documentation work;
it does not execute or accept the planned Gamemaster integration.

## Implementation progress

### Checkpoint 01 — complete

- The unchanged baseline suite passed: 177/177 programs. Workspace checking
  also passed with PATH FPAS.
- Installed adapter combination: Codex ACP 2.3.0, Pi ACP 0.0.34 and Pi 1.4.0.
  Separate live probes selected `gpt-6-luna` and `llamacpp/qwen3.5` and observed
  actual callbacks through the same `gamemaster_probe` tool.
- Pi's managed route is a native FPAS launcher that passes `--approve` to Pi
  only after verifying its session marker. It inherits the adapter's RPC pipes.
  The private cwd contains `.pi/mcp.json`; no global trust or provider setting
  changes. Codex receives the HTTP descriptor in `session/new`.
- Cleanup exposed an FPAS scheduler defect after hosted callbacks: the MCP
  serving task's next wait was discarded instead of parked. The user authorized
  its repair and distribution rebuild. A normal-worker regression failed before
  the repair with `callback completed` / `server closed` and now passes including
  `worker joined`. Full FPAS checks and the first distribution rebuild passed.

The distribution rebuild succeeded, including 123 compiled standard-library
units. Both live probes then exited successfully: Codex Luna 9,310 ms and local
Pi Qwen 6,359 ms for the model request, with verified callbacks and joined MCP
workers. Baseline formatting also passed before checkpoint 02.

### Checkpoint 02 — complete

Added the mandatory connection/model pair and atomic read/write API. The runtime
suite passed 3/3 programs, including new global selection, independent roots,
reciprocal defaults preservation, invalid/obsolete input preservation and failed
write checks. Gameplay formats and client configuration are unchanged.

### Checkpoint 03 — complete

Added installed-command resolution, grouped advertised model catalogs and a
single-reader ACP session boundary. Setup has a 60-second bound; exact model
acknowledgement is required. Discovery sends no model prompt.

The grouped-catalog test passed. A live run through the production preset and
session units advertised 7 Codex and 43 Pi choices and acknowledged the exact
requested IDs for both agents without prompting a model.

### Checkpoint 04 — complete

The shared nonce-bound tool and operation owner are implemented, including a
cached native FPAS Pi launcher built with PATH FPAS. Production operation probes
passed with real callbacks, exact acknowledgement and complete cleanup: Codex
Luna 4,548 ms and local Pi Qwen 15,599 ms for the explicit model request.

The real MCP transport test rejects a previous run's nonce without producing a
receipt, accepts the current nonce and rejects access after close. A live Pi
operation was cancelled through a task group, joined within the bound and left
no temporary session/credential directory.

### Checkpoint 05 — complete

F2 settings now open the connection/model UI. Arrow keys browse, Enter applies
an exact model, Refresh reloads the catalog, Test explicitly sends a real model
request, and Save atomically publishes the acknowledged pair. A dedicated
single-slot result channel keeps provider I/O outside update/rendering. TUI
subscriptions serialize replacement and cancellation; revision checks reject
late results. The headless input/render test passed with loading, stale results,
failed Save, removed models, clear/save and multiple terminal sizes.

### Checkpoint 06 — complete

The listener's common logging path emits an explicit warning after listening
starts. Both console and headless entrypoints supply the loaded global choice.

Actual headless starts, console listener events and ordinary client handshake /
catalog requests passed. The warning is emitted once and preserves the full
console command and custom-data-root reminder. A configured unavailable model
does not trigger an agent query on startup. Help still exits before runtime I/O.

### Checkpoint 07 — complete

Scripted FPAS ACP processes use real MCP HTTP transport through both descriptor
and native Pi config delivery. Success requires both the callback and a completed
turn. Negative cases cover text-only claims, wrong nonces, failed turns, wrong
model acknowledgement, model changes during the request, process exit and a
bounded timeout. Removed models return the new catalog without substitution.

### Checkpoint 08 — complete

The production console application was driven with native terminal-key events
using the normal-worker TUI host. Both Codex/Luna and Pi/local-Qwen passed model
selection, exact acknowledgement, the real tool test, Save, stop/restart and
retention. Pi also passed Escape during work and application close during work.
The native key route exposed an Enter handling omission; its owner test failed
before the game-side repair and passed afterward.

The authorized local Pi setup preserved personal provider/credential/trust
settings, backed up the old local server configuration before an explicit schema
update, and selected/saved `pi` / `llamacpp/qwen3.5` through this console route.
World/save JSON bytes stayed identical.

The first server-console DAP attempt blocked before listening. A task-only
control passed outside the sandbox; adding cancellable network acceptance
reproduced a debugger timeout. The user separately authorized its FPAS repair.
The new all-stop network regression now passes, including peer reads/writes and
cancelled nested-group cleanup. A native-ownership test also verifies joining
abandoned waits and closing undelivered accepted sockets. The full FPAS workspace
tests, build, formatting and VM-library Clippy checks passed. The additional
`dist.ps1` run published the binaries and 123 standard-library units.

With that PATH distribution, both Codex/Luna and Pi/local-Qwen passed the original
server-console DAP route: listening, exact model acknowledgement, actual tool
test, Save, restart, retained selection and cleanup. The DAP route used a small
terminal viewport; the normal-worker console route verified initial selection
and readable layouts. Both approved FPAS repairs are complete.

### Checkpoint 09 — complete

Permanent connection, setup, console, runtime and architecture documentation is
aligned. The final complete game suite passed 183/183 with the rebuilt PATH
distribution, including the pre-dispatch cancellation regression. Formatting and
checks passed for all 22 workspace projects and the separate scripted ACP peer
project. An FPAS helper checked 98 local Markdown targets and confirmed the saved
local Pi/Qwen selection without temporary operation credential directories.
Setup, prompt and elapsed-time budgets use the monotonic clock. The plan remains
until user acceptance.
