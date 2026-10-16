# Combat

Combat is a server-authoritative fight against restless skeletons and giant rats.
Each generated dungeon contains both kinds. Combat keeps the grid-based first-person
presentation of
classic dungeon crawlers such as *Eye of the Beholder* and *Legend of
Grimrock*: the opponent stands visibly in the corridor, attacks target the
field directly ahead, and stepping away or around it matters. Time, however,
advances only through player actions, as in *Rogue* or the turn-based combat
of *Might and Magic*. This fits the request-response protocol: every accepted
intention returns exactly one authoritative result, the server never needs to
push unsolicited updates, and every fight is reproducible in tests.

## Opponents

Each generated dungeon places one **restless skeleton** in its farthest eligible
room by walking distance and one **giant rat** in the next farthest. They occupy
separate room centers outside the exit room. Generation guarantees that neither
can see the start, so a visit begins calmly and exploring the far rooms means
meeting them.

- It blocks its field while it stands.
- It is dormant until it can see the player: the player's field lies within six
  fields and an unobstructed line of sight connects both field centers. From
  then on it stays alerted.
- An alerted opponent attacks when the player occupies an orthogonally adjacent
  field. Otherwise it takes one step along a shortest traversable path toward
  the player. Walls and the player's own field block that path; items do
  not.
- A destroyed opponent disappears from all projections and never returns in
  the same game.

## Turns

These actions consume a turn: a successful first-person **step**, an
**attack**, **wait**, wearing, removing or dropping an item, and potion use
through inventory `I`/`Enter`. After each,
every standing opponent in the player's current area acts once, in stable
stored order. Turning, interaction, the
exploration map, saving, and rejected intentions do not advance time.

Keys: `Space` attacks the field directly ahead and `Z` waits one turn. `Enter`
keeps its non-violent meaning.

## Rules and dice

| Value | Player | Restless skeleton | Giant rat |
|---|---|---|---|
| Health | 20 | 12 | 6 |
| Hit | d20 ≥ 6 (75 %) | d20 ≥ 9 + armor (60 % unarmored) | d20 ≥ 12 + armor (45 % unarmored) |
| Damage | d3 unarmed, d6 + 1 with the rusty short sword | d4 | d2 |

Dice come from a small linear congruential generator whose state is part of
the authoritative game state. A new game seeds it from the world seed, and a
loaded game continues from its saved state. Identical actions therefore always
produce identical fights, which keeps tests deterministic without making the
fight predictable for a player.

Each accepted outdoor step restores one health point up to the player's
maximum. The player's values come from base values plus equipment; see
[equipment and character values](equipment.md).

Checkpoint 05 adds `TurnAction.UseItem`: a carried Healing potion restores up
to six points, capped at derived maximum health, before the hostile phase. Its
log reports the actual amount, and the exact item becomes consumed. Use draws
no dice and creates no player attack event. Each standing opponent then acts
once in stored order, so the healed player can still be defeated. Outdoors
there is no hostile phase or additional step healing. Invalid item use and use
at full health return an error before any opponent acts. Checkpoint 06 adds
the `use_item` protocol/session intention; checkpoint 07 queues it through
inventory `I`/`Enter`. The client applies health only from the reply and plays
only the returned hostile events; using an item creates no weapon swing.

## Defeat and victory

When the player's health reaches zero, the server ends the game session and
answers with a dedicated defeat message instead of a visible state. The client
shows a defeat overlay above the session start screen; the player may then
load the last explicit save or start a new game. Nothing is saved or deleted
automatically.

When an opponent's health reaches zero it is marked destroyed. The state keeps
the record so that savegames can prove that the fight already happened.
Skeletons collapse into bones; rats fall lifeless to the floor. Inspection and
blocked-movement feedback also identify the actual opponent kind.

## Protocol

Introduced with protocol version 11 and extended in versions 12 and 15:


- Client intentions `attack` and `wait`, both without fields.
- `use_item` carries only an `item_id` and uses the same turn commit and defeat
  path. Rejected rules or failed candidate preparation return
  `item_use_rejected` and preserve the installed session, including its dirty
  flag and last successful save time. The client network adapter accepts state
  and defeat responses for this request, without a fabricated player attack.
- Both visible states carry `health` and `max_health` for the character panel.
  The first-person state also carries `combat_log`: the bounded messages of the
  resolved turn, such as `You hit the restless skeleton for 3.`, and, since
  protocol version 12, `combat_events`: the same turn as structured facts that
  drive the client's combat animation.
- In protocol 15 every event has exactly `kind`, `amount` and `hostile_code`.
  The code is `h` or `r`: the target for player hit/miss/defeat and the actor
  for hostile hit/miss. Hit amounts are 1..999; miss/defeat amounts are zero.
  Missing, extra, duplicate or unknown values are rejected. Events retain the
  defeated kind even when it is absent from the final rows. No opponent stats,
  IDs or positions are sent in events.
- The interior alphabet uses `InteriorHostileCode` (`h`) for a skeleton and
  `InteriorRatCode` (`r`) for a rat. Remembered fields never retain opponents.
  Outdoor `r` remains a river. The map and raycaster distinguish both kinds;
  the rat is shorter and wider, including during its collapse animation.
- `defeated` replaces the state response of the turn that ended the game; it
  carries a player-facing summary.

## Persistence

The save (format 8) holds the player's health, the random generator state, and
the complete record of every opponent of the visited dungeons with identity,
kind, area, position, health, and alert status. Validation requires exactly one
record per stored opponent placement, a traversable field in its own area that
overlaps no standing player or opponent, and consistent health. Destroyed
opponents stay recorded, so re-entering never restores them. Saving
is allowed during a fight.
Persisted kinds are `restless_skeleton` and `giant_rat`; a rat's health must be
0..6 and a skeleton's 0..12. Format 7 saves are rejected and preserved.

## Ownership

`Dungeon.Hostiles` owns opponent kinds and their values; `Dungeon.GameState`
owns the opponent and health state, collision queries, visible codes, and
validation. `Dungeon.Combat` owns turns: attacks, dice, the opponent's
perception, pathfinding, and attacks, and defeat. `Dungeon.Consumables` owns
the pure potion validation, healing and consumed-state change. The server translates
intentions and outcomes into protocol messages. The client only renders the
projected opponent, health, combat log, and defeat.

Generated floor finds and healing potions are implemented. Experience, ranged
attacks, spells, fleeing behavior and real-time combat remain later work.
