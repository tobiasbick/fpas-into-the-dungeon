# AGENTS

Into the Dungeon is a client-server role-playing game with a terminal user
interface, written in Functional Pascal.

Before writing Functional Pascal, read the
[FPAS language reference](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/agent-reference.md).
Before changing this repository, read the
[game development rules](docs/agent-reference.md).

## Code

- Keep files focused on one concern and usually below 500 lines.
- Group related files in directories by topic.
- Write all code comments in English.

## Approach

- Prefer clear rewrites over layers of patches.
- Less is more: keep solutions small and simple. Remove unnecessary code.
- This is a hobby project for fun. Backward compatibility and historical
  implementation notes are not required.
- Fix errors when you encounter them. Do not dismiss errors as pre-existing.

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
