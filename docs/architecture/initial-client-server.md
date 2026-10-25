# Client-server protocol

The client and authoritative server exchange bounded intentions and projections
over TCP. The protocol covers exploration, combat, inventory, dialogue and trade.

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

Each production client connection attempt owns a new intention queue. Its
events carry a local generation in the host inbox; generations never appear
in the wire protocol. Cancelling or quitting invalidates the attempt and closes
its queue before the host cancels and joins the worker. Buffered old intentions
cannot reach a new connection, and late old events cannot restore gameplay or
replace the new attempt's status. Cancellation does not roll back work the
server already received. Reconnecting remains an explicit user action.

The network adapter owns every successfully connected socket. All ordinary
outcomes close it, including failed setup, hello/request writes, response reads,
event publication, cancellation and normal completion. The original session
error wins if cleanup also fails; cleanup errors after success are returned.
Ordinary connection errors are delivered to the UI through the tagged inbox,
because the TUI host does not present a subscription's ordinary Result.Error.

No game time passes without a player intention. Dialogue and trade consume no
turn. Authentication, TLS, multiplayer state and LLM integration remain future work.

## Protocol

The transport is TCP with one UTF-8 JSON object per LF-delimited line. Each
line is limited to 64 KiB. The client starts with `hello`; the server answers
with `welcome` and the world catalog, save classifications and creation
defaults. Invalid data is preserved. A complete initial `state` follows
only after `new_game` or `load_game`.

Catalog requests enumerate canonical world directory identities in stable order
before choosing a page. Full metadata, save and referenced-level inspection is
limited to that page (at most 64 entries) and an existing selected world if it
lies outside the page. An on-page selection uses the same inspection as its row.
Directory enumeration still grows with the total world count; unrelated
off-page content is not read. Every request inspects its reported entries anew,
preserves invalid data and retains the existing status classifications. Continue
always loads and fully validates the save and its referenced levels again;
a previous catalog status does not authorize loading changed or damaged data.

```text
Client: hello, list_worlds, select_world, create_world, new_game, load_game,
         save_game, overwrite_save, viewport, move,
         first_person_step, first_person_turn, interact, exploration_map,
         attack, wait, equip, unequip, drop_item, use_item,
         dialogue_choice, end_dialogue, trade_buy, trade_sell, trade_page,
         end_trade, disconnect
Server: welcome, worlds, state, interaction, exploration_map,
        dialogue, dialogue_ended, trade, save_completed, defeated, rejected, error
```

The current protocol version `20` is included in the handshake. `hello` includes the initial
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

Both state families also require integer `coins` in 0..1,000,000,000. Trade
replies contain a complete state, quote and dirty flag in one envelope. The
quote has 16 entries per side/page; buying and selling carry only exact item
identity and current revision. See [trade and economy](economy.md) for exact
fields, capability checks, session precedence and the unchanged 64-KiB budget.

Session selection and save intentions are also request-response operations.
The server acknowledges a save only after the atomic replacement succeeds.
Before session selection it rejects projection and gameplay intentions with a
stable lifecycle error.

Gameplay and viewport candidates prepare the complete projection and check its
encoded UTF-8 size before sending. A preparation failure rejects the intention
and preserves the entire installed session: game state, discovery, RNG, retained
map, chunk cache and LRU clock, viewport, dirty flag and last-save timestamp.
Move preparation keeps the original session separate from the candidate cache.
The player can retry over the same connection after the underlying cause is
repaired. Rejections use the intention's code (`movement_rejected`,
`turn_rejected`, `interaction_rejected`, or the combat action's existing code);
viewport preparation uses `viewport_rejected`. Invalid viewport dimensions
still use `invalid_viewport`.

Only a successful state write installs the candidate. Viewport success preserves
game state and dirty/save facts. Actual response or rejection write errors end
the connection as before. Preparation may leave valid generated chunk files for
a retry, but never writes an explicit save or repairs a corrupt file silently.

Small runtime contracts protect server-owned lifecycle facts at decoded-message
dispatch and viewport/game installation. Dispatch requires an unfinished session;
the connection loop stops after a handler marks it finished. Viewport and map
requests preserve dirty and last-save facts, while game installation preserves
the transport viewport and finish flag. These clauses inspect scalar flags,
timestamps and viewport fields. Invalid intentions and candidate preparation
failures keep their ordinary `Result` rejection paths; a contract violation
identifies an internal programming error.

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
and checks that shutdown preserves the previous save. Checkpoint 12 completed
the automated checks and the [persistence measurements](persistence-measurements.md).
The user accepted 14b on 2026-10-16.
That acceptance supersedes the earlier manual-terminal deferral. Later
client/server maintenance adds lifecycle-handler parity, shared interior
knowledge projection and socket-completion checks; these retain the accepted
14b gameplay, protocol, storage formats and generator fingerprints.
