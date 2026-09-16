# First-person interior

The first-person interior slice adds one fixed dungeon that proves discrete
navigation and terminal raycasting without adding general dungeon generation or
gameplay systems.

## Ownership

`libs/game` owns the bounded 11 by 9 interior map, its field meanings, the
player's area-local coordinate and cardinal facing, collision, and entry and
exit rules. The map contains walls, traversable floor, one start field, one
visible exit field, and one fixed stone tablet mounted on a wall. Validation
requires rectangular geometry, a traversable start, exactly one exit, a wall
field for the tablet, and connectivity between all traversable fields.

The player's retained outdoor return location remains separate from the
interior pose. Entering establishes the fixed start pose. Leaving is accepted
only on the exit field and restores the exact retained outdoor coordinate.
Neither the client nor the renderer decides whether a step, turn, or transition
succeeds.

## Protocol and server projection

Protocol version `8` carries distinct intentions for a relative one-field step
(`forward`, `backward`, `left`, or `right`) and a 90-degree turn (`left` or
`right`). Outdoor cardinal movement remains a separate message.

The first-person visible-state variant contains only the bounded field rows,
dimensions, knowledge rows, area-local player coordinate, cardinal facing, title, and status.
It excludes area identities, the outdoor return location, persistence paths,
and other server-owned state. The server returns a complete projection after
each accepted intention and a structured rejection after an invalid one.
Viewport updates return the same validated interior geometry without loading
outdoor chunks.

## Client rendering

`Dungeon.Client.Raycast` is a pure presentation module. It derives a cardinal
camera and fixed field of view from a validated first-person state, finds the
nearest opaque field for each terminal column with grid DDA, corrects wall
distance for perspective, and fills every output cell with ceiling, wall, or
floor. Walls use deterministic distance and side shading. The tablet projection
is opaque and uses a distinct material without changing the wall geometry. Only the projected
exit floor field is gold; rays crossing it never recolor walls. Adjacent front
walls use inset geometry with forward-facing side lanes and closed-side wedges.
Unknown fields remain masked. See the client UI specification for presentation
details.

Rendering never changes game state and does not infer collision or hidden
geometry. The first-person cell grid fills the primary panel at its available
terminal width, while the existing frame, context panel, message panel, status
view, overlays, resizing behavior, and shortcuts remain shared with the map
view.

## Persistence and lifecycle

The fixed interior remains current program data, so world format `2`, chunk
format `2`, and generator version `5` remain unchanged. Savegame format `2`
persists the active interior area ID, local field, cardinal facing, and exact
outdoor return location, together with accumulated discovery. Reconnecting does not restore it implicitly: the
connected start screen requires an explicit new-game or load choice.
