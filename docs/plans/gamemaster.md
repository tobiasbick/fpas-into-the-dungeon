# Gamemaster: feasibility and open questions

The existing LLM connection and model-selection work is accepted and complete.
See the [connection contract](../architecture/gamemaster-connection.md).
This note explores possible next work. It is a starting point for discussion;
implementation steps will be defined later.

## Gamemaster ownership and jobs

Each game has its own Gamemaster, whose role is to create the world, dungeons
and NPCs. The player never chats with it. This discussion currently focuses on
world generation.

The server signals a specific generation job. The Gamemaster receives the
required context, calls game tools, inspects results and revises its draft.
After validation, publication and a context update, the job ends. No autonomous
work continues between jobs. Whether the technical ACP session stays open is
still undecided. Branching is outside the required workflow.

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

Give each area a scoped generation job with the world premise, local
geographic constraints and brief summaries of all existing direct neighbors.
Store a few sentences with each completed area. Include exact shared-edge
constraints for rivers, paths and terrain; prose alone cannot fix their geometry.
New areas must fit every existing neighbor, including when exploration closes
a loop.

Load only relevant context. Keep tool replies compact and request map excerpts
when needed. Avoid accumulating the world's generation history in one session.
Context per job should stay bounded as the world grows.

## Persistence, compaction and harness changes

Keep portable Gamemaster context in a dedicated `gamemaster/` directory inside
the game's world directory. Store generation notes, decisions, relationships
and area summaries there. Read authoritative world facts through game tools.
Update the notes after completed jobs; save and restore the context with the
game, consistently with its stored world data.

Harness changes, such as Pi to Codex or OpenCode, happen only in the server
console while no game is running. Finish or cancel remaining generation jobs
before switching. The selected harness receives the game's portable context
on its next start. Native ACP session restoration is optional and depends on
agent capabilities and consistency with the loaded game state.

Leave conversation compaction to the harness where supported and enabled.
Continuously archive ACP-visible requests, messages, tool calls and results
for debugging. When compaction is reported, retain the earlier history and
store any supplied summary. ACP does not guarantee an exact export of the
internal model context. Keep the debug archive out of normal generation prompts.

## Topics to expand

- Technical ACP session lifetime, reuse, recovery, cancellation and retries.
- Model changes, capability differences and interrupted work.
- Context budgets, summaries, selective queries and tool-output limits.
- Game tools for inspection, drafting, revision, validation and publication.
- Scheduling, latency, cost, failures and concurrent generation.
- Persisted LLM output and the current seed-based determinism requirement.

Feasibility remains to be checked with example areas: landscape quality,
neighbor continuity, reachability, context use, generation time and cost.
