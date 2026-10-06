# Into the Dungeon

A small client-server role-playing game with a terminal user interface, written
in [Functional Pascal](https://github.com/tobiasbick/functional-pascal).

> **Disclaimer:** This is a hobby project at a very early stage. It is entirely
> vibe-coded, and we do not know where it will lead or whether it will ever
> reach an ending. It is also a practical test of Functional Pascal: can an LLM
> create a VM-based programming language and then use it to build something
> more substantial than "Hello, world"? Developing a real game exercises the
> language, compiler, virtual machine, standard library, and tooling together
> and exposes the bugs and missing pieces that small examples do not.

The current version has a TUI client connected to an authoritative game server,
with a generated, chunked outdoor world and a first-person dungeon view.

## Screenshots

**Start screen**

![Start screen with a dungeon entrance rendered as colored ASCII art](docs/images/start-screen.png)

The start menu sits inside a torch-lit dungeon entrance. The surrounding
scenery is colored ASCII art generated to fit the current terminal size.

**Outdoor world**

![Outdoor world with terrain, paths, water, mountains, and Fog of War](docs/images/outdoor-world.png)

The outdoor view shows the player among forests, grassland, water, mountains,
paths, and an entrance. Darker and hidden areas visualize the Fog of War.

> **Development note:** This is a staged preview of the outdoor renderer, not
> the current playable world. During this early development phase, the outdoor
> world leads to rare dungeon entrances, each opening a generated dungeon.

**Dungeon encounter**

![First-person dungeon encounter with a restless skeleton](docs/images/dungeon-skeleton.png)

Interiors use a grid-based first-person view rather than free movement. Here,
the player faces a restless skeleton in a generated dungeon.

```powershell
fpas run apps/server/server.fpasprj
fpas run apps/client/client.fpasprj
```

This branch targets Functional Pascal revision
[`269d8013`](https://github.com/tobiasbick/functional-pascal/commit/269d80132582ddcfb1f8615592e5229be42e9a19).
Use the compiler and source standard library from the same checkout. The source
uses the new statement terminators, named block endings, `when` case arms, and
explicit result consumption. See the [migration plan](docs/plans/fpas-syntax-migration.md).

This feature additionally requires `Std.Fs.ReadDir` (including its `go` call
support) from the accompanying FPAS checkout; it is not part of the linked
baseline revision.

The game also uses `Std.Json.Fields`, `Std.Toml.Fields`, `Std.Fs.CreateDirAll`,
context-typed record updates such as `State with Hostiles := []; end with`, and
`Cmd.RequestTick` for combat animation, and imports the concurrency unit as
`Std.Tasks` now that `task` is a reserved word. It also stops the main task
from running queued tasks while it waits, which the in-process client/server
tests rely on to avoid sporadic deadlocks.

The game's [`main` branch](https://github.com/tobiasbick/fpas-into-the-dungeon/tree/main)
retains legacy FPAS sources and documents its older compiler requirement.

Run the server first. Both programs use `127.0.0.1:4040` by default and create
their TOML configuration under `~/.fpas-into-the-dungeon/config/`. Optional
host and port arguments override that address; `--data-dir PATH` selects a
different runtime-data directory.
The server accepts `--world ID` to preselect an existing world. Startup never
creates it. After connecting, choose **Create world**, **Continue**, or **Start
over**. Creation assigns a new identity even for an existing seed. Invalid saves
are kept; overwriting requires confirmation. **Choose world** in the system menu
asks before discarding unsaved progress.

```powershell
fpas run apps/server/server.fpasprj -- --console
```

The optional server console shows live logs/status and edits creation defaults
in `server.toml`. Seed values are signed 32-bit integers; entrance regions are
1 through 16 chunks wide. Existing worlds retain their original parameters.
The server admits one connected player at a time.

Inspect terrain or an individual generator field without starting the server:

```powershell
fpas run tools/world-preview/world-preview.fpasprj -- terrain
fpas run tools/world-preview/world-preview.fpasprj -- continentalness
```

See the [architecture overview](docs/architecture/overview.md) for the planned
repository structure and the [roadmap](docs/roadmap.md) for the incremental
development order. Functional Pascal's
[language documentation](https://github.com/tobiasbick/functional-pascal/tree/269d80132582ddcfb1f8615592e5229be42e9a19/docs/pascal)
is the source of truth for the implementation.

Contributions are described in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[BSD-3-Clause](LICENSE)
