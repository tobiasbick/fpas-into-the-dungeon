# Migration to current Functional Pascal

Target compiler and source standard library: Functional Pascal `afd7b258d`.
This plan applies to `feat/generated-dungeons`; the game's `main` branch keeps
its legacy sources and documents its compiler compatibility boundary.

## Scope

Migrate all tracked FPAS sources and documentation examples to the current
implemented language rules, including individual declarations, `const`/`var`,
typed construction, native operations, patterns, and exhaustive enum cases.
Preserve gameplay, protocol and persistence schemas, generator versions,
fingerprints, and existing failure handling.

## Verification

Use `fpas fmt --check apps libs tests tools`, `fpas check dungeon.fpasworkspace`,
and `fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace` with the target FPAS checkout's
`lib/` selected as the source standard library. No persistence or generator
version changes are part of this migration.
Use a release build of the compiler; the network tests keep their existing
30-second response limits.

## Previous migration to `269d8013`

- All 138 tracked FPAS sources pass the formatter check.
- All 20 workspace projects pass the compiler check.
- The complete workspace suite passes: 55 passed, 0 failed.
- A token and comment comparison against the original sources confirms that
  expressions, literals, and comments are unchanged. Differences are limited
  to syntax rules, explicit result discards, and binding the server accept task.
- Existing fingerprints, schema versions, and generator versions are unchanged.

## Progress for `afd7b258d`

- [x] Inspect the current compiler, language reference, and workspace diagnostics.
- [x] Migrate individual declarations, immutable bindings, and parenthesized Result types.
- [x] Replace record literals, native helper calls, and implicit pattern bindings.
- [x] Make closed-enum coverage and caller mutation explicit; preserve parameter value semantics.
- [x] Update the documented compiler requirement and current examples.
- [x] Format all sources, check all 20 projects, and run the complete workspace suite.
- [x] Review the diff for behavior preservation and record the verification results.

## Verification for `afd7b258d`

- Formatted and checked all 156 FPAS sources; 155 sources required changes.
- All 20 workspace projects pass `fpas check` with the matching source library.
- The source comparison preserves every numeric and string literal, comment,
  arithmetic, comparison, and Boolean operator, and assignment target.
- `git diff --check` passes. Protocol, persistence, and generator versions and
  expected fingerprints retain their original values.
- Initial sandbox run: 49 passed; 16 network tests could not connect to loopback
  sockets (Windows error 10013). The server admission test passes outside the
  sandbox.
- Debug build outside the sandbox: 63 passed; world client and lifecycle tests
  exceeded their existing response deadlines. Both unchanged tests pass with
  the current release build (31 seconds combined). No test deadlines were raised.
- Final release verification outside the sandbox: all 20 projects pass the
  compiler check; the complete suite passes **65/65 programs**, with no failures.
  This includes client rendering, protocol rejection, real TCP sessions, save/load,
  world generation and its unchanged fingerprints, and chunk caching.
