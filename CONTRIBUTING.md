# Contributing

Thanks for contributing to Into the Dungeon.

This is an experimental, vibe-coded project. Its direction may change as the
game takes shape, so keep contributions small, focused, and easy to review.

## Ground rules

- Read [AGENTS.md](AGENTS.md) and the
  [architecture overview](docs/architecture/overview.md) before changing code
  or project structure.
- Follow the
  [Functional Pascal documentation](https://github.com/tobiasbick/functional-pascal/tree/main/docs/pascal)
  for implemented language behavior.
- Keep authoritative game rules in `libs/game` and out of the client and shared
  protocol types.
- Add or update tests for meaningful behavior.
- Use English for code, identifiers, comments, documentation, and commit
  messages.
- Keep pull requests focused and avoid unrelated refactoring.

When the compiler, runtime, tooling, or standard library behaves incorrectly or
lacks a required capability, create a reproducible
[Functional Pascal issue](https://github.com/tobiasbick/functional-pascal/issues/new).

## Verification

Once the Functional Pascal project manifests exist, format and check every
changed `.fpas` project and run its relevant tests. Include the commands and
results in the pull request.

## AI-assisted contributions

AI-assisted development is welcome here. Coding agents may open issues, write
code, tests, and documentation, and create commits in this repository.

Generated work follows the same standard as any other contribution: review the
diff, run the relevant checks, and take responsibility for the result.
