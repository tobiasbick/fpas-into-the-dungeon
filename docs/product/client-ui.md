# Client UI

This document defines the initial terminal client's presentation and
interaction foundation. It describes the stable shell shared by the current map
view and later first-person views without fixing the final visual design or
gameplay-specific panels.

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
contains connect, information, and quit. Loading becomes available only after a
server connection because the server owns saved games. Saving belongs in the
system menu during a session. Load and save entries appear only when those
server operations exist.

## Game screen

The active game uses a bordered main row and a persistent status line:

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
│ Connection, action status, message, or error             │
└──────────────────────────────────────────────────────────┘
```

The primary view and context panel share the available width in a 2:1 ratio on
a wide terminal, so the context panel fills roughly one third of the main row.
It contains summaries rather than the complete inventory or another full game
screen.

The context and message panels can be shown or hidden. The one-line status line
remains visible because it carries connection feedback, pending actions, and
errors. Hidden panels remain reachable as overlays when the terminal cannot fit
them beside or below the primary view.

## Client states

### Connecting

The client shows that it is connecting and that it is waiting for initial world
state. Movement input is ignored until the server has completed the handshake.
Quit remains available.

### Active

The latest visible state fills the primary view. The status shows that the
client is connected, and controls appropriate to the current view are enabled.

### Request pending

After sending a movement intention, the existing view remains visible and the
status shows that movement is pending. Further movement is ignored until the
server returns either a new visible state or a rejection. This preserves the
request-response protocol and avoids speculative local movement.

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
kind, dimensions, terrain rows, and player coordinates. The client renders the
terrain glyphs unchanged and overlays `@` at the authoritative player position.
It must not assume the initial 13 by 7 dimensions.

The first implementation is top-down. A later isometric renderer may present
the same kind of outdoor state differently, but isometric presentation is not a
separate simulation.

## First-person view

Entered interiors and dungeons use a first-person view. It will be rendered
with terminal raycasting inside the same screen shell. Its visible-state payload
and controls will be specified with the first interior slice; map rows must not
be reinterpreted as first-person geometry by the client.

## System menu

`Ctrl+P` opens a framed overlay above the game screen. It contains at least
resume, current key bindings, information, available session actions, and quit.
While the overlay is open, movement keys operate the menu and no player
intention is sent to the server. `Escape` or another `Ctrl+P` closes it.

The overlay pauses client input only. It does not pause the authoritative
server or other players that may exist later.

## Controls

- `W`, `A`, `S`, and `D` request cardinal movement in the map view.
- In the first-person view, `W` and `S` move forward and backward, `A` and `D`
  move sideways, and `Q` and `E` turn.
- `Ctrl+P` opens or closes the system menu.
- `Escape` closes the active overlay.
- `Alt+X` requests a clean disconnect and exits the client.
- Arrow keys and `Enter` navigate and activate menu entries.
- Movement is accepted only in the active state with no request pending.

`F2` toggles the context panel and `F3` toggles the message panel. On a narrow
terminal the same keys open or close the corresponding overlay. `Ctrl+P` and
`Alt+X` must be verified on every supported terminal; the system-menu quit
action remains an alternative to `Alt+X`.

Mouse input and remappable keys are not yet defined.

## Terminal size

Map dimensions come from the server rather than the terminal. The initial
client hides the context panel first when horizontal space is insufficient and
hides the optional message panel when vertical space is insufficient. The
primary view and one-line status remain. At still smaller sizes, hidden panels
open as overlays and the TUI may clip the primary view, but it must not fail or
access rows outside the visible-state bounds. Scrolling, scaling, and a minimum
supported terminal size remain open.

## Completion criteria

The client UI foundation is complete when:

- the framed start screen and its keyboard navigation have headless coverage;
- connecting, active, pending, rejected, failed, and disconnected states have
  deliberate status text and headless test coverage;
- map rendering is covered with server-provided dimensions that differ from
  the first fixed map;
- the game-screen layout, panel visibility, menu overlay, movement gating, and
  quit behavior are covered through the update interface;
- a terminal smaller than the rendered content does not crash;
- `Ctrl+P` and `Alt+X` are verified on the supported terminal backends;
- client projects do not import server-owned game rules; and
- the implementation and this document describe the same behavior.

Final colors, title artwork, complete inventory, combat UI, dialogue UI,
first-person styling, and accessibility conventions are deferred until their
corresponding gameplay slices are planned.
