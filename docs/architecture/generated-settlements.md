# Generated settlements

Generator 13 supplies occasional villages alongside authored Hearthmoor. Each
uses a bounded map view with closed houses, resident, guard, innkeeper and merchant.
[Trade](economy.md) is available; entered building interiors remain future work.
Mara alone owns the compass quest.

## Sites and identities

A settlement region is one 128 by 128 chunk, independent of dungeon entrance
region size. One third are eligible by the private hash with salt 1601. Test
at most sixteen candidates, using X/Y salts 1607 + index * 37 and
1609 + index * 53, with offsets 16 + hash modulo 96. The first acceptable
candidate is the gate; otherwise the region has no village.

Gates require clear natural land, a walkable cardinal approach, distance at
least 32 from spawn and the home gate, and no dungeon entrance on or adjacent
to the field. No terrain is cleared and no roads or global wilderness
reachability are promised. Chunk generation and decoding compute the site once
per chunk; point generation resolves the same rule. Looking at a marker never
creates a definition or NPC state.

Area IDs are `<world>:settlement:<sx>:<sy>` with canonical signed coordinates.
Hearthmoor keeps `<world>:settlement:home`. NPC slots 0, 1, 2 and 3 are resident,
guard, innkeeper and merchant, identified by `<area>:npc:<slot>`. Names do not identify an
area or NPC. World-ID allocation does not change physical generation.

Layout salt 1613 selects 23 by 15, 27 by 19 or 31 by 21 fields. Name and NPC
domains are separate (1619/1716 and 1621 + slot * 73). Layouts have a connected
plaza, closed house blocks, one exit and an adjacent start. NPCs block their
fields; shared validation proves access to the exit and every talk position
while treating those fields as occupied. Talk positions must be ordinary floor;
the exit cannot count because Enter there leaves the village. NPCs stay off start/exit and at least
four Manhattan fields apart. Names contain 1 through 64 printable ASCII
characters without edge spaces; the four NPC names differ within a village.
Merchant names use `Darin`, `Esme`, `Finn` and `Vera` in the existing slot hash
domain. The innkeeper occupies slot 2; gates and layouts retain their placement rules.

## Definitions and saves

`Dungeon.Settlements.Sites`, `.Identities`, `.Generation` and `.Validation`
own pure rules. `Dungeon.Npcs.Model` owns immutable placements and mutable
meeting records without a game-state dependency. `InteriorMap.Npcs` retains
placements together with geometry in the existing area view and server session.

`Dungeon.World.Settlements` reads or opens a definition for an exact current
entry target. Files live at `worlds/<world>/settlements/<sx>_<sy>.json`.
Settlement format 3 has exactly sixteen root fields: format/world/generator
identity, original seed and dungeon region size, area/region/gate, name,
width/height/rows, start/exit, and four NPC placements. Points and placements
have exact nested fields. Text is bounded to 64 KiB; static cells are only
wall `#`, floor `.` and exit `x`. NPC markers are projections.

Only a missing, unvisited target may be generated, round-trip validated and
atomically published. Existing unusable files and missing visited files fail;
they are never regenerated. Stored valid names, layouts and placements are
authoritative, even when they differ from fresh generation. Hearthmoor still
resolves from authored code and needs no file.

First entry in a game materializes that village's four initially unmet NPC
records, five merchant goods and discovery. Savegame 15 stores only ID, kind, area and meeting flag
for NPCs, canonically sorted, and the canonical world clock. Full validation requires all three home NPCs and every visited
village's complete roster, and resolves all visited definitions even while
outdoors. Unmet records for unvisited villages are invalid too. Mara is found
by exact identity rather than array position. Dialogue frames remain transient.

Save/Continue never create definitions. Start over resets visits, discovery
and meeting records, keeps immutable definitions and preserves the previous
explicit save. A failed entry reply may leave a complete published definition,
but cannot install its candidate position, roster, visit, discovery, cache or
dirty state. Common `Dungeon.World.Areas.Errors.AreaFailure` distinguishes
missing, invalid, generation and I/O failures. World deletion removes the
whole directory, including settlements, under the existing admission permit.

## Presentation and dialogue

Enter on `s` opens a settlement; Enter on its local `x` returns to that exact
outdoor gate. Settlement movement has no combat phase, dice draw or passive
healing. Radius-eight visibility and separate finite discovery masks apply.
Only currently visible placements show `n`; remembered fields retain geometry.
Retained definitions supply titles, talk hints, resize/map replies and console
area names without outdoor chunk or settlement-file access.

Residents, guards and innkeepers offer `identity`, `settlement` and `goodbye`.
Innkeepers additionally offer `rest`: confirmation costs 5 coins, advances eight
hours and fully heals, even at full health. First greeting changes only that
NPC's meeting flag; repeat greetings and information are read-only. Movement
still marks progress unsaved. Merchants additionally offer the root `trade`
topic under protocol 22. The client renders the projected speaker, including pending text.
Quest choices and world preflight require Mara's exact identity and current
quest node. See [NPCs and dialogue](npcs-and-dialogue.md).

## Reproducible acceptance

Create a **new** world with seed **25**, dungeon region size **1**. Existing
older worlds and saves are preserved and rejected. Current
versions are world/chunks 4, generator 13, settlement 3, dungeon level 4,
savegame 15 and protocol 22. Runtime configuration is unchanged. The current
paid-rest route is recorded in [15e verification](time-and-rest-acceptance.md).

Start the server with `--console`, connect the client and create the world in
its editor. The spawn is (10912,-10144). Directions below count accepted steps:
N is up, S down, E right, W left. Enter changes area only at the destination.

Spawn to **Fernhollow**, gate (10951,-10539), 476 steps:

```text
W21 N289 E1 N3 E1 N2 E1 N1 E1 N1 E1 N2 E1 N1 E1 N1 E2 N1
E1 N1 E2 N1 E1 N1 E2 N1 E2 N1 E3 N1 E3 N1 E3 N1 E5 N1
E6 N1 E23 N84
```

Fernhollow to **Brackenford**, gate (11238,-10820), 568 steps:

```text
E287 N281
```

The nearby dungeon entrance is (10955,-10539), four steps east of Fernhollow's
gate. Collect and sell an Ancient coin for 10 coins, take ordinary dungeon
damage, walk four steps west and enter the village still hurt. Talk beside the
innkeeper, open and confirm rest, end dialogue and use Ctrl+P to Save. Restart the server and
Continue inside the village; names, map, position and remembered greetings
remain. Leave through `x`, visit the second village, Save outdoors, restart and
Continue again. Start over should offer fresh greetings without removing
definitions or replacing the previous save.

The automated `village_play_test.fpas` performs this injury/paid-rest loop and
four listener lifetimes with ordinary TCP intentions. `quest_play_test.fpas`
visits generated villages before running Mara's complete compass loop,
including remembered completion after restart. Run either by selecting its
file with `fpas test --timeout 600 --file ... dungeon.fpasworkspace`.
