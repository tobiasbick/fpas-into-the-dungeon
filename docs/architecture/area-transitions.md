# Area transitions

Transitions connect the outdoor region with its generated dungeons and back. It uses the shared interaction intention described in
[interaction](interaction.md), while transition validity remains an area rule.

## Authoritative model

The selected world's metadata owns the outdoor area identity and label, the
spawn entrance, and the entrance region size. Every **entrance region** has at
most one **entrance site**; its dungeon is named `<world>:dungeon:<rx>:<ry>`
(`Dungeon.Terrain.Entrances`, `Dungeon.Areas.Identities`). Sites are
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
outdoor state has no return location. A dungeon state must retain the outdoor
area identity and the exact entrance site of its dungeon's region. Entry and exit
change current area and return state as one rule result. The outdoor coordinate
is not repurposed as interior geometry.

`AreaTransitionTarget(View, State)` checks the entrance under the player
(`EntranceRegionAt`) or the exit of the supplied map and returns the
authoritative target identity. Interaction
returns `TransitionRequested(TargetAreaId)` without changing the state. The
server reads or, on a first visit, creates the target level through
`OpenLevelForEntry` ([level storage](dungeon-level-storage.md)) and supplies it
to `ActivateAreaTransition(View, State, TargetMap)`: entry requires matching geometry, and exit requires `None`.
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
area only while the player occupies the visible exit field, then leaves through
the retained return location. Interacting elsewhere may return a description
and does not close the connection or alter the area.

The server selects one of two view-specific protocol states:

- map state contains the visible window and player coordinates;
- first-person state contains bounded field rows, an area-local player pose,
  title, and status instruction.

Viewport messages update the retained terminal dimensions in both areas, but
the server loads and projects outdoor chunks only for a map state. Entry and
exit reuse the same selected world session and chunk cache.

## Versions and lifecycle

World and chunk format version `3`, generator version `6`, level-file format
`1`, protocol version `13`, and savegame format `7` are required. Development data from older schemas is
rejected without migrations, fallbacks, or compatibility paths. The retained
return location is part of the authoritative savegame, so a saved interior can
be loaded and later return to its exact outdoor coordinate. Connecting alone
does not implicitly start or load a session.

Interior navigation and projection are detailed in
[first-person interior](first-person-interior.md).
