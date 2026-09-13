# World structure and views

This document defines the canonical terms for the spatial world model and its
presentation. It does not yet define gameplay systems such as combat, quests,
or character progression.

## Terminology

- **World** is the complete authoritative game state owned by the server. It
  contains all known areas, locations, actors, and their relationships.
- **Area** is one navigable spatial environment. The player occupies one area
  at a time.
- **Area identity** is the stable server-owned identifier of one area. It is
  deterministic within the selected world and remains separate from the
  display label shown to players.
- **Outdoor region** is an exterior area such as countryside, wilderness, or
  the land between settlements. Outdoor regions may be practically unbounded.
- **Settlement** is an exterior built-up area such as a village or town.
- **Interior** is an entered, enclosed part of a building such as a house or
  castle.
- **Dungeon** is an enclosed exploration area. It remains a distinct kind of
  area even though it shares its view family with interiors.
- **Location** is an identifiable place within an area. A location can mark a
  destination or an entrance to another area, such as a building or dungeon
  entrance.
- **Entrance** is a location in one source area that names a valid transition
  target. Standing on an entrance and activating it are separate events.
- **Return location** is the exact source area identity and coordinate retained
  by the server while the player occupies an entered area.
- **Terrain** is the generated ground material, vegetation, or water that gives
  an outdoor location its physical character.
- **Tree** is an individual vegetation feature on otherwise open terrain.
- **Forest** is a connected vegetation region with a dense interior and a
  looser edge of individual trees.
- **Lake** is a finite inland body of water with a generated shoreline.
- **Chunk** is one fixed 128 by 128 storage, generation, and cache partition
  inside an outdoor region. It is not an area and is never presented to the
  player as a transition.
- **Chunk coordinate** is the signed pair identifying a chunk. World
  coordinates use floor-based conversion so negative positions map
  consistently to chunk and local coordinates.
- **Visible window** is the bounded rectangular part of an area sent to a
  client. It has a world-coordinate origin and is independent of chunk
  boundaries.
- **Player intention** is an action requested by the client. It is not an
  authoritative result.
- **Visible state** is the server-produced, client-safe projection of the
  current area and player state. It is not the complete world.
- **Transition** is the server-authoritative move from one area to another,
  such as entering or leaving a building or dungeon.

Walking across a chunk boundary is seamless movement within the same outdoor
region. A transition changes both area identity and view family and occurs only
when entering or leaving a settlement, interior, dungeon, or another distinct
area.

## UI terminology

- **Start screen** is the framed, centered menu shown before a game session.
- **Game screen** is the client screen used during an active session.
- **Primary view** is the map or first-person presentation on the game screen.
- **Context panel** is the optional right-hand summary of character, location,
  equipment, and immediately relevant inventory information.
- **Status view** is the persistent framed bottom view with one content line for
  connection state, action progress, messages, and errors.
- **Message panel** is an optional, larger history area above the status view.
- **System menu** is the overlay for information, controls, session actions,
  and quitting.

## View families

Outdoor regions and settlements use a **map view**. The initial implementation
uses a top-down grid of terminal cells. Isometric rendering remains a possible
later presentation alternative, not a separate world simulation.

Dungeons and all entered interiors use a **first-person view**. The current
dungeon uses a framed placeholder; terminal raycasting begins with the first
interior slice. This view family also covers houses, castles, and similar
buildings. Leaving an interior or dungeon returns the player to the exact
retained location in the map view of the surrounding area.

The server owns the area kind, geometry, rules, and visible state. The client
does not receive the complete world. It selects the required view family from
the visible state and renders it without owning or duplicating game rules.

## Current implementation

The first world contains a deterministic, chunked outdoor region and one
initial dungeon. A distinct entrance is generated exactly three traversable
cardinal steps from the spawn. Walking onto it remains ordinary outdoor
movement; `Enter` activates the server-authoritative transition. The dungeon is
already a distinct area even though its current presentation is only the
first-person placeholder. Pressing `Enter` there returns to the exact entrance
coordinate.

Settlements, further entrances, navigable interiors, mutable terrain, broader
world simulation, isometric rendering, LLM integration, and the first RPG
action remain outside this slice. Their intended order is tracked in the
[roadmap](../roadmap.md).
