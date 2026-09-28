# Equipment and character values

Stage 13a gives the character its first progression: equipment that changes
the existing fight at once. It adds no named attributes, classes, or levels.
The character has **derived values**, computed from fixed base values plus the
equipped items; the combat rules read only these derived values.

## Derived values

| Value | Base | Rusty short sword | Leather jerkin |
|---|---|---|---|
| Hit threshold (d20) | 6 (75 %) | — | — |
| Damage | d3 | d6 + 1 | — |
| Armor | 0 | — | +2 |
| Maximum health | 20 | — | — |

- A weapon replaces the unarmed damage dice; it does not add to them.
- Armor raises the threshold an opponent must roll: the restless skeleton hits
  on d20 ≥ 9 + armor, so the jerkin lowers its chance from 60 % to 50 %.
- Unarmed damage drops from d4 + 1 to d3 so that finding a weapon matters.
  Unarmed, the skeleton falls after about eight turns; with the sword after
  about four.
- Maximum health and hit threshold are still derived values, so later stages
  can change them without changing the combat rules again.

`Dungeon.Equipment` owns the base values, the derivation, and the equip rules.
`Dungeon.Combat` asks it for the character's values.

## Items and slots

The item model keeps one location per item. A new location variant,
**equipped by the player in a slot**, joins the existing interior placement
and carried state, so an item is never both carried and worn.

| Item | Kind | Slot | Initial field |
|---|---|---|---|
| Ancient coin | treasure | none | `8, 1` |
| Rusty short sword | weapon | weapon | `7, 4` |
| Leather jerkin | armor | body | `1, 6` |

- The sword lies in the middle passage between the upper corridor and the
  lower hall, the jerkin in the nook north of the exit. A test proves that
  neither field is in line of sight of the skeleton's resting field. Both lie off the main
  route and outside the skeleton's line of sight, so exploring before the fight
  pays off.
- An interior map now lists its item placements by item identity instead of
  holding one item field. Validation requires every placement to be a distinct
  floor field that differs from start, exit, Mara, and the opponent.
- Picking up keeps the existing rule: `Enter` on the item's field carries it.
  Nothing is equipped automatically.

## Equipping

Equipping and unequipping are turn actions like a step or a wait: each change
consumes one turn, after which a standing opponent in the same area acts. Gear
therefore cannot be swapped for free during a fight.

- **Equip** a carried item into its slot. If the slot is occupied, the worn
  item returns to the inventory in the same turn.
- **Unequip** a worn item back into the inventory.
- The server rejects unknown items, items the player does not carry or wear,
  items without a slot, equipping an already worn item, and unequipping an item
  that is not worn. Rejections consume no turn and leave the dice untouched.
- Equipping works in every area. Outdoors no opponent acts afterwards.

The turn log reports the change, for example `You wield the rusty short sword.`
or `You take off the leather jerkin.`

## Protocol version 12

- Client intentions `equip` and `unequip`, each with an `item_id`.
- Inventory entries gain `slot` (`weapon`, `body`, or empty for items that
  cannot be worn) and `equipped`.
- Both visible states carry `character`: a bounded list of derived values, each
  with a label, a display value, and its source, for example
  `Damage · d6+1 · Rusty short sword`. The server formats these lines, so the
  client never needs the rules.
- The first-person state carries `combat_events`: structured, bounded facts of
  the resolved turn (`player_hit`, `player_miss`, `hostile_hit`,
  `hostile_miss`, `hostile_defeated`, each with an amount). They drive the
  animation; the readable combat log remains unchanged.
- The interior alphabet gains `w` for a weapon and `a` for armor lying on a
  visible field. `i` remains the code for other items.

## Persistence

Savegame format 6 stores equipped items as their own location variant with
their slot. Validation requires exactly the three known items with matching
identity and kind, at most one item per slot, and a slot that fits the item.
Format 5 and older are rejected according to the current-version-only policy.

## Client presentation

- **Inventory overlay** on `I`: lists carried and worn items with their slot.
  `W`/`S` or the arrow keys select, `Enter` equips or unequips the selection,
  `Escape` or `I` closes. Items without a slot show that they cannot be worn.
  The overlay stays open after a change so the result is visible.
- **Character sheet** on `C`: health and the projected derived values with
  their sources, followed by the equipment. `Escape` or `C` closes.
- The context panel replaces `Equipment: Not available` with the weapon and
  body slots; `Quick inventory` lists carried items that are not worn.
- The first-person view draws the sword and the jerkin as small floor sprites;
  the exploration map marks them like the coin.

## Combat animation

The animation is presentation only. The client plays the `combat_events` of a
turn after the new state has arrived; the rules and the resolved state are
already final.

- Up to three phases of 160 ms, so at most 480 ms: a blade or fist swing from
  the lower right of the view, then a white hit flash with a rising damage
  number or a sideways dodge with `miss`, then the skeleton's lunge. The red
  damage frame and the player's damage number wait for that lunge. A destroyed
  skeleton is already gone from the state, so the client draws it on the field
  ahead once more and lets it sink into the floor.
- **Clock:** the client asks the TUI host for its frames with
  `Cmd.RequestTick(40)`. Each `TuiMsg.Tick` advances the animation by the
  elapsed time and requests the next frame until the animation ends. A key
  press, defeat, or a lost connection stops it; a tick still pending then
  changes nothing.
- **Input:** a key press during an animation completes it at once and is then
  handled normally, so fast play never feels delayed and no input is lost.
- **Cost:** a full first-person frame of 128 by 44 cells took about 29 ms,
  too much for a 40 ms frame interval plus terminal output. The raycaster
  therefore renders walls, floor, and the depth buffer once as a scene when an
  animation starts; each frame only composes sprites, effects, and texts onto
  it, which took about 10 ms. A resized terminal falls back to a full render.
- Tests inject frame events directly and assert individual frames.

## Ownership

`Dungeon.Items` owns item kinds, slots, and locations; `Dungeon.Interior`
owns placements; `Dungeon.GameState` validates the complete item set.
`Dungeon.Equipment` owns base values, derivation, equip rules, and the
character sheet lines. `Dungeon.Combat` resolves equip actions as turns, reads
the derived values, and reports combat events. The server projects inventory,
character values, and combat events. In the client, `Dungeon.Client.Character`
builds the inventory overlay, character sheet, and equipment summaries,
`Dungeon.Client.Animation` turns combat events into frames, and
`Dungeon.Client.Raycast` draws scenes, sprites, and effects. The client never
derives game values.

Item rarity, durability, shops, loot tables, two-handed weapons, further slots,
experience, and levels remain outside this slice.
