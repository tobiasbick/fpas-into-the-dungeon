# Generated settlements: DAP acceptance

Status: DAP gameplay checks passed on 2026-10-24. User acceptance and merge
remain pending.

The [FPAS controller](../../tools/dap-acceptance/README.md) owns a normal server
and the real client launched through DAP. It uses terminal keyboard events and
the ordinary TCP connection. Debugger inspection is read-only; world definitions
and saves are written only by the game. The isolated world uses seed 25,
dungeon region size 1 and generator 11.

## Verification

- The complete game workspace passes 161/161 test programs.
- Client regressions now cover closing a start overlay without a selected world
  and selecting the sole highlighted world with Enter. Live play exposed both
  failures; the fixes share catalog focus selection and route list activation.
- Native FPAS integration tests pass for interactive binary pipes, pending/data/
  EOF, typed launch failures, source and portable-image execution, handle aliases
  and child cleanup after termination, close, normal completion and failure.
- The real DAP terminal-acquisition regression passes without keepalive requests.
  All 81 Console tests pass, including virtual resize retention. FPAS Clippy
  passes for all targets and features with warnings denied.
- FPAS was rebuilt with `dist.ps1`; the PATH executable matches the resulting
  release binary. Server and client were restarted with that distribution.
- A separate empty data root verifies world creation through the client editor,
  seed/region validation, route reversal, movement without saves and a subsequent
  explicit checkpoint save. World creation reaches the expected spawn directly.

## Confirmed play

| Check | Observed result |
|-------|-----------------|
| Create world through client editor | Seed 25, region size 1; spawn `(10912,-10144)`. |
| Documented outdoor route | Fernhollow gate `(10951,-10539)` reached through accepted movement. |
| Deferred village definition | No `settlements/` directory before the first village entry. |
| Nearby dungeon | Entered Broken Tomb at `(10955,-10539)`, level 1 of 3. |
| Equipment | Picked up and equipped the rusty short sword and leather jerkin through the inventory. |
| Ordinary injury | Skeleton attacks reduced health from 20 to 12; fighting it left health 9. |
| Return while hurt | Left the dungeon with 9 health; four west steps restored health to 13. |
| Village entry | Entered Fernhollow at local `(11,12)` with 13 health. Definition contains Nell, Edda and Orin. |
| First healer greeting | Orin greets the player as a new visitor and offers `wounds`. |
| Healing | Selected `wounds` with arrow keys and Enter; health rises from 13 to 20, with the expected healing response. |
| Independent meetings | Save after healing has Orin met, Nell/Edda/Mara unmet. Nell and Edda then give their own fresh greetings. |
| Role-specific topics | Nell describes neighbors; Edda describes guarding Fernhollow. |
| Save inside | Saved at local `(11,8)` with health 20 and all three village meeting flags true; Mara stays unmet. |
| Continue inside | Restarted both processes; Continue restores Fernhollow, `(11,8)`, health 20 and a clean progress flag. |
| Remembered greeting | Edda recognizes the player immediately after Continue; greeting keeps `Dirty=false`. |
| Exact return gate | Leaving local exit `(11,13)` returns to outdoor `(10951,-10539)`. |
| Second documented route | Reached Brackenford gate `(11238,-10820)` through `E287 N281`, counting accepted steps. |
| Second village entry | Brackenford is 27 by 19 fields with Tess, Bram and Iona, distinct from Fernhollow's 23 by 15 layout and roster. Its definition appears on entry. |
| Independent second resident | Tess greets a new visitor despite Nell already being met in the first village. |
| Outdoor Save/Continue | Left Brackenford through local `(13,17)`, saved at exact outdoor `(11238,-10820)`, restarted both processes and restored that position with health 20. |
| Remembered second resident | Tess recognizes the player after outdoor Continue and re-entry. |
| Independent second healer | Iona gives a fresh greeting and identifies herself as Brackenford's healer despite Orin already being met. |
| Independent second guard | Bram gives a fresh greeting and identifies himself as Brackenford's guard despite Edda already being met. All six generated NPCs have been met through the client. |
| Return for Mara | Walked the complete known route back to spawn in the same game; all six village meeting flags remain saved and Mara is still unmet. |
| Mara identity and offer | Reached Hearthmoor and opened Mara's own compass offer with six generated NPCs already met. Preflight and acceptance leave the spawn dungeon files absent. |
| Quest acceptance | Saved an active objective targeting `world-1:dungeon:85:-80:2:item:6`. |
| Active quest after restart | Restarted both processes and continued inside Hearthmoor; the journal still shows Active, the correct dungeon objective and two healing potions as the reward. |
| Quest dungeon | Entered all three levels of Forgotten Catacombs near spawn, collected a potion on each level and reached the compass through ordinary movement and combat. Health is 18/20. |
| Compass pickup | Picked up `world-1:dungeon:85:-80:2:item:6`; the journal switches to Ready to return. Its projected inventory entry has no equipment slot and `Usable=false`. |
| Compass inventory behavior | Enter on the selected compass reports No item action available. Dropping it through the inventory restores Active and Compass not carried; Enter picks it up again and restores Ready to return. |
| Ready quest after restart | Saved on level 3 at `(11,15)`, restarted both processes and continued with health 18, the compass carried, Ready to return and `Dirty=false`. |
| Quest return | Climbed all three levels and left through the exact spawn entrance. Walked back to Hearthmoor and reached Mara with health 20. |
| Hand-in and reward | Selected Mara's offered `quest_report`. The compass is consumed, the journal becomes Completed and the inventory gains exactly `reward:0` and `reward:1`, both usable healing potions. |
| Completed quest after restart | Saved at Hearthmoor `(11,8)`, restarted both processes and continued with health 20, seven inventory entries and Completed. Mara thanks the player for returning her compass; her quest topic offers only Back, and information keeps `Dirty=false`. |
| Start over | Chose Start over through the world screen. Restored spawn `(10912,-10144)`, health 20, empty inventory and No accepted quests. The previous completed save retains its hash and modification time. |
| Fresh meeting after reset | Walked the same 476-step route without saving, entered Fernhollow and talked to Orin at `(16,8)`. The same healer greets a new visitor; the fresh character still has no accepted quests or inventory. |
| Retained files | Both village definitions retain their original bytes and modification times after reset and re-entry. The completed save remains identical to its copy from before Start over. |
| Restore after reset test | Disconnected without saving the fresh character. Continue restores Hearthmoor `(11,8)`, health 20, seven inventory entries, Completed and `Dirty=false`. The owned client, server and controller were then closed. |

## Retained files

Paths below are relative to `game/worlds/world-1/` in the isolated data root.
These SHA-256 values and UTC modification times remain unchanged after the
reset, full walk and fresh conversation:

| File | SHA-256 | Last write (UTC) |
|------|---------|------------------|
| `settlements/85_-83.json` | `A15E196D0359E8DBE63C3690162D32D5130A928BAFAD28E4A2CFA4CC16B6C3A9` | 2026-10-24 13:32:32 |
| `settlements/87_-85.json` | `B331C023E14014FCBE2440DCDF0DABE1BBB0C55F51EC6345587CD087C51AEC4F` | 2026-10-24 14:20:44 |
| `saves/default.json` | `0BA9F8622BEE3BEEA79707B91A9D9BC6AF5DB73E0DFD673D56751DA477D7261C` | 2026-10-24 16:32:41 |

Local raw evidence is retained under `.temp-data/dap-acceptance-25-1/`: completed
commands, accepted travel coordinates, client snapshots and terminal output.
It also includes the completed save, reward entries and fresh-meeting snapshots.
The server console's presentation is covered by automated tests; this controller
runs the server without its console UI, so this run does not sign off its visual
presentation. Sustained DAP execution remains slow; the FPAS dogfooding gap
records that observation separately from the passing gameplay checks.
