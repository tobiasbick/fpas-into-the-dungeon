# Initial client-server slice

The first executable slice proves the process, protocol, authority, TUI, and
test seams without defining the wider game.

## Behavior

- `dungeon-server` listens on `127.0.0.1:4040` by default.
- `dungeon-server` opens the configured world, creating missing metadata and
  deterministic chunks below the runtime-data root.
- `dungeon-client` connects to that address and requests a visible window that
  fits its current primary view.
- After connecting, the client explicitly starts a new game at the stable spawn
  or loads the selected world's existing savegame.
- `W`, `A`, `S`, and `D` send cardinal movement intentions.
- The server validates movement and returns the resulting visible state.
- `Alt+X` cleanly disconnects and quits the client. A disconnected client does
  not stop the server.
- The initial server accepts one active client at a time.

No game time passes without a player intention. The slice has no combat,
mutable-world persistence, authentication, TLS, multiplayer state, or LLM
integration.

## Protocol

The transport is TCP with one UTF-8 JSON object per LF-delimited line. Each
line is limited to 64 KiB. The client starts with `hello`; the server answers
with `welcome`, the availability of the selected world's save, and whether an
invalid save was removed during inspection. A complete initial `state` follows
only after `new_game` or `load_game`.

```text
Client: hello, new_game, load_game, save_game, viewport, move,
        first_person_step, first_person_turn, interact, exploration_map,
        disconnect
Server: welcome, state, interaction, exploration_map, save_completed,
        rejected, error
```

Protocol version `8` is included in the handshake. `hello` includes the initial
world-cell viewport, and later `viewport` messages report terminal or panel
layout changes. Unknown, malformed, or
oversized messages produce a structured error and close only that connection.
Player intentions are request-response: every accepted or rejected movement,
turn, or interaction receives one server message before the next intention is
sent. An interaction can return a replacement visible state or a read-only
description.

Session selection and save intentions are also request-response operations.
The server acknowledges a save only after the atomic replacement succeeds.
Before session selection it rejects projection and gameplay intentions with a
stable lifecycle error.

Each `state` message identifies its view family. A map state contains its world
origin, dimensions, compact server-produced terrain rows, and the player's
local and authoritative world coordinates. A first-person state contains
bounded field rows, dimensions, an area-local player coordinate, cardinal
facing, title, and concise status text. The two payloads are structurally
distinct. Stable area identities, return locations, chunks, generation,
collision, and movement rules remain server-owned.

## Configuration

Persistent TOML configuration and command-line overrides use the paths and
precedence described in [runtime-data.md](runtime-data.md).

## Completion

The slice is complete when the workspace checks, protocol and game tests pass,
the TUI has a headless state/render test, a loopback integration test crosses a
real TCP connection, and client/server shutdown leaves no blocked tasks.
