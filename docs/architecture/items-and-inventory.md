# Items and inventory

Phase 10 introduces one deliberately narrow mutable-item loop. It proves that
an item can be visible, inspected, picked up, projected to the client, and
persisted without adding a general loot, equipment, or scripting system.

## Authoritative model

`libs/game` owns every item. An item has a stable ID, a kind, and exactly one
location. The current model permits the fixed Ancient coin either at field
`8,1` in the initial dungeon or in the player's inventory. Validation requires
exactly one coin with the expected identity and rejects missing, duplicate,
unknown, or misplaced item state.

Starting a new game always creates the coin at its initial dungeon field. Area
transitions and movement preserve its state. The client never creates, moves,
or owns items.

## Interaction

The generic `Enter` intention resolves the occupied field before the field
directly ahead:

- when the coin is directly ahead, interaction returns its description and
  leaves state unchanged;
- when the player occupies the coin's field, interaction changes its location
  to the player's inventory and returns a fresh visible state;
- after pickup, the same interaction cannot find or create another coin.

No action menu or scripting layer is required for this fixed rule. Future
interactions may introduce a more general mechanism only when their concrete
requirements justify it.

## Protocol and presentation

Protocol version 9 projects visible inventory entries as stable ID and display
name pairs. Both map and first-person visible states carry the same bounded,
validated inventory projection. The dungeon uses cell code `i` only while the
coin remains on its field and Fog of War permits that field to be shown.

The first-person renderer and exploration map draw the coin in gold. After
pickup, the field returns to its underlying floor presentation. The context
panel lists `Ancient coin` under `Quick inventory`; an empty inventory is shown
as `Empty`.

The first-person coin occupies a small disc at the center of its floor field.
A non-blocking hint is painted over the bottom image row without resizing the
view. The server supplies `Ancient coin — Enter: Examine` when it is directly
ahead and `At your feet: Ancient coin — Enter: Pick up` on its field, regardless
of facing. After an authoritative inventory addition, the client shows
`Picked up: Ancient coin` until the next visible-state update. Loading existing
inventory does not announce a pickup. These hints remain available with the
context panel hidden; movement and inspection controls remain unchanged.

## Persistence

Savegame format 3 stores the complete item array alongside player, return, and
exploration state. Each location is an explicit variant: an interior area and
field, or carried by the player. Loading validates the full state before it can
replace the active game. Format 2 and other obsolete schemas are rejected and
removed according to the current-version-only configuration and save policy.

An explicit save is the only persistence boundary. Disconnecting, reconnecting,
or rendering cannot change item ownership. Saving and loading a carried coin
must preserve exactly one carried coin; starting a new game must restore
exactly one coin to the dungeon without altering an existing save until the
next explicit save.

## Deferred scope

Dropping, equipping, using, stacking, capacity limits, random loot, containers,
shops, an economy, and multiple item kinds remain outside Phase 10.
