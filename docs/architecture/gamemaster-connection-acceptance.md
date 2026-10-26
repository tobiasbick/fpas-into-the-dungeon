# Gamemaster connection acceptance

Date: 2026-10-26. Branch: `codex/16-llm-integration`. User acceptance is pending.

## Live adapters

| Route | Verified installation | Selected model | Result |
| --- | --- | --- | --- |
| Codex ACP | `@agentclientprotocol/codex-acp` 2.3.0 | `gpt-6-luna` | Exact model acknowledgement, real MCP callback, completed turn and cleanup |
| Pi ACP / native MCP | `pi-acp` 0.0.34 / Pi 1.4.0 | `llamacpp/qwen3.5` through the existing local llama.cpp service | Same tool and completion checks, with no cloud substitution |

Separate operation-owner probes measured 4,548 ms for the Codex model request and
15,599 ms for the local Pi request. These are individual live calls, not a
throughput benchmark or a latency guarantee. The model catalog is discovered
afresh; observed catalog sizes changed during development and are not defaults.

The complete console route was then exercised with native terminal-key events
in FPAS's normal-worker TUI host. It runs the production `Console.Application`
lifecycle, real listener, update/view handlers, subscriptions, installed agents
and MCP publication. It does not inject catalogs, tool receipts or state edits.
Both routes passed connection/model selection, Enter acknowledgement, explicit
test, Save, stop, restart and retention of the exact selection. Readiness reset
on restart. Pi also passed Escape during a test and application close during
work, with joined operations and no remaining session credential directory.

After the debugger repair below, both installed adapters also passed the real
server-console route through DAP terminal input: listening, model acknowledgement,
tool test, Save, restart, retained selection and cleanup. This route used a small
terminal viewport to keep all-stop rendering bounded; the normal-worker route
above verified the readable console layouts and initial model selection.

The local server configuration was explicitly updated to the current schema
with its original file backed up, then Pi/Qwen was selected and saved through
the console route. Existing world/save JSON files retained their exact bytes.
Personal Pi defaults, providers, credentials and global trust policy were not
edited. Temporary endpoints and authentication were removed after each run.

## Automated coverage

- Current-schema persistence covers defaults, invalid/obsolete files, exact
  IDs, independent roots, reciprocal preservation and failed writes.
- Scripted ACP processes call the real MCP transport through descriptor and
  native Pi-config delivery. Negative cases include text-only claims, foreign
  nonces, failed turns, substituted acknowledgements, model changes while the
  original remains offered, process exit, timeout and a removed saved model.
  A pre-cancelled operation leaves ACP uninitialized and dispatches no request.
- Native TUI rendering/input covers delayed results, invalid focus guards,
  loading, failed publication, missing models, clear/save and multiple sizes.
  The Enter regression failed with native key input before its game-side fix.
- Actual headless starts and console listener events verify one warning, the
  full console command, custom-data-root guidance and working client handshake
  and world catalog access. Configured startup queries no agent/model.

The final complete game suite passed **183/183 programs** against the rebuilt
PATH distribution, including the pre-dispatch cancellation regression. Formatting
and checks passed for all **22 workspace projects** and the separate scripted ACP
peer project. An FPAS helper verified **98 local Markdown links**. The final run
is recorded in the retained [implementation plan](../plans/16a-gamemaster-connection.md).

## FPAS repairs found during integration

The first normal-worker regression completed an MCP callback and closed its
server but failed to join the serving worker. The scheduler now parks every
still-owned suspension after a hosted continuation. Its regression failed
before the repair and passed afterward, including both live agent lifecycles.
FPAS was rebuilt with `dist.ps1` and the game used the PATH distribution.

The initial server-console DAP run exposed blocking network acceptance in the
all-stop scheduler. A network-only reproduction timed out while the normal run
completed; the task-only control passed. The user authorized the separate
debugger repair and another distribution rebuild. Debugger network waits now
yield to the all-stop scheduler and resume with their result on the VM thread.
The regression covers cancelled acceptance in nested task groups and a real
peer's accept/read/write sequence. Ownership tests cover joining abandoned waits
and closing accepted sockets whose result was not delivered.

The debugger regression failed before the repair and passed afterward. The full
FPAS workspace tests, build, formatting and VM-library Clippy checks passed.
The final `dist.ps1` run published the binaries and 123 standard-library units.
The game checks and both live DAP routes then used this PATH distribution.
