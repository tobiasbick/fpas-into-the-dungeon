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
- **Interaction** is a player intention resolved by the server against the
  occupied field or the field directly ahead. It may change authoritative
  state or only return a description.
- **Inspectable object** is a world feature that can return a description
  without necessarily changing game state.
- **Stone tablet** is the first fixed, wall-mounted inspectable object in the
  initial dungeon.
- **Item** is a server-owned game object with stable identity, kind, and exactly
  one authoritative location.
- **Inventory** is the set of items whose authoritative location is the player.
  The visible inventory is only a client-safe projection of that set.
- **Ancient coin** is the first fixed collectible item in the initial dungeon.
  It proves inspection, pickup, projection, and persistence without defining a
  broader loot system.
- **Visible state** is the server-produced, client-safe projection of the
  current area and player state. It is not the complete world.
- **Game session** is one connected, server-authoritative period of play. A
  connection waits for an explicit new-game or load choice before it becomes
  an active game session.
- **Savegame** is the selected world's single versioned snapshot of resumable
  authoritative game state. It is server-owned and distinct from generated
  world data and client preferences.
- **Transition** is the server-authoritative move from one area to another,
  such as entering or leaving a building or dungeon.
- **Grid-based first-person movement** is discrete movement through a
  first-person area. The player occupies one whole field and faces one cardinal
  direction; one movement intention can advance by at most one field, while a
  turn changes the facing direction without changing the occupied field.

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
- **Environment panel** is the area above the context panel for current
  interaction opportunities and immediate interaction feedback. It describes
  the player's surroundings, not carried inventory or connection state.
- **Status view** is the persistent framed bottom view with one content line for
  connection state, action progress, messages, and errors.
- **Message panel** is an optional, larger history area above the status view.
- **System menu** is the overlay for information, controls, session actions,
  and quitting.
- **Currently visible** describes a location inside the player's present
  outdoor sight radius or unobstructed interior line of sight.
- **Discovered but not visible** describes a previously visible location
  retained as world knowledge without claiming that its current contents are
  visible.
- **Undiscovered** describes a location never made visible in the current game.
- **Discovered area** is the persistent, server-owned set of currently visible
  and previously discovered locations.
- **Sight field** is the currently derived set of visible locations for the
  player's area, position, and, inside, cardinal facing. It is not persisted.
- **Fog of War** is the rule that masks undiscovered locations and visually
  distinguishes remembered locations from currently visible ones in both the
  primary map view and the exploration map.
- **Exploration map** is an overlay showing the current area's discovered
  world knowledge. It may be panned independently of the player and does not
  replace the primary view or issue movement intentions.

## View families

Outdoor regions and settlements use a **map view**. The initial implementation
uses a top-down grid of terminal cells. Isometric rendering remains a possible
later presentation alternative, not a separate world simulation.

Dungeons and all entered interiors use a **first-person view**. The current
dungeon uses terminal raycasting inside the shared framed primary view. This
view family also covers houses, castles, and similar buildings. Leaving an
interior or dungeon returns the player to the exact retained location in the
map view of the surrounding area.

The first-person view uses grid-based first-person movement rather than free or
continuous movement. Raycasting is the presentation of the discrete area; it
does not introduce fractional gameplay positions, arbitrary view angles, velocity, or
movement across several fields from one intention.
The visual eye is offset backward within the occupied field to make lateral
openings readable; this does not change the player's position or interaction reach.

The server owns the area kind, geometry, rules, and visible state. The client
does not receive the complete world. It selects the required view family from
the visible state and renders it without owning or duplicating game rules.

The current implementation retains discovered areas separately for the
outdoor region and each entered finite area. Current visibility is derived from
the player's authoritative state: outdoors as a non-occluded radius and inside
as facing-aware line of sight. Viewport size and exploration-map position are
presentation concerns and never expand the discovered area.

## Current implementation

The first world contains a deterministic, chunked outdoor region and one
initial dungeon. A distinct entrance is generated exactly three traversable
cardinal steps from the spawn. Walking onto it remains ordinary outdoor
movement; `Enter` requests a server-authoritative interaction, which activates
the transition on that field. The dungeon is
an 11 by 9 bounded area with a fixed start pose, walls, floor, corridors, and
one visible exit field. It also contains a fixed stone tablet on a wall directly
north of the start. Facing the tablet and pressing `Enter` returns its
description without changing game state. A fixed Ancient coin can first be
inspected from the adjacent start field and then picked up with `Enter` while
standing on its field. The server removes it from the area, exposes it in the
visible inventory, and persists its carried state. The server accepts the exit
interaction only on the exit field and then returns the player to the exact
outdoor entrance coordinate.

Settlements, further entrances, navigable interiors, mutable terrain, broader
world simulation, isometric rendering, LLM integration, and broader mutable RPG
systems remain outside this slice. Their intended order is tracked in the
[roadmap](../roadmap.md).
