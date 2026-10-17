# Architecture overview

The game is organized as a Functional Pascal workspace with separate runnable
applications and reusable libraries:

```text
fpas-into-the-dungeon/
├── dungeon.fpasworkspace
├── apps/
│   ├── client/
│   │   ├── client-core.fpasprj
│   │   ├── client.fpasprj
│   │   └── src/
│   │       ├── client.fpas
│   │       └── Dungeon/Client/
│   └── server/
│       ├── server-core.fpasprj
│       ├── server.fpasprj
│       └── src/
│           ├── server.fpas
│           └── Dungeon/Server/
├── libs/
│   ├── game/
│   ├── world/
│   ├── protocol/
│   └── persistence/
│       └── runtime-data.fpasprj
├── tools/
│   └── world-preview/
├── tests/
│   ├── game/
│   ├── world/
│   ├── protocol/
│   ├── client/
│   ├── runtime/
│   └── server/
└── docs/
│   ├── roadmap.md
│   ├── product/
│   └── architecture/
```

Each module under `apps/`, `libs/`, and `tests/` owns its `.fpasprj` manifest.
Production source lives under the module's `src/` directory; small test
programs live beside their test manifest. The root `.fpasworkspace` connects
these projects.

## Module ownership

- `apps/client` owns the client program entry point, input handling, and the
  connection to the game simulation.
  `Dungeon.Client.Ui` holds the TUI update and view entry points; its subunits
  own one concern each: `Backdrop` (responsive pre-game ASCII scenery),
  `Controls` (control and action identities), `Layout` (docking and viewports),
  `Session` (connection and session lifecycle), `Worlds` (catalog, creation
  editor and discard confirmation),
  `Intentions` (queued player requests), `Dialogue` (modal frame and input),
  `Input` (keys and actions), `Events`
  (network events), `Playback` (combat animation clock), `MapCells`,
  `GameView`, and `Overlays`. `Dungeon.Client.Raycast`, `.Animation`,
  `.Character` and `.CharacterSheet` render the first-person view, combat
  animation, inventory, and the scrollable character sheet. The raycaster's subunits own ray casting (`Rays`), pixels and
  lighting (`Pixels`), wall and floor textures (`Textures`), pixel art (`Art`),
  and sprites with animation effects (`Sprites`). `Dungeon.Client.Journal`
  renders server-formatted quest text with wrapping and local scrolling.
  The client facade prepares size-dependent start artwork after framework and
  network updates. `Backdrop` owns its generation and reuse; `Model` retains one
  immutable cell grid so focus navigation does not regenerate it.
  Each connection attempt owns a fresh request queue. The host retains one
  event inbox, but `ConnectionEvent` tags each event with its local generation;
  the facade rejects events from cancelled or replaced attempts. The network
  adapter owns its socket from successful connect through every ordinary
  session outcome, including publication errors. Cancel/quit invalidate the
  attempt and close its request queue before host cancellation. Raw-event
  adapters remain available for explicitly caller-orchestrated sessions.
  Normal non-cancelled completion publishes `ClientEvent.Disconnected` only
  after successful socket closure. A previously published failure stays terminal;
  transport, cleanup and publication errors retain their failure outcome.
  Cancellation is normalized by the outer adapter after cleanup and emits no
  terminal disconnect event. The server's `ServeConnection` borrows its socket;
  its listener or test caller closes it after either result. EOF, cancellation
  and ordinary read failures end that server session normally; failed writes
  remain errors. Connection teardown never autosaves.
  The adapter retains the response intent when decoding the shared wire `state`:
  viewport replies publish `ClientEvent.ViewportState`, while gameplay/session
  replies publish `State`. `Events` preserves the current overlay/focus for the
  read-only viewport refresh. Exploration-map projections and pending requests
  remain independent from primary state; an explicitly closed map stays closed.
  Inventory rendering derives a bounded item window from selection and terminal
  dimensions, with reserved controls; it retains no additional scroll state.
  Item intentions require renderable inventory dimensions. The context summary
  has a fixed maximum row count and reduces to the remaining panel height, with
  an explicit count of omitted carried names. Neither view mutates inventory
  to fit the terminal; identity and item rules remain authoritative.
- `apps/server` owns the server program entry point and server lifetime.
  `Dungeon.Server` runs the handshake/message loop and validates listener
  configuration. `Listener` owns the bound listener and two persistent workers:
  accept/admission and sequential protocol sessions. Their bounded handoff
  retains each connection until closure, and ordinary worker failures reach
  the owner before shutdown completes. Session completion events precede the
  next admission, preserving dashboard event order. Shutdown uses one shared
  two-second grace budget. A timeout is logged and returned as an error after
  the cancelled workers finish and their connections close; cancellation is
  cooperative, so cleanup can exceed that budget without a forced process exit.
  Other subunits
  own the policy (`Config`), per-connection session rules (`Session`),
  enumeration conversions (`Mapping`), client-safe projections (`Projection`),
  replies, turn and transition commits (`Replies`), message handling
  (`Handling`), connection-local dialogue (`Dialogue`), and the mapping of typed storage failures to stable rejection
  codes (`Failures`), world lifecycle (`Worlds`), bounded diagnostics (`Logging`)
  and optional dashboard/settings (`Console`). `Diagnostics` projects committed
  session facts into typed snapshots, separately from timestamped log text.
  Persistence rejection paths in `Worlds` log the detailed cause separately
  from the sanitized client reply, with operation and world identity. Typed
  failures use `Failures.PersistenceFailureReason`; incompatible save contents
  retain the loader's reason. Both use the existing non-blocking log delivery.
  `Worlds.Catalog` resolves page bounds and selection from canonical directory
  identities before invoking full world inspection. A request inspects at most
  64 page entries and one existing off-page selection, with no duplicate
  inspection for an on-page selection. It also binds that inspector to the world
  layer and reads creation defaults. `Worlds` is the existing lifecycle facade;
  `Worlds.Selection` owns catalog requests and world selection,
  `Worlds.Creation` owns create/start, and `Worlds.Persistence` owns load/save.
  Each concrete handler owns its active/selected/dirty prerequisites, including
  guard precedence; the gameplay dispatcher does not duplicate save guards.
  `Worlds.Replies` owns sanitized lifecycle rejections and installation after a
  successful state reply. A successful disk save precedes its acknowledgement;
  a failed acknowledgement is fatal and does not undo the committed save.
  Continue still validates and loads the complete save independently of catalog
  inspection. These internal subunits do not widen the server library exports.
  The console submodules own presentation/settings state (`Model`), bounded log
  filtering and scroll anchors (`Log`), responsive dimensions (`Layout`), native
  panels and settings overlays (`View`), and validated keyboard events (`Input`).
  `Console.Worlds.Model`, `.Input` and `.View` own the paged world list,
  identity-bound deletion confirmation and native controls. Deletion and client
  admission exclusively acquire the same caller-owned channel permit. The
  console seeds it before starting the listener and closes it after joining
  the listener; headless listeners retain their internally owned permit.
  The facade owns the cancellable listener subscription, event inbox and the
  shared admission permit.
  `Session` retains
  the current finite map and builds area views from it. Dungeon entry opens the target
  level through the world layer; settlement entry resolves authored geometry
  from `Dungeon.Settlements` without files. Loading
  installs the already validated view returned by the world layer.
  Turn and ordinary state replies prepare discovery, projection and a bounded
  UTF-8 response before installing a replacement session. Preparation failures
  reject the intention and retain every installed fact, including the original
  world cache and its LRU clock; successful gameplay sends mark progress unsaved.
  Viewport candidates share preparation/rejection policy but change no game
  state or dirty/save facts. A response or rejection write failure remains fatal.
  First-person rows and exploration-map windows share one interior-field
  decision for visible, remembered and unknown knowledge. Remembered fields
  contain only static geometry; current items and opponents appear only while
  visible. Each projection retains its own window traversal and padding.
- `libs/game` owns the authoritative world model, rules, and simulation,
  including the deterministic outdoor terrain generator. It has one unit per
  concern, layered without cycles:
  - `Dungeon.Coordinates`: positions, facing, relative steps, chunk arithmetic.
  - `Dungeon.Terrain` with `.Noise`, `.Generation`, `.Entrances`, `.Chunks`, and
    `.Placement`: cells, chunks, and world metadata; noise; natural terrain;
    entrance regions and sites; complete chunks with entrances; spawn and spawn
    entrance.
  - `Dungeon.Items`, `Dungeon.Hostiles`: kinds, identities,
    and per-kind texts and values.
  - `Dungeon.Interior` with `.Generation`, `.Generation.Content`, `.Generation.Levels`
    and `.Generation.Validation`: interior geometry, stairs and per-level
    endpoints and their validation; the deterministic dungeon level generator;
    dungeon depth and per-level content rules; the structural rules shared by the
    generator and stored levels. `Content`
    derives dungeon names and bounded optional loot using private domain seeds;
    the generator places its selected original slots without consuming geometry
    draws. The immutable map retains its display name for storage, projections
    and diagnostics.
  - `Dungeon.Quests.Model` and `.Items`: independent quest/objective identities,
    retained phases, terminal compass ownership and reward-origin validation.
    `Dungeon.Quests` applies acceptance and hand-in rules; `.Reachability`
    proves a route over supplied maps and `.Journal` formats the projection.
    `Dungeon.Npcs.Interaction` shares reach without a dialogue/rules cycle.
    `Dungeon.Dialogue.Model` retains private nodes and display fields, while
    `.Quests` owns quest-specific frames.
  - `Dungeon.GameState`: the authoritative state, new games, validation, and
    read-only queries; the `AreaView` type pairs world metadata with a supplied
    current interior map.
  - `Dungeon.Areas`: pure construction of an area view, requiring no interior
    outdoors and a matching map in a dungeon; first-visit entity materialization;
    `.Identities` owns canonical dungeon area identities; `.Validation` owns the
    map-free save shape check and full saved-state checks against all supplied
    visited maps and placements, without loading or generating geometry.
  - `Dungeon.Movement`, `Dungeon.Interaction`,
    `Dungeon.Equipment`, `Dungeon.Consumables`, `Dungeon.Combat`: the rules that
    change the state. Consumables validates and applies pure potion healing;
    Combat orders the resulting turn and hostile phase.
  - `Dungeon.Exploration` with `.Model` and `.Sight`: discovery masks,
    outdoor sight and discovery updates, and interior line of sight.
- `libs/world` owns validated world, chunk, and savegame persistence,
  creation of missing chunks through the `libs/game` generator, visible-window
  composition, prefetching, and bounded caching. `Dungeon.World` owns world
  sessions, the chunk cache, and visible windows; `Dungeon.World.Encoding` owns
  the exact JSON formats of world metadata and chunks. `Dungeon.World.Interiors`
  owns immutable level files (read, transient preview, first-visit creation, visited-level reads)
  with `.Encoding` (level format) and `.Errors` (`LevelFailure`).
  `Dungeon.World.Quests` coordinates read-only preflight and retained objective
  validation. `Dungeon.World.Savegame.Quests` owns the exact quest codec.
  `Dungeon.World.Catalog` opens existing worlds without creating them, lists
  non-destructively, and allocates exclusive new identities using `Std.Fs.ReadDir`.
  `ListWorldIds` enumerates canonical directories without opening metadata,
  saves or levels; `InspectWorld` validates one complete entry. `ListWorlds`
  explicitly inspects every identity for callers that need a complete list.
  `DeleteWorld` validates a direct child identity, refuses linked targets and
  uses `Std.Fs.DeleteDirAll` without decoding obsolete metadata. Callers own
  exclusion of active sessions; filesystem failures may leave partial contents.
  `Dungeon.World.Names` holds the persisted kind and facing names shared by saves
  and levels. `Dungeon.World.Savegame` owns the savegame file, its format version,
  and three-phase loading; its subunits `Player`, `Entities`, `Discovery`, and
  `Errors` (`PersistenceFailure`) encode, decode, and classify its parts.
- `libs/protocol` owns commands and visible-state messages shared by client and
  server, including the one-character cell and knowledge code alphabet of
  visible rows. It contains no game rules; a server contract test verifies that
  every code produced by `libs/game` belongs to that alphabet.
  `Dungeon.Protocol` holds the contract itself: limits, codes, and message
  types. `Names`, `Validation`, and `Fields` encode and check nested values;
  `ClientMessages` and `ServerMessages` encode and strictly decode whole
  messages; `Worlds` validates bounded world catalogs and selection predicates;
  `Transport` frames them as bounded lines.
- `libs/persistence` currently owns the shared runtime path and configuration
  interface. Authoritative world files are owned by `libs/world`.
- `tools/world-preview` samples final terrain or one normalized generator field
  without loading a persistent world. `tools/persistence-bench` measures
  first-entry level creation and complete save and load for a chosen number of
  visited dungeons.
- `tests` follows the production modules so each module is exercised through
  its interface. `tests/fixtures` is a test-only library exporting
  `Dungeon.Test.Fixtures`, `Dungeon.Test.Catalog` and `Dungeon.Test.StateComparison`:
  protocol catalog fixtures,
  independent authored dungeon geometry, metadata with an area identity, initial
  entities at a requested pose, and area-view helpers. `Dungeon.Test.StateComparison`
  compares complete states, including entity arrays and discovery masks, for
  regression assertions without invoking game rules or persistence.
  The fixture library also lends its layout to any world's spawn dungeon for
  pure rule tests and turns maps into first-person routes (`RouteTo`). Production projects do not
  depend on it; fixture geometry stays independent of generated output.
  `tests/levels` exports `Dungeon.Test.Levels` (entering and validating against
  stored generated levels), `Dungeon.Test.Routes` (routes as client intentions,
  outdoor paths), and `Dungeon.Test.Wire` (whole TCP play sessions).
  `tests/server/internal` compiles production server units directly in a
  separate test project to test session and projection internals without
  expanding the server library's public exports.
  `tests/client/internal` uses the same pattern for direct socket-ownership
  failure tests without exporting private client units from the library.

## Client-server seam

Client and server run as separate processes from the first executable slice.
The server is authoritative: the client sends player intentions and renders
visible state returned by the server. Shared protocol types must not expose or
duplicate server-owned game rules. See the
[initial client-server slice](initial-client-server.md) for the first executable
contract.

The chunked world seam is described in
[unbounded outdoor world](unbounded-world.md).
The server-owned seam between areas and view-specific protocol states is
described in [area transitions](area-transitions.md).
The ownership and rendering seams for discrete indoor navigation are described
in [first-person interior](first-person-interior.md).
The explicit server-owned save lifecycle is described in
[persistent game state](persistent-game-state.md).
Server-owned discovery, visibility derivation, Fog of War projections, and the
client-owned map overlay are described in
[exploration and map](exploration-and-map.md).
The shared interaction intention and its state-changing or descriptive outcomes
are described in [interaction](interaction.md).
The server-owned item state, inventory projection, pickup semantics, and
persistence boundary are described in
[items and inventory](items-and-inventory.md).
Turn-based combat, its dice, opponent behavior, defeat, and persistence are
described in [combat](combat.md).
Experience and skill levels (13b) are specified in
[progression](progression.md).

## Runtime data

Configuration, worlds, savegames, logs, and caches live outside the repository. See
the [runtime data layout](runtime-data.md) for the default location, overrides,
and ownership rules.

## Documentation

- The [roadmap](../roadmap.md) records the incremental development order and
  completion criteria without defining the complete game in advance.
- `docs/product` describes the game and player experience. The
  [world structure and views](../product/world-and-views.md) document defines
  the canonical spatial terminology and presentation rules. The
  [client UI](../product/client-ui.md) document defines the shared terminal
  presentation and interaction shell.
- The [server console](../product/server-console.md) describes the optional
  full-terminal administration dashboard, log controls and creation defaults.
- `docs/architecture` describes the system structure and module interfaces.

## Home settlement

`Dungeon.Settlements`, `Dungeon.Npcs` and `Dungeon.Dialogue` in `libs/game`
own authored geometry, NPC records and deterministic conversation effects.
The world save layer owns the exact NPC codec; it resolves settlement maps
from code. The protocol shares its visible-state codec between ordinary and
atomic dialogue replies. The server retains the active authoritative frame;
the client retains its projection and local selection. See
[NPCs and dialogue](npcs-and-dialogue.md) and [quests](quests.md) for the
complete contracts.
