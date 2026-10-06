# Dungeon level storage contract

This is the 14a level storage contract supplementing
[generated dungeons](generated-dungeons.md). It is implemented by
`Dungeon.World.Interiors` and its `.Encoding` and `.Errors` units, the
three-phase savegame loading in `Dungeon.World.Savegame`, and the transition
handling in `Dungeon.Server.Handling` and `Dungeon.Server.Replies`. The
structural rules shared by the generator and stored levels live in
`Dungeon.Interior.Generation.Validation`. Later multi-level support changes
the format deliberately; 14a stores only level 0.

## Immutable level file

Use `worlds/<world-id>/dungeons/<rx>_<ry>/0.json`. Validate the world identity
with the existing world-ID validator. Parse the area identity canonically into
signed region coordinates, then build the path from those integers. Reject
leading zeros, a leading plus, negative zero, extra segments, and an area with
no entrance. Never insert a received area identity into a filesystem path.

The JSON root has exactly these 12 required keys. Object key order is not
significant; the writer emits the order below. Unknown, missing, duplicate,
null, or mistyped fields are errors, including in nested objects. Numeric
fields must be integral and within their stated bounds.

| Key | Format and requirement |
| --- | --- |
| `format_version` | Integer `1`. |
| `world_id` | String exactly equal to selected world metadata ID. |
| `generator_version` | Integer equal to metadata generator version, `6` in 14a. |
| `area_id` | Canonical `<world>:dungeon:<rx>:<ry>`, equal to the requested area. |
| `level` | Integer `0`. |
| `width` | Integer `31`. |
| `height` | Integer `21`. |
| `rows` | Exactly 21 strings, each exactly 31 ASCII characters: `#`, `.`, `x`. |
| `start` | Exact object `{ "x": integer, "y": integer, "facing": string }`. |
| `exit` | Exact object `{ "x": integer, "y": integer }`. |
| `items` | Exactly three placement objects, defined below. |
| `hostiles` | One or two placement objects, defined below. |

Positions use `0 <= x < 31` and `0 <= y < 21`. Facing uses the existing strings
`north`, `east`, `south`, `west`; the generated start in 14a must be `east`, one
field east of the exit on the same row. Rows are terrain only: item and actor
markers must never be written into them. Reuse the existing interior cell-code
functions.

Each placement is exactly `{ "id": string, "kind": string, "x": integer,
"y": integer }`. Items occur in index order 0, 1, 2, with IDs
`<area>:item:<index>` and kinds `ancient_coin`, `rusty_short_sword`,
`leather_jerkin`, respectively. Hostiles occur in index order starting at 0,
with IDs `<area>:hostile:<index>` and kind `restless_skeleton`. A placement has
no current health, alert status, ownership, equipment slot, or discovery data.
Identity strings must also fit the existing 128-character inventory-ID bound.

Move the existing item-kind, hostile-kind, and facing JSON string conversions
into a small shared world-layer encoding unit used by saves and levels. Keep
their established spellings; do not make the level codec depend on the
savegame orchestration unit or copy the mappings.

Reject level text longer than 65536 characters before parsing. Validate the
outer wall, unique exit, connected walkable fields, start/exit relation, floor
share of 25 through 60 percent, and initial hostile sight restriction. Original
placements occupy distinct ordinary floor fields, away from start and exit;
items and hostiles do not overlap. Room count is checked at generation time
only: rooms are not persisted or inferred again from finished corridors.
Neither decoding nor validation reruns the generator. Structural validity is
the storage contract; fingerprint tests verify generator output separately.

Only a missing first-visit file is generated and atomically written, using the
existing filesystem primitives and the same single-server ownership assumption
as world chunks. One server owns a runtime world directory; concurrent servers
and external modifications during an operation are outside 14a. Existing files
are read, never overwritten, repaired, or migrated. Creation failure leaves no
partially published target. A valid file published just before a later failure
may remain and is reused on the next entry.

## Final interfaces and ownership

Use these signatures from step 3 onward. The declarations below describe the
public contract; normal imports and purpose comments are added during coding.

`Dungeon.Areas` in `libs/game` provides pure functions:

```pascal
public function AreaViewFor(Metadata: WorldMetadata; State: GameState;
  Map: option of InteriorMap): result of AreaView, string;
public function MaterializeArea(State: GameState; Map: InteriorMap): GameState;
public function ValidateSavedGame(Metadata: WorldMetadata; State: GameState;
  Maps: array of InteriorMap): result of GameState, string;
```

`AreaViewFor` requires `None` outdoors and a matching map indoors; it never
loads anything. `Maps` contains exactly one validated map for every visited
area in the same canonical order as `VisitedAreas`, with no missing or extra
entries. Full validation checks every area's entities against its supplied
map and reuses the current map for the player view. Materialization requires a
validated map and state, adds original placements only for an unvisited area,
and returns an already visited state unchanged.

`Dungeon.Movement` provides pure transition functions:

```pascal
public function AreaTransitionTarget(View: AreaView; State: GameState):
  result of string, string;
public function ActivateAreaTransition(View: AreaView; State: GameState;
  TargetMap: option of InteriorMap): result of AreaTransition, string;
```

`AreaTransitionTarget` validates the current pose and entrance/exit interaction
and returns the authoritative target area identity. `Interact(View, State)`
uses it only for a transition field and returns
`InteractionOutcome.TransitionRequested(TargetAreaId: string)` without changing
state. The client does not supply an area ID. Other interactions keep their
described/state-changed outcomes. `ActivateAreaTransition` repeats the pure
eligibility check, requires a map with that target ID on entry or `None` on
exit, and returns `AreaTransition { State, View }`. An invalid request performs
no storage operation. Transitions remain free actions and do not advance combat.

`Dungeon.World.Interiors.Errors` defines the typed world-layer failure:

```pascal
public type LevelFailure = enum
  Missing(AreaId: string);
  Invalid(AreaId: string; Reason: string);
  Io(Reason: string);
  Generation(AreaId: string; Reason: string);
end enum;
```

`Dungeon.World.Interiors` owns filesystem operations and generation:

```pascal
public function ReadLevel(World: WorldSession; AreaId: string):
  result of InteriorMap, LevelFailure;
public function OpenLevelForEntry(World: WorldSession; State: GameState;
  AreaId: string): result of InteriorMap, LevelFailure;
public function ReadVisitedLevels(World: WorldSession; State: GameState):
  result of array of InteriorMap, LevelFailure;
```

`ReadLevel` never generates or writes. `OpenLevelForEntry` first tries a read;
only `Missing` combined with an unvisited target permits generation and atomic
storage. It verifies the target against the player's transition before creating
anything. A missing already visited level remains an error. `ReadVisitedLevels`
reads each visited area once in canonical order; it never calls the entry
operation. It returns maps for the duration of validation, not a permanent
unbounded cache. The server retains only the current map between intentions.

`Dungeon.World.Interiors.Encoding` provides
`EncodeLevel(Metadata: WorldMetadata; Map: InteriorMap): string` for validated
input and `DecodeLevel(Text: string; Metadata: WorldMetadata; AreaId: string):
result of InteriorMap, string` with the schema above. Storage wraps decode
errors as `LevelFailure.Invalid`; I/O errors are never relabeled as invalid
content. The world layer may import game rules; the reverse is forbidden.

## Save loading and failure classification

Split save processing into three phases: decode and check self-contained save
fields; read its referenced level files; validate game state against those maps.
Expose `DecodeSaveGameState(Text, Metadata): result of GameState, string` for
the first phase and remove the old all-in-one `DecodeSaveGame` entry point.
The first phase checks schema/version/world, canonical and unique area and
entity IDs, visited-area membership, inventory/slot bounds, and scalar and
shape constraints without map access. It is explicitly not full validation.
Only fully validated states may become active.

The exact decoder signature is `DecodeSaveGameState(Text: string;
Metadata: WorldMetadata): result of GameState, string`. The storage signatures
are `LoadSaveGame(World: WorldSession): result of SaveGameLoad,
PersistenceFailure` and `WriteSaveGame(World: WorldSession; State: GameState):
result of boolean, PersistenceFailure`. A successful write returns `true`.

Keep `LoadSaveGame(World)` and `WriteSaveGame(World, State)` parameter lists.
Their error type becomes `PersistenceFailure`, owned by
`Dungeon.World.Savegame.Errors`:

```pascal
public type PersistenceFailure = enum
  InvalidState(Reason: string);
  Level(Failure: LevelFailure);
  Io(Reason: string);
end enum;
```

`SaveGameLoad` retains `Missing` and `InvalidRemoved(Reason)` and changes its
success case to `Loaded(State: GameState; View: AreaView)`. The view retains the
already read current map. Handshake inspection discards the returned state and
view after reporting availability; an explicit load rereads and validates, so
inspection never silently resumes a game or substitutes a stale snapshot.

| Condition | Load result and side effects |
| --- | --- |
| No save file | `Missing`; do not inspect or create level files. |
| Bad save schema/version/world or invalid self-contained state | Delete only `default.json`, then `InvalidRemoved`, as before. |
| Referenced level missing, invalid, or incompatible | `Error(Level(...))`; preserve save and all world files. |
| Save or level I/O failure | Typed `Io` failure; preserve data. |
| Levels valid but saved items/pose violate their maps | Invalid save: delete only `default.json`, then `InvalidRemoved`. |
| Deletion of an invalid save fails | `Error(Io(...))`; never report successful removal. |
| Fully valid | `Loaded(State, View)`; no writes. |

On write, every validation failure returns an error without deleting anything;
invalid state uses `InvalidState`, level failures use `Level`, filesystem
failures use `Io`. Validate before atomically replacing the previous save.
Do not classify failures by text prefixes. Test that a missing level can never
fall into `InvalidRemoved`, including during the handshake.

An inspection failure before `Welcome` uses the existing rejected-message
channel, then closes the transport; the client displays the reason. Explicit
load/save failures reject the operation and leave the existing session state
unchanged. Use stable rejection codes `world_data_error` for missing/invalid
levels, `storage_error` for I/O, `generation_error` for generation failure, and
the existing invalid-intention path for rejected game rules. Client messages
identify the affected world/area without displaying host filesystem paths.
Keep this within protocol version 13; no new message variant is needed.
Extend the client handshake branch to recognize `Rejected` before `Welcome`
and publish its reason as the existing connection-failed event instead of an
unexpected-message error. Test this through the network adapter and headless
UI, including rejection followed immediately by connection close.

## Entry ordering and interruption behavior

The server serializes intentions. For a transition request:

1. Validate the active state and interaction using its current area view;
   determine the target with pure rules. Keep the original session unchanged.
2. For an indoor target, read or create its immutable level through
   `OpenLevelForEntry`. For an outdoor target use `None`. Any creation must be
   successfully published before proceeding.
3. Apply `ActivateAreaTransition` to a local candidate, materialize if needed,
   reveal the destination, and validate the candidate. Build its projection
   using the candidate map; never pair the new state with the old map.
4. Send the prepared projection and return the new session containing state,
   map, and updated world cache together through the existing functional
   handler flow. The main loop accepts that returned session before handling
   another intention. Do not split the state and map assignments across turns.

Failures before sending leave the original active state unchanged and return
a rejection. A valid newly created level file may remain, but discovery and
visited areas are unchanged. A send failure closes the connection: discard
the unsaved session; do not retry a transition on the same connection or write
a save. Reconnecting follows the existing explicit new/load choice. There is
no autosave and no transaction spanning the socket and filesystem.

Regression checkpoints: invalid interaction before storage; read failure;
generation failure; atomic-write failure; valid file published then candidate
validation/projection failure; send failure; successful transition. For each,
assert player pose, visited areas, inventory, discovery, level-file contents,
and previous save bytes. Use private pure helpers or narrow test seams for
deterministic failures; avoid timing races or a general storage abstraction.
Also prove that two visits create only one file, an older save reuses that file
without inheriting later mutable state, and save/load performs zero generation.
