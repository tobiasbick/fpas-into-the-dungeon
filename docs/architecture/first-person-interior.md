# First-person interior

The first-person interior slice adds one fixed dungeon that proves discrete
navigation and terminal raycasting without adding general dungeon generation or
gameplay systems.

## Ownership

`libs/game` owns the bounded 11 by 9 interior map, its field meanings, the
player's area-local coordinate and cardinal facing, collision, and entry and
exit rules. The map contains walls, traversable floor, one start field, one
visible exit field, one fixed stone tablet mounted on a wall, one fixed item
field, and one fixed blocking NPC field. Validation requires rectangular geometry, a traversable start,
exactly one exit, a wall field for the tablet, a traversable item field, and
connectivity between all traversable fields. The NPC must occupy a distinct
floor field and the player cannot enter it.

The player's retained outdoor return location remains separate from the
interior pose. Entering establishes the fixed start pose. Leaving is accepted
only on the exit field and restores the exact retained outdoor coordinate.
Neither the client nor the renderer decides whether a step, turn, or transition
succeeds.

## Protocol and server projection

Protocol version `10` carries distinct intentions for a relative one-field step
(`forward`, `backward`, `left`, or `right`) and a 90-degree turn (`left` or
`right`). Outdoor cardinal movement remains a separate message.

The first-person visible-state variant contains only the bounded field rows,
dimensions, knowledge rows, area-local player coordinate, cardinal facing,
title, status, and visible inventory summary.
It excludes area identities, the outdoor return location, persistence paths,
and other server-owned state. The server returns a complete projection after
each accepted intention and a structured rejection after an invalid one.
Viewport updates return the same validated interior geometry without loading
outdoor chunks.

## Client rendering

`Dungeon.Client.Raycast` is a pure presentation module. It derives a cardinal
camera and fixed field of view from a validated first-person state, finds the
nearest opaque field for each terminal column with one grid DDA ray, corrects
wall distance for perspective, and fills a pixel buffer with ceiling, wall, or
floor. Each terminal cell holds two stacked pixels: equal halves render as a
colored space, differing halves as an upper-half block whose foreground is the
upper pixel and whose background is the lower pixel. Walls use deterministic
distance and side shading plus a masonry texture: four staggered stone courses
and two stones per field width, with a stable per-stone tint derived from the
hit field and darker mortar joints that appear only while the wall is tall
enough to show them without flicker. The tablet projection is opaque and draws
a framed slate panel with engraved lines inset into that masonry, without
changing the wall geometry. Floor and ceiling keep their base colors within
1.5 fields of the eye and darken with depth like torchlight; the floor shows
one flagstone per field whose joints fade out beyond 3.5 fields. The
projected exit floor uses a distinct gold material; rays crossing it never
recolor walls. Currently visible NPC, opponent, and item fields are drawn as upright
pixel-art billboards at their field centers, scaled by depth, darkened like
walls, and hidden behind nearer walls through the per-column wall depth. The visual eye is shifted 0.35 fields
back from the occupied field's center, opposite the facing direction. It stays
inside that field even when a wall is directly behind the player. A camera-plane
scale of 1.0 gives a 90-degree horizontal view; the vertical projection scale
remains 0.58 times the terminal height. This intentionally readable presentation
exposes immediate side branches, including at junctions with an open path ahead.
Walls and floor samples share this eye and projection. There is no separate
close-wall renderer or camera placed in a neighboring field. The player's
authoritative coordinate, collision, interaction reach, and facing do not change.
Interior visibility includes the immediate left and right fields in addition to
the existing forward sight cone, without revealing a whole sideways corridor.
Unknown and remembered-but-not-currently-visible fields both stop first-person
rays as dark fog. Wall and floor sampling consult the same server-provided
knowledge mask; map memory never extends current first-person sight.
The fixed NPC appears as a standing figure only while her field is currently
visible. Remembered map geometry does not retain that dynamic figure.
The server includes exposed wall faces even when a wall's center is occluded
by its neighbor, preventing false fog gaps in continuous corridor walls.
See the client UI specification for presentation
details.

Rendering never changes game state and does not infer collision or hidden
geometry. The first-person cell grid fills the primary panel at its available
terminal width, while the existing frame, context panel, message panel, status
view, overlays, resizing behavior, and shortcuts remain shared with the map
view.

## Persistence and lifecycle

The fixed interior remains current program data, so world format `2`, chunk
format `2`, and generator version `5` remain unchanged. Savegame format `4`
persists the active interior area ID, local field, cardinal facing, and exact
outdoor return location, together with accumulated discovery, item state, and
whether the fixed NPC has met the player. Active dialogue is not persisted.
Reconnecting does not restore it implicitly: the
connected start screen requires an explicit new-game or load choice.
