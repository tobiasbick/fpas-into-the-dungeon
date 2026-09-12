# Into the Dungeon

A small client-server role-playing game with a terminal user interface, written
in [Functional Pascal](https://github.com/tobiasbick/functional-pascal).

> **Disclaimer:** This is a hobby project and entirely vibe-coded. We do not
> know where it will lead, or whether it will ever reach an ending.

The repository is at a very early stage. Its first executable slice is a TUI
client connected to an authoritative game server, with one player moving on a
small outdoor map.

```powershell
fpas run apps/server/server.fpasprj
fpas run apps/client/client.fpasprj
```

Run the server first. Both programs use `127.0.0.1:4040` by default and create
their TOML configuration under `~/.fpas-into-the-dungeon/config/`. Optional
host and port arguments override that address; `--data-dir PATH` selects a
different runtime-data directory.

See the [architecture overview](docs/architecture/overview.md) for the planned
repository structure and the [roadmap](docs/roadmap.md) for the incremental
development order. Functional Pascal's
[language documentation](https://github.com/tobiasbick/functional-pascal/tree/main/docs/pascal)
is the source of truth for the implementation.

Contributions are described in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[BSD-3-Clause](LICENSE)
