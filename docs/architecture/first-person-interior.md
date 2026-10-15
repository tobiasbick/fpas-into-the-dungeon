# First-person interior

Dungeons are bounded first-person interiors with discrete navigation and
terminal raycasting. Their geometry comes from [generated dungeons](generated-dungeons.md)
and is stored as immutable [level files](dungeon-level-storage.md).

## Ownership

`libs/game` owns the bounded interior map (31 by 21 fields for generated
dungeons; rules accept any validated size), its field meanings, the
player's area-local coordinate and cardinal facing, collision, and entry and
exit rules. The map contains walls, traversable floor, one start field, one
visible exit field and fixed item fields.
Validation requires rectangular geometry, a traversable start, exactly one
exit, traversable item fields, and connectivity between all traversable fields.

Item placements carry their identity, kind, and initial position. Opponent
placements form an array with the same information; an empty array is valid.
Placement identities are unique across items and opponents. Opponents occupy
distinct floor fields away from items, the start, and the exit. Generated
dungeons place one or two restless skeletons and the coin, sword, and jerkin.
First entry materializes item kinds and opponents from these placements;
opponents start dormant at full health.

`InteriorMap.AreaId` identifies the area whose geometry the map contains;
validation rejects an empty identity. `AreaView` pairs world metadata with an optional current map. The pure
`Dungeon.Areas.AreaViewFor` constructor accepts `None` outdoors and requires a
map matching the state's current area in a dungeon. Its caller supplies
validated geometry; the constructor retains it without loading or generating
a replacement. State validation, first-person movement and turning,
interaction, turn resolution, and discovery updates receive this view and
use its map. `CurrentInterior` rejects missing or mismatched current geometry.
These rules never load or generate a map. `ServerSession.Interior` retains
the current geometry. Actions, viewport changes, first-person projections,
and exploration-map projections reuse it. Entry installs the view returned
by the transition; exit and defeat clear the current map. Loading installs
the validated view returned with the saved state. Entry reads or creates the
level through `Dungeon.World.Interiors.OpenLevelForEntry`.

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
Interior visibility tests field extents at the forward sight cone's edges,
with a one-field margin for the rearward eye. This includes immediate left and
right neighbors and the partly projected fields ahead, preventing opaque fog
slabs at the screen edges. Fields behind the player and fields farther sideways
on the player's row stay hidden; distance and wall occlusion remain enforced.
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

Dungeon geometry is world data: world and chunk format `3`, generator version
`6`, and level-file format `1`. The current savegame format `7`
persists the active interior area ID, local field, cardinal facing, and exact
outdoor return location, together with accumulated discovery and item state.
Reconnecting does not restore it implicitly: the
connected start screen requires an explicit new-game or load choice.
