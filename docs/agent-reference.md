# Game development rules

## Functional Pascal issues

This game showcases Functional Pascal. When development reveals a bug or a
missing language, runtime, tooling, or standard-library capability, stop and
report it with a minimal reproduction. With the user's agreement, fix it in the
[Functional Pascal repository](https://github.com/tobiasbick/functional-pascal)
with tests, or create a
[GitHub issue](https://github.com/tobiasbick/functional-pascal/issues/new).
Never work around it silently. Language or specification changes always need
the user's explicit agreement.

## Architecture and terminology

Before adding projects or changing module ownership, read the
[architecture overview](architecture/overview.md).
Game and architecture documentation belongs under `docs/`.

Use the canonical terms in [world structure and views](product/world-and-views.md).
Add newly established game terms there when they are missing.

The server is authoritative. The client only sends intentions and renders
projections.

## Compatibility and determinism

Runtime configuration files are current-version only. When their schema
changes, reject obsolete files with a clear error and instruct the user to
delete or recreate them. Keep defaults, documentation, and tests aligned with
the current schema.

World files, savegames, and the protocol carry a version. Any change to their
schema raises the version once per feature branch; obsolete versions are
rejected, never migrated.

Generated content (terrain, entrances, dungeons) is a pure function of the
world seed and stable identities. Any change to generated output raises the
world generator version and updates the fingerprint tests deliberately;
never adjust a fingerprint to make a test pass without that.

## Verification

- Format changed Functional Pascal files with `fpas fmt`, run `fpas check` for
  every changed project, and run the relevant test project, for example
  `fpas test --timeout 600 tests/game/game-tests.fpasprj`.
- Before handing work back, run the complete suite with
  `fpas test --timeout 600 dungeon.fpasworkspace`. Report failures with their
  output; do not call work done while the suite is red.
- Run long commands in the background and say so.

## Source documentation

Before committing Functional Pascal changes, verify that every changed `.fpas`
file starts with a concise purpose comment. Document each public type, constant,
function, and procedure with its role and any non-obvious invariants, ownership,
error, or lifecycle behavior. Keep comments synchronized with the interface and
omit comments that merely repeat the declaration.

## Git and plans

- Commit, merge, or push only when the user asks.
- Implementation plans for a feature branch live in `docs/plans/` on that
  branch and are deleted after the user accepts the feature.
- When a plan is given, follow its steps in order and ask before deviating.

## Privacy

Keep repository files, commits, and reports free of hostnames, usernames,
home directory paths, and other machine-identifying metadata.
