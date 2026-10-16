# Into the Dungeon

Explore a generated world, enter dungeons, and fight skeletons and giant rats — all in
your terminal. Into the Dungeon is a client-server role-playing game written in
[Functional Pascal](https://github.com/tobiasbick/functional-pascal).

![First-person encounter with a restless skeleton in Hollow Sanctum, with environment and character panels](docs/images/dungeon-skeleton.png)

The client renders a top-down outdoor map and a grid-based first-person dungeon
view. An authoritative server owns the world, movement, combat, and saves; it can
run headless or with a full-terminal dashboard.

> **Early development:** This is an experimental, vibe-coded hobby project, with
> no promise of a finished game. It also tests whether an LLM can build a VM-based
> programming language and use it for more than “Hello, world”. Developing the
> game exercises Functional Pascal's compiler, runtime, standard library, and
> tooling together.

## What you can play today

- Explore a seeded outdoor world with grassland, forests, water, mountains, and
  rare dungeon entrances. Movement across terrain chunks is seamless.
- Enter generated dungeons with rooms, corridors, and stored names. A dungeon's
  layout is fixed on first entry and retained when you revisit it.
- Discover the world through Fog of War and open a pannable exploration map.
- Inspect and collect ancient coins, equip a rusty short sword and leather
  jerkin, find and use healing potions, and drop carried items.
- Fight restless skeletons and giant rats in turn-based combat, with health, armor, combat
  messages, and animations. Walking outdoors gradually restores health.
- Create separate worlds, continue a saved game, or start over in an existing
  world. Saves retain discovery, inventory, equipment, and visited dungeon state.
- Monitor the server through status panels, a live log, filters, and settings
  for new-world defaults.

Each dungeon has one skeleton, one giant rat, four guaranteed floor finds and
up to two optional finds. The server currently accepts **one connected player
at a time**. Deeper dungeon levels are still planned.

## Quick start

You need a true-color terminal and a release build of
[Functional Pascal](https://github.com/tobiasbick/functional-pascal), with `fpas`
available on your command line. Use the compiler and source standard library
from the same FPAS checkout or installation. **FPAS 1 syntax is stable**;
further syntax changes are planned for **FPAS2**. The game remains under active
development. Older FPAS builds from before the completed syntax migration may
not compile this checkout.

Run the following commands from the repository root, in **two terminals**.

First, start the server with its dashboard:

```powershell
fpas run apps/server/server.fpasprj -- --console
```

Then start the client:

```powershell
fpas run apps/client/client.fpasprj
```

If you built FPAS from source, you can select its matching library explicitly:
`fpas run --std-lib ../functional-pascal/lib apps/server/server.fpasprj -- --console`.
Use the same `--std-lib` option when starting the client.

1. Select **Connect** in the client. Both programs default to `127.0.0.1:4040`.
2. On a fresh installation, select **Create world**. Keep the creation defaults
   or choose a seed and entrance-region size.
3. Walk to the nearby dungeon entrance with **WASD**, then press **Enter**.
4. Explore, collect equipment, and use **Space** to attack the field ahead.
5. Open the system menu with **Ctrl+P** and choose **Save** before leaving.

**Continue** loads the selected world's explicit save, or starts at spawn if it
has no save yet. **Start over** resets the game in that world while retaining its
stored dungeon layouts and the previous save; replacing a save asks for
confirmation. **Choose world** returns to world selection and asks before
discarding unsaved progress. Quitting or stopping the server does not save
automatically.

To run the server without a dashboard, omit `--console`:

```powershell
fpas run apps/server/server.fpasprj
```

## Controls

| Key | Action |
| --- | --- |
| WASD | Move outdoors; forward, left, backward, right inside a dungeon |
| Q / E | Turn left / right by 90 degrees inside a dungeon |
| Enter | Interact: inspect, pick up, or use an entrance or exit |
| Space / Z | Attack ahead / wait one turn inside a dungeon |
| I | Inventory; Enter uses a consumable or wears/removes gear, D drops the selected item |
| C | Character sheet with health, equipment, and derived values |
| M | Exploration map; WASD or arrows pan, Home centers, M or Esc closes |
| F2 / F3 | Toggle the client's context / message panels |
| Ctrl+P | System menu, including Save and Choose world |
| Alt+X | Quit |

In dungeons, successful steps, attacks, waiting, wearing/removing or dropping
items, and potion use advance a turn. A carried potion restores up to six health
points before the opponents act once. At full health the server rejects use
without consuming the potion or a turn. Turning, inspecting and rejected actions
do not advance time. The in-game system menu also lists the controls.

## Screenshots

These images were captured before the final 14b contents at 144 × 45 terminal
cells; they illustrate that earlier version rather than every current item.
The gameplay images use a newly created world with seed `12345`, normal Fog of
War, and real server responses. Font appearance can vary between terminals.

### Start screen

![Start menu inside a torch-lit dungeon entrance, surrounded by colored ASCII scenery](docs/images/start-screen.png)

The start menu sits inside a torch-lit entrance. Its colored ASCII scenery
adapts to the terminal size; connecting opens the world selection menu.

### Outdoor exploration

![Playable outdoor world at a dungeon entrance, with visible grassland, trees, remembered terrain, and undiscovered space](docs/images/outdoor-world.png)

The player stands on the spawn region's dungeon entrance after the short walk
from spawn. Bright terrain is currently visible, darker terrain is remembered,
and black areas are undiscovered.

### Dungeon exploration map

![Exploration map of Hollow Sanctum showing discovered rooms, corridors, the player, and a nearby skeleton](docs/images/exploration-map.png)

Press **M** to inspect discovered rooms and corridors without moving the
character. The overlay retains the dungeon's stored name and hides unexplored
parts of the level.

### Server dashboard

![Running server dashboard with Server, Session, and World panels above a timestamped live log](docs/images/server-dashboard.png)

The panels show listener status, connected players, the active world and dungeon,
and explicit-save status. Below them, the live log records real events from the
same session, including world creation, dungeon entry, and saving.

In the dashboard, **F2** opens settings, **F3** cycles log filters, and **End**
resumes following the latest entries. **Tab** selects controls; the focused log
supports arrows, PageUp/PageDown, and Home. See the
[server console guide](docs/product/server-console.md) for all controls.

## Worlds, settings, and compatibility

Runtime data defaults to `~/.fpas-into-the-dungeon/`. The programs create
`config/client.toml` and `config/server.toml` there; the server stores worlds,
immutable dungeon levels, and savegames under `worlds/`. Pass `--data-dir PATH`
to select a different data directory, or set `INTO_THE_DUNGEON_HOME`.

Both programs accept optional host and port arguments after `--`. The server's
`--world ID` preselects an **existing** world; startup never creates it. Create
new worlds through the connected client.

New-world seeds are signed 32-bit integers. Entrance regions can be 1 through
16 chunks wide. **Settings** in the dashboard changes creation defaults in
`server.toml`; existing worlds keep their original parameters. Each new world
gets its own identity, even when another world uses the same seed.

Worlds, levels, saves, and the protocol are versioned. The current versions are **world format 3**,
**generator 7**, **level format 2**, **protocol 15** and **save format 8**.
Format-7 saves remain intact but cannot be continued with this server.
Generator-6 worlds remain on disk but
cannot be continued; create a new world for this version. Compatible worlds
can still be continued. Incompatible data is rejected without migration or
automatic deletion. Obsolete runtime configuration also produces an error
asking you to delete or recreate that configuration.

## Development and next steps

Generated dungeons (14a) and world management with the server dashboard (14s)
are complete. Dungeon contents (14b) was **accepted on 2026-10-16**: named dungeons now
naturally contain a skeleton, a giant rat, equipment and healing potions.
Optional floor finds keep stable original slot identities. Combat, storage,
protocol, rendering and inventory `I`/`Enter` potion use are implemented.
Storage tests now cover potion transfer between dungeons, terminal items,
explicit save/reopen/load, revisit, Start over and earlier-save rewind without
replacing level files. TCP tests also cover the complete contents loop, combat
art, reconnect before saving, Continue, old-data rejection and shutdown without
autosave. The
[persistence smoke measurements](docs/architecture/persistence-measurements.md)
cover 1/10/100 visited dungeons and explain the additional validation cost.
Independent review findings are corrected and the documentation is aligned.
Progression (13b) is the next gameplay slice, before multiple dungeon levels
(14c). Client/server connection isolation and socket cleanup are verified.
Server preparation failures preserve the current session. Large inventories
keep selection and controls visible; quick summaries stay bounded. World-catalog
inspection is limited to the requested page and any selected
world outside it; Continue still fully validates the save and referenced levels.
Save and load failures retain their detailed causes in the server log while
client rejections stay sanitized. Viewport refreshes keep the exploration map
open and preserve its current projection and pending map request. The completed
client/server review also separates world-lifecycle responsibilities and
documents connection ownership and UI state contracts.
Settlements, multiplayer, and LLM
integration remain later work.

See the [roadmap](docs/roadmap.md) for the current checkpoints.
The [architecture overview](docs/architecture/overview.md) explains
module ownership, and [world structure and views](docs/product/world-and-views.md)
defines the game's terms.

Run the checks with your matching FPAS compiler and standard library:

```powershell
fpas fmt --check apps libs tests tools
fpas check dungeon.fpasworkspace
fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace
```

The complete suite passes **107/107 test programs**, and all **21 workspace
projects** check. Coverage includes game rules,
deterministic generation, storage, protocol validation, TUI rendering and input,
and real TCP sessions.

To inspect generated terrain without starting a game server:

```powershell
fpas run tools/world-preview/world-preview.fpasprj -- terrain
fpas run tools/world-preview/world-preview.fpasprj -- continentalness
```

Contributions are described in [CONTRIBUTING.md](CONTRIBUTING.md). Functional
Pascal's [language documentation](https://github.com/tobiasbick/functional-pascal/tree/main/docs/pascal)
is the reference for the implementation.

## License

[BSD-3-Clause](LICENSE)
