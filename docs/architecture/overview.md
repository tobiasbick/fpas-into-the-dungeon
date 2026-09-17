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
- `apps/server` owns the server program entry point and server lifetime.
- `libs/game` owns the authoritative world model, rules, and simulation.
- `libs/world` owns validated world, chunk, and savegame persistence,
  missing-chunk generation, visible-window composition, prefetching, and
  bounded caching.
- `libs/protocol` owns commands and visible-state messages shared by client and
  server. It contains no game rules.
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
