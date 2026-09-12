# Project

This repository develops a role-playing game as a client-server application
with a terminal user interface (TUI). The game is written in Functional Pascal.

Functional Pascal resources:

- [Repository](https://github.com/tobiasbick/functional-pascal)
- [Language specification and documentation](https://github.com/tobiasbick/functional-pascal/tree/main/docs/pascal)
- [Formal grammar](https://github.com/tobiasbick/functional-pascal/blob/main/docs/specs/grammar.ebnf)

When development reveals a bug in Functional Pascal or a missing language,
runtime, tooling, or standard-library capability, create a
[GitHub issue](https://github.com/tobiasbick/functional-pascal/issues/new) with
a reproducible report.

Before adding projects or changing module ownership, read the
[architecture overview](docs/architecture/overview.md). Further game and
architecture documentation belongs under `docs/`.

## Functional Pascal source documentation

Before committing Functional Pascal changes, verify that every changed `.fpas`
file starts with a concise purpose comment. Document each public type, constant,
function, and procedure with its role and any non-obvious invariants, ownership,
error, or lifecycle behavior. Keep comments synchronized with the interface and
omit comments that merely repeat the declaration.
