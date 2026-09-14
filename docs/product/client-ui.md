# Client UI

This document defines the terminal client's presentation and interaction
foundation. It describes the stable shell shared by the map and first-person
views without fixing the final visual design or gameplay-specific panels.

Every client screen, frame, panel, menu, and overlay is implemented with
Functional Pascal's TUI facilities. The client has no separate GUI or web
frontend.

The canonical spatial terms and the assignment of view families are defined in
[world structure and views](world-and-views.md).

## Responsibility boundary

The server owns the world, area kind, geometry, rules, and authoritative player
state. It sends a client-safe visible state that identifies the required view
family. The client owns presentation and translates input into player
intentions; it does not reconstruct hidden world state or decide whether an
intention succeeds.

The client may retain the last visible state while waiting for a response. A
new authoritative state replaces it as one complete presentation snapshot.

## Start screen

Before a session, the client shows a framed menu centered in the terminal:

```text
                 ┌────── INTO THE DUNGEON ──────┐
                 │ Connect                      │
                 │ Information                  │
                 │ Quit                         │
                 └──────────────────────────────┘
```

The frame remains centered as the terminal changes size. Initially the menu
contains connect, information, and quit. A successful connection keeps this
screen visible and enables `New game`; `Load` appears only when the server
reports a valid savegame. Choosing either action shows its pending status until
the first complete visible state arrives. A rejected load remains on the start
screen with the server's explanation. If the server removes an invalid save
during connection, the status explains the removal and only `New game` is
offered.

## Game screen

The active game uses a bordered main row, an optional framed message panel,
and a persistent framed status view:

```text
┌──────────────────────────────────────┬───────────────────┐
│                                      │ Context           │
│                                      │                   │
│             Primary view             │ Character         │
│                                      │ Location          │
│                                      │ Equipment         │
│                                      │ Quick inventory   │
├──────────────────────────────────────┴───────────────────┤
│ Optional message panel                                   │
├──────────────────────────────────────────────────────────┤
│ ctrl-p | Connection, action status, message, or error    │
└──────────────────────────────────────────────────────────┘
```

The primary view and context panel share the available width in a 2:1 ratio on
a wide terminal, so the context panel fills roughly one third of the main row.
It contains summaries rather than the complete inventory or another full game
screen.

The context and message panels can be shown or hidden. The framed status view
remains visible with one content line in the form `ctrl-p | <current message>`.
The current message carries connection feedback, pending actions, and errors;
detailed key bindings remain in the system menu. Hidden panels remain reachable
as overlays when the terminal cannot fit them beside or below the primary view.

## Client states

### Connecting

The client shows that it is connecting and waiting for the server handshake.
Movement input is ignored, and the start screen remains visible. Quit remains
available.

### Active

The latest visible state fills the primary view. The status shows that the
client is connected, and controls appropriate to the current view are enabled.

### Connected without a game session

The framed start screen offers `New game`, optional `Load`, disconnect,
information, and quit. Movement, turning, transitions, viewport projection, and
saving remain disabled until the server accepts a session choice and returns
the initial visible state.

### Request pending

After sending a movement, transition activation, or viewport intention, the existing complete view
remains visible and the status shows that an update is pending. Further
movement is ignored until the server returns either a new visible state or a
rejection. This preserves the request-response protocol and avoids speculative
local movement or partially painted resizes.

### Rejected

The last visible state remains unchanged and the server-provided explanation is
shown in the status area. The client may accept the next intention afterward.

### Connection failed

The failure is visible in the status area and movement is disabled. Recovery or
reconnection behavior is not yet defined.

### Disconnected

The status shows that the session has ended and movement is disabled. Automatic
reconnection is not part of the initial UI.

## Map view

Outdoor regions and settlements use the map view. The server supplies the view
kind, world origin, dimensions, compact visible-cell rows, and local and world
player coordinates. The client maps visible kinds to a restrained glyph and a
concrete truecolor style in a `TuiCellGrid`. Grass, forest, desert, mountains,
sea, rivers, lakes, and paths have distinct palette entries. The player uses a
separate overlay style without changing the received terrain.

Entrances also have their own two-column truecolor cell. The player marker
covers it only while standing on it; the entrance reappears unchanged after the
player leaves.

One world cell occupies two adjacent terminal cells with the same background.
This corrects terminal character proportions and makes continuous color fields
dominant over glyphs. The client does not know chunk coordinates or reproduce
generation, movement, or passability rules.

The first implementation is top-down. A later isometric renderer may present
the same kind of outdoor state differently, but isometric presentation is not a
separate simulation.

## First-person view

Entered interiors and dungeons use a first-person view. The initial dungeon is
rendered with terminal raycasting inside the same framed screen shell. Its
server state supplies validated bounded field rows, dimensions, the area-local
player coordinate, cardinal facing, title, and status. The client derives a
cardinal camera and fills the primary view with colored ceiling, floor, and
distance-shaded walls. The exit is visible with a gold tint. Outdoor map rows
are never reinterpreted as first-person geometry.

First-person movement remains tile-based and server-authoritative. `W` and `S`
request a move by exactly one field forward or backward relative to the current
facing direction. `A` and `D` request a one-field step to the left or right.
`Q` and `E` request a 90-degree turn on the occupied field. A blocked move
leaves both position and facing unchanged. Holding a key may produce separate
intentions, but it never creates continuous movement, fractional coordinates,
or arbitrary viewing angles.

## System menu

`Ctrl+P` opens a framed overlay above the game screen. It contains at least
resume, save, current key bindings, information, available session actions, and
quit. A first save is sent directly. When the server reports that a save already
exists, `Save` opens a confirmation that clearly names the overwrite; cancel
sends nothing. The status reports success only after the server acknowledges
the completed atomic write, and a rejected save can be retried.
While the overlay is open, movement keys operate the menu and no player
intention is sent to the server. `Escape` or another `Ctrl+P` closes it.

The overlay pauses client input only. It does not pause the authoritative
server or other players that may exist later.

## Controls

- `W`, `A`, `S`, and `D` request cardinal one-field movement in the map view.
- `Enter` activates an entrance under the player or leaves a first-person area
  while the player occupies its exit field. Walking onto an entrance or exit
  does not activate it.
- In the first-person view, `W` and `S` move one field forward or backward,
  `A` and `D` step one field left or right, and `Q` and `E` turn 90 degrees
  left or right without changing fields.
- `Ctrl+P` opens or closes the system menu.
- `Escape` closes the active overlay.
- `Alt+X` requests a clean disconnect and exits the client.
- Arrow keys and `Enter` navigate and activate menu entries while a menu owns
  input; no game intention is sent through an overlay.
- Movement is accepted only in the active state with no request pending.

`F2` toggles the context panel and `F3` toggles the message panel. On a narrow
terminal the same keys open or close the corresponding overlay. `Ctrl+P` and
`Alt+X` must be verified on every supported terminal; the system-menu quit
action remains an alternative to `Alt+X`.

Mouse input and remappable keys are not yet defined.

## Terminal size

For a map view, the client derives its requested world-cell width from the
primary view's terminal columns divided by two, after panel and border space.
For a first-person view, every available primary-view terminal column is one
rendered ray column. Both view families account for the framed status view,
primary border, and optional message panel when requesting height. The client
sends this size on connect and whenever terminal size or docked-panel
visibility changes. The server may clamp it to its configured limit.

The client hides the context panel first when horizontal space is insufficient
and hides the optional message panel when vertical space is insufficient. The
primary view and one-line status remain. At still smaller sizes, hidden panels
open as overlays and the TUI may clip the previous complete primary view while
the replacement is pending, but it must not fail or access rows outside the
visible-state bounds. Scrolling, scaling, and a minimum supported terminal size
remain open.

## Completion criteria

The client UI foundation is complete when:

- the framed start screen and its keyboard navigation have headless coverage;
- connecting, active, pending, rejected, failed, and disconnected states have
  deliberate status text and headless test coverage;
- truecolor cell-grid rendering, two-column cells, player overlay, and
  server-provided dimensions are covered headlessly;
- the game-screen layout, panel visibility, menu overlay, movement gating, and
  quit behavior are covered through the update interface;
- a terminal smaller than the rendered content does not crash;
- `Ctrl+P` and `Alt+X` are verified on the supported terminal backends;
- client projects do not import server-owned game rules; and
- the implementation and this document describe the same behavior.

Title artwork, complete inventory, combat UI, dialogue UI, textured or final
first-person styling, and accessibility conventions are deferred until their
corresponding gameplay slices are planned.
