# Mara's compass quest

Stage 15b implements one authored, deterministic quest. Mara asks the player to
recover her compass from the deepest level of the spawn dungeon and return it
for two Healing potions. The server owns the objective, dialogue choices,
progress and reward. No quest action depends on an LLM.

## Objective and reachability

The spawn entrance belongs to the spawn's region, including when the entrance
crosses a region boundary. Generator 10 places exactly one `maras_compass` in
original item slot 6 of that dungeon's deepest level. Other required and
optional slots keep their identities. Other dungeons contain no compass.
Level format 4 validates this requirement against world metadata and stored
depth; readers do not regenerate placements, geometry or names.

Selecting Mara's quest topic before acceptance runs `Dungeon.World.Quests`
preflight. Existing level files take precedence. A missing level can be
previewed in memory only when the current game has not visited it. An invalid
existing file or a missing visited file fails with the established typed
world-data/storage/generation error. Preflight creates no files, visits,
entities, discovery or combat random draws.

Level 0 supplies its stored depth when present; otherwise the current generator
supplies it. `Dungeon.Quests.Reachability` checks validated outdoor access,
complete level identities, matching depth/name, connected traversable fields,
paired stairs and the unique reachable target. This proves an outward and
return route, rather than promising victory in combat. Persistent level
creation still occurs on first entry. Existing files are never replaced by a
preview.

The server retains the resulting objective in the connection-local offer node.
The client can submit only an NPC ID and choice ID; it cannot choose a target
or reward. Acceptance copies the bound objective into game state.

## Lifecycle and item ownership

The quest identity is `<world>:quest:mara-compass`. Its objective contains that
identity, the deepest spawn-level area ID and `<target-area>:item:6`.

| Journal phase | Persistent state | Meaning |
| --- | --- | --- |
| No accepted quests | `NotAccepted` | Mara's offer can be revisited. |
| Active | `Active(objective)` | Accepted, but the compass is not carried. |
| Ready to return | `Active(objective)` | The objective's compass is carried. |
| Completed | `Rewarded(objective)` | Mara has the compass and both reward items were granted. |

Readiness follows current item ownership. Retrieving the compass before
acceptance counts immediately on acceptance. Dropping it removes readiness;
normal pickup restores it. The compass cannot be worn or consumed. It can be
dropped only under the existing ordinary dungeon-floor rules, so it remains
recoverable. There is no abandonment, timer or repeat within one game.

Hand-in requires Mara in cardinal reach, a matching active dialogue node and
the accepted compass in inventory. The final inventory count is the old count
minus the compass plus two potions. At 63 carried/worn items it succeeds with
64; at 64 it defers the entire exchange. The ready dialogue explains that space
is needed and allows a later attempt.

Successful hand-in performs three changes together:

1. The compass becomes `ReturnedToMara(quest_id)`, a terminal location retaining
   its original identity and kind. It occupies no field or inventory capacity.
2. Two carried Healing potions receive IDs `<quest-id>:reward:0` and `:1`.
3. The quest becomes `Rewarded(objective)`.

Quest rewards have their own validated origin; they are never invented dungeon
placements. Both records must remain present after reward, including when a
potion is consumed or dropped. Full validation still requires every original
dungeon placement exactly once. Missing, duplicate, foreign, premature or
wrong-kind reward records reject the save. Only this quest's compass may use
the returned terminal location.

Talking, accepting and reporting consume no turn or random draw. They award no
skill experience; combat damage remains the only training source. Mara's free
healing and existing information topics remain available through the root
dialogue. Her later greeting and quest status remember the returned compass.

## Dialogue, projection and journal

`Dungeon.Dialogue.Model` separates display fields from server-owned nodes:
root, compass offer with objective, and compass status. The root adds `quest`
within the existing six-choice limit. Quest frames use `quest_accept`,
`quest_report` when ready, and `quest_back`. Rules check eligibility against
both the retained frame and current state, including a repeated or stale
choice. Back returns to other questions; explicit end works from every node.

Protocol 18 retains the dialogue envelopes and adds the required `journal`
string array to map and first-person state objects, including embedded dialogue
states. It admits at most eight lines of 1..160 printable ASCII characters;
an empty array is valid. Missing/mistyped fields, oversized entries, control
characters and non-ASCII journal text reject the message. The journal exposes
no undiscovered map geometry or actor positions.

`Dungeon.Quests.Journal` formats the phase, objective, progress, return hint and
reward. The client renders these lines on `J`, wraps long text, and scrolls
with W/S, arrows or Page Up/Down. Escape/J closes it. Input stays local and
cannot move the player, consume a turn or dirty a save. Refresh and resize
preserve the overlay and clamp its wrapped-row offset. An active conversation
retains keyboard ownership over the journal shortcut.

Dialogue replies retain prepare/send/install ordering. Failed projection or
bounded-line preparation preserves the state, offer node, compass, rewards,
dirty flag and cache. Failed writes are fatal without installing the candidate.
Preflight failures use sanitized client errors and detailed server logs.

## Persistence and compatibility

Savegame format 12 adds an exact `quest` object. An unaccepted quest stores
`{"phase":"not_accepted"}`. Accepted/rewarded records contain exactly `phase`
and `objective`; the objective contains exactly `quest_id`, `area_id` and
`item_id`. Ready status is never serialized.

The returned compass location is exactly
`{"kind":"returned_to_mara","quest_id":"<quest-id>"}`. Potion consumption
retains its existing `consumed` meaning. Quest state, terminal ownership and
reward origins are cross-validated, including while the player is outdoors.
An accepted quest requires that Mara has been met.

Save/load reuse visited maps and check the retained objective against stored
spawn-dungeon depth. If level 0 is still unvisited and absent, its current
content contract supplies depth without generating a map. An existing
unvisited level 0 is read; invalid world data stays an error. No saved proof
flag or client progress value is trusted.

Explicit Save after closing dialogue persists progress. Disconnect, shutdown
and quest completion do not autosave. Continue restores the complete saved
state, including whether the reward was claimed; loading an earlier save
rewinds the whole game. Start over resets quest, NPC and mutable item state
while retaining immutable level files and the previous save until explicitly
overwritten.

Current versions are world metadata 4, generator 10, level file 4, savegame 12
and protocol 18. Obsolete data is rejected and preserved without migration;
generator-9 worlds require creating a new world.

## Ownership and verification

`Quests.Model` owns independent state/identity types and objective validation.
`Quests.Items` owns reward identities and terminal ownership checks; neither
depends on `GameState`. `Dungeon.Quests` applies pure rules against game state,
and `Quests.Journal` formats its read-only projection. `Npcs.Interaction`
shares Mara's reach rule with dialogue. `Dialogue.Quests` owns quest frames,
and the world save layer owns their persistent data codec separately.

World tests cover preflight authority, reachability, strict saved objectives,
earlier retrieval, capacity and retained reward origins after use/drop.
Protocol tests own journal bounds and wire shapes; native TUI tests own wrapping,
scrolling, refresh, resize and input isolation. Server tests cover failed
accept/report preparation and stale claims. The natural TCP play test runs
through four listener lifetimes: accept and Save, Continue and retrieve/Save,
Continue and return/Save, then Continue and observe Mara's remembered outcome
without another reward. Existing level files remain byte-for-byte unchanged.
