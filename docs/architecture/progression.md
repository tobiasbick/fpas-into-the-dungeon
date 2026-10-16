# Experience and skill levels

Status: **implemented** (stage 13b, accepted 2026-10-16). This document is the lasting
rule and storage contract for experience and skill levels.

The character learns by doing: it improves the fighting skill it actually uses.
There is no overall character level, class, attribute allocation, or skill-point
editor. Equipment still determines the weapon's base damage.

## Skills and experience

- Two independent skills: **Unarmed** and **Blades**.
- The **active skill** is captured from the valid state before an attack. No
  weapon equipped selects Unarmed; the equipped Rusty short sword selects
  Blades. Carrying a sword, wearing armor, and equip/unequip/drop actions never
  select a skill or grant experience. All sword copies share Blades.
- A successful player hit awards one experience point per health point actually
  removed from the standing target:
  `award = target health before - target health after`.
  A 7-damage blow against 2 remaining health awards 2. The combat log and
  `PlayerHit.Amount` still report the rolled damage (7).
- Misses award nothing. Attacks without a standing target remain rejected and
  consume neither dice nor a turn. No extra reward for a defeat. Movement,
  taking damage, healing, items, inspection, saving and waiting never train.
- Each skill stores cumulative experience in 0..120. Gains saturate at 120 using
  the remaining capacity before addition. Experience never decays or transfers;
  a capped skill discards further awards.
- Opponents never heal or respawn in an active game, so their finite health
  bounds the available training without a reward ledger.

## Levels and benefits

Thresholds are cumulative; equality reaches the new level.

| Skill level | Total experience | Hit bonus | Damage bonus | Next threshold |
|---|---:|---:|---:|---:|
| 1 | 0..11 | 0 | 0 | 12 |
| 2 | 12..35 | 0 | +1 | 36 |
| 3 | 36..71 | +1 | +1 | 72 |
| 4 | 72..119 | +1 | +2 | 120 |
| 5 (**mastery**) | 120 | +2 | +2 | none |

Only the active skill contributes. The player hits on `d20 >= 6 - hit bonus`
(75 %, 75 %, 80 %, 80 %, 85 %). Unarmed damage is `d3 + damage bonus`; sword
damage is `d6 + 1 + damage bonus`. Armor (0 or 2) and maximum health (20) are
unchanged. No benefit adds a die, a random draw, or healing.

## Turn order

1. Resolve the attack with the level at its start.
2. Apply the target's damage, award experience, derive the new level.
3. Log, in order: player hit, opponent death if any, level increase if any
   (once, with the final level, e.g. `Blades reached level 2.`).
4. Run the existing hostile phase. A level increase consumes no extra turn.

The new bonus first affects a subsequent attack. No combat-event kind and no
client timer are added. A turn ending in player defeat keeps the existing
state-less defeat outcome: unsaved progress is lost and the last explicit save
stays intact.

## Ownership

- `Dungeon.Progression` is a leaf game unit without dependencies on GameState,
  Equipment, Combat, the protocol, storage, or the client. It owns `SkillKind`,
  `ProgressionState` (two experience integers), the cap, the threshold table,
  derived benefits (level, hit bonus, damage bonus; never persisted), strict
  validation, lookups, and `AwardDamage`. Validation and awarding never repair
  invalid counters; invalid input returns an error.
- `Dungeon.GameState` holds one `Progression` field, initializes it to zero and
  delegates shape validation.
- `Dungeon.Equipment` maps the worn weapon to the active skill and adds its
  benefits to the derived values and character lines.
- `Dungeon.Combat` awards experience only in player-attack resolution. Hostile
  pathfinding moves to `Dungeon.Combat.Navigation` beforehand.
- The server commits the candidate state atomically; a rejected or failed
  preparation retains the installed experience with every other fact.

## Persistence

Savegame format **9** adds one top-level field `progression`, an exact
two-field object:

```json
{
  "unarmed_experience": 0,
  "blades_experience": 12
}
```

Both are required integers in 0..120. Unknown, missing, duplicate or wrongly
typed fields are errors. Level, active skill, bonuses and thresholds are never
stored. `Dungeon.World.Savegame.Progression` encodes and decodes the field; the
Savegame facade keeps version checking, full validation and atomic publication.

| Format or contract | Before | After 13b |
|---|---:|---:|
| Savegame format | 8 | 9 |
| Protocol | 15 | 15 |
| World metadata/chunks | 3 | 3 |
| World generator | 7 | 7 |
| Immutable dungeon level | 2 | 2 |

Format-8 saves in reusable worlds are rejected with an actionable reason and
preserved byte-for-byte, never migrated or deleted. Start over in such a world
begins at 0/0 and keeps the old save until an explicit overwrite. New worlds and
absent saves start at level 1 in both skills. Loading restores opponent health,
both counters and dice together; replaying an earlier save replaces later
progress rather than adding to it.

## Presentation

The server sends six `character` lines in both view families: Maximum health,
Hit chance, Damage, Armor, Unarmed, Blades. Skill lines show total experience
and the next cumulative threshold, for example `L2 XP 12/36` with source
`Active; next: hit +1`; mastery shows `L5 XP 120/120` and `Mastered`. The client
renders these lines without parsing or deriving anything. The character sheet
is a bounded, scrollable read-only overlay; see the
[client UI](../product/client-ui.md) for sizes and keys.

## Pacing

A full-health rat (6) and skeleton (12) supply 18 points per generated dungeon,
shared between whichever skills damage them. One uncapped skill reaches level 2
after one dungeon, level 3 after two, level 4 after four and mastery after seven.
