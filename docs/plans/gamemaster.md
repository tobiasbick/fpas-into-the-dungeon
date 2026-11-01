# Gamemaster: feasibility and open questions

The existing LLM connection and model-selection work is accepted and complete.
See the [connection contract](../architecture/gamemaster-connection.md).
This note explores possible next work. It is a starting point for discussion;
implementation steps will be defined later.

## Outdoor world generation

Explore whether the Gamemaster can design outdoor areas through game tools.
Start with 64 by 64 fields; 128 by 128 remains an option. The relationship to
the existing storage chunks is still open.

The Gamemaster plans terrain, rivers, paths, settlements, landmarks and dungeon
entrances, inspects results and revises its draft. Tools build larger shapes
and connections, fill local details and report validation failures. The server
validates and publishes complete results and remains authoritative.

Generation should happen ahead of exploration, before Fog of War reveals the
area. Persist completed areas and reuse them on later visits.

A coarse geographic foundation supplies biomes from map position, latitude,
elevation, temperature and moisture. Allow gradual transitions. Larger mountain
ranges, rivers and routes need continuity across multiple areas.

## Bounded context and continuity

Give each area a fresh, scoped generation job with the world premise, local
geographic constraints and brief summaries of all existing direct neighbors.
Store a few sentences with each completed area. Include exact shared-edge
constraints for rivers, paths and terrain; prose alone cannot fix their geometry.
New areas must fit every existing neighbor, including when exploration closes
a loop.

Load only relevant context. Keep tool replies compact and request map excerpts
when needed. Avoid accumulating the world's generation history in one session.
Context per job should stay bounded as the world grows.

## Topics to expand

- Session lifetime, reuse, recovery, cancellation and retries.
- Model changes, capability differences and interrupted work.
- Context budgets, summaries, selective queries and tool-output limits.
- Game tools for inspection, drafting, revision, validation and publication.
- Scheduling, latency, cost, failures and concurrent generation.
- Persisted LLM output and the current seed-based determinism requirement.

Feasibility remains to be checked with example areas: landscape quality,
neighbor continuity, reachability, context use, generation time and cost.
