# AGENTS

Into the Dungeon is a client-server role-playing game with a terminal user
interface, written in Functional Pascal.

Before writing Functional Pascal, read the
[FPAS language reference](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/agents/README.md).
Before changing this repository, read the
[game development rules](docs/agent-reference.md).

## Code

- Keep files focused on one concern and usually below 500 lines.
- Group related files in directories by topic.
- Write all code comments in English.
- Before proposing a new public `Std.*` unit in a plan, follow the
  [FPAS namespace specification](https://github.com/tobiasbick/functional-pascal/blob/main/docs/specs/std-namespaces.md).

## Approach

- Prefer clear rewrites over layers of patches.
- Less is more: keep solutions small and simple. Remove unnecessary code.
- This is a hobby project for fun. Backward compatibility and historical
  implementation notes are not required.
- Make architecture and implementation decisions autonomously within the game
  development rules. Internal APIs, data structures, and existing designs may be
  rewritten, reorganized, or replaced.
- Fix errors when you encounter them. Do not dismiss errors as pre-existing.

## Before every commit

- Inspect the exact staged changes, file names and full contents of every file
  being committed for secrets, credentials, personal data and machine-specific
  information. Include API/private keys, tokens, passwords, personal contact
  details, host/user names, private addresses and machine-specific paths or IDs.
- If any such data is found, do not commit. Remove or anonymize it and repeat
  the complete review before committing. Never print sensitive values in reports
  or logs.

## Dogfooding

- Write helper scripts in FPAS instead of Python, JavaScript or shell logic.
- Debug FPAS programs with
  [`fpas debug`](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/tools/debugger-batch.md):
  one run to a breakpoint or failure, one JSON result.
- Investigate performance with
  [`fpas run --profile`](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/tools/profiler.md)
  before writing external samplers or benchmark variants.
- Record gaps that force a fallback or make FPAS awkward in
  [FPAS dogfooding gaps](https://github.com/tobiasbick/functional-pascal/blob/main/docs/future/dogfooding-gaps.md).
