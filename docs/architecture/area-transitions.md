# Area transitions

Transitions connect the outdoor region with its generated dungeons, the levels
of a dungeon with each other, and lead back outdoors. It uses the shared interaction intention described in
[interaction](interaction.md), while transition validity remains an area rule.

## Authoritative model

The selected world's metadata owns the outdoor area identity and label, the
spawn entrance, and the entrance region size. Every **entrance region** has at
most one **entrance site**; each level of its dungeon is an area named
`<world>:dungeon:<rx>:<ry>:<level>` (`Dungeon.Terrain.Entrances`,
`Dungeon.Areas.Identities`). Sites are
deterministic for the world seed and region and do not depend on chunk load
order, cache state, client state, or process lifetime; see
[generated dungeons](generated-dungeons.md).

New-world creation chooses the **spawn entrance**: a naturally clear,
traversable cell exactly three cardinal steps from the spawn. It belongs to the
spawn region even when it lies across a region border. Entrance features are
composed into generated chunks and validated again when chunks are loaded.
Missing, displaced, or conflicting entrance state is an error; existing files
are never repaired.

A session's game state carries its current area identity and area kind. An
outdoor state has no return location. A dungeon state on any level must retain
the outdoor area identity and the exact entrance site of its dungeon's region;
stair travel keeps it unchanged. Entry and exit
change current area and return state as one rule result. The outdoor coordinate
is not repurposed as interior geometry.

`AreaTransitionTarget(View, State)` checks the entrance under the player
(`EntranceRegionAt`), or the exit or stairs of the supplied map, and returns the
authoritative target identity: level 0 from an entrance, the outdoor area from
the level-0 exit, the level above from stairs up, and the level below from
stairs down. Stair links are computed from the identity and the maps; no link
record is stored. `TransitionTargetOfValid` computes the same target for a state
its caller has already validated. Interaction
returns `TransitionRequested(TargetAreaId)` without changing the state. The
server reads or, on a first visit, creates the target level through
`OpenLevelForEntry` ([level storage](dungeon-level-storage.md)) and supplies it
to `ActivateAreaTransition(View, State, TargetMap)`: entry and stairs require
matching geometry with the current dungeon's depth and name, and leaving requires
`None`. Entry and stairs down arrive on the target's start pose; stairs up arrive
on its **descent landing**, the field east of its stairs down, facing east. When
a standing opponent occupies that field, the player arrives on the first free
floor field in breadth-first order north, east, south, west, keeping the facing;
opponents on a level without the player never move, so they must not block
travel. Transitions are free actions and do not advance combat.
The result contains both the replacement state and its matching view. Entry
validates the target map and calls `MaterializeArea`: first entry adds the area
to the sorted `VisitedAreas` list and creates its placed items and opponents.
A revisit preserves their current locations, health, and alert state. Exit
retains this content and the visit record. Neither pure transition function
loads a map. The server reveals, validates, and projects the candidate before
sending it; a failure before sending rejects the intention and keeps the
session unchanged.

## Intention and projection

The client sends `interact` after `Enter` on the active game screen with no
request pending and no overlay. In the outdoor area, the interaction changes
area only while the player occupies the entrance. In the dungeon, it changes
area only while the player occupies the exit field of level 0, which leaves
through the retained return location, or a stairs field, which changes level. Interacting elsewhere may return a description
and does not close the connection or alter the area.

The server selects one of two view-specific protocol states:

- map state contains the visible window and player coordinates;
- first-person state contains bounded field rows, an area-local player pose,
  title, and status instruction.

Viewport messages update the retained terminal dimensions in both areas, but
the server loads and projects outdoor chunks only for a map state. Entry and
exit reuse the same selected world session and chunk cache.

## Versions and lifecycle

World and chunk format version `3`, generator version `8`, level-file format
`3`, protocol version `16`, and savegame format `10` are required. Development
data from older schemas is rejected and preserved without migration or repair. The retained
return location is part of the authoritative savegame, so a saved interior can
be loaded and later return to its exact outdoor coordinate. Connecting alone
does not implicitly start or load a session.

Interior navigation and projection are detailed in
[first-person interior](first-person-interior.md).
