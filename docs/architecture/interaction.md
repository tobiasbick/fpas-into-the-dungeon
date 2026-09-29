# Interaction

The first RPG interactions use one small server-authoritative seam without
defining a general scripting system.

## Semantics

`Enter` sends the protocol version 13 `interact` intention while the game screen
is active, no overlay owns input, and no earlier request is pending. The server
resolves the occupied field first for state-changing actions, then the field
directly ahead for an inspectable object. Interaction never moves or turns the
player implicitly.

There are three successful outcomes:

- a transition replaces authoritative game state and returns a complete visible
  state;
- a state change, such as picking up an item, replaces authoritative game state
  and returns a complete visible state;
- a description leaves authoritative game state unchanged and returns an
  `interaction` message containing a title and text. A nonempty title opens a
  centered, framed description overlay. An empty title denotes a short status
  response, such as having no target. Both outcomes are retained in message history.

The description overlay wraps text to the available width. Longer descriptions
scroll with Up/Down. Enter or Escape closes it, and gameplay keys send no
intentions while it is open. Its content and scroll position are client
presentation state and are not saved.

Having no target is a successful descriptive outcome rather than a protocol or
rule error. Invalid session or game state remains a structured rejection.

## First collectible item

The fixed Ancient coin extends the same seam. From the adjacent start field,
`Enter` inspects it without changing state. After the player moves onto its
field, `Enter` moves the server-owned item into the player's inventory. The
updated visible state removes the item from the dungeon and adds it to the
projected quick inventory. Further interaction cannot create another copy.

The complete ownership, projection, and persistence contract is described in
[items and inventory](items-and-inventory.md).

## Deferred systems

Multiple item kinds, interaction menus, reach beyond one field, using, stacking,
capacity limits, general mutable object state, and configurable bindings remain outside this slice.
They should extend or replace this narrow model only when a concrete gameplay
requirement needs them.
