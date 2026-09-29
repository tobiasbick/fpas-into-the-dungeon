# Combat

The first combat slice adds one server-authoritative fight against one opponent
in the initial dungeon. It keeps the grid-based first-person presentation of
classic dungeon crawlers such as *Eye of the Beholder* and *Legend of
Grimrock*: the opponent stands visibly in the corridor, attacks target the
field directly ahead, and stepping away or around it matters. Time, however,
advances only through player actions, as in *Rogue* or the turn-based combat
of *Might and Magic*. This fits the request-response protocol: every accepted
intention returns exactly one authoritative result, the server never needs to
push unsolicited updates, and every fight is reproducible in tests.

## Opponent

The **restless skeleton** rests in the inner passages of the initial dungeon at
field `(3, 3)`. Those passages form the second route to the exit; walls hide
them from the upper corridor, the long eastern corridor, and the lower
hall. Exploring the side route therefore means meeting the skeleton, while the
main route stays calm, as side passages in classic crawlers tend to be more
dangerous.

- It blocks its field while it stands.
- It is dormant until it can see the player: the player's field lies within six
  fields and an unobstructed line of sight connects both field centers. From
  then on it stays alerted.
- An alerted skeleton attacks when the player occupies an orthogonally adjacent
  field. Otherwise it takes one step along a shortest traversable path toward
  the player. Walls and the player's own field block that path; items do
  not.
- A destroyed skeleton disappears from all projections and never returns in
  the same game.

## Turns

Only these intentions consume a turn: a successful first-person **step**, an
**attack**, **wait**, and wearing or removing an item. After each of them the skeleton acts once while it
stands in the player's current area. Turning, interaction, the
exploration map, saving, and rejected intentions do not advance time.

Keys: `Space` attacks the field directly ahead and `Z` waits one turn. `Enter`
keeps its non-violent meaning.

## Rules and dice

| Value | Player | Restless skeleton |
|---|---|---|
| Health | 20 | 12 |
| Hit | d20 ≥ 6 (75 %) | d20 ≥ 9 + armor (60 % unarmored) |
| Damage | d3 unarmed, d6 + 1 with the rusty short sword | d4 |

Dice come from a small linear congruential generator whose state is part of
the authoritative game state. A new game seeds it from the world seed, and a
loaded game continues from its saved state. Identical actions therefore always
produce identical fights, which keeps tests deterministic without making the
fight predictable for a player.

Each accepted outdoor step restores one health point up to the player's
maximum. The player's values come from base values plus equipment; see
[equipment and character values](equipment.md).

## Defeat and victory

When the player's health reaches zero, the server ends the game session and
answers with a dedicated defeat message instead of a visible state. The client
shows a defeat overlay above the session start screen; the player may then
load the last explicit save or start a new game. Nothing is saved or deleted
automatically.

When the skeleton's health reaches zero it is marked destroyed. The state keeps
the record so that savegames can prove that the fight already happened.

## Protocol

Introduced with protocol version 11 and extended in version 12:


- Client intentions `attack` and `wait`, both without fields.
- Both visible states carry `health` and `max_health` for the character panel.
  The first-person state also carries `combat_log`: the bounded messages of the
  resolved turn, such as `You hit the restless skeleton for 3.`, and, since
  protocol version 12, `combat_events`: the same turn as structured facts that
  drive the client's combat animation.
- The interior alphabet gains `InteriorHostileCode` (`h`) for a currently
  visible standing opponent. Remembered fields never retain it.
- `defeated` replaces the state response of the turn that ended the game; it
  carries a player-facing summary.

## Persistence

Since savegame format 5 the save holds the player's health, the random generator state, and
the complete opponent record with identity, kind, area, position, health, and
alert status. Validation requires exactly the known opponent, a floor field
that overlaps no standing player, and consistent health. Saving
is allowed during a fight.

## Ownership

`Dungeon.Hostiles` owns opponent kinds and their values; `Dungeon.GameState`
owns the opponent and health state, collision queries, visible codes, and
validation. `Dungeon.Combat` owns turns: attacks, dice, the opponent's
perception, pathfinding, and attacks, and defeat. The server translates
intentions and outcomes into protocol messages. The client only renders the
projected opponent, health, combat log, and defeat.

Multiple opponents, loot, experience, ranged attacks, spells, fleeing
behavior, and real-time combat remain outside this slice.
