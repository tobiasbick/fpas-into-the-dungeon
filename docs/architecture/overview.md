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
  own one concern each: `Controls` (control and action identities), `Layout`
  (docking and viewports), `Session` (connection and session lifecycle),
  `Intentions` (queued player requests), `Input` (keys and actions), `Events`
  (network events), `Playback` (combat animation clock), `MapCells`,
  `GameView`, and `Overlays`. `Dungeon.Client.Raycast`, `.Animation`, and
  `.Character` render the first-person view, combat animation, inventory, and
  character sheet. The raycaster's subunits own ray casting (`Rays`), pixels and
  lighting (`Pixels`), wall and floor textures (`Textures`), pixel art (`Art`),
  and sprites with animation effects (`Sprites`).
- `apps/server` owns the server program entry point and server lifetime.
  `Dungeon.Server` runs the handshake, message loop, and listener; its subunits
  own the policy (`Config`), per-connection session rules (`Session`),
  enumeration conversions (`Mapping`), client-safe projections (`Projection`),
  replies and turn commits (`Replies`), and message handling (`Handling`).
- `libs/game` owns the authoritative world model, rules, and simulation,
  including the deterministic outdoor terrain generator. It has one unit per
  concern, layered without cycles:
  - `Dungeon.Coordinates`: positions, facing, relative steps, chunk arithmetic.
  - `Dungeon.Terrain` with `.Noise`, `.Generation`, and `.Placement`: cells,
    chunks, and world metadata; noise; chunk generation; spawn and entrance.
  - `Dungeon.Items`, `Dungeon.Npcs`, `Dungeon.Hostiles`: kinds, identities,
    and per-kind texts and values.
  - `Dungeon.Interior` and `Dungeon.Interior.InitialDungeon`: interior
    geometry and its validation; the hand-authored initial dungeon.
  - `Dungeon.GameState`: the authoritative state, new games, validation, and
    read-only queries.
  - `Dungeon.Movement`, `Dungeon.Interaction`, `Dungeon.Dialogue`,
    `Dungeon.Equipment`, `Dungeon.Combat`: the rules that change the state.
  - `Dungeon.Exploration` with `.Model`: discovery and line of sight.
- `libs/world` owns validated world, chunk, and savegame persistence,
  creation of missing chunks through the `libs/game` generator, visible-window
  composition, prefetching, and bounded caching. `Dungeon.World.Savegame` owns the
  savegame file and its format version; its subunits `Player`, `Entities`, and
  `Discovery` encode and strictly decode the parts of the saved state.
- `libs/protocol` owns commands and visible-state messages shared by client and
  server, including the one-character cell and knowledge code alphabet of
  visible rows. It contains no game rules; a server contract test verifies that
  every code produced by `libs/game` belongs to that alphabet.
  `Dungeon.Protocol` holds the contract itself: limits, codes, and message
  types. `Names`, `Validation`, and `Fields` encode and check nested values;
  `ClientMessages` and `ServerMessages` encode and strictly decode whole
  messages; `Transport` frames them as bounded lines.
- `libs/persistence` currently owns the shared runtime path and configuration
  interface. Authoritative world files are owned by `libs/world`.
- `tools/world-preview` samples final terrain or one normalized generator field
  without loading a persistent world.
- `tests` follows the production modules so each module is exercised through
  its interface.

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
The fixed NPC, deterministic dialogue graph, session lifecycle, and persistence
boundary are described in [NPCs and simple dialogue](npcs-and-dialogue.md).
Turn-based combat, its dice, opponent behavior, defeat, and persistence are
described in [combat](combat.md).

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
- `docs/architecture` describes the system structure and module interfaces.
