# NPCs and simple dialogue

The first NPC slice adds one fixed, server-owned character and one typed,
deterministic conversation. It deliberately proves the dialogue boundary
without introducing a scripting language or LLM-generated behavior.

## Authoritative model

The initial dungeon contains **Mara, the old adventurer**, with stable identity
`initial-dungeon:old-adventurer`. Her position `(1, 1)` is part of the validated
interior definition. It must be a floor field distinct from the start, exit,
item, and tablet. Mara is stationary and blocks movement; the player cannot
occupy her field.

The persistent NPC record contains identity, kind, and `has_met_player`. A new
game resets the flag. The flag changes when the first dialogue starts and is
written only by an explicit save. Active dialogue, selected choice, and overlay
state belong to the current connection and are never saved.

## Interaction and dialogue

`Enter` starts dialogue only when Mara is directly ahead. The server returns a
complete dialogue frame containing NPC identity, speaker name, text, and an
ordered set of stable choice IDs with display text. The client renders these
values but does not derive available choices or resolve their effects.

The initial typed dialogue graph offers questions about Mara and the dungeon,
plus goodbye. A question about the Ancient coin appears only while the
authoritative inventory contains it. Mara comments on the coin but neither
takes nor changes it. The first and later greetings differ according to
`has_met_player`.

While a dialogue is active, the server accepts only a dialogue choice, explicit
dialogue end, viewport update, or disconnect. Movement, turning, interaction,
map requests, and saving receive `dialogue_active`. A choice not present in the
current authoritative frame is rejected. Ending or disconnecting changes no
persistent game state; reconnecting never resumes a conversation.

This graph is ordinary Functional Pascal data and functions. A general
scripting system, quests, schedules, moving NPCs, branching world effects,
free text, and LLM involvement remain deferred until a concrete requirement
justifies their additional authority and lifecycle rules.

## Projection and presentation

Protocol version `10` adds `dialogue_choice` and `end_dialogue` intentions plus
`dialogue` and `dialogue_ended` responses. IDs, text, choice count, unique
choice identities, and exact JSON field sets are bounded and validated.

Mara is a dynamic `n` cell only while her field is currently visible. Both the
first-person renderer and exploration map use a distinct NPC marker. A
remembered field retains only static floor geometry, so Fog of War does not
claim that Mara is still visible there.

The client opens a framed modal dialogue overlay. W/S or arrow keys select a
choice, Enter submits it, and Escape asks the server to end the dialogue. The
selection wraps at both ends. Pending requests suppress repeated input, and
movement, the exploration map, and the system menu cannot take ownership until
the dialogue ends. `Alt+X` remains the global clean-exit path.

## Persistence and tests

Savegame format `4` stores the exact NPC record beside discovery and item
state. Missing, duplicate, unknown, mistyped, or extra NPC data rejects the
whole save. Older formats are intentionally unsupported and follow the current
invalid-save removal policy.

Game, protocol, persistence, client-update, headless-TUI, raycasting, client
network-adapter, and TCP server tests cover the success path as well as invalid
placement, collisions, unavailable and unknown choices, malformed messages,
input gating, current versus remembered visibility, explicit save, reconnect,
and repeat greeting behavior.
