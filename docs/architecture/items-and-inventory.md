# Items and inventory

Phase 10 introduces one deliberately narrow mutable-item loop. It proves that
an item can be visible, inspected, picked up, projected to the client, and
persisted without adding a general loot, equipment, or scripting system.

## Authoritative model

`libs/game` owns every item. An item has a stable ID, a kind, and exactly one
location. Every generated dungeon places an Ancient coin, a Rusty short sword,
and a Leather jerkin on room corners, named `<area>:item:0` to `:2`.
Full validation permits an item's current location on an ordinary floor field
of any visited dungeon or in the player's inventory, while requiring its
original placement identity and kind. The interaction loop supports pickup; the
drop intention lays a carried item back on the floor (see below). Validation
requires exactly one item per placement of every visited dungeon and rejects
missing, duplicate, unknown, or invalid floor-item state. A floor item must lie on an
ordinary floor field, never on a wall or the exit.

Starting a new game creates no dungeon items. First entry materializes a
dungeon's items at their placements. Further transitions and movement preserve
its state, including after save/load. The client never creates, moves, or owns
items.

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

## Capacity and dropping

Carried and worn items together fill at most `MaximumInventoryItems` (64)
entries, the same bound as the protocol's visible inventory. A full inventory
rejects pickup without changing state or time, and the hint reads
`At your feet: <item> — inventory full`. State validation rejects more than 64
carried or worn items.

The `drop_item` intention (inventory overlay, `D`) lays the selected carried item
on the player's occupied ordinary dungeon floor field. It is a turn action like
wearing gear: an adjacent opponent acts afterwards, and a successful drop logs
`You drop the <item>.` The server rejects unknown items, worn items, items lying
on the floor, dropping outdoors or on the exit, and a field that already holds
an item; a rejection changes neither state nor time. The item keeps its identity
and kind, so the existing floor-item projection, inspection, pickup, and save
format apply unchanged. See [generated dungeons](generated-dungeons.md).

## Protocol and presentation

Protocol version 12 projects visible inventory entries as stable ID, display
name, slot, and worn flag. Both map and first-person visible states carry the same bounded,
validated inventory projection. The dungeon uses cell code `i` only while the
coin remains on its field and Fog of War permits that field to be shown.

The first-person renderer and exploration map draw the coin in gold. After
pickup, the field returns to its underlying floor presentation. The context
panel lists `Ancient coin` under `Quick inventory`; an empty inventory is shown
as `Empty`.

The first-person coin is a small pixel-art billboard lying at the center of its
floor field.
The fixed-height Environment panel above Context displays the interaction hint.
Only with the sidebar hidden or unable to dock is the hint painted over the
bottom image row without resizing the view. The server supplies
`Ancient coin — Enter: Examine` when it is directly
ahead and `At your feet: Ancient coin — Enter: Pick up` on its field, regardless
of facing. After an authoritative inventory addition, the client shows
`Picked up: Ancient coin` until the next visible-state update. Loading existing
inventory does not announce a pickup. These hints remain available with the
context panel hidden; movement and inspection controls remain unchanged.
The server sends `Nothing in reach` when no action is available. This neutral
text appears in Environment but never as a fallback over the image.
Both right-hand panels share the existing F2 toggle and
narrow-screen overlay; no new preference or configuration schema is introduced.

## Persistence

Savegame format 7 stores the complete item array alongside player, return, and
exploration state. Each location is an explicit variant: an interior area and
field, or carried by the player. Loading validates the full state before it can
replace the active game. Format 3 and all other obsolete schemas are rejected
and removed according to the current-version-only configuration and save policy.

An explicit save is the only persistence boundary. Disconnecting, reconnecting,
or rendering cannot change item ownership. Saving and loading a carried coin
must preserve exactly one carried coin; starting a new game must restore
exactly one coin on the new game's first dungeon entry without altering an
existing save until the next explicit save.

## Deferred scope

Using, stacking, random loot, containers, shops, and an economy remain outside
Phase 10; dropping and the capacity limit follow the section above. Stage 13a adds further item kinds, several
item placements per interior, and wearing items; see
[equipment and character values](equipment.md).
