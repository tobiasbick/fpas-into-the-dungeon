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
│   ├── protocol/
│   ├── tui/
│   └── persistence/
│       └── runtime-data.fpasprj
├── tests/
│   ├── game/
│   ├── protocol/
│   ├── client/
│   └── server/
├── docs/
│   ├── product/
│   ├── architecture/
│   └── decisions/
└── fixtures/
    └── worlds/
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
- `libs/protocol` owns commands and visible-state messages shared by client and
  server. It contains no game rules.
- `libs/tui` owns terminal rendering and interaction.
- `libs/persistence` owns loading and saving authoritative state.
  `Dungeon.RuntimeData` also owns the shared runtime path and configuration
  interface.
- `tests` follows the production modules so each module is exercised through
  its interface.
- `fixtures` contains reusable, deterministic test data such as saved worlds.

## Client-server seam

Client and server run as separate processes from the first executable slice.
The server is authoritative: the client sends player intentions and renders
visible state returned by the server. Shared protocol types must not expose or
duplicate server-owned game rules. See the
[initial client-server slice](initial-client-server.md) for the first executable
contract.

## Runtime data

Configuration, saved worlds, logs, and caches live outside the repository. See
the [runtime data layout](runtime-data.md) for the default location, overrides,
and ownership rules.

## Documentation

- `docs/product` describes the game and player experience. The
  [world structure and views](../product/world-and-views.md) document defines
  the canonical spatial terminology and presentation rules.
- `docs/architecture` describes the system structure and module interfaces.
- `docs/decisions` records architecture decisions whose reasoning must remain
  available later.
