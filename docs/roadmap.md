# Roadmap

This roadmap records the intended development order without defining the
complete game in advance. Work proceeds as small end-to-end slices that leave
the client and server executable and tested.

`DONE` means the current acceptance criteria are met. `NEXT` is the only stage
that should be detailed enough for immediate implementation. `LATER` gives an
ordering direction and may change as the project teaches us more. `OPEN` marks
a question that has not been decided.

## 1. Project foundation — DONE

The repository has separate client, server, library, and test projects,
architecture and product documentation, and an external runtime-data layout.
Functional Pascal source and public interfaces have documentation rules.

## 2. Connected outdoor slice — DONE

The authoritative server supplies a fixed outdoor region. The TUI client
connects over the versioned protocol, renders the visible state, sends cardinal
movement intentions, and handles accepted and rejected movement. Unit,
headless-TUI, protocol-contract, and loopback tests cover the slice.

See the [initial client-server slice](architecture/initial-client-server.md).

## 3. Client UI foundation — DONE

The stable presentation and interaction shell is implemented with the states,
layout, controls, and small-terminal behavior described in the
[client UI](product/client-ui.md) document. Headless tests cover the shell and
its connection lifecycle.

This stage is complete when connecting, active, pending, rejected, failed, and
disconnected states have deliberate presentation and test coverage; map sizes
remain server-defined; and a terminal smaller than the content does not crash
the client. Final styling and gameplay-specific panels remain outside this
stage.

## 4. Unbounded outdoor region — DONE

Create the first deterministic, chunked outdoor region with signed stable world
coordinates. The server persists versioned 128 by 128 chunks, loads every chunk
required by a bounded visible window, prefetches one surrounding margin, and
retains a bounded cache. The client reports its available map size and renders
the server projection as a two-column, truecolor `TuiCellGrid`.

This stage is complete when invalid existing data fails without modification,
missing chunks are atomically generated, restart and chunk-edge movement are
covered end to end, viewport resizing crosses arbitrary chunk ranges, and the
client contains presentation mappings but no world rules.

Mutable objects, savegames, settlements, broader world simulation, and
simulated erosion and hydrology remain outside this stage.

## 5. Area transitions — DONE

Add one server-authoritative transition from an outdoor location into one
interior or dungeon and back. Define stable area identities, entrances, return
locations, and the protocol seam between map and first-person views.

This stage is complete when the server validates both directions of the
transition and the client selects the requested view family without inferring
area rules.

The first implementation places one deterministic dungeon entrance exactly
three traversable steps from spawn. `Enter` changes between the outdoor map and
a distinct first-person state while the server retains the exact return
location. World, protocol, TUI, and loopback tests cover both directions.

See [area transitions](architecture/area-transitions.md).

## 6. First-person interior slice — DONE

Render one small entered interior with terminal raycasting and grid-based
first-person movement. The player always occupies one whole field. A movement
intention advances by at most one field, and turning changes the cardinal
facing direction in 90-degree steps without changing position. Free,
continuous movement and arbitrary view angles are explicitly outside the game
model. The same view family will later serve houses, castles, and dungeons.

This stage is complete when the interior can be entered, navigated one field at
a time, turned through all four facing directions, blocked by solid fields, and
left in an end-to-end test. Final visual style, combat, and generated dungeons
remain outside this stage.

The implemented slice uses one validated 11 by 9 dungeon, server-authoritative
relative steps and cardinal turns, a visible exit field, and a pure truecolor
terminal raycaster. Unit, protocol, headless-TUI, loopback, full-session, and
real-process smoke tests cover the complete path. See
[first-person interior](architecture/first-person-interior.md).

The current presentation checkpoint uses one rearward rendering eye and a
90-degree horizontal projection for both near and distant walls. Immediate
lateral fields are visible so junctions can be read without moving or turning.
This changes presentation, not grid-based movement or interaction reach.

## 7. Persistent game state — DONE

Give each selected world one server-owned, versioned savegame below the
configured runtime-data root. Connecting keeps the client on the start screen
until the player explicitly starts a new game or loads the existing save.
Saving is manual, atomic, and confirmed before overwriting; disconnect and quit
never save implicitly. Client persistence remains limited to endpoint and panel
preferences.

This stage is complete when outdoor and first-person state survive a server
restart with exact position, facing, area identity, and return location;
invalid development saves are removed without touching other world data; and
unit, protocol, headless-TUI, restart, and real-process tests pass. A database
is introduced only if concrete access or recovery requirements make the
file-based approach insufficient.

See [persistent game state](architecture/persistent-game-state.md).

## 8. Exploration and map — DONE

Fog of War and an exploration map now show only places the player has
discovered. Discovery is server-owned game state and survives explicit
save and load. The exploration map exists only as an overlay; the context panel
is not split to contain another map. It shows the current area and can pan
independently of the player without issuing movement intentions.

World knowledge has three states: currently visible, discovered but no longer
visible, and undiscovered. Outdoor visibility initially uses a fixed radius
without terrain occlusion. Interior visibility uses line of sight and does not
reveal fields through walls. Fog of War also masks the outdoor primary view so
a large terminal cannot reveal distant cells automatically.

The overlay uses one terminal cell per world field, opens and closes with `M`,
pans with WASD or the arrow keys, recenters on the player with `Home`, and closes
with `Escape`. Zoom is outside this stage. A new game begins with no discovered
area; an existing save remains unchanged until explicit confirmed saving.

This stage is complete when all three knowledge states have deliberate
presentation, outdoor and interior discovery survive a server restart, opening
and panning the overlay cannot move the player, and protocol, persistence,
client/server, and headless-TUI tests cover the complete behavior.

The implemented slice uses a non-occluded outdoor sight radius of eight fields
and facing-aware interior line of sight. Protocol version 8 masks hidden
terrain, savegame format 2 persists sparse outdoor and bounded interior
discovery masks, and the one-cell-per-field overlay serializes and coalesces
pan requests. Unit, protocol, persistence, headless-TUI, loopback, restart, and
real-process smoke tests cover the complete path. See
[exploration and map](architecture/exploration-and-map.md).

## 9. First RPG interaction — DONE

`Enter` is one generic server-authoritative interaction with the occupied field
or the field directly ahead. Existing entrance and exit behavior uses that
seam. A fixed stone tablet in the initial dungeon proves a read-only inspection
result without introducing inventory, dialogue, or mutable object persistence.
Inspection descriptions open a framed overlay with wrapped, scrollable text
and Enter/Escape dismissal.

The interaction semantics, tablet placement, and presentation are accepted.
Game, protocol, client, server, raycasting, map-overlay, and end-to-end tests
cover descriptive and state-changing outcomes. See
[interaction](architecture/interaction.md).

## 10. Items and inventory — DONE

Build the smallest mutable item loop on top of the generic interaction seam.
The initial dungeon contains one fixed **Ancient coin**. The server owns its
stable identity and whether it lies in the dungeon or is carried by the player;
the client only renders the projected state and sends interaction intentions.

### 10a. Item model and visibility

- [x] Add one stable item identity and one server-owned location state.
- [x] Place the item deterministically in the initial dungeon.
- [x] Include visible inventory entries and visible item cells in the protocol.
- [x] Render the item in the first-person view and exploration map.
- [x] Complete model, protocol, projection, and rendering edge-case tests.

### 10b. Inspection, pickup, and inventory presentation

- [x] Inspect the item with `Enter` while it is directly ahead.
- [x] Pick up the item with `Enter` while occupying its field.
- [x] Remove a picked-up item from the area projection.
- [x] Replace the context panel placeholder with the carried item list.
- [x] Show examine/pickup hints and pickup confirmation in a fixed-height
  Environment panel above Context, with a non-blocking in-view fallback when
  the sidebar is hidden or cannot dock. Render one small coin instead of
  covering its floor field.
- [x] Prove that repeated interaction and reconnects cannot duplicate or lose
  the item.

### 10c. Persistence and completion proof

- [x] Persist the item location or carried state in the current savegame
  format.
- [x] Restore the initial placement when starting a new game.
- [x] Prove pickup, explicit save, server restart, and load end to end.
- [x] Cover malformed, missing, duplicate, and incompatible item state with
  negative and edge-case tests.
- [x] Synchronize the architecture, interaction, persistence, product, and UI
  documentation with the accepted behavior.
- [x] Run the complete workspace and real-process test suite.

Phase 10 is complete only when every item above is checked and game, protocol,
persistence, client, server, rendering, and end-to-end tests cover the complete
path.

The implemented slice uses protocol version 9 and savegame format 3. Unit,
negative, edge-case, protocol, persistence, headless-TUI, loopback, restart,
full-session, and real-process smoke tests cover the complete path. See
[items and inventory](architecture/items-and-inventory.md).

Dropping, equipping, using, stacking, capacity limits, random loot, containers,
shops, and an economy remain outside this phase.

### Presentation follow-up — OPEN

The current dungeon projection and split sidebar are retained as an intermediate
checkpoint, not an accepted final visual design. The item loop remains complete;
further visual work will be discussed separately.

- [x] Use one coherent wall/floor projection and cover lateral openings with tests.
- [x] Separate environment hints from character and inventory information.
- [x] Cover fixed panel height, text wrapping, hidden-sidebar fallback, and
  narrow/short-terminal behavior.
- [ ] Revisit the first-person visual presentation and Ancient coin appearance
  with the user before treating their visual design as final.

## 11. NPCs and simple dialogue — LATER

Introduce one server-owned NPC and one deterministic conversation without LLM
involvement. Dialogue structure, persistence, and presentation will be designed
as a separate slice before implementation.

## 12. Combat — LATER

Introduce one small server-authoritative combat loop with one opponent. Combat
rules, defeat behavior, and their relationship to grid movement will be
designed separately before implementation.

## 13. Character progression — LATER

Define character attributes and progression only after interaction, inventory,
and combat provide concrete requirements. Equipment belongs here unless an
earlier slice demonstrates that it needs its own stage.

## 14. Generated game content — LATER

Expand beyond the fixed initial dungeon with generated interiors, dungeons,
locations, and their contents. Generation remains deterministic and
server-owned.

## 15. Broader world simulation — LATER

Settlements, changing world state, time, weather, and other simulation systems
will be split further when their first concrete gameplay requirement is known.

## 16. Multiplayer behavior — LATER

Multiple simultaneous players require separate authority, visibility,
conflict-resolution, lifecycle, and persistence decisions. The current
single-player client-server model does not imply those rules.

## 17. LLM integration — LATER

LLM integration is explicitly postponed. Its authority boundaries, failure
behavior, cost controls, and effect on deterministic game rules will be
designed separately before implementation begins.
