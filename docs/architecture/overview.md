# Architecture overview

The game is organized as a Functional Pascal workspace with separate runnable
applications and reusable libraries:

```text
fpas-into-the-dungeon/
├── dungeon.fpasworkspace
├── apps/
│   ├── client/
│   │   ├── client.fpasprj
│   │   └── src/
│   │       └── main.fpas
│   └── server/
│       ├── server.fpasprj
│       └── src/
│           └── main.fpas
├── libs/
│   ├── game/
│   ├── protocol/
│   ├── tui/
│   └── persistence/
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

Each directory under `apps/`, `libs/`, and `tests/` owns its own `.fpasprj`
manifest and `src/` directory. The root `.fpasworkspace` connects these
projects.

## Module ownership

- `apps/client` owns the client program entry point, input handling, and the
  connection to the game simulation.
- `apps/server` owns the server program entry point and server lifetime.
- `libs/game` owns the authoritative world model, rules, and simulation.
- `libs/protocol` owns commands and visible-state messages shared by client and
  server. It contains no game rules.
- `libs/tui` owns terminal rendering and interaction.
- `libs/persistence` owns loading and saving authoritative state.
- `tests` follows the production modules so each module is exercised through
  its interface.
- `fixtures` contains reusable, deterministic test data such as saved worlds.

## Client-server seam

The first playable version may run the simulation in the client process. The
client still talks to the simulation through a small interface. A local adapter
implements that interface initially; a network adapter can replace it later
without changing the TUI or the game simulation.

The server remains authoritative once it becomes a separate process. The
client sends player intentions and renders visible state returned by the
server. Shared protocol types must not expose or duplicate server-owned game
rules.

## Documentation

- `docs/product` describes the game and player experience.
- `docs/architecture` describes the system structure and module interfaces.
- `docs/decisions` records architecture decisions whose reasoning must remain
  available later.
