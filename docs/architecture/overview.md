# Architecture

`Dungeon.slnx` contains four FPAS projects and an FPAS xUnit test project.

- `Dungeon.Game` owns deterministic generation, movement and combat. Its state
  changes are independent of terminal, files and network. `Terrain` regenerates
  outdoor cells, gates and dungeon layouts from a seed and coordinates.
  `Settlements` owns Hearthmoor and generated village geometry and NPC slots.
  `World` retains sparse discovery, combat progress and meetings for visited
  areas. `Exploration` derives sight and builds bounded map windows.
- `Dungeon.Protocol` owns the shared request and view types. The wire format is
  UTF-8 JSON in a bounded frame with a four-byte big-endian length. It
  sends parallel terrain and knowledge rows. Unknown fields carry no terrain.
  Remembered fields carry static terrain. Actors appear only in current sight.
  Version 3 adds a conversation with speaker, text, offered topics and revision.
- `Dungeon.Server` owns admission, the active game session and the explicit save
  slot. It serves one player at a time on loopback. A disconnected session
  discards unsaved changes. Panning is a read-only request on the current area
  and leaves movement, discovery and turn count untouched. Save format 3 stores
  the position, outdoor return site, discovery, per-floor opponent health and
  per-settlement meetings. The generator version pins the static layouts.
  The connection owns the active dialogue. It accepts only offered topics with
  the current revision and blocks gameplay and saving until the dialogue closes.
- `Dungeon.Client` sends intentions and renders the returned projection with
  Fpas.Tui. It keeps at most one request in flight.
- `Dungeon.Tests` runs the client exchange and the server host over loopback.
  The save acceptance starts a fresh listener and restores a game from disk.
  Generator fingerprints cover signed outdoor coordinates, two floors and two
  village layouts. The settlement journeys visit Hearthmoor, Ashbrook and
  Elmbridge through ordinary player commands.

See [rewrite progress](../plans/clr-rewrite.md) for the current feature scope.
