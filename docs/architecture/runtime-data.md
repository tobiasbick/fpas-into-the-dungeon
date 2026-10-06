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
│       ├── world.json
│       ├── chunks/
│       └── saves/
│           └── default.json
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
missing, then load it as TOML. The client file contains its endpoint and local
panel preferences:

```toml
host = "127.0.0.1"
port = 4040
context_panel_visible = true
message_panel_visible = false
```

The server file additionally preselects an existing world and bounds client
viewport requests:

```toml
host = "127.0.0.1"
port = 4040
world_id = "main"
world_seed = 12345
dungeon_region_chunks = 4
chunk_cache_limit = 64
max_view_width = 240
max_view_height = 120
```

`world_seed` is a signed 32-bit creation default (-2147483648 through
2147483647). `dungeon_region_chunks` (1 through 16) sets the side length of entrance regions
in chunks and therefore how rare dungeon entrances are. Like `world_seed`, it
applies only when a world is created; an existing world keeps the value stored
in its metadata. A file without it is obsolete and is rejected.

Command-line `HOST` and `PORT` values override the loaded file for that run.
The server's `--world ID` preselects an existing world without changing the
stored default. Neither this option nor `world_id` creates a world. A missing or
incompatible selection leaves the connected world catalog available. Use `--data-dir PATH` to select a different data root before
configuration is loaded.

Runtime configuration, world, chunk, and savegame formats support only their
current schema and generator version. After an incompatible development change,
select a new world id or delete the obsolete configuration or world data as
instructed by the reported error. Configuration is never deleted automatically.
Invalid or incompatible worlds and saves remain visible and are preserved.
Storage errors remain distinct from missing or incompatible data. Recreate a
world through the client or start over in a compatible world; replacing an
existing save requires explicit confirmation. No migration is provided.

`dungeon-server --console` opens a live terminal log/status view and a settings
editor for `world_seed` and `dungeon_region_chunks`. It validates both fields
before atomically replacing `server.toml`, preserving all other current fields.
An error keeps the previous published defaults and leaves the editor open.
Existing world metadata never changes. Settings are read again for catalog
requests, so connected clients receive updated defaults when they refresh the
world list. Stop closes the listener and joins the active session. Without the
option, the server stays headless.

## Ownership

- `config` contains persistent client and server settings. The client's panel
  visibility changes are written atomically; command-line host and port
  overrides are not written back.
- `worlds` contains versioned authoritative world metadata, generated chunk
  files, immutable dungeon level files, and one atomic `saves/default.json`
  savegame per world. Level files are never removed with an invalid save. That snapshot
  includes discovery, item ownership, health, and opponents. It is owned by the server.
- `logs` contains diagnostic output and is not part of a saved world.
- `cache` contains disposable data that the application can rebuild.
- Tests use a temporary data root supplied through the same interface and do
  not write to the user's default directory.

The savegame contains only the authoritative state needed to resume a session.
See [persistent game state](persistent-game-state.md) for its lifecycle and
validation rules.
