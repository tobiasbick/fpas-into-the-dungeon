# Emergent dungeon RPG in Functional Pascal

## Purpose

Build a small but real game that demonstrates what Functional Pascal can do.
The game should combine terminal graphics, procedural generation, persistent
world state, client-server networking, concurrency, and a local LLM.

The goal is not to reproduce NetHack, Might and Magic, or Wolfenstein. Those
games are useful visual and mechanical references. The intended result is an
exploration RPG whose world takes shape while the player discovers it. There is
no fixed story. Deterministic game rules keep the world playable, while a local
LLM supplies characters, places, conflicts, dialogue, and quest proposals.

This should eventually live in its own GitHub repository. The current dungeon
under `apps/dungeon/` is an incubating prototype and proves that FPAS can render
and navigate a first-person terminal dungeon.

## Current prototype

The prototype already provides:

- a fixed 20 by 16 dungeon map;
- Wolfenstein-style DDA raycasting;
- first-person rendering through `Std.Tui` and `TuiCellGrid`;
- two vertical color samples per terminal cell using the `▀` glyph;
- free movement, turning, strafing, wall clearance, and wall sliding;
- a responsive layout with the dungeon on the left;
- an `Infos` panel on the right at 110 terminal columns or more;
- a status line, resize handling, and headless TUI tests.

The prototype has no monsters, items, combat, generated maps, networking, save
files, or LLM-driven content yet.

## Player experience

The player starts in a new world generated from a random seed. The seed defines
the reproducible structure of the world. It determines geography, regions,
roads, settlements, entrances, and dungeon geometry.

The LLM turns that structure into a particular world. It supplies names,
cultures, local disputes, NPC personalities, descriptions, and quests. A new
seed changes the physical world. LLM sampling makes the interpretation and
population of that world different as well.

The world should materialize progressively:

1. World creation produces only geography and coarse facts.
2. Approaching a region adds local terrain and candidate locations.
3. Discovering a location gives it a name, visible history, and inhabitants.
4. Entering a dungeon generates and validates its complete geometry.
5. Important generated content becomes persistent and never needs to be
   regenerated from the LLM.

This allows a large world without generating or holding every detail at once.
Storage grows mostly with what the player has explored.

## Views

The canonical terminology and presentation rules now live in
[World structure and views](docs/product/world-and-views.md).

## Generation and authority

FPAS owns all authoritative game state and rules. The LLM may propose content,
but it must not directly mutate the world.

The procedural generators must guarantee structural validity:

- locations and exits exist;
- dungeon rooms and stairs are reachable;
- quests use supported goals;
- required items can exist and remain obtainable;
- rewards follow game rules;
- NPC knowledge does not exceed what the NPC could know;
- accepted content does not contradict confirmed facts.

The LLM receives fixed facts and returns structured proposals. FPAS parses,
validates, accepts, repairs, or rejects each proposal. Free-form prose is never
treated as an authoritative state change.

A location can move through explicit states:

```text
Undiscovered
    Only coordinates, region, seed, and coarse type exist.

Discovered
    Name, visible description, and clues are persistent.

Materialized
    Geometry, NPCs, items, quests, and events are persistent.
```

A dungeon seed should derive from stable inputs such as the world seed and
location identity. This makes geometry reproducible even though its narrative
decoration is sampled from an LLM.

## LLM roles

One locally hosted model can provide many logical agents. The model weights are
loaded once. Each agent has its own system instructions, selected knowledge,
memory, and current assignment. Several inference slots allow roles to work
concurrently without loading several complete copies of the model.

Start with three roles:

### World planner

The world planner proposes broad conflicts, faction goals, regional changes,
and consequences of important player actions. It runs infrequently and sees a
compressed world overview. It does not create maps or alter state directly.

### Location builder

The location builder turns one validated region or location skeleton into
concrete proposals for names, local history, NPCs, points of interest, and
quests. It runs while the player approaches undiscovered content or first
enters it.

### NPC actor

The NPC actor speaks and proposes immediate reactions for one character. It
receives only that character's identity, permitted knowledge, relevant
memories, relationship to the player, current surroundings, and recent
conversation. It cannot invent possessions or authoritative world facts.

Logical agents should not hold open-ended discussions with each other. They
communicate through validated, stored results. Each invocation has a concrete
assignment and ends after returning its result.

A later content critic could detect repetitive quests or weak proposals. FPAS
must still perform mechanical validation because a second LLM opinion cannot
prove that a quest is reachable or an item exists.

## Context strategy

The target machine can hold a large native context, but ordinary calls should
remain much smaller. A local Qwen MoE model in the approximate 30 to 35 billion
parameter class can be served once with two or three independent 32K contexts.

Expected working ranges:

| Call | Typical input | Typical output |
| --- | ---: | ---: |
| NPC response | 4K to 15K tokens | 100 to 800 tokens |
| Quest proposal | 3K to 8K tokens | 500 to 2K tokens |
| Location materialization | 6K to 15K tokens | 3K to 8K tokens |
| Regional planning | 10K to 25K tokens | 2K to 6K tokens |

The game should construct a context package for each call:

```text
role instructions
+ output schema
+ relevant global facts
+ current region and location
+ permitted NPC knowledge
+ active quests and relationships
+ compact memories
+ recent dialogue
+ current request
```

Do not send the entire world or complete campaign log. Old conversations remain
in the save file but are summarized into durable facts, relationship changes,
open promises, and a short conversation summary. Important facts are stored in
structured form.

Large context support remains useful for exceptional planning and debugging.
It should be reserve capacity rather than a requirement for every interaction.
MoE reduces active compute per generated token, but each concurrent context
still consumes its own KV cache.

## Persistent NPC identity

Important NPCs should be durable entities rather than names regenerated for
each conversation. A character such as Maria can have a directory in the save:

```text
save/world-001/npcs/maria/
├── identity.json
├── soul.md
├── memories.jsonl
├── relationships.json
└── conversation-summary.md
```

`identity.json` contains authoritative facts such as identity, occupation,
home, possessions, and whether the NPC is alive.

`soul.md` contains the softer and more readable character definition:

- values and temperament;
- speech habits;
- fears and desires;
- internal conflicts;
- behavior under pressure;
- slow character development caused by important events.

`memories.jsonl` records confirmed events. Memories can carry importance,
emotional weight, participants, and references to known world entities.

`relationships.json` stores measurable relationships such as trust, fear,
respect, obligation, and hostility.

`conversation-summary.md` compresses older dialogue. Recent messages can remain
verbatim for a short time.

The model may propose memories, relationship changes, and amendments to
`soul.md`. The game validates them before writing. Identity changes rarely,
personality changes after meaningful events, and memories change regularly.
This produces development without allowing each model response to rewrite the
character.

## Controlled model tools

Personality persistence does not require tools or MCP. The game can assemble
the relevant files and pass them with each request.

Small game-owned model tools become useful when an agent needs information or
wants to propose an action:

```text
recall_memories
inspect_relationship
ask_world_fact
offer_quest
give_item
remember_event
propose_soul_change
```

Every tool has narrow permissions. An NPC can only recall its own memories and
ask for facts it could plausibly know. Giving an item fails if the NPC does not
own it. Offering a quest creates a proposal that the quest rules validate.

MCP is not needed for the first game. A small internal tool-call protocol has
less machinery and keeps game rules close to the simulation. MCP can later be
added as an adapter if external editors, debuggers, agent programs, or other
games need the same tools. It would also be a useful FPAS interoperability demo
once the game itself works.

## Client and server

The intended architecture eventually uses separate FPAS programs:

```text
TUI client
    |
    | commands and visible state
    v
game server
    ├── authoritative simulation
    ├── procedural generators
    ├── persistence
    ├── content validation
    └── agent orchestration
              |
              v
       local model server
```

The game server owns the world. The client sends player intentions and renders
the resulting visible state. This demonstrates FPAS networking and permits a
second client later without moving game rules.

The local model server exposes an OpenAI-compatible endpoint. FPAS already has
a buffered OpenAI-compatible client, JSON, filesystem operations, TCP and TLS,
tasks, channels, server lifetime management, and background-capable TUI
execution. The application still needs multi-turn conversation construction,
structured model result handling, persistence, and orchestration.

Do not split the prototype into physical client and server processes before the
first playable vertical slice. First establish the simulation interface so the
in-process implementation can later be replaced by a network adapter without
changing the game UI.

## Suggested repository

The full game should use its own repository because it will have independent
architecture, issues, save fixtures, prompts, releases, and possibly assets.
The compiler repository should remain focused on the language and small
reference applications.

A possible layout is:

```text
fpas-dungeon/
├── README.md
├── LICENSE
├── dungeon.fpasworkspace
├── apps/
│   ├── client/
│   └── server/
├── libs/
│   ├── world/
│   ├── simulation/
│   ├── rendering/
│   ├── protocol/
│   ├── persistence/
│   └── agents/
├── prompts/
│   ├── world-planner.md
│   ├── location-builder.md
│   └── npc-actor.md
├── tests/
│   ├── world/
│   ├── simulation/
│   ├── protocol/
│   └── agents/
└── examples/
    └── sample-world/
```

Prompts are implementation and belong under version control. Save metadata
should record the model identifier, generation settings, prompt versions, and
game version used to materialize content. This helps reproduce and diagnose bad
generation without making exact LLM output part of the gameplay contract.

## First playable vertical slice

The first milestone should prove the whole idea on a small scale:

1. Generate a seeded top-down outdoor region.
2. Enter one settlement.
3. Materialize one persistent NPC with a `soul.md`.
4. Talk to that NPC in the responsive TUI panel.
5. Let the NPC propose one validated, solvable quest.
6. Generate a dungeon when its entrance is first used.
7. Complete the objective through deterministic game rules.
8. Return to the NPC and observe remembered events and a changed relationship.
9. Save, quit, reload, and continue the same world consistently.

This milestone is successful when Maria remembers an earlier conversation,
offers a quest whose target really exists, reacts to its outcome, and remains
the same developed character after loading the save.

## Design decisions so far

- Keep gameplay deterministic and authoritative in FPAS.
- Use procedural seeds for reproducible physical structure.
- Use the LLM for meaning, language, and bounded proposals.
- Materialize places lazily and persist accepted results.
- Load one local model and represent roles as logical agents with separate
  contexts.
- Begin with world planner, location builder, and NPC actor roles.
- Give important NPCs structured identity, readable `soul.md`, memories,
  relationships, and conversation summaries.
- Add narrow internal model tools before considering MCP.
- Prove one complete quest loop before increasing world size or separating
  processes.
- Move the full game to its own repository when development begins in earnest.

## Open questions

- What is the game called?
- How tactical should movement and combat be?
- Does time advance continuously, per action, or in larger turns?
- Which quest forms belong to the initial deterministic rule set?
- How much can the world planner change regions the player has already seen?
- Which NPCs deserve full persistent identities, and which can remain compact?
- Should model generation happen ahead of discovery or only after entering a
  loading state?
- What should happen when the local model is unavailable or returns invalid
  content repeatedly?
- When should the in-process simulation gain its network adapter and become a
  separate server process?
