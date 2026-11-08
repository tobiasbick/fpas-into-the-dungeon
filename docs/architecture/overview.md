# Architecture

`Dungeon.slnx` contains four FPAS projects and an FPAS xUnit test project.

- `Dungeon.Game` owns deterministic generation, movement and combat. Its state
  changes are independent of terminal, files and network. `Terrain` regenerates
  outdoor cells, gates and dungeon layouts from a seed and coordinates.
  `Settlements` owns Hearthmoor and generated village geometry and NPC slots.
  `World` retains sparse discovery, combat progress and meetings for visited
  areas. `Items` assigns stable IDs to generated finds and validates ownership.
  `Inventory` resolves pickup, use, equipment and drops. `Quests` derives
  readiness and journal text from the compass's current owner and exchanges
  it for two quest-origin potions in one state change. `Trade` prices items
  and changes the wallet and item owner together. Each visited settlement adds
  its merchant's original stock once to the shared item ledger.
  `Skills` tracks cumulative Unarmed and Blades experience. A hit grants the
  active skill only the health it actually removes, up to 120 experience.
  At 12, 36, 72 and 120 experience the skill advances from level 1 to levels
  2–5. The respective damage bonuses are +1, +1, +2 and +2.
  `Clock` starts at day 1, 08:00. Accepted outdoor steps take five minutes.
  Other ordinary timed actions take one minute. Night begins at 20:00 and
  ends at 06:00.
  The seed selects one rainy six-hour window per day. `Rest` advances eight
  hours and restores full health for five coins when an inn offer is confirmed.
  `Exploration` derives sight and builds bounded map windows.
- `Dungeon.Protocol` owns the shared request and view types. The wire format is
  UTF-8 JSON in a bounded frame with a four-byte big-endian length. It
  sends parallel terrain and knowledge rows. Unknown fields carry no terrain.
  Remembered fields carry static terrain. Actors appear only in current sight.
  A conversation carries its speaker, text, offered topics and revision.
  Inventory entries carry offered item actions and derived character values
  accompany the bag. The merchant's buy and sell quotes have at most 16 items
  per page. Version 7 also carries the current conditions in map projections
  and both skill levels with the inventory.
- `Dungeon.Server` owns admission, the active game session and the explicit save
  slot. It serves one player at a time on loopback. A disconnected session
  discards unsaved changes. Panning is a read-only request on the current area
  and leaves movement, discovery, turns and time untouched. Save format 7
  stores every materialized item with one location, quest phase, wallet, game
  minutes and both experience counters.
  Loading validates dungeon, quest and merchant origins, current shop owners
  and capacity. A sale or purchase keeps the item's original identity.
  The connection owns the active dialogue. It accepts only offered topics with
  the current revision and blocks gameplay and saving until the interaction
  closes. Rest uses the current innkeeper and offer revision. Trade suspends
  the dialogue and authorizes transfers only for the current merchant, quote
  revision and page. Esc restores the dialogue.
- `Dungeon.Client` sends intentions and renders the returned projection with
  Fpas.Tui. It keeps at most one request in flight.
- `Dungeon.Tests` runs the client exchange and the server host over loopback.
  The save acceptance starts a fresh listener and restores a game from disk.
  Generator fingerprints cover signed outdoor coordinates, two floors and two
  village layouts. The settlement journeys visit Hearthmoor, Ashbrook and
  Elmbridge through ordinary player commands. The inventory journey checks
  ownership, equipment effects, potion consumption and reload through the
  same TCP path. The compass journey saves and continues after acceptance,
  retrieval and hand-in. A separate rule test checks earlier retrieval and the
  63- and 64-item reward boundary. The trade journeys check stock and balance
  after reload, item transfers between shops, stale quotes and page boundaries.
  The clock and rest tests cover the weather schedule, time overflow, payment,
  replayed confirmation and reload. The compass journey checks Blades
  experience and damage through promotion and reload.

See [rewrite progress](../plans/clr-rewrite.md) for the current feature scope.
