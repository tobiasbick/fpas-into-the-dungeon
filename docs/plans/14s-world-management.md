# 14s: World management and server console

Implement roadmap 14s completely, after the committed 14a rendering correction.
The server remains authoritative. No migration, automatic deletion, autosave,
client world deletion, or LLM integration belongs to this feature.

## FPAS prerequisite

The user approved adding `Std.Fs.ReadDir` on 2026-10-06. It returns immediate
files and directories in stable order without recursion. Invalid roots and
storage errors remain errors. The direct and task-call tests pass. The existing
compiler omitted canonical standard-call metadata and lowering for `go` calls;
the integration fix keeps existing language rules and covers short/qualified
calls, task results, variadic output and source-routine shadowing.
`cargo fmt --all --check`, `cargo build --workspace --locked`, and
`cargo test --workspace --locked --no-fail-fast` passed; the Rust test results
total 3,542 passed and zero failed. The API and FPAS regression sources also
pass `fpas fmt --check`.

## Decisions and contracts

- Keep world format 3, generator 6, and save format 7: geometry and persisted
  schemas do not change. Raise the protocol to 14 for world selection messages.
- `world_id` only preselects an existing world. Startup never creates it. A
  missing or incompatible selection leaves the connected world menu usable.
- List world directories in stable ID order, with seed, entrance region size,
  compatibility, save status, and actionable reasons. Inspection never writes
  or deletes data. Distinguish incompatible data from storage failures.
- New-world seed bounds are signed 32-bit (-2147483648 through 2147483647); entrance regions are
  1 through 16 chunks. Defaults come from current `server.toml`; existing worlds
  retain their metadata. A newly created world gets a server-allocated unique
  ID independent of its seed. A collision must never reopen/overwrite a world.
- Continue loads the last explicit valid save, or starts at spawn if absent.
  Start over uses fresh mutable state in the selected existing world. It keeps
  the old save, which requires an explicit overwrite confirmation to replace.
- A switch or return to selection with unsaved state requires an explicit
  discard intention. Prepare the catalog/selected world and projection first;
  failures leave the installed session unchanged. No implicit save.
- One connected player at a time. Console mode is optional and headless mode
  remains the default. The console shows live log, connection/world status,
  and editable seed/entrance defaults. Validate before atomically saving TOML;
  publish new defaults only after successful storage, for new worlds only.

## Ordered implementation

- [x] 1. World catalog, existing-only opening, collision-safe creation, and
  non-destructive save inspection. Storage tests: positive, invalid data,
  versions, missing files, wrong path types, ID traversal, boundaries/collision.
- [x] 2. Protocol 14, strict bounded catalog codec and lifecycle intentions.
  Round trips and missing/extra/wrong-type/duplicate/boundary rejection tests.
- [x] 3. Server world selection, continue/start over/create, discard and overwrite
  guards, failure atomicity, startup preselection, single-player admission.
  Real TCP tests covering persistence/reconnect and failure paths.
- [x] 4. Client world list, separate actions, parameter editor, discard/cancel,
  overwrite/cancel, pending and failure handling. Test model, UI, and network.
- [x] 5. Optional live server console, settings persistence and lifecycle.
  Test settings validation/storage errors, event/status updates, and shutdown.
- [x] 6. Update architecture/product/README/roadmap, format and check every
  changed project, complete workspace suite. Report exact results and leave
  14s in review pending the user's acceptance.

## Completion gate

Every roadmap 14s behavior is implemented through the real client/server seam.
Positive, negative, and edge-case tests pass. Existing worlds/saves remain
intact across selection, failed operations, and start over. Run
`fpas fmt --check`, `fpas check dungeon.fpasworkspace`, and
`fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace` before handing back.
Do not commit the new 14s implementation or push without another request.

## Final verification

- World catalog, protocol, client model/terminal input, console settings/status,
  real TCP lifecycle/reconnect, real client adapter and listener admission tests
  pass individually. Preparation tests verify that storage/projection failures
  preserve installed world, state and dirty flag.
- All 63 changed Functional Pascal sources pass `fpas fmt --check`.
  `fpas check dungeon.fpasworkspace` passes, covering every changed project.
  The final `fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace` run passed
  65 test programs with zero failures on 2026-10-06. This supersedes the
  intermediate development failures. Positive, negative, and boundary coverage
  includes the eight new world-management test programs, the menu-navigation
  regression, and updated existing regressions.
- The headless listener owns process signals. Embedded/console listeners use
  caller-owned cancellation, allowing tests without process-signal ownership.
- Catalog reasons displayed by the server are capped at 96 characters so a
  64-entry page fits even with JSON escaping. The protocol additionally checks
  the encoded UTF-8 byte budget. Existing 64-bit seeds use canonical decimal
  text; creation input remains signed 32-bit.
- Catalog regressions cover more than 64 worlds, selection near the end,
  out-of-range offsets, first/last client pages, and paging blocked by an editor
  or pending request. Previous-page navigation clamps a partial first page to
  offset zero.
- Defeat refreshes the server-selected world catalog while keeping the defeat
  report visible. Creating a world clears stale client selection until that
  catalog is returned; a client regression test covers the refresh and Continue.

## Menu responsiveness correction

The user's terminal test exposed slow local keyboard navigation after the
functional checks. An isolated headless replay reproduced it without a server:
at 144 by 41 terminal cells, rebuilding the static backdrop consumed most frame
time. The client now prepares one immutable grid in its update path and reuses
it for the same size. Resize and return-from-game events prepare a new grid when
needed; the renderer and generated pixels stay unchanged.

- [x] Reproduce Tab navigation and measure generation separately from painting.
- [x] Retain the size-dependent grid in the client model, covering framework and
  network events without adding work to gameplay updates.
- [x] Add `menu_navigation_test`: real focus routing, a latency tripwire, retained
  pixels through menus/editor updates, changed/unchanged sizes, deferred resize
  in gameplay, return to selection, zero sizes and standalone rendering.
- [x] Format/check the final sources and pass the complete workspace suite:
  `fpas fmt --check`, `fpas check dungeon.fpasworkspace`, and
  `fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace` pass (65/65 programs).

Paired before/after runs used the same executable and isolated copies differing
only in this cache change. Seven queued Tab changes took 2,174 and 1,789 ms
before, and 238 and 208 ms after. The original 144 by 41 replay now averages
54 ms per key with a 62 ms maximum (previously 757 ms average, 778 ms maximum).
These are local headless measurements, excluding compilation and initial artwork
preparation; product acceptance still requires the user's terminal check.

## Remaining terminal review

On 2026-10-06 the user reported that some behavior still needs correction and
ended the session for the day. The remaining symptoms have not yet been isolated.
The passing automated tests do not close this review. Keep 14s in review and
retain this plan.

- [ ] Reproduce and describe the remaining issues from the user's terminal test.
- [ ] Correct the confirmed causes and add focused regression coverage.
- [ ] Repeat the terminal check and obtain the user's acceptance.
