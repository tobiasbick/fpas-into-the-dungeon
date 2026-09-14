# Area transitions

The first transition connects the initial outdoor region to one initial
dungeon and back. It establishes the ownership and protocol seams without
introducing a generic interaction system.

## Authoritative model

The selected world's current metadata owns stable identities and separate
display labels for the outdoor region and initial dungeon. It also owns one
entrance identity, its outdoor coordinate, and its dungeon target. These values
are deterministic for the world id and seed and do not depend on chunk load
order, cache state, client state, or process lifetime.

New-world creation chooses a naturally clear, traversable entrance cell whose
shortest cardinal distance from the spawn is exactly three steps. The selected
feature is composed into generated chunks and validated again when chunks are
loaded. Missing, duplicate, displaced, or conflicting entrance state is an
error; existing files are never repaired.

A session's game state carries its current area identity and area kind. An
outdoor state has no return location. A dungeon state must retain the exact
outdoor area identity and coordinate from which it was entered. Entry and exit
change current area and return state as one rule result. The outdoor coordinate
is not repurposed as interior geometry.

## Intention and projection

The client sends `activate_area_transition` only after `Enter` on the active
game screen with no request pending and no overlay. In the outdoor area, the
server accepts it only while the player occupies the entrance. In the dungeon,
the same narrow intention is accepted only while the player occupies the
visible exit field, then leaves through the retained return location. Invalid
activation is a structured rejection and does not close the connection.

The server selects one of two view-specific protocol states:

- map state contains the visible window and player coordinates;
- first-person state contains bounded field rows, an area-local player pose,
  title, and status instruction.

Viewport messages update the retained terminal dimensions in both areas, but
the server loads and projects outdoor chunks only for a map state. Entry and
exit reuse the same selected world session and chunk cache.

## Versions and lifecycle

World and chunk format version `2`, generator version `5`, protocol version `5`,
and savegame format `1` are required. Development data from older schemas is
rejected without migrations, fallbacks, or compatibility paths. The retained
return location is part of the authoritative savegame, so a saved interior can
be loaded and later return to its exact outdoor coordinate. Connecting alone
does not implicitly start or load a session.

Interior navigation and projection are detailed in
[first-person interior](first-person-interior.md).
