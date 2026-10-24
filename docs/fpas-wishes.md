# FPAS wishes

Language and tooling wishes collected while developing Into the Dungeon.
Entries describe proposals, not implemented features or confirmed compiler bugs.

## Entry values in postconditions: `old`

### Current behavior

FPAS supports `requires` and `ensures`, but has no entry snapshots or `old`
operation. Postconditions read current parameter values, including changes made
through `var`. Local variables declared in the routine body are outside their
scope. See the [FPAS contract reference](https://github.com/tobiasbick/functional-pascal/blob/main/docs/pascal/language/functions/contracts.md#postconditions).

### Motivation

A postcondition on a mutating routine cannot directly compare the result of a
change with the original value. For example, an increment operation should promise
that the final counter equals its entry value plus one. Checking only that the
final counter is positive would not express that guarantee.

This is a gap for routines with `var` parameters. Functional routines that accept
an unchanged value and return a replacement can already compare input and output.
Our client and server state transitions generally follow that pattern; `old` is
not a prerequisite for adding contracts there.

### Goal

Allow a postcondition to refer explicitly to the value of an expression captured
at routine entry. An illustrative proposal, unsupported by current FPAS:

```pascal
procedure Increment(var Value: integer);
ensures Value = old(Value) + 1;
begin
  Value := Value + 1;
end procedure;
```

The contract should distinguish the captured entry value from the final value,
including after early returns. A language design must specify capture timing
relative to preconditions, permitted expressions, and snapshot semantics for
records, collections and aliased storage. Capturing a resource handle must not
silently promise a snapshot of the external resource.

### Performance and validation

Capture only explicitly requested entry values. Routines without `old` should
not acquire snapshot work. Define and measure copying, retention and allocation
costs before adopting snapshots widely; no performance claim is established yet.

Start contract adoption at higher-level client and server transitions with small
field and status checks. Validate contracts in real client/server integration
flows as well as unit tests, and compare execution cost before extending them
to frequently called helpers.

## Completely disable contracts through the CLI

### Motivation

`requires` and `ensures` currently execute in every build mode. Initial
[application-boundary measurements](bench/contracts.md) found small absolute
client costs and server differences within timing noise. They required separate
source copies because the CLI cannot disable contracts. We need to compare the
same program with and without contract execution and choose whether to include
that work in a deployed build. Full interactive workloads and deeper contracts
still need measurement.

### Goal

Provide an explicit CLI parameter that completely disables both `requires` and
`ensures`. A possible name is `--no-contracts`; this is a proposal, not an
existing option. Keep contracts enabled by default.

When disabled, generate no contract checks or condition evaluation, no
contract-only branches or diagnostic preparation, and no entry snapshots for
`old`. Suppressing violations while still evaluating conditions is insufficient.
Contract expressions should still be parsed and type-checked.

Apply the selected policy consistently to the complete program, including
dependencies, indirect calls and compiled artifacts. Define its behavior for
`run`, `build`, `test` and `debug`, and prevent cached artifacts from silently
retaining checks that were requested to be disabled. Ordinary application
validation, `Result` handling and test assertions keep their existing behavior.

### Validation

Add integration coverage for enabled and disabled execution, source and compiled
programs, and dependencies. Verify that disabled contracts and `old` captures
are absent from generated executable code. Measure runtime and allocation costs
with the option enabled and disabled before making performance claims.
