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

## 3. Client UI foundation — NEXT

Establish the stable presentation and interaction shell before adding loaded
world data. Bring the implementation and headless tests up to the states,
layout, controls, and small-terminal behavior described in the
[client UI](product/client-ui.md) document.

This stage is complete when connecting, active, pending, rejected, failed, and
disconnected states have deliberate presentation and test coverage; map sizes
remain server-defined; and a terminal smaller than the content does not crash
the client. Final styling and gameplay-specific panels remain outside this
stage.

## 4. Data-driven outdoor region — LATER

Move the outdoor geometry and terrain out of compiled game code into a small,
validated world-data file. The server loads the data and continues to send only
client-safe visible state, so the client does not gain world rules or direct
file access.

This stage is complete when a deterministic fixture can start the server,
invalid world data fails with a useful error, and the existing client can
navigate the loaded region unchanged. Procedural generation and databases are
not part of this stage.

## 5. Area transitions — LATER

Add one server-authoritative transition from an outdoor location into one
interior or dungeon and back. Define stable area identities, entrances, return
locations, and the protocol seam between map and first-person views.

This stage is complete when the server validates both directions of the
transition and the client selects the requested view family without inferring
area rules.

## 6. First-person interior slice — LATER

Render one small entered interior with terminal raycasting and support the
minimum movement needed to explore it. The same view family will later serve
houses, castles, and dungeons.

This stage is complete when the interior can be entered, navigated, and left in
an end-to-end test. Final visual style, combat, and generated dungeons remain
outside this stage.

## 7. Persistent game state — LATER

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
