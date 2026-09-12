# Initial client-server slice

The first executable slice proves the process, protocol, authority, TUI, and
test seams without defining the wider game.

## Behavior

- `dungeon-server` listens on `127.0.0.1:4040` by default.
- `dungeon-client` connects to that address and renders a fixed 13 by 7 outdoor
  region supplied by the server.
- The server creates one player at the center of the map.
- Arrow keys send cardinal movement intentions.
- The server validates movement and returns the resulting visible state.
- `Q` quits the client. A disconnected client does not stop the server.
- The initial server accepts one active client at a time.

No game time passes without a player intention. The slice has no combat,
generation, persistence, authentication, TLS, multiplayer state, or LLM
integration.

## Protocol

The transport is TCP with one UTF-8 JSON object per LF-delimited line. Each
line is limited to 64 KiB. The client starts with `hello`; the server answers
with `welcome` followed by the initial `state`.

```text
Client: hello, move, disconnect
Server: welcome, state, rejected, error
```

Protocol version `1` is included in the handshake. Unknown, malformed, or
oversized messages produce a structured error and close only that connection.
Movement is request-response: every accepted or rejected `move` receives one
server message before the next move is sent.

Each `state` message identifies the map view and contains its dimensions,
server-produced terrain rows, and the player's authoritative coordinates. The
client validates this visible-state shape and does not import map dimensions or
rules from the game module.

## Configuration

Persistent TOML configuration and command-line overrides use the paths and
precedence described in [runtime-data.md](runtime-data.md).

## Completion

The slice is complete when the workspace checks, protocol and game tests pass,
the TUI has a headless state/render test, a loopback integration test crosses a
real TCP connection, and client/server shutdown leaves no blocked tasks.
