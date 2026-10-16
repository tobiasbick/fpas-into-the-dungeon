# Initial client-server slice

The first executable slice proves the process, protocol, authority, TUI, and
test seams without defining the wider game.

## Behavior

- `dungeon-server` listens on `127.0.0.1:4040` by default.
- `dungeon-server` preselects the configured existing world and supplies a
  non-destructive catalog. Worlds are created only through an explicit request.
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
general mutable-world simulation, authentication, TLS, multiplayer state, or
LLM integration.

## Protocol

The transport is TCP with one UTF-8 JSON object per LF-delimited line. Each
line is limited to 64 KiB. The client starts with `hello`; the server answers
with `welcome` and the world catalog, save classifications and creation
defaults. Invalid data is preserved. A complete initial `state` follows
only after `new_game` or `load_game`.

```text
Client: hello, list_worlds, select_world, create_world, new_game, load_game,
         save_game, overwrite_save, viewport, move,
         first_person_step, first_person_turn, interact, exploration_map,
         attack, wait, equip, unequip, drop_item, use_item, disconnect
Server: welcome, worlds, state, interaction, exploration_map,
        save_completed, defeated, rejected, error
```

The current protocol version `15` is included in the handshake. `hello` includes the initial
world-cell viewport, and later `viewport` messages report terminal or panel
layout changes. Unknown, malformed, or
oversized messages produce a structured error and close only that connection.
Player intentions are request-response: every accepted or rejected movement,
turn, or interaction receives one server message before the next intention is
sent. An interaction can return a replacement visible state or a read-only
description.

Inventory entries in either state family require `id`, `name`, `slot`,
`equipped` and boolean `usable`. `use_item` carries only `type` and a bounded
`item_id`; capability and healing remain server-owned. See
[items and inventory](items-and-inventory.md) for rejection and commit behavior.

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

## Dungeon-contents integration verification

Checkpoint 11 drives the production connection loop over TCP: create a world,
enter its generated named dungeon, collect and equip its sword and jerkin,
pick up and drink its potion during combat, defeat its skeleton and giant rat,
save, reconnect, Continue and revisit. The natural-play fixture uses ordinary
routes and no health, opponent or item edits. Independent literal dice
accounting checks the potion turn's healing, enemy damage and persisted RNG.

The actual received combat facts feed the client animation and raycaster;
standing/fallen markers and sprite heights retain the opponent kind. The
first-person title, exploration-map label and typed dashboard snapshot use the
stored name. A second existing two-dungeon test deliberately gives different
area IDs the same stored display name and verifies their separate origins,
visits and map labels through load and travel. Existing adapter/keyboard tests
continue to cover inventory `I`/`Enter` against real server replies.

Reconnect before saving restores the earlier carried potion and repeats its
turn exactly. Explicit saves retain consumed/defeated records across revisit;
restoring an earlier file and Start over exercise the overwrite/discard guards.
Old protocol 14, world/level/save versions, invalid item IDs, full-health use,
failed saves and failed loads retain the established rejection or connection
failure policy. Internal cases compare the entire installed session on
rejection, including state, geometry, dirty/save facts and the bounded cache.
A failed send yields an error for connection teardown and writes no progress.

These automated programs run real sockets and production server workers.
The listener/dashboard test also cancels the server with an active dirty game
and checks that shutdown preserves the previous save. Final performance smoke
checks and visual terminal acceptance remain checkpoint 12.
