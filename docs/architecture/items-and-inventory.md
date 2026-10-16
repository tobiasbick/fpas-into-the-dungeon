# Items and inventory

Phase 10 introduced the inspection/pickup/persistence loop. The current game
extends it with equipment, dropping, fixed optional floor finds and healing
potions; item ownership and use remain authoritative server rules.

## Authoritative model

`libs/game` owns every item. An item has a stable ID, a kind, and exactly one
location. Every generated dungeon places an Ancient coin, a Rusty short sword,
a Leather jerkin and a Healing potion on room corners, named `<area>:item:0`
to `:3`. The potion has kind `healing_potion` and no equipment slot. Optional
original slots 4/5 use those same four kinds and keep their suffixes when
another slot is empty. Stored generated levels accept four through six finds
without rerolling their contents.
Full validation permits an item's current location on an ordinary floor field
of any visited dungeon or in the player's inventory, while requiring its
original placement identity and kind. The interaction loop supports pickup; the
drop intention lays a carried item back on the floor (see below). Validation
requires exactly one item per placement of every visited dungeon and rejects
missing, duplicate, unknown, or invalid floor-item state. A floor item must lie on an
ordinary floor field, never on a wall or the exit.

`Consumed` is a terminal location for a Healing potion only. Its record keeps
the original ID and kind, with no area, position, owner or equipment slot.
It occupies no inventory capacity or field, cannot be inspected, picked up,
dropped or worn, and is absent from all visible projections. Full validation
still requires it to match exactly one original placement in a visited level;
missing, duplicate or foreign consumed records reject the save. Revisit/load
never rematerializes it. Checkpoint 05 adds the authoritative use rule below.

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
Consumed potion records do not count toward the limit. A state with 64 carried
or worn items plus consumed potions remains valid; a 65th inventory entry does not.

The `drop_item` intention (inventory overlay, `D`) lays the selected carried item
on the player's occupied ordinary dungeon floor field. It is a turn action like
wearing gear: an adjacent opponent acts afterwards, and a successful drop logs
`You drop the <item>.` The server rejects unknown items, worn items, items lying
on the floor, dropping outdoors or on the exit, and a field that already holds
an item; a rejection changes neither state nor time. The item keeps its identity
and kind, so the existing floor-item projection, inspection, pickup, and save
format apply unchanged. See [generated dungeons](generated-dungeons.md).

## Potion use rule

`Dungeon.Consumables.UseItem(State, ItemId)` accepts a carried Healing potion
only when health is below the derived maximum. It returns a replacement state
and a message containing the actual healing: at most six points, capped at the
maximum. Exactly the selected ID becomes `Consumed`; other potions with the
same name remain independent. Consumption frees one inventory place and draws
no random number.

`Dungeon.Combat.TurnAction.UseItem` applies that change before exactly one
hostile phase in the current dungeon. The turn returns the usual continued or
defeated outcome. Outdoors it heals without a hostile phase or the extra health
from an outdoor step. Unknown, non-carried, consumed or non-consumable items and
use at full health return an error without changing state, dice or time.
The rule expects a validated state; the turn entry point performs validation.
Checkpoint 06 exposes this rule through the protocol and server session.
Checkpoint 07 makes it reachable through `I`/`Enter` in the inventory overlay.

The selected action is shown as `Enter: Use`, `Enter: Wear` or `Enter: Remove`;
items without a projected action show `Enter: No action`. Health is displayed
in the overlay. `Enter` uses projected capability before equipment state, and
the client never infers a healing rule from names or current health. `D` keeps
its drop behavior. Explicit selection navigation wraps; authoritative refreshes
retain the selected ID when it survives, otherwise clamp the old index to the
remaining list (zero when empty). Identical display names do not merge items.

Requests require an active visible session and no pending request. A full or
closed request channel queues nothing and changes no item, health or progress.
The overlay stays open through accepted state and rejection. Only the accepted
projection changes inventory/health; rejection keeps the selected potion and
displays the server's reason, including at full health. Consumption does not
announce pickup or create a player attack animation. Existing hostile events
may play, and another key interrupts playback without queuing twice.

## Protocol and presentation

Protocol version 15 projects visible inventory entries as exactly `id`, `name`,
`slot`, `equipped` and required boolean `usable`. Both map and first-person visible states carry the same bounded,
validated inventory projection. The dungeon uses cell code `i` only while the
coin remains on its field and Fog of War permits that field to be shown.

`usable` describes capability: it is true only for a carried Healing potion,
including at full health, and false for other items. A usable entry cannot be
worn or have an equipment slot. Missing, extra, duplicate or wrongly typed
fields reject the complete message; clients never infer capability from names.

The request is exactly `{"type":"use_item","item_id":"<id>"}`, with an ID
of 1..128 characters. The client supplies no healing amount or replacement
state. The server requires an active session and resolves the existing turn
rule. Accepted use installs the revealed result after sending its prepared
projection, marks unsaved progress and updates dashboard facts. Rule and
candidate-preparation failures return `item_use_rejected`, keeping installed
state, retained map, RNG, dirty flag and last successful save time unchanged.
Before a game is active, the rejection is `session_not_started`.

Transport remains capped at 65,536 UTF-8 bytes before LF. A generated 31-by-21
view with 64 inventory entries and full bounded combat reports fits this
budget. Larger candidate responses are rejected before sending; inventory is
never omitted to make a response fit. A send failure still closes the connection.

The first-person renderer and exploration map draw the coin in gold. After
pickup, the field returns to its underlying floor presentation. The context
panel lists `Ancient coin` under `Quick inventory`; an empty inventory is shown
as `Empty`.

The first-person coin is a small pixel-art billboard lying at the center of its
floor field.
Healing potions use interior code `p`, a small crimson flask sprite and `!` on
the exploration map. The server strips all floor-item markers from remembered
fields; outdoor `p` remains the path code. The protocol and client network
adapter support use, and the inventory overlay queues it from `Enter`.
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

Savegame format 8 stores the complete item array alongside player, return, and
exploration state. Each location is an explicit variant: an interior area and
field, carried by the player, equipped in a slot, or consumed. A consumed
location is exactly `{"kind":"consumed"}`; extra coordinates, owner, area or
slot fields are rejected. Only a Healing potion may use it. Loading validates
the full state before it can replace the active game. Obsolete schemas are rejected and preserved without
migration, repair or automatic deletion.

An explicit save is the only persistence boundary. Disconnecting, reconnecting,
or rendering cannot change item ownership. Saving and loading preserves exactly
one record for each original coin ID, including additional optional coins,
without duplication. Start over materializes every original floor find on that
new game's first entry, while preserving the previous save until an explicitly
confirmed replacement.

## Scope

Equipment, dropping and potion use are implemented; see
[equipment and character values](equipment.md). The 14b fixed optional-loot
table, pure slot-specific selection and generated placements are implemented.
Stacking, containers, shops, an economy and broader loot systems remain deferred.
See [generated dungeons](generated-dungeons.md#pure-content-selection) for the
weights, domains and error bounds. This selection never changes a game state's
inventory or combat RNG.
