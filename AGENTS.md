# AGENTS

Into the Dungeon is a console-based text adventure with Unicode terminal art and a
large language model as the game master. The console interface uses the FPAS
TUI. The game area sits above the command input and a status bar with an Exit
action.

## Reboot

- Keep the first version focused on player commands, game master replies,
  and generated Unicode room art.
- Record current design decisions under `docs/`.
- Use the retained game development notes as background on the earlier
  version. [Game development notes](docs/agent-reference.md)

## Code and verification

- Read the language reference before writing Functional Pascal.
  [FPAS language reference](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/agents/README.md)
- Keep files focused and group related files by topic.
- Write code comments and documentation in English.
- Prefer small, clear implementations. Fix errors when you encounter them.
- Format and check changed FPAS projects and run the tests relevant to the
  change.

## Git and privacy

- Commit, merge, or push only when the user asks.
- Before committing, inspect the exact staged changes, file names, and full
  contents of each staged file for secrets, credentials, personal data,
  and machine-specific information.
- Remove or anonymize sensitive data and repeat the review before committing.
  Keep sensitive values out of reports and logs.

## Dogfooding

- Use FPAS for project helper scripts when it supports the task.
- Use the FPAS debugger to investigate failures and the profiler to measure
  performance. [Debugger](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/tools/debugger-batch.md) · [Profiler](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/tools/profiler.md)
- Record FPAS gaps that force a fallback or make a task awkward.
  [FPAS dogfooding gaps](https://github.com/tobiasbick/functional-pascal/blob/main/docs/future/dogfooding-gaps.md)
