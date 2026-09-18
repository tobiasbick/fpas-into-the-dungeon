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
the first complete visible state arrives. While the session choice is pending,
the menu is replaced by the status, `Please wait.`, and a single `Cancel`
button. Cancel requires confirmation because it closes the connection and
returns to the initial start menu; it does not roll back server work that may
already have completed. A rejected load restores the session menu with the
server's explanation. If the server removes an invalid save during connection,
the status explains the removal and only `New game` is offered.

## Game screen

The active game uses a bordered main row, an optional framed message panel,
and a persistent framed status view:

```text
┌──────────────────────────────────────┬───────────────────┐
│                                      │ Environment       │
│                                      │ Object / action   │
│                                      ├───────────────────┤
│                                      │ Context           │
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
The right-hand column has two separately framed sections: a fixed seven-row
`Environment` panel (five content rows) above an expanding `Context` panel.
Environment shows server-provided interaction hints and pickup confirmation,
wrapped to its width, or `Nothing in reach` when no hint exists. Its height
does not change when the player moves or picks up an item. General connection
messages and errors stay in the status view and message history.
Both sections are toggled together with F2; the narrow-screen context overlay
also includes both sections.
Docking also requires enough height for both frames and the existing character
summary; short terminals use the same overlay and hint fallback as narrow ones.

Context contains summaries rather than another full game screen. Its quick inventory
lists the carried item names projected by the server and displays `Empty` when
the player carries nothing. Item identity, ownership, and rules never move into
the client.

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

While a new or loaded session is starting, the framed start screen shows only
the pending status, a wait message, and the confirmed cancel action described
above. After sending a movement, transition activation, or viewport intention,
the existing complete view remains visible and the status shows that an update
is pending. Further movement is ignored until the server returns either a new
visible state or a rejection. This preserves the request-response protocol and
avoids speculative local movement or partially painted resizes.

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

## Exploration map

The exploration map is distinct from the primary map view. It presents only
the current area's world knowledge retained through exploration and opens as a
framed overlay above either view family. There is no additional map in the
right-hand context panel. Outdoors the overlay can pan across discovered
chunks; inside it shows the discovered part of the current floor.

The map distinguishes currently visible, discovered but no longer visible, and
undiscovered fields. Visible fields use the normal palette, remembered fields
use half-intensity foreground and background RGB colors, and undiscovered fields are dark and contain no terrain or geometry
information. Fog of War applies to the exploration map, the outdoor primary
view, and undiscovered first-person geometry. Outdoor fields become visible
within a fixed radius of eight fields; terrain does not occlude that radius.
Interior visibility uses a facing-aware line of sight with a range of eight
fields. A blocking wall remains visible while fields behind it do not.

`M` opens or closes the overlay. WASD and the arrow keys pan it, `Home`
recenters it on the player, and `Escape` closes it. These controls never move
the player or send movement intentions. The overlay uses one terminal cell per
world field and has no zoom in this stage; the primary map view retains its
two-column fields. On a sufficiently large terminal, its requested dimensions
use roughly four fifths of the terminal before accounting for the overlay frame
and controls. This leaves the game screen visible around the centered map.
Small terminals retain compact margins so map content remains useful. The
result is clamped to at least one field and at most 240 by 120 fields. Outdoor
windows accept signed origins. An interior window may extend beyond the current
finite floor; those positions appear as undiscovered padding rather than
changing the window.

Only one map request is in flight. Additional pan input changes the desired
origin and is coalesced into the next request. The overlay shows
`Loading map...` before its first projection. While updating, it retains the
previous valid projection and shows `Updating map...` in the status view without
adding an overlay row or changing its size; a recoverable rejection
also retains it and reports the error in the status view.

The overlay derives entirely from server-owned discovered-area state; the
client does not reconstruct unknown world cells. Requesting or panning a map
window never discovers fields and never generates unknown outdoor terrain. A
new game starts with an empty discovered area. Explicit saving persists it and
retains the existing save until overwrite is confirmed.

## First-person view

Entered interiors and dungeons use a first-person view. The initial dungeon is
rendered with terminal raycasting inside the same framed screen shell. Its
server state supplies validated bounded field rows, dimensions, the area-local
player coordinate, cardinal facing, title, and status. The client derives a
cardinal camera and fills the primary view with colored ceiling, floor, and
distance-shaded walls. The exit is a gold floor field, projected at its actual
location. A fixed wall-mounted stone tablet uses a distinct blue-gray material
in the first-person view and a distinct symbol on the exploration map. It
remains opaque like the wall that carries it. The fixed Ancient coin uses a gold
marker in the first-person view and exploration map until it is picked up.
In first person it is a small disc in the field center. The Environment panel
identifies the available action: examine while facing the adjacent coin, or
pick up when standing on it. Pickup confirmation remains until the next state
update. With the sidebar hidden or unable to dock, a non-blocking fallback hint
is painted over the bottom image row without resizing the primary view. No
dialog opens automatically when stepping onto an item; explicit inspection
still opens the description overlay. The status view continues to show
connection and request feedback.
Walls keep their stone material even when a view ray crosses the exit or coin.
Moving onto either field colors only the visible part of that floor field.
Outdoor map rows
are never reinterpreted as first-person geometry. The visual eye sits 0.35 fields
behind the field center, still inside the occupied field, with a 90-degree
horizontal view. This exposes the immediate side openings both before a wall
and at a junction where the path ahead is open. Closed sides form perspective
walls toward the screen edges; open sides expose the adjoining space. A
continuous wall retains continuous edges, and recessed walls shrink with
distance. Walls, floor, exits, and items use the same projection at every
distance rather than switching to a special close-wall layout.
The server exposes the immediately adjacent lateral fields, but not an entire
side corridor. Unknown geometry stays opaque and uses its own dark material.
Only the rendering eye moves backward; gameplay still uses the occupied field.

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
- `Enter` requests an interaction with the occupied field or the field directly
  ahead. It activates an entrance under the player, leaves a first-person area
  from its exit field, picks up an item under the player, or examines an
  inspectable object ahead. A successful
  inspection opens a centered, framed overlay with a title and wrapped text.
  Up/Down scrolls longer descriptions; Enter or Escape closes the overlay.
  Gameplay input is blocked while reading. Short no-target feedback remains in
  the status view, and descriptions are retained in message history. Walking onto
  an entrance or exit does not activate it.
- In the first-person view, `W` and `S` move one field forward or backward,
  `A` and `D` step one field left or right, and `Q` and `E` turn 90 degrees
  left or right without changing fields.
- `Ctrl+P` opens or closes the system menu.
- `M` opens or closes the exploration map. While it is open, WASD and the arrow
  keys pan, and `Home` recenters on the player.
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
