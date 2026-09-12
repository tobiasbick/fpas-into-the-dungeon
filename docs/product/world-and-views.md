# World structure and views

This document defines the canonical terms for the spatial world model and its
presentation. It does not yet define gameplay systems such as combat, quests,
or character progression.

## Terminology

- **World** is the complete authoritative game state owned by the server. It
  contains all known areas, locations, actors, and their relationships.
- **Area** is one navigable spatial environment. The player occupies one area
  at a time.
- **Outdoor region** is an exterior area such as countryside, wilderness, or
  the land between settlements.
- **Settlement** is an exterior built-up area such as a village or town.
- **Interior** is an entered, enclosed part of a building such as a house or
  castle.
- **Dungeon** is an enclosed exploration area. It remains a distinct kind of
  area even though it shares its view family with interiors.
- **Location** is an identifiable place within an area. A location can mark a
  destination or an entrance to another area, such as a building or dungeon
  entrance.
- **Player intention** is an action requested by the client. It is not an
  authoritative result.
- **Visible state** is the server-produced, client-safe projection of the
  current area and player state. It is not the complete world.
- **Transition** is the server-authoritative move from one area to another,
  such as entering or leaving a building or dungeon.

## View families

Outdoor regions and settlements use a **map view**. The initial implementation
uses a top-down grid of terminal cells. Isometric rendering remains a possible
later presentation alternative, not a separate world simulation.

Dungeons and all entered interiors use a **first-person view** rendered with
terminal raycasting. This includes houses, castles, and similar buildings.
Leaving an interior or dungeon returns the player to the map view of the
surrounding outdoor region or settlement.

The server owns the area kind, geometry, rules, and visible state. The client
does not receive the complete world. It selects the required view family from
the visible state and renders it without owning or duplicating game rules.

## Initial implementation direction

The next world slice is a fixed outdoor region shown in the top-down map view,
not a dungeon. Its visible state is owned and produced by the server. The
client renders that state without importing world dimensions or rules from the
game module.

Isometric rendering, area transitions, interiors, dungeons, procedural world
generation, persistence, LLM integration, and the first RPG action are outside
this slice and will be specified separately.
