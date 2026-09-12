# Client UI

This document defines the initial terminal client's presentation and
interaction foundation. It describes the stable shell shared by the current map
view and later first-person views without fixing the final visual design or
gameplay-specific panels.

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

## Screen shell

The initial screen is a vertical terminal layout:

```text
INTO THE DUNGEON

<primary view>

<connection or action status>
<controls relevant to the current view>
```

The primary view changes between map and first-person presentation. The title,
status, and contextual controls form the shared shell. Borders, colors, and
exact spacing are not yet part of the product contract.

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

## Initial controls

- Arrow keys request one cardinal movement step in the map view.
- `Q` requests a clean disconnect and exits the client.
- Movement is accepted only in the active state with no request pending.

Mouse input, remappable keys, menus, and first-person controls are not yet
defined.

## Terminal size

Map dimensions come from the server rather than the terminal. The initial
client may use the TUI framework's clipping when content exceeds the available
space, but it must not fail or access rows outside the visible-state bounds.
Scrolling, scaling, responsive rearrangement, and a minimum supported terminal
size remain open.

## Completion criteria

The client UI foundation is complete when:

- connecting, active, pending, rejected, failed, and disconnected states have
  deliberate status text and headless test coverage;
- map rendering is covered with server-provided dimensions that differ from
  the first fixed map;
- movement gating and quit behavior are covered through the update interface;
- a terminal smaller than the rendered content does not crash;
- client projects do not import server-owned game rules; and
- the implementation and this document describe the same behavior.

Final colors, decorative borders, title artwork, menus, inventory, combat UI,
dialogue UI, first-person styling, and accessibility conventions are deferred
until their corresponding gameplay slices are planned.
