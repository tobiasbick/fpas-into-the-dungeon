# Runtime cost of game contracts

Measured on 2026-10-24 at game commit `b511a857295ffda2d57be2686ef56d265c3afb30`.
The production source is unchanged.

The small contracts are measurable on cheap client updates. They add about
0.13–0.44 microseconds per call in these workloads. The server results are within
the observed timing noise. This supports keeping the current scalar checks at
the application boundaries; it does not establish the cost of deeper contracts.

## Unprofiled measurements

Nine pairs per row, alternating enabled/disabled order. Times are medians of
whole batches in milliseconds. Relative overhead is the median of paired ratios;
per-operation overhead is the median paired time difference divided by batch size.
These statistics need not equal a ratio or difference of the displayed medians.

| Workload | Operations per batch | Enabled ms | Disabled ms | Paired overhead | Extra microseconds per operation |
| --- | ---: | ---: | ---: | ---: | ---: |
| Client constructor | 120,000 | 490 | 475 | +3.16% | +0.125 |
| Client tick, 80×24 map | 600,000 | 731 | 595 | +22.93% | +0.227 |
| Client tick, 240×120 map | 600,000 | 732 | 597 | +22.17% | +0.222 |
| Client save acknowledgement, 80×24 | 120,000 | 633 | 582 | +9.09% | +0.442 |
| Client save acknowledgement, 240×120 | 120,000 | 633 | 582 | +8.95% | +0.433 |
| Client stale event, 80×24 | 1,200,000 | 1,048 | 774 | +35.27% | +0.228 |
| Client stale event, 240×120 | 1,200,000 | 1,047 | 763 | +36.86% | +0.236 |
| Server wait turn | 1,000 | 1,545 | 1,541 | +0.26% | unresolved |
| Server viewport update | 1,000 | 934 | 932 | +0.43% | unresolved |
| Server game installation | 500 | 666 | 667 | −0.15% | unresolved |

Across individual server A/B pairs, ratios ranged from −0.90% to +1.37%.
Nine A/A viewport pairs using the identical enabled image had median 0.00%
and ranged from −0.43% to +3.42%. The negative installation result is noise,
not evidence that contracts make it faster. There is no reliable server time
estimate at the measured scale.

Increasing retained client map cells from 1,920 to 28,800 did not produce a
visible increase in the contract delta in these samples. Rows are immutable
shared values; this comparison does not cover arbitrary aggregate contents.

## Profiler evidence

Profiling was run separately from the timing series. Both variants used the same
runtime settings: 23 workers and default collection thresholds 4096/8192/256.
Sampling used batches of at most 256 steps; counters were exclusive. The
different executable digests are intentional: only the seven game contract
blocks are removed in the disabled source copy. Standard-library contracts remain
enabled in both variants.

| Path | Extra dispatched VM steps per call |
| --- | ---: |
| `Client.NewClientModel` | 15 |
| `Client.UpdateClient` | 27 |
| `Client.UpdateConnectionEvent` → save acknowledgement | 44 |
| `Client.UpdateConnectionEvent` → stale event | 35 |
| `Handling.HandleSessionMessage` → wait turn | 27 |
| `Handling.HandleSessionMessage` → `Replies.ChangeViewport` | 57 |
| `Worlds.Replies.InstallGame` | 26 |

Counts account for warmup calls and the one extra client constructor in setup.
Server step-count increases are about 0.016%, 0.052%, and 0.017% of the full
profiled workload respectively. Scheduling steps are not CPU cycles or exact
allocation counts. Profiled milliseconds were not mixed with unprofiled timings.

## Method and validation

- Compiler: `fpas` from PATH, game-associated FPAS binary, version 0.0.1.
  Build identity: `source-91082da1597526321609cf814d36973b9de95f52151bfda7a3d146818966c5aa`.
  Executable SHA-256: `4269D40561A572EEBC0B014F918BDB1C8C318199BD003C9F377D8E4503CD1E0C`.
- Native Windows execution of prebuilt `.fpascp` images. No compilation, process
  startup, source copying, fixture generation or socket setup in timed batches.
- `prepare.fpas` copies the current sources and manifests into fresh `on`/`off`
  trees. It removes exactly seven contract blocks only in `off`, preserving line
  positions. The client remains a library dependency. Server internals use the
  same source inclusion arrangement as the internal integration tests.
- Warmup: 200 client calls or five server calls before each timed batch.
- Client: real public facade, retained map rows, no terminal rendering or request
  transport. Save events traverse both the scoped and raw event boundaries.
  Stale events exercise the early-return contract path.
- Server: real dispatcher/projection/serialization and actual loopback TCP
  replies, using the independent 11×9 dungeon fixture without hostiles.
  Each operation receives the same initial session. A bounded log channel avoids
  terminal output in installation timings. No save/load disk I/O is measured.
- All paired checksums matched. Separate compiled caller controls rejected
  invalid generation and viewport inputs with FP5010 only in `on`; valid inputs
  succeeded in both. Separate verification builds confirmed six complete,
  successful state replies match byte-for-byte for each server scenario.
- An optional batch-debugger inspection reached its 30-second deadline during
  fixture metadata generation; it supplies no performance or verification data.
  Normal native runs and the separate validation completed successfully.

These are controlled application-boundary workloads, not a full interactive
client/server frame-rate or production-load benchmark. They do not cover `old`
snapshots, recursive invariants, large saves, combat-heavy worlds, or concurrent
sessions. The compiler still has no CLI contract-disable option; the disabled
image is an experimental source variant only.

## Evidence and local helpers

The recorded timing data is versioned with this report:

- [Nine A/B pairs for each workload](contracts/measurements.csv).
- [Nine A/A viewport control pairs](contracts/control.csv).

The one-off FPAS helpers and individual JSON profiles remain in the local,
ignored `.temp-data/contracts-measure/` directory; they are not part of a fresh
checkout. Where those helpers are present, run from the game repository root
using the same FPAS binary:

```text
fpas run .temp-data/contracts-measure/prepare.fpas
fpas run .temp-data/contracts-measure/measure.fpas -- 9 .temp-data/contracts-measure/new-measurements.csv
fpas run .temp-data/contracts-measure/measure.fpas -- 9 .temp-data/contracts-measure/new-control.csv on server-viewport
fpas run .temp-data/contracts-measure/report.fpas -- .temp-data/contracts-measure/new-measurements.csv
fpas run .temp-data/contracts-measure/validate.fpas
```

`prepare.fpas` expects fresh variant directories. Use its `refresh` argument to
recopy sources and rebuild existing local variants deliberately. Profile report
destinations and measurement CSV paths must be new; `profile.fpas` captures the
six remaining paths after the two initial client-tick profile runs.

Calibration data was excluded from all reported medians. The local JSON files
ending in `-profile.json` contain the individual profiles;
`client-on-profile.json` and `client-off-profile.json` are the client-tick pair.
