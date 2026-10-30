# Design language

Into the Dungeon follows a classic-retro visual direction: warm, dark surfaces,
parchment text and restrained brass accents.

## Theme colors

| Role | Color | RGB |
| --- | --- | --- |
| Background | Near-black brown | `#17140F` |
| Area surface | Dark brown | `#211C15` |
| Overlay surface | Lighter brown | `#2B241A` |
| Button surface | Brown | `#383023` |
| Default button surface | Dark gold brown | `#4A3C27` |
| Frame | Muted brass | `#A68A55` |
| Active frame and focus | Light gold | `#E2C477` |
| Text | Parchment | `#E8DFC7` |
| Secondary text | Muted beige | `#A99D86` |
| Selection background | Dark gold brown | `#705522` |
| Success | Muted green | `#8FBF78` |
| Warning | Amber | `#E0A85A` |
| Error | Muted red | `#DB7770` |
| Cancel | Muted sage | `#B5BBA6` |

Focused selections use light text on the selection background; an unfocused
selection remains gold. Use color alongside
labels, symbols or other visible cues when conveying status or focus.
Game-world artwork may use additional colors to represent its content.

## Frames and overlays

Every distinct interface area and every overlay has a continuous frame. A title
in the top edge is optional. Ordinary frames use muted brass; the active area's
or overlay's frame uses light gold. Overlays use the lighter overlay surface to
stand apart from the content behind them.

Tab bars show the selected page in gold. When the bar has keyboard focus, the
selected tab uses the selection background; it remains marked after focus moves
into the page. Disabled tabs use muted text.

## Dialog layout

- Keep a dialog's size stable when switching tabs or changing content. Center
  it and let it grow with the terminal.
- Place vertical tabs at the left or right of the content, with at least one
  empty column between the tab bar and the page.
- Separate headings, controls, lists and actions with empty lines when space
  permits. Keep related controls together.
- Lists use the available content width. Align their frame with the content
  and action row.
- Place primary and cancel actions together at the bottom right, in the order
  `Save  Cancel` or `OK  Cancel`.
- Place secondary actions such as `Test connection` at the bottom left,
  aligned with the content, on the same row when space permits.
- On smaller terminals, reduce spacing and visible list rows first. Keep actions
  reachable and preserve their order.

## Controls and focus

- Buttons are distinguished by theme colors, with no automatic brackets.
- Use parchment for normal actions, gold for primary actions, muted sage for
  cancel, amber for warnings and red for dangerous actions. Disabled actions
  use muted beige. Headings use light gold on their surrounding surface.
- Button meaning is independent of interaction state and the default action.
  Focus and presses change the color while retaining the meaning's hue; active
  choices and default actions also have distinct styles.
- Give focused and active elements a brighter or otherwise distinct theme
  color. Keep selection visible when focus moves elsewhere.
- In an activating list, Up/Down move the selection and scroll it into view.
  Enter activates the selection; a mouse click selects and activates it.
- Show status and secondary information as text.

We will refine symbols, layout and other details as we review the running game.

The current client interface and its behavior are described in
[Client UI](client-ui.md); the server dashboard is described in
[Server console](server-console.md).
