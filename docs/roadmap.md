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

## 7. Persistent game state — NEXT

Save and restore the selected world and authoritative player state below the
configured runtime-data root. The storage format must be versioned and updates
must not leave a partially written save.

A database is introduced only if concrete access or recovery requirements make
the file-based approach insufficient.

## 8. First RPG interaction — OPEN

Choose one small interaction only after movement, views, transitions, and
persistence have stable seams. Possible candidates include examining an
object, picking up an item, or speaking to one character. The choice is
deliberately not made in this roadmap.

## 9. Further game systems — LATER

Inventory, combat, character progression, multiplayer behavior, content
generation, and broader world simulation will each require their own small
slice. Their order is intentionally undecided.

## 10. LLM integration — LATER

LLM integration is explicitly postponed. Its authority boundaries, failure
behavior, cost controls, and effect on deterministic game rules will be
designed separately before implementation begins.
