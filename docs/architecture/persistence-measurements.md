# Persistence measurements: 14b

Measured on 2026-10-16. This is an automated persistence smoke check, separate
from the user's explicit acceptance of 14b on 2026-10-16.

## Scenario and timing boundaries

`tools/persistence-bench` creates a fresh world with seed 24680, entrance regions
of one chunk and cache limit 64. It visits 1, 10 or 100 dungeons, reveals each
entry, destroys alternating skeletons, carries at most 64 coins and transfers
each preceding sword to the next dungeon. The 14b scenario additionally retains
the guaranteed potion as `Consumed` in alternating dungeons; other potions and
finds stay on their original floors. These are constructed persistence fixtures,
not a timed gameplay/combat sequence.

Each of three rounds measures the complete `WriteSaveGame` and `LoadSaveGame`
operations separately with the monotonic millisecond clock. Decoding, strict
validation, level reads and atomic save replacement are included. Fixture
construction, initial entry and the current benchmark's exact encoded-state
comparison after load are outside both intervals. Every loaded entity, discovery
cell, visit, health and RNG value must match; a mismatch or invalid load aborts
the benchmark.
Initial entry separately measures generation, validation and immutable storage.

The compiler is the ignored game-local release snapshot built from FPAS
`33814ef3`, with its copied matching source standard library. Compiler SHA-256:
`71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.
The compiler repository remains untouched. Run from the game root:

```text
.temp-data/rat-toolchain/fpas run --std-lib .temp-data/rat-toolchain/lib tools/persistence-bench/persistence-bench.fpasprj -- 1 3
.temp-data/rat-toolchain/fpas run --std-lib .temp-data/rat-toolchain/lib tools/persistence-bench/persistence-bench.fpasprj -- 10 3
.temp-data/rat-toolchain/fpas run --std-lib .temp-data/rat-toolchain/lib tools/persistence-bench/persistence-bench.fpasprj -- 100 3
```

The same commands/compiler/library also measure a source-only archive of the
documented 14a baseline `f605c1c`, and final 14b source with the original
unchanged 14a benchmark as a control without consumed potion fixtures. Controls
use separate temporary trees
and fresh ignored data directories. For the final comparison, all scenarios
use one common ignored working directory on the workspace filesystem; project
paths and the matching library are absolute. No existing game data is altered.
Peak RSS is collected by Python `os.wait4` around each command: the largest process RSS
reported for the command and its waited descendants, including compilation,
not a sum of simultaneous processes.

## Results and investigation

All final runs complete successfully: three rounds each at 1 and 10 visits,
and two fresh runs of three rounds at 100 visits per scenario (36 save/load
rounds in total). The 100-visit order is 14a, floor control, consumed; then
consumed, floor control, 14a. The suite is stopped during these measurements.
Tables show medians; brackets show minimum–maximum at 100 visits, in ms.

| Scenario | Visits | Items / consumed | Save ms | Load ms | Save bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| 14a baseline | 1 | 3 / 0 | 3 | 2 | 1641 |
| 14a baseline | 10 | 30 / 0 | 24 | 24 | 14494 |
| 14a baseline | 100 | 300 / 0 | 425.5 [354–522] | 477.5 [355–535] | 143604 |
| 14b floor control | 1 | 6 / 0 | 3 | 2 | 2204 |
| 14b floor control | 10 | 54 / 0 | 27 | 26 | 18391 |
| 14b floor control | 100 | 539 / 0 | 548 [543–722] | 556.5 [550–643] | 182704 |
| 14b with consumed | 1 | 6 / 1 | 4 | 2 | 2155 |
| 14b with consumed | 10 | 54 / 5 | 27 | 26 | 18148 |
| 14b with consumed | 100 | 539 / 50 | 558.5 [553–569] | 542 [538–545] | 180281 |

At 100 visits, new contents retain 539 items and 200 opponents versus the
baseline's 300 and 158. The consumed save is about 25.5% larger than baseline,
and 2,423 bytes smaller than the same contents kept on the floor. Consumed
records keep their identity while omitting a floor coordinate. First entry
for the current scenario totals 4 ms / 49 ms / 486–565 ms at 1/10/100 visits
(about 4.9–5.7 ms per dungeon at 100); baseline 100-entry totals span 472–888 ms.
Largest process RSS including compilation is 66.4–67.5 MiB for the current
scenario, 64.6–65.2 MiB for baseline, and 60.6–60.8 MiB for the floor control.
This is not a measurement of the standalone VM heap.

The historic 14a figure was about 260 ms per operation at 100 visits. Its
same-session control is also slower and variable, so those old absolute values
cannot establish the size of a regression. Current medians are about 31% higher
for save and 14% for load than the final same-session baseline; ranges above
show substantial baseline variation. The content increase still has a measurable
cost. To locate it, temporary diagnostic programs use the same existing stored
100-dungeon states and public APIs, outside the benchmark, for three rounds:

| Scenario | Decode + self-contained validation | Read/decode/validate all levels | Pure full-state validation | Encode save |
| --- | ---: | ---: | ---: | ---: |
| 14a baseline | 66 | 123 | 173 | 15 |
| 14b floor control | 127 | 126 | 310 | 12 |
| 14b with consumed | 123 | 126 | 305 | 11 |

The first phase calls `DecodeSaveGameState`, which includes parsing and
`Areas.ValidateSaveShape`: self-contained state shape and canonical identity
checks. It does not isolate parser time. Phase medians are diagnostic and do
not sum to a complete save: writing also checks state shape and atomically
publishes the encoded file. The material increase is in decoding with
self-contained validation and pure full-state validation, while level reads
remain close. Source inspection confirms existing pairwise item uniqueness and
occupancy checks plus origin scans over all placements. They process about 80%
more items; these loops already existed in 14a. Terminal locations take the
non-floor branch rather than introducing another scan or generation. The
consumed scenario stays close to the floor control (save +2%, load −3%); it
does not explain the increase. Save/load still reads each visited level once
and never regenerates it, as separately traced in checkpoint 10.

No cache, optimization, validation shortcut or changed performance expectation
was introduced. The measurements locate and document the additional strict
content-validation work; they do not claim linear scaling to arbitrary visit
counts or a terminal latency guarantee.

Initial diagnostic runs included a 100-dungeon run overlapping the suite and
controls on a RAM filesystem while current data used the workspace filesystem.
Those timings are excluded from the final tables; the final runs above use a
common filesystem without a parallel suite. Temporary probes do not change
production sources, exports or manifests.

## 14c multi-level measurements

The benchmark now descends through every level of each visited dungeon, reveals
it, and climbs back before leaving, so each dungeon contributes three visited
levels. Medians of three rounds on 2026-10-17, monotonic milliseconds:

| Dungeons | Levels | Items / consumed | Opponents | First entries total ms | Save ms | Load ms | Save bytes |
| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 3 | 11 / 1 | 8 | 25 | 10 | 5 | 5472 |
| 10 | 30 | 103 / 5 | 80 | 249 | 71 | 69 | 50589 |
| 100 | 300 | 1022 / 50 | 800 | 2461 | 1651 | 1668 | 503101 |

First entries grow linearly at about 8 ms per level, including generation, the
round-trip check, and atomic storage. Two quadratic costs found during 14c were
removed: save validation parsed every other map identity in a nested loop, and
`OpenLevelForEntry` validated the whole state once more per transition.
Save and load still grow faster than linearly (2.3 ms per level at 30 levels,
5.5 ms at 300) through the existing pairwise item and identity checks noted
above; at 300 levels these cover three times the areas and twice the items of the
14b 100-visit scenario. No caching was added; this remains a measurement, not a
limit on visited levels.
