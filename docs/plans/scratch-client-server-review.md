# Scratch: client/server maintainability review

Status: pass 02 is BLOCKED by a reproduced FPAS compiler defect; R03/R04
remain open. R01, R02 and R08 remain closed (3/15 items). Pass 01 was committed
as `2c17456` and passed 94/94 programs. The pass 02 draft is not verified or
ready for acceptance. The user requested a co-authored checkpoint commit and
push on 2026-10-16; this does not close R03/R04 or authorize compiler changes.
Created on 2026-10-16 from the five-agent review of commit `3faf77e`.
This is a temporary tracking plan. Delete it after the agreed work is complete,
verified and accepted by the user. Retain lasting contracts in architecture or
product documentation rather than keeping this scratch file indefinitely.

## Scope and evidence

- Client/server correctness, ownership, extensibility, dead code and documentation.
- Review baseline: 43 client/server production FPAS files, about 10,200 lines.
- Publication required GitHub noreply email metadata for the three previously
  unpublished commits. The historical review baseline `3faf77e` corresponds to
  `bca346d`; pass 01 changed from `2d64d52` to `2c17456`. Their complete source
  trees are identical. Last-verified-pass references below use `2c17456`.
- The existing complete suite passed 91/91 programs before this review; it was
  not rerun for the static review. This does not close the findings below.
- R01 was additionally reproduced with the unchanged game-local compiler and
  matching library: 1,023 completed sessions, one task registration failure,
  and a server lifetime that still reported ready.
- Source locations below refer to the review baseline. Update references if
  implementation moves their responsibilities.
- Keep the compiler repository unchanged. Follow AGENTS.md if a language,
  runtime or library defect is discovered; the documented task-group limit in
  R01 is a game ownership/lifetime issue.
- The separate 14b manual terminal review and acceptance remain deliberately
  open. Completing this cleanup does not close that gate.
- Implementation is authorized in coherent passes. Each pass receives an
  independent subagent review and an update here. Commit and push still require
  a separate request.

P1: address before further feature expansion. P2: concrete correctness or
growth risks. P3: focused cleanup or documentation. Address P1 first; related
lower-priority items may share a coherent change without expanding scope.

## Findings and acceptance criteria

- [x] **R01 — P1: bound server worker lifetime and observe worker results.**
  [Server.fpas](../../apps/server/src/Dungeon/Server/Server.fpas), review lines
  262 and 307. The listener registers every session in one task group until
  shutdown. Completed children count toward its 1,024-child limit: one acceptor
  plus 1,023 sessions. The next registration ends the acceptor while the
  listener owner still reports ready. Ordinary returned acceptor errors also
  go unobserved and can produce an apparently successful server exit.
  Direction: use a bounded/persistent worker lifecycle and propagate worker
  completion/failure to the listener owner while preserving shutdown cleanup.
  Verify: more than 1,024 sequential short TCP sessions remain serviceable;
  an acceptor failure becomes observable and stops or fails the server cleanly.

- [x] **R02 — P1: keep the rendered world-list cursor valid.**
  [Client Worlds.fpas](../../apps/client/src/Dungeon/Client/Ui/Worlds.fpas),
  review line 279. A nonempty page can pass selection -1 to MakeList when the
  selected world is elsewhere or missing. Resize can also leave the cursor
  outside the shortened list. The TUI correctly rejects these values.
  Direction: reconcile the local cursor against displayed entries separately
  from authoritative world selection.
  Verify: actually render another page, a missing selection, an incompatible
  entry and a page shortened by resize. The existing mixed-catalog test does
  not render its problematic state.

- [ ] **R03 — P2: isolate requests and events between connection attempts.**
  [Client.fpas](../../apps/client/src/Dungeon/Client/Client.fpas), review line 74;
  [Session.fpas](../../apps/client/src/Dungeon/Client/Ui/Session.fpas), line 155.
  Channels live for the entire application. Cancel queues Disconnect and then
  cancels its consumer, allowing that request to reach the next connection.
  Already published old events can also reinstall an active game after cancel.
  Direction: give requests connection ownership and associate events with a
  connection attempt so stale replies are ignored.
  Verify: cancel during a pending response, reconnect, then successfully
  Continue/Start; inject a late old State. The current cancellation test drains
  Disconnect itself and never reconnects.

- [ ] **R04 — P2: close the client socket on every session exit.**
  [Network.fpas](../../apps/client/src/Dungeon/Client/Network.fpas), review
  lines 229, 232, 281, 313 and 341. Early try returns after connect bypass Close
  on failed writes or event publication, retaining connection resources.
  Direction: concentrate connection ownership around the session result and
  always close, preserving the original error if closing also fails.
  Verify: hello/request write failure, failed event publication, cancellation
  and normal completion all release the connection; repeated attempts work.

- [ ] **R05 — P2: unify candidate-preparation failure policy.**
  [Replies.fpas](../../apps/server/src/Dungeon/Server/Replies.fpas), review
  lines 99 and 218. PlayTurn rejects preparation failures with the installed
  session intact; CommitState propagates them to connection teardown. A valid
  outdoor step can therefore lose all unsaved progress when projection needs
  an unreadable boundary chunk. Viewport projection has the same fatal path.
  Direction: share preparation/rejection policy while keeping actual send
  failures fatal and state installation after a successful send.
  Verify: Move and Viewport preparation failures preserve the complete session
  and permit retry, matching the existing UseItem failure coverage.

- [ ] **R06 — P2: keep large inventories visible and navigable.**
  [Character.fpas](../../apps/client/src/Dungeon/Client/Character.fpas), review
  line 206; [Layout.fpas](../../apps/client/src/Dungeon/Client/Ui/Layout.fpas),
  line 39. All 64 possible entries render as unscrolled labels, while actions
  remain enabled for selections outside the terminal. The sidebar also renders
  an unbounded summary under a fixed height budget.
  Direction: a selection-following inventory window with visible controls,
  and a bounded quick-inventory summary. Correct the docking documentation.
  Verify: render a full inventory in a normal and small terminal, navigate to
  the final item, resize and refresh; selection and action remain visible.

- [ ] **R07 — P2: paginate before validating every world's complete save.**
  [Server Worlds.fpas](../../apps/server/src/Dungeon/Server/Worlds.fpas), review
  line 27; [Catalog.fpas](../../libs/world/src/Dungeon/World/Catalog.fpas),
  line 130. Every catalog page first inspects all worlds, including complete
  saves and all visited level files. Paging bounds the response, not the work.
  Direction: enumerate identities first and inspect the entries needed for the
  response/selection. Continue must retain full validation; avoid a speculative
  global cache or weakening classifications.
  Verify: many valid worlds with large saves; unrelated pages do not cause
  every off-page save/level to be reread. Existing 67-directory pagination
  coverage mainly uses incompatible entries and does not establish this.

- [x] **R08 — P2: order disconnect events before permitting reconnect.**
  [Server.fpas](../../apps/server/src/Dungeon/Server/Server.fpas), review line
  272; [Console Model.fpas](../../apps/server/src/Dungeon/Server/Console/Model.fpas),
  line 81. The old worker releases admission before publishing disconnected.
  A new connected/snapshot event can arrive first, then be cleared by the old
  disconnected event.
  Direction: finish the old session's completion events before releasing its
  permit, coordinated with R01.
  Verify: immediate parallel reconnect leaves the dashboard attached to the
  new connection. Existing tests wait for disconnected before reconnecting.

- [ ] **R09 — P2: retain detailed persistence failures in server diagnostics.**
  [Server Worlds.fpas](../../apps/server/src/Dungeon/Server/Worlds.fpas), review
  lines 557 and 678; [Failures.fpas](../../apps/server/src/Dungeon/Server/Failures.fpas),
  line 95. Save/load logging receives only sanitized client text, losing the
  original I/O or level cause. PersistenceFailureReason has no callers.
  Direction: use the existing detailed reason server-side and preserve the
  sanitized client response.
  Verify: failing save and load log the original cause, preserve existing data
  and the installed session, and disclose no host paths to the client.

- [ ] **R10 — P2: retain the exploration map across viewport responses.**
  [Events.fpas](../../apps/client/src/Dungeon/Client/Ui/Events.fpas), review
  line 23; [Ui.fpas](../../apps/client/src/Dungeon/Client/Ui.fpas), line 18.
  Resize queues Viewport; its State response closes the map overlay. The
  existing resize test artificially sets Pending and bypasses that path.
  Direction: retain response intent so a viewport refresh preserves the map,
  rather than extending an unrelated collection of overlay exceptions.
  Verify: real Resize -> Viewport -> State with a map displayed and with a map
  request pending; received map state remains coherent and the map stays open.

- [ ] **R11 — P3: separate world-lifecycle responsibilities.**
  [Server Worlds.fpas](../../apps/server/src/Dungeon/Server/Worlds.fpas), review
  line 253. The 718-line unit combines catalog construction, installation and
  Select/Create/Start/Load/Save handling. Request prerequisites are maintained
  in multiple dispatch layers, including guards bypassed by earlier dispatch.
  Direction: extract small responsible operations and place prerequisites with
  their owning handler. Read/update the architecture overview when ownership
  changes; preserve internal test seams and keep exports narrow.
  Verify: existing lifecycle, failure, dirty/discard and overwrite behavior
  remains covered. Avoid a new generic dispatch framework.

- [ ] **R12 — P3: share interior visibility/memory classification.**
  [Projection.fpas](../../apps/server/src/Dungeon/Server/Projection.fpas),
  review lines 198 and 343. First-person and exploration-map projections
  duplicate discovery classification and removal of remembered dynamic markers.
  Direction: share the field decision while retaining separate window geometry.
  Verify: existing rat/potion visibility cases still agree across both views;
  hidden and remembered fields disclose no dynamic entities.

- [ ] **R13 — P3: remove or resolve verified dead imports/state.**
  Fifteen unused aliases were found in nine production files: client entry
  Conv; Client.Model Tasks; Ui.Events AnimationUnit/WorldsUnit; Ui.Input Console;
  Ui.Playback Controls/Tasks; server entry Conv; Diagnostics Tasks;
  Handling Savegame/Console; Server.Server FailuresUnit/WorldUnit/Savegame/Console.
  [Intentions.fpas](../../apps/client/src/Dungeon/Client/Ui/Intentions.fpas),
  line 35 also immediately overwrites PendingChangesProgress := true with false.
  ClientEvent.Disconnected has no production publisher; decide whether normal
  completion should emit it or the alternate path should be removed.
  [Rays.fpas](../../apps/client/src/Dungeon/Client/Raycast/Rays.fpas), line 15
  exposes SawExit, maintained in production but read only by tests; the visible
  exit material is sampled separately. Remove unnecessary state while retaining
  meaningful visibility/render coverage. Do not delete test-used exports merely
  because their callers are tests. PersistenceFailureReason belongs to R09.
  Verify: repo-wide references, relevant behavior tests and project checks.

- [ ] **R14 — P3: document lifecycle invariants and correct status drift.**
  [Client Model.fpas](../../apps/client/src/Dungeon/Client/Model.fpas), review
  line 90: document validity/reset rules of Pending, PendingChangesProgress,
  PendingCreatedWorld and Dirty, synchronized with the resolved lifecycle.
  [Server.fpas](../../apps/server/src/Dungeon/Server/Server.fpas), line 27:
  document ServeConnection ownership, caller responsibility to close, normal
  EOF/cancellation and returned error behavior.
  [Integration documentation](../architecture/initial-client-server.md), line
  108: mark automated checkpoint-12 measurements complete and retain only the
  explicitly deferred manual review/acceptance as open.
  Verify: contracts match implemented transitions and documentation links resolve.

- [ ] **R15 — P3: record the combat-animation identity limitation.**
  [Animation.fpas](../../apps/client/src/Dungeon/Client/Animation.fpas), review
  line 180; [Sprites.fpas](../../apps/client/src/Dungeon/Client/Raycast/Sprites.fpas),
  line 168. Events address opponents by kind, so multiple visible opponents of
  one kind would share effects. The current generator has one per kind; this
  is a future extension boundary, not an existing generated-content bug.
  Close this item by documenting the current invariant and placing the future
  requirement in lasting architecture/product documentation: identify a distinct
  figure or position before allowing same-kind groups. Do not introduce a new
  gameplay feature or protocol bump merely to close this scratch item.

## Closure record

When addressing an item, record its commit (if requested), changed behavior,
verification and any intentional remaining limitation under its stable R-number.
Check the item only after the stated acceptance criteria pass; do not treat the
previous green suite as evidence for a new fix. Record failed checks honestly.
Documentation-only cleanup needs appropriate document/link checks rather than
new tests that mirror prose. Runtime fixes need the relevant regression coverage.

- [ ] All R01-R15 items have a completed or explicitly agreed disposition and evidence.
- [ ] Changed FPAS sources are formatted and their public contracts documented.
- [ ] All affected projects check; the complete suite passes with actual counts recorded.
- [ ] Architecture/product docs retain the lasting contracts and limitations.
- [ ] User accepts the completed cleanup; delete this scratch plan afterward.

Commit or push only on request. Keep the separate 14b plan until its own
explicit acceptance; deleting this scratch plan does not imply 14b acceptance.


## Pass 01 — R01, R02 and R08

Status: complete on 2026-10-16. Implementation, independent review, review
corrections and final verification passed. The user authorized a co-authored
commit on 2026-10-16. R01, R02 and R08 are recorded together in the commit
containing this record, titled `fix: bound server workers and keep world cursor valid`.

- **R01:** extracted listener ownership into
  [Listener.fpas](../../apps/server/src/Dungeon/Server/Listener.fpas).
  One persistent acceptor and one persistent session worker use a bounded
  handoff, with a retained connection lease covering cancellation before or
  during session delivery. The owner observes worker completion and ordinary
  error results. Session errors still close only that client's session.
- **R02:** catalog installation, resize and rendering reconcile the local
  cursor against the displayed rows. Missing/off-page authority and inspecting
  an incompatible row never change the selected world or enqueue selection.
- **R08:** the session worker closes the old connection and publishes its
  completion/error events before releasing admission for the next session.
- Lasting contracts are documented in the
  [architecture overview](../architecture/overview.md),
  [client UI](../product/client-ui.md) and the server public API comments.
  Removing obsolete server imports also partially advances R13; documenting
  ServeConnection partially advances R14. Both items remain open.

### Regression and review evidence

- New actual-render test:
  [world_catalog_render_test.fpas](../../tests/client/world_catalog_render_test.fpas)
  covers missing/off-page selection, incompatible rows, visible preselection,
  paging, resize, empty catalogs and defensive rendering of a stale cursor.
  The same test on baseline `3faf77e` fails with the expected TUI diagnostic,
  `Tui list selection must be within its items` (exit 3).
- New real-TCP test:
  [server_reconnect_lifetime_test.fpas](../../tests/server/server_reconnect_lifetime_test.fpas)
  completes 1,050 sessions without waiting for the previous disconnected log
  before reconnecting. It checks alternating connection events, snapshots and
  the real dashboard model, then stops and verifies listener closure.
- New internal listener test:
  [listener_lifetime_test.fpas](../../tests/server/internal/listener_lifetime_test.fpas)
  injects a real accept failure, verifies two ordinary handler failures leave
  admission reusable, and verifies cleanup after a controlled shutdown timeout
  and after exhaustion of the documented lifetime identity limit.
- Independent subagent review found two ownership paths requiring correction:
  the timeout must retain ownership until cancelled work finishes, and a failed
  lifetime creation must close the transferred listener. Both were fixed,
  regression-tested and re-reviewed; no findings remain in this pass's scope.
- Shutdown remains cooperative: exceeding the single two-second grace budget
  is logged and returned as an error after joining and cleanup. It does not
  forcibly terminate an uncooperative handler or start another grace budget.
- Development checks: an initial multi-file patch/check failed because the
  cursor helper was not yet installed; an initial reconnect-test assertion
  accidentally counted a final snapshot from the old session; a timeout-test
  draft omitted `end with`. All three were corrected. The final targeted
  regressions passed 3/3, the existing admission test passed 1/1, and the expanded
  internal listener test passed 1/1 after both review corrections. An earlier
  full-suite run passed 94/94 before those final corrections; it is not the
  final verification evidence.
- Final verification after both review corrections: format check passed; all
  20 workspace projects checked; the complete serial suite passed **94/94**
  programs, with **0 failures**. Relative documentation link targets and
  `git diff --check` passed. All seven changed FPAS files have purpose comments;
  new public contracts document ownership and error behavior. The unchanged
  game-local FPAS toolchain is used throughout, with its matching standard
  library; the compiler repository remains unchanged.
  Toolchain revision: `33814ef3`; compiler SHA-256:
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`.

Verification commands (repository root, matching game-local compiler/library):

```sh
.temp-data/rat-toolchain/fpas fmt --check apps libs tests tools
.temp-data/rat-toolchain/fpas check --std-lib .temp-data/rat-toolchain/lib dungeon.fpasworkspace
.temp-data/rat-toolchain/fpas test --std-lib .temp-data/rat-toolchain/lib --timeout 600 --jobs 1 dungeon.fpasworkspace
git diff --check
```

Next pass: R03 and R04 together, because request/event isolation and socket
closure share client connection ownership. The remaining R05-R07 and R09-R15
stay open. Manual 14b terminal review and user acceptance stay explicitly open.


## Pass 02 — R03 and R04 (blocked)

Status: BLOCKED on 2026-10-16, before the targeted regressions and final suite.
Implementation paused under AGENTS.md's compiler-defect rule. No item closed
and no compiler repository changes made. The user requested a co-authored
checkpoint commit and push on 2026-10-16. This draft and reproduction are
recorded in the commit containing this entry, titled
`wip(client): checkpoint blocked connection lifecycle cleanup`.

### Draft scope

- **R03:** each StartConnection creates a fresh request queue. Cancel/quit close
  the old queue and invalidate its generation before host cancellation. A
  ConnectionEvent envelope tags network events; the production host discards
  old generations. Ordinary network errors are explicitly published as tagged
  Failed events because the TUI silently reaps ordinary task Result values.
- **R04:** Exchange borrows a socket; RunConnection owns it and closes it after
  every ordinary Result outcome. A session error retains priority over an
  additional close error. The raw-event RunNetwork adapter remains available
  to callers that orchestrate their own network session.
- UI tests were mechanically adapted to the new host-inbox type; existing TCP
  tests retain raw network channels and use a separate UI inbox. Assertions
  that expect cancellation to enqueue Disconnect still need updating, together
  with new cancellation/reconnect and socket-failure regressions. Production
  API comments and lasting architecture/product contracts need final alignment.
- These are unfinished draft changes, retained for review and continuation.
  The last verified implementation is commit `2c17456`, not this working tree.

### Compiler blocker and independent review

- The unchanged game-local compiler reports `FP9001: The compiler could not
  lower field access on non-record` for a field access on an inferred generic
  function result. The first workspace check failed; a fresh client-core check
  reproduced it. Its game diagnostic names unchanged ClientMessages code;
  isolation locates the trigger at `Final.Requests` after Tui.RunWithBackground.
- Minimal game-independent reproduction:
  [pass02-inferred-generic-record.fpas](repros/pass02-inferred-generic-record.fpas).
  It defines Identity<T>(Value: T): T, infers a local record result, and reads
  its Generation field. No TUI, networking, game units or dependencies are
  required. Expected behavior: successful compilation; actual: FP9001 at the
  field access, exit code 1.
- A diagnostic control that changes only `const Final :=` to
  `const Final: State :=` checks successfully. The language reference explicitly
  permits inference for completely determined local initializers and generic
  calls. This annotation was tried only in isolated temporary copies, not
  installed as a game workaround.
- Independent subagent review reproduced the minimal failure and the green
  annotated control. R04 alone checks in a baseline copy; the entire clientcore
  draft checks in an isolated copy when only Final is annotated. Static review
  found no additional concrete correctness issue in the draft ownership or
  generation policy, but cannot replace its missing behavioral regressions.
- Toolchain is unchanged from pass 01: revision `33814ef3`, SHA-256
  `71d2ddc8912509f302832cff3e4db26c9f33fa4741fb16b091075461dfc97d4f`,
  with its matching standard library. The compiler repository remains untouched.

Reproduce from the game repository root:

```sh
.temp-data/rat-toolchain/fpas check --std-lib .temp-data/rat-toolchain/lib docs/plans/repros/pass02-inferred-generic-record.fpas
```

Resume after the user agrees to a compiler fix with regression coverage or
chooses another explicit disposition of the compiler defect. Then finish the
R03/R04 regressions and API/docs, run all project checks and the complete suite,
obtain a final independent review, and update this pass's evidence before
checking R03/R04. The manual 14b review and acceptance remain explicitly open.
