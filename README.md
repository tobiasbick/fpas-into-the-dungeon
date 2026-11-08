# Into the Dungeon

A client-server terminal RPG written in Functional Pascal for .NET 10. The server
owns the world and resolves player actions. The terminal client renders the
server's view with Fpas.Tui.

Explore a seeded outdoor region that continues across signed coordinates.
Discover named, three-level dungeons and fight skeletons and giant rats. Visit
Hearthmoor and generated villages to talk with their inhabitants. The server
remembers explored terrain, visited floors and NPC meetings in one explicit save slot. See [rewrite progress](docs/plans/clr-rewrite.md) for the remaining scope.

## Build

Install the .NET 10 SDK and clone the [Functional Pascal compiler](https://github.com/tobiasbick/functional-pascal)
next to this repository. Run from the game's root:

```powershell
dotnet pack ../functional-pascal/sdk/Fpas.NET.Sdk/Fpas.NET.Sdk.csproj -c Debug -o .tmp/feed
dotnet pack ../functional-pascal/src/Fpas.Tui/Fpas.Tui.fpasproj -c Debug -o .tmp/feed "-p:RestoreConfigFile=$PWD/NuGet.Config"
dotnet build Dungeon.slnx
dotnet test Dungeon.slnx
```

The local feed and NuGet cache are under `.tmp/`. When replacing the packages
at the same version, remove the cached `fpas.net.sdk/0.1.0-dev` and
`fpas.tui/0.1.0-dev` under `.tmp/packages/` before restoring.

## Play

Start the server and client in separate terminals from the game root:

```text
dotnet run --no-build --project src/Dungeon.Server/Dungeon.Server.fpasproj
dotnet run --no-build --project src/Dungeon.Client/Dungeon.Client.fpasproj
```

Press **N** to create a world. Walk three steps east and press **Enter** on
`>` to enter the dungeon. Walk three more steps east to reach the skeleton and
press **Space** to attack. In a dungeon, `>` leads down, `<` leads up and `x`
leads outdoors. Stand on the marker and press **Enter**.

Hearthmoor's gate lies six steps south of spawn. Enter on `s` to visit a
settlement. Walk beside an NPC marked `n` and press **Enter** to talk. Select a
topic with **W/S** or the arrows and confirm with **Enter**. Use **Esc** or
**Goodbye** to end the conversation before saving. Enter on `x` to return to
the same outdoor gate.

Open the exploration map with **M**. Pan with the arrows or WASD, center on
the player with **Home** and close with **M** or **Esc**. Bright cells are
visible, dim cells are remembered and blank cells are unexplored.

Press **Ctrl+S** to save. After a server restart, launch the client and press
**C** to continue. **Esc** exits the client outside the map. Save format and
generator version 3 require a new world when starting from an earlier save.

Both programs accept a port as their first argument and default to loopback port
4040. The server's second argument selects the save file, which defaults to
`.dungeon/save.json`. The client's second argument selects the seed for new
worlds, which defaults to 25.
