# Into the Dungeon

Explore a generated world, enter dungeons, and fight restless skeletons — all in
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
  jerkin, and drop carried items.
- Fight restless skeletons in turn-based combat, with health, armor, combat
  messages, and animations. Walking outdoors gradually restores health.
- Create separate worlds, continue a saved game, or start over in an existing
  world. Saves retain discovery, inventory, equipment, and visited dungeon state.
- Monitor the server through status panels, a live log, filters, and settings
  for new-world defaults.

The server currently accepts **one connected player at a time**. More opponent
kinds, healing potions, and deeper dungeon levels are still planned.

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
| I | Inventory; Enter wears or removes gear, D drops the selected item |
| C | Character sheet with health, equipment, and derived values |
| M | Exploration map; WASD or arrows pan, Home centers, M or Esc closes |
| F2 / F3 | Toggle the client's context / message panels |
| Ctrl+P | System menu, including Save and Choose world |
| Alt+X | Quit |

In dungeons, movement, attacking, waiting, and changing or dropping equipment
advance a turn. Turning and inspecting do not. The in-game system menu also
lists the controls.

## Screenshots

These images come from the current TUI renderer at 144 × 45 terminal cells.
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

Worlds, levels, saves, and the protocol are versioned. This checkpoint uses
**generator 7** and **level format 2**. Generator-6 worlds remain on disk but
cannot be continued; create a new world for this version. Compatible worlds
can still be continued. Incompatible data is rejected without migration or
automatic deletion. Obsolete runtime configuration also produces an error
asking you to delete or recreate that configuration.

## Development and next steps

Generated dungeons (14a) and world management with the server dashboard (14s)
are complete. Dungeon contents (14b) is in progress: the regression foundation
and stored dungeon names are implemented. The next small checkpoint introduces
the Giant rat; healing potions and generated floor finds follow later. Multiple
dungeon levels belong to 14c. Settlements, multiplayer, and LLM integration
remain later work.

See the [roadmap](docs/roadmap.md) and the
[14b implementation plan](docs/plans/14b-dungeon-contents.md) for the current
checkpoints. The [architecture overview](docs/architecture/overview.md) explains
module ownership, and [world structure and views](docs/product/world-and-views.md)
defines the game's terms.

Run the checks with your matching FPAS compiler and standard library:

```powershell
fpas fmt --check apps libs tests tools
fpas check dungeon.fpasworkspace
fpas test --timeout 600 --jobs 1 dungeon.fpasworkspace
```

The current complete suite contains **70 test programs**, covering game rules,
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
