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
contains connect, information, and quit. A successful connection shows the server's world catalog with original seed,
entrance-region size, compatibility and save status. Previous/next controls page
through the list. The server fully checks only the requested page and, when
outside that page, the selected world. Refresh checks those entries again;
Continue independently validates the selected save and all its referenced
dungeon levels. `Create world` opens controlled seed and region inputs with
server-provided defaults and ranges. `Continue` loads the selected world's
explicit save or starts at spawn if absent. `Start over` starts fresh in the
same world and keeps its earlier save. The catalog is a table with fixed
columns (world, status, seed, region, save), at most 76 cells wide; rows clip
by terminal cells. Incompatible worlds and saves are never deleted
automatically; the reason appears once, for the selected world, wrapped below
the table. The list cursor belongs to the
client and always lies within the displayed rows; an empty list has no cursor.
Paging, a missing preselection and resize reconcile that cursor without
changing the server-selected world or implicitly queuing a selection request.

While a selection or start request is pending, further requests are gated.
Cancel confirms disconnecting; it does not roll back server work that may
already have completed. A rejection keeps the existing selection or editor and
shows the server's explanation. Missing startup preselection still allows
creation and selection. The system menu's `Choose world` returns to the same
connected catalog. Unsaved progress requires discard confirmation; cancellation
keeps the active game. Saving over an existing save requires a separate explicit
overwrite confirmation.

Behind the menu, the client draws a colored ASCII view of an overgrown dungeon
entrance at dusk. The geometry is generated from the current terminal size:
small terminals retain the gate and path, while larger terminals add mountains,
trees, stars, and torches. The menu remains an opaque, focused overlay inside
the entrance, so decoration never competes with labels or controls. Connection,
session-selection, pending, information, confirmation, and defeat states share
the same backdrop. The client prepares its immutable cell grid once for the
current terminal size and retains it in the presentation model. Focus changes,
menu navigation and editor input reuse that grid. A changed size rebuilds it
while a start screen is visible; resizing during gameplay defers that work until
the client returns to a start screen. Rendering a standalone unprepared model
still builds the correctly sized artwork without changing the supplied model.

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

Context contains summaries rather than another full game screen. Its equipment
section lists the two server-owned worn slots, such as `Weapon: Rusty short sword`,
or `Nothing worn`. Quick inventory shows carried items in projection order and
`Empty` when there are none. It uses at most four rows, reduced to the height
remaining after the fixed context labels and equipment. When names are omitted,
its final row shows `+N more (I)`; if only one row fits, it shows `N items (I)`.
If no item row fits, the heading itself states the carried count.
Open `I` to reach every item. Long inventory/equipment names are clipped by
terminal-cell width without splitting graphemes.

Docking reserves the seven-row Environment panel and at least fourteen rows
for Context, including its frame, nine fixed labels, up to two worn slots and
one quick-summary row. This requires width 72 and height 24 with Messages
hidden, or height 30 with Messages docked. Inventory count does not enlarge
the sidebar or change these thresholds. Item identity, ownership and rules
remain server-owned.
The F2 overlay additionally reserves its outer frame and Close button and omits
one optional context spacer, keeping the button and bottom frame inside the surface.

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

The framed start screen offers the catalog, Create world, Continue and Start
over when applicable, disconnect, information and quit. Game intentions remain
disabled until the server accepts a session choice and supplies visible state.

### Request pending

While a new or loaded session is starting, the framed start screen shows only
the pending status, a wait message, and the confirmed cancel action described
above. After sending a movement, transition activation, or viewport intention,
the existing complete view remains visible and the status shows that an update
is pending. Further movement is ignored until the server returns either a new
visible state or a rejection. This preserves the request-response protocol and
avoids speculative local movement or partially painted resizes.

The primary pending request and the exploration-map request are independent.
The client marks progress unsaved after an accepted state reply to a changing
intention; queuing an intention alone does not mark it successful. A rejected
intention preserves the unsaved-progress hint, except that `discard_required`
corrects it from the authoritative server. Successful saving, installing a
world catalog and defeat clear the hint. Starting a fresh session creates
unsaved progress, while continuing an existing save starts clean.

Internally, `PendingChangesProgress` describes an outstanding intention that
expects a primary state; `PendingCreatedWorld` additionally invalidates the
previous catalog/save hint when its creation reply arrives. State, rejection
and catalog installation clear those flags. Returning to start and applying a
failure/disconnection clear `Pending` and can retain inactive flag values and the
old dirty hint; they are not session facts
outside their request or active visible game. A newly accepted catalog resets
them before another session starts. Generation checks ignore all late events
from a cancelled or replaced connection. Quitting invalidates the attempt and
ends the application without resetting its final model snapshot.

### Rejected

The last visible state remains unchanged and the server-provided explanation is
shown in the status area. The client may accept the next intention afterward.

### Connection failed

The failure is visible in the status area and movement is disabled. Connect
starts a new connection attempt with its own request queue. Late events from
previous attempts cannot replace the current screen, status or visible state.

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

Resizing refreshes the primary view without closing the exploration map or
changing its received projection, desired window or pending map request. The
client adapter retains the viewport response's intent internally, so this
read-only state refresh preserves the current overlay and focus. Map and
viewport replies resolve their own pending requests independently, regardless
of which arrives first. Home requests map dimensions for the current terminal;
the received dimensions remain in use until a complete map reply replaces
them. Closing the map while a refresh is pending keeps it closed when the
reply arrives. Ordinary gameplay/session states retain their existing behavior.

The overlay derives entirely from server-owned discovered-area state; the
client does not reconstruct unknown world cells. Requesting or panning a map
window never discovers fields and never generates unknown outdoor terrain. A
new game starts with an empty discovered area. Explicit saving persists it and
retains the existing save until overwrite is confirmed.

## First-person view

Entered interiors and dungeons use a first-person view. Generated dungeons are
rendered with terminal raycasting inside the same framed screen shell. Its
server state supplies validated bounded field rows, dimensions, the area-local
player coordinate, cardinal facing, title, and status. The client derives a
cardinal camera and fills the primary view with colored ceiling, floor, and
distance-shaded walls. The exit is a gold floor field, projected at its actual
location. The Ancient coin uses a gold marker in the first-person view
and exploration map until it is picked up.
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
Remembered map fields retain only static geometry rather than stale dynamic markers.
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
side corridor. First-person geometry uses currently visible fields only.
Unknown and remembered fields both stop the view with dark fog; previously
visited walls cannot extend the current sight range. Remembered geometry
remains available, dimmed, on the exploration map.
Only the rendering eye moves backward; gameplay still uses the occupied field.

First-person movement remains tile-based and server-authoritative. `W` and `S`
request a move by exactly one field forward or backward relative to the current
facing direction. `A` and `D` request a one-field step to the left or right.
`Q` and `E` request a 90-degree turn on the occupied field. A blocked move
leaves both position and facing unchanged. Holding a key may produce separate
intentions, but it never creates continuous movement, fractional coordinates,
or arbitrary viewing angles.

## Combat

The Character section of the context panel shows health as numbers and an
eight-segment bar, for example `Health 14/20 ██████░░`. While an opponent stands
directly ahead, the Environment panel names it with its health and the attack
key. Every message of a resolved turn is appended to the message history, and
the last one also becomes the status text. When a turn lowers health, a red
frame surrounds the first-person image until the next projection; starting or
loading a game never shows it.

After a first-person turn with combat events the client plays a short combat
animation of at most three 160 ms phases: the player's swing with a blade or a
fist, then a white hit flash with a rising damage number or a sideways dodge
with `miss`, then the opponent's lunge. The red frame and the player's rising
damage number wait for that lunge; a destroyed opponent sinks into the floor.
The animation only presents the already resolved state. Any key completes it at
once and is then handled normally. While an animation runs, the client requests
a host tick every 40 ms; walls and floor are rendered once at its start, so
each frame only composes sprites and texts.

Combat effects currently identify opponent kinds, not individual figures.
Generated levels contain one restless skeleton and one giant rat, so each
kind identifies at most one figure there. With several visible opponents of
the same kind, an effect would be applied to every matching sprite. Supporting
such groups first requires a distinct figure or position in the combat-event
and animation contract, including standing/fallen targeting. This is an
extension boundary; the current generated content and protocol stay unchanged.

Defeat returns to the session start screen with a `You have fallen` overlay
containing the server's summary. `Continue` closes it with `New game` focused,
or `Cancel` while the world-catalog refresh is still pending. The player can
then load the last explicit save or start again. Disconnect and connection
failure stop animation and return to the start screen; late ticks cannot resume
it. This includes a viewport request deferred behind an inventory action.

## Equipment

`I` opens the inventory overlay. Every carried and worn item is reachable in
a selection-following window of at most twelve rows, reduced to terminal height.
The title shows the visible range and total. Projected health, selected Enter
action, drop/navigation/close hints and the turn cost stay below the window.
Long entry text is clipped by terminal-cell width without splitting graphemes;
the selected action remains visible separately. W/S or Up/Down select;
`Enter` asks the server to use a usable
item, otherwise wear or remove gear. `D` asks the server to drop the selected
item on the occupied dungeon floor field, and `Escape` or `I` closes the overlay.
Items without a projected action do not send an Enter request. Full-health use
is still sent so the server can decide and explain rejection.

The overlay stays open through the reply. Accepted state changes update health
and inventory together; a rejection retains the potion, selection and server
reason. The client never heals or removes an item optimistically and consumption
never announces pickup. Only active visible sessions can queue actions, with
no request pending and a writable request channel. Other overlays keep their
input ownership. Explicit navigation wraps; a refresh retains the selected ID
when present, otherwise clamps the previous index, including an empty list.
Using, changing or dropping an item takes a turn, so an adjacent opponent may
strike in between. Hostile animation events still play, with no player swing.

Inventory actions require at least 32 by 8 terminal cells. Below that threshold
the overlay shows `Resize to 32x8`; Enter and D send no item intention, while
Escape/I still close it. This is an inventory-specific threshold. Resize and
authoritative refresh recalculate the visible window without extra scroll state.

`C` opens the character sheet, a read-only scrolling overlay owned by
`Dungeon.Client.CharacterSheet`. Health and the visible row range stay above the
body; two hint rows stay below it. The body shows each server-formatted line as
a label/value row and a source row, for example `Blades L2 XP 12/36` and
`· Active; next: hit +1`, followed by the worn equipment. The six lines are
maximum health, hit chance, damage, armor, Unarmed and Blades; skill lines show
total experience and the next cumulative threshold (see
[progression](../architecture/progression.md)).

- Body rows are the terminal height minus 6; the body is at most
  `min(width - 4, 76)` cells wide and clips by terminal cells.
- `Up`/`Down` or `W`/`S` scroll one row, clamped without wrapping. Other keys,
  including Space and Enter, do nothing; no key reaches the game while the sheet
  is open. Opening, closing and scrolling consume no turn.
- Below 32 by 8 cells only `Resize to 32x8` and the close hint are shown.
- The UI-only offset is clamped after resizing or an authoritative refresh,
  kept while the sheet stays open, and reset on a fresh open, close or return to
  the start screen. A late reply never reopens a closed sheet.
- `I` switches to the inventory, `Escape` or `C` closes it. Level notices appear
  in the normal combat log. The client never parses or computes these values.

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

## Quest journal

`J` opens the server-projected journal during an active game. It shows accepted
objectives, active or ready-to-return progress, and completed outcomes. The
client displays these lines without inferring completion from inventory.
Long lines wrap to the available width. W/S or arrows scroll one row;
Page Up/Down scroll a page. Escape/J closes it. Other gameplay keys are consumed
locally, with no intention, turn or dirty-state change. Resize and authoritative
refresh retain the overlay and clamp its wrapped-row offset. Active dialogue
keeps keyboard ownership, so J cannot open another overlay while talking.

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
- In the first-person view, `Space` attacks the field directly ahead and `Z`
  waits one turn. Both are turns and, like steps, are accepted only with no
  request pending. `Enter` never attacks.
- `I` opens or closes the inventory overlay and `C` the character sheet; both
  need an active game and no other overlay.
- `J` opens or closes the read-only quest journal; W/S, arrows and Page Up/Down
  scroll its wrapped text.
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
visible-state bounds. The inventory has its own bounded window and action-size
threshold described above; a minimum supported size for the whole game remains
open.

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

Inventory use, gear controls, kind-specific combat art and death animation have
headless and TCP coverage. The user accepted 14b on 2026-10-16. Accessibility
conventions and further first-person styling remain later work.

## Settlement dialogue

Hearthmoor and generated villages use the map view with bounded local coordinates and no facing.
WASD or arrows request absolute cardinal steps. Server-projected titles name
the stored area name; Environment shows gate entry/exit and the selected NPC's
`name — Enter: Talk` hint. House blocks use `▩`, gates `⌂`, and NPCs `M`;
fog applies in both map views.

Enter beside an NPC opens a framed dialogue with the server's text and ordered
choices. W/S and arrows wrap the selection; Enter submits the stable choice ID.
Answers refresh the same window, including removal of healing after health
is restored. Escape requests an end and retains the window until the reply.
Pending requests suppress repeated input, and ordinary movement or other
overlays are blocked while talking. Alt+X still exits cleanly. Text wraps and
Page Up/Down scrolls long frames on small terminals. Resize preserves the
frame and selection; new answers reset selection. No choices or NPC behavior
are inferred by the client. Pending text names the server-projected speaker.
Residents, guards, healers and merchants use the same controls; healing and topic
availability remain server-owned. See the [15c review route](../architecture/generated-settlements.md#reproducible-acceptance).

## Trade

Elias in Hearthmoor and each village merchant offer **Show me your wares**.
The separate trade window shows the merchant, coin balance, selected price,
Buy/Sell side, page, individual goods and reasons for unavailable actions.
Tab switches sides; Up/Down selects; Page Up/Down requests another 16-item
page. Enter buys or sells one enabled selected item immediately. Escape
returns to the conversation, then Escape ends it. Alt+X keeps normal quitting.
Worn gear must be removed in inventory before selling. The compass is unavailable.

All page rows remain reachable by local scrolling at **40x12** or larger.
Smaller terminals show a size hint and allow closing, while trade/page actions
are suppressed. Long refusal text scrolls with Left/Right without hiding price
or controls. The client renders server prices and capabilities; it calculates
no transaction result. One pending request blocks further actions. Rejection
retains the quote and displays the reason. A surviving selected ID remains
selected after transfer; otherwise its index is clamped. Page replies reset
to a valid first row. Resize and viewport replies retain the modal and selection.

Coins remain visible in context and inventory outside trade, separately from
items. The context sidebar reserves the extra wallet row before docking.
See [economy](../architecture/economy.md) and the
[running-game verification](../architecture/economy-acceptance.md).
