# Migration to current Functional Pascal

Target compiler and source standard library: Functional Pascal `269d8013`.
This plan applies to `feat/generated-dungeons`; the game's `main` branch keeps
its legacy sources and documents its compiler compatibility boundary.

## Scope

Migrate all tracked FPAS sources and documentation examples to the implemented
AP13 block rules, AP07 Boolean rules, and AP04 explicit result consumption.
Preserve gameplay, protocol and persistence schemas, generator versions,
fingerprints, and existing failure handling.

## Progress

- [x] Document the legacy compiler boundary and current development branch on `main`.
- [x] Migrate statement terminators, declaration and expression endings, control blocks, and case arms.
- [x] Preserve Boolean grouping and consume every standalone function result.
- [x] Update the compiler requirement and documentation examples.
- [x] Check formatting and all workspace projects with the target compiler and matching library.
- [x] Run the complete dungeon workspace test suite and inspect the migration diff.

## Verification

Use `fpas fmt --check apps libs tests tools`, `fpas check dungeon.fpasworkspace`,
and `fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace` with the target FPAS checkout's
`lib/` selected as the source standard library. No persistence or generator
version changes are part of this migration.

## Results

- All 138 tracked FPAS sources pass the formatter check.
- All 20 workspace projects pass the compiler check.
- The complete workspace suite passes: 55 passed, 0 failed.
- A token and comment comparison against the original sources confirms that
  expressions, literals, and comments are unchanged. Differences are limited
  to syntax rules, explicit result discards, and binding the server accept task.
- Existing fingerprints, schema versions, and generator versions are unchanged.
