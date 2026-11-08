# CLR rewrite

Rebuild Into the Dungeon on FPAS for .NET 10. Use [rust-backup](https://github.com/tobiasbick/fpas-into-the-dungeon/tree/rust-backup) as the reference for shipped gameplay and controls. The CLR edition owns its source, projects and versioned formats.

`Dungeon.slnx` contains the FPAS game rules, shared protocol, authoritative server, terminal client and tests. Use `Fpas.Tui` for the interface. Keep game rules independent of transport and storage.

## Progress

- [x] Verified that the GitHub backup contains the full Rust-era game.
- [x] Set up the CLR solution with four FPAS projects and native .NET tests. Removed the Rust workspace from this branch.
- [x] First playable slice. Create a seeded outdoor area, enter the dungeon, defeat a skeleton, save and continue after restarting the server. Verified in the Windows terminal and with two TCP tests.
- [x] Added seeded outdoor exploration, persistent Fog of War and a pannable map. Added named three-floor dungeons, paired stairs, exact outdoor returns and per-floor skeleton and rat state. Verified save/continue and generator fingerprints.
- [x] Added Hearthmoor with Mara, Elias and Nora, plus seeded villages with residents, guards, innkeepers and merchants. Dialogues offer role-specific topics and remember each NPC meeting after Save/Continue. Verified Hearthmoor, Ashbrook and Elmbridge over TCP and the dialogue controls in the Windows terminal.
- [x] Added seeded dungeon finds, inspection and pickup, inventory and character panels, weapon and armor effects, dropping and healing potions. Save format 4 retains exact item ownership and rejects missing finds. Verified nine tests and the Windows terminal equip flow.
- [x] Added Mara's compass quest, the journal on J, the deepest start-dungeon objective and the one-time two-potion reward. Save format 5 validates quest and item ownership together. Verified the four-connection journey, inventory capacity, Hearthmoor's response and the Windows terminal quest flow.
- [x] Added buying and selling at Elias and village merchants with independent stock, a saved wallet and exact item ownership. Verified Elias and Finn across save/continue, 16-item pages, stale quotes, the wallet limit and a buy/sell run in the Windows terminal.
- [x] Added separate Unarmed and Blades experience, five skill levels and damage bonuses. Added the game clock, day and night, seeded weather and eight-hour stays for five coins at Nora and village inns. Save and protocol version 7 carry the clock and progression. Verified time limits, weather boundaries, rest confirmation and reload in the 16-test suite.
- [ ] Add dungeon facing, enemy pursuit, first-person raycasting. Add world selection and the server dashboard.
- [ ] Restore Gamemaster configuration, model selection and connection checks for Codex, Pi and OpenCode. Use the official `ModelContextProtocol.AspNetCore` package and the maintained ACP client `ShihaoShen.Agentic.ACPLibrary`. Cover the HTTP MCP descriptor and model options in the adapter.

## FPAS tooling

The formatter takes two passes on a long `if` expression when the first pass
wraps a call inside one branch. Reproduce with a single-line declaration inside
an FPAS routine:

```pascal
const Path: string := if Arguments.Length > 2 then Arguments[2] else IO.Path.Combine('.dungeon', 'save.json') end if;
```

After the first `fpas fmt`, `fpas fmt --check` exits 2. After a second format
pass the check exits 0. The game sources use the stable layout.
