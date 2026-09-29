# First-person interior

The first-person interior slice adds one fixed dungeon that proves discrete
navigation and terminal raycasting without adding general dungeon generation or
gameplay systems.

## Ownership

`libs/game` owns the bounded 11 by 9 interior map, its field meanings, the
player's area-local coordinate and cardinal facing, collision, and entry and
exit rules. The map contains walls, traversable floor, one start field, one
visible exit field and fixed item fields.
Validation requires rectangular geometry, a traversable start, exactly one
exit, traversable item fields, and connectivity between all traversable fields.

Item placements carry their identity, kind, and initial position. Opponent
placements form an array with the same information; an empty array is valid.
Placement identities are unique across items and opponents. Opponents occupy
distinct floor fields away from items, the start, and the exit. The fixed initial
dungeon still supplies one restless skeleton. New game state derives item kinds
and opponents from these placements; opponents start dormant at full health.

`InteriorMap.AreaId` identifies the area whose geometry the map contains;
validation rejects an empty identity. `InitialDungeonMap(Metadata)` assigns
the selected world's dungeon identity while preserving the authored geometry.
`AreaView` pairs world metadata with an optional current map. The pure
`Dungeon.Areas.AreaViewFor` constructor accepts `None` outdoors and requires a
map matching the state's current area in a dungeon. Its caller supplies
validated geometry; the constructor retains it without loading or generating
a replacement. State validation, first-person movement and turning,
interaction, turn resolution, and discovery updates receive this view and
use its map. `CurrentInterior` rejects missing or mismatched current geometry.
These rules do not resolve the initial map. `ServerSession.Interior` retains
the current geometry. Actions, viewport changes, first-person projections,
and exploration-map projections reuse it. Entry installs the view returned
by the transition; exit and defeat clear the current map. Loading installs
the validated view returned with the saved state. A temporary server helper
supplies initial geometry only on entry until dungeon level storage is connected.

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
enough to show them without flicker. Floor and ceiling keep their base colors
within 1.5 fields of the eye and darken with depth like torchlight; the floor shows
one flagstone per field whose joints fade out beyond 3.5 fields. The
projected exit floor uses a distinct gold material; rays crossing it never
recolor walls. Currently visible opponent and item fields are drawn as upright
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
Remembered map geometry does not retain dynamic figures.
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
format `2`, and generator version `5` remain unchanged. The current savegame format `7`
persists the active interior area ID, local field, cardinal facing, and exact
outdoor return location, together with accumulated discovery and item state.
Reconnecting does not restore it implicitly: the
connected start screen requires an explicit new-game or load choice.
