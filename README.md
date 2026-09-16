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

```powershell
fpas run apps/server/server.fpasprj
fpas run apps/client/client.fpasprj
```

Run the server first. Both programs use `127.0.0.1:4040` by default and create
their TOML configuration under `~/.fpas-into-the-dungeon/config/`. Optional
host and port arguments override that address; `--data-dir PATH` selects a
different runtime-data directory.
The server also accepts `--world ID` to select or create another world.

Inspect terrain or an individual generator field without starting the server:

```powershell
fpas run tools/world-preview/world-preview.fpasprj -- terrain
fpas run tools/world-preview/world-preview.fpasprj -- continentalness
```

See the [architecture overview](docs/architecture/overview.md) for the planned
repository structure and the [roadmap](docs/roadmap.md) for the incremental
development order. Functional Pascal's
[language documentation](https://github.com/tobiasbick/functional-pascal/tree/main/docs/pascal)
is the source of truth for the implementation.

Contributions are described in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[BSD-3-Clause](LICENSE)
