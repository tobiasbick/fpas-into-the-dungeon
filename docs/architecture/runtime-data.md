# Runtime data

The game stores user-created and runtime data outside the repository. Its
default data root is:

```text
~/.fpas-into-the-dungeon/
├── config/
│   ├── client.toml
│   └── server.toml
├── worlds/
│   └── <world-id>/
├── logs/
└── cache/
```

The path uses `~` as documentation shorthand. The application resolves the
current user's home directory and works with an absolute path.

## Path resolution

The data root is selected in this order:

1. the `--data-dir` command-line option;
2. the `INTO_THE_DUNGEON_HOME` environment variable;
3. the default `~/.fpas-into-the-dungeon` directory.

Path resolution belongs behind one interface shared by the client, server, and
tests. Callers receive the resolved data root instead of constructing these
paths themselves. The default is absolute because it is derived from the home
directory. Explicit overrides are normalized with the host's path rules; a
relative override is resolved from the process working directory.

## Configuration

The client and server create their configuration file with defaults when it is
missing, then load it as TOML. Both files currently have the same shape:

```toml
host = "127.0.0.1"
port = 4040
```

Command-line `HOST` and `PORT` values override the loaded file for that run.
Use `--data-dir PATH` to select a different data root before configuration is
loaded.

## Ownership

- `config` contains persistent client and server settings.
- `worlds` contains authoritative world state and is owned by the server.
- `logs` contains diagnostic output and is not part of a saved world.
- `cache` contains disposable data that the application can rebuild.
- Tests use a temporary data root supplied through the same interface and do
  not write to the user's default directory.
