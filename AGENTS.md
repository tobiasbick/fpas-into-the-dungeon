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

Use the canonical terms in [world structure and views](docs/product/world-and-views.md).
Add newly established game terms there when they are missing.

## Configuration compatibility

Treat runtime configuration files as current-version only. When their schema
changes, reject obsolete files with a clear error and instruct the user to
delete or recreate them. Keep defaults, documentation, and tests aligned with
the current schema.

## Functional Pascal source documentation

Before committing Functional Pascal changes, verify that every changed `.fpas`
file starts with a concise purpose comment. Document each public type, constant,
function, and procedure with its role and any non-obvious invariants, ownership,
error, or lifecycle behavior. Keep comments synchronized with the interface and
omit comments that merely repeat the declaration.

## Privacy

Do not write hostnames, usernames, home directory paths, or other machine-identifying metadata into the repository (docs, bench history, skills, comments, commits, or reports).

## Core Priorities

1. One concern per file. Name files after the concern they implement.
2. Keep files focused and usually below 500 LOC. When a file grows past roughly 600 LOC, consider splitting it by sub-responsibility.
3. Prefer subdirectories over crowded top-level modules. Group related code by theme.
4. Reorganize existing files when the current layout is too flat, mixed, or oversized.
5. Reuse existing implementations. Do not duplicate logic.
6. Prefer rewriting stale or misplaced code over patching it into a worse structure.
7. Remove dead code created or exposed by your changes.

## Decision Protocol

Before implementing:

- State assumptions explicitly. If something is unclear, ask instead of guessing.
- If multiple interpretations exist, surface them instead of choosing silently.
- Prefer the simplest solution that fully solves the task.
- Define success in a verifiable way before changing code.

## Change Discipline

- Make the minimum change that solves the task.
- Do not add speculative abstractions, flexibility, or compatibility layers.
- Do not refactor unrelated code just because you noticed it.
- Remove dead code exposed by your change only, unless the user asked for broader cleanup.
- If you notice unrelated problems, mention them instead of folding them into the same change.
