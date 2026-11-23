# Into the Dungeon

> **A note from the Human Overlord**
>
> Another try with the CLR version of Functional Pascal and an LLM as the
> game master. I'm still unsure about it. The first version had a client and
> server, an overworld, trading, and dungeons. That was too much for a first
> attempt.
>
> As always, I have no idea where this is going, whether I'll keep working
> on it, or whether I'll lose interest in a month or two.

Into the Dungeon is a small terminal adventure written in
[Functional Pascal](https://github.com/tobiasbick/functional-pascal). Type
commands to explore the pump room, find a brass key, and open the way to the
grotto. The game master narrates each turn. **Continue** picks up your saved
adventure.

![The English game running at 80 × 25 in the pump room, with room art, the adventure log, and a command prompt](docs/images/pump-room.png)

## Quick start

Use a true-color terminal, .NET 10, the matching FPAS SDK and UI packages in
`.tmp/feed`, and an installed, signed-in ACP agent.

```powershell
dotnet run --project src/Dungeon/Dungeon.fpasproj
```

Press **F2** to send a command and **F10** to exit.
See [game settings](docs/plan/README.md#game-settings) for agent setup.

## License

[BSD-3-Clause](LICENSE)
