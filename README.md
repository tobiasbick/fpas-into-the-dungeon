# Into the Dungeon

> [!IMPORTANT]
> We've put development of Into the Dungeon on hold. We don't know if or when
> we'll pick it back up.

A client-server terminal RPG written in Functional Pascal for .NET 10. The server
owns the world and resolves player actions. The terminal client renders the
server's view with Fpas.Tui.

Explore a seeded outdoor region that continues across signed coordinates.
Discover named, three-level dungeons and fight skeletons and giant rats. Visit
Hearthmoor and generated villages to talk with their inhabitants. The server
remembers explored terrain, visited floors, items and NPC meetings in one
explicit save slot. See [rewrite progress](docs/plans/clr-rewrite.md) for the remaining scope.

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

After preparing the local package feed, start the server in one terminal.
When it reports that it is listening, start the client in another terminal.

Windows PowerShell

```powershell
./start-server.ps1
./start-client.ps1
```

Linux

```bash
./start-server.sh
./start-client.sh
```

Each launcher builds its Debug project before running it. Use `-NoBuild` on
Windows or `--no-build` on Linux to reuse a build. Both default to loopback
port 4040. If you change the port, pass the same value to both launchers.
The server keeps running when the client exits. Press **Ctrl+C** in the server
terminal to stop it.

Use `-Help` on Windows or `--help` on Linux for examples. The server accepts
a save file path, relative to the game root by default. The client accepts the
seed for new worlds.

Press **N** to create a world. Walk three steps east and press **Enter** on
`>` to enter the dungeon. Walk three more steps east to reach the skeleton and
press **Space** to attack. In a dungeon, `>` leads down, `<` leads up and `x`
leads outdoors. Stand on the marker and press **Enter**.

The first dungeon level has an ancient coin, a rusty short sword, a leather
jerkin and a healing potion. **Enter** examines a nearby find or picks up one
at your feet. Open inventory with **I**, select an item and press **Enter** to
use a potion, wear equipment or remove it. **D** drops a carried item on empty
dungeon floor. **C** opens the character sheet during play.
Successful attacks train Unarmed or Blades, depending on the equipped weapon.
The character sheet shows each skill's level and experience.

Hearthmoor's gate lies six steps south of spawn. Enter on `s` to visit a
settlement. Walk beside an NPC marked `n` and press **Enter** to talk. Select a
topic with **W/S** or the arrows and confirm with **Enter**. Use **Esc** or
**Goodbye** to end the conversation before saving. Enter on `x` to return to
the same outdoor gate.

Ask Nora or a village innkeeper about a room. Confirm to spend five coins,
sleep eight hours and recover fully. The map title shows the day, time and
weather. Travel, combat and **.** (wait) advance the clock.

Ask Elias or a village merchant to show their goods. In the trade window,
**Left/Right** switch between Buy and Sell, **Up/Down** select an offer and
**Enter** trades the selected item. Use **Ctrl+Page Up/Down** to change pages
and **Esc** to return to the conversation. Each merchant keeps a separate
stock. An Ancient coin is a find you can sell for ten spendable coins.

Ask Mara about her lost compass. **J** opens the quest journal with the
objective and current progress. Return the compass to Mara for two healing
potions. The exchange needs one free inventory slot.

Open the exploration map with **M**. Pan with the arrows or WASD, center on
the player with **Home** and close with **M** or **Esc**. Bright cells are
visible, dim cells are remembered and blank cells are unexplored.

Press **Ctrl+S** to save. After a server restart, launch the client and press
**C** to continue. **Esc** exits the client outside the map. Save format 7
requires a new world when starting from an earlier save.

Both programs accept a port as their first argument and default to loopback port
4040. The server's second argument selects the save file, which defaults to
`.dungeon/save.json`. The client's second argument selects the seed for new
worlds, which defaults to 25.
