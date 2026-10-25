# Server console

Start the server with `fpas run apps/server/server.fpasprj -- --console`.
The console uses the full terminal window. Without the option the server keeps
its headless text output. Closing the console cancels and joins its listener
and connected session; it does not save gameplay implicitly.

## Dashboard

At 100 columns or more, three summary panels form one row:

- **Server:** listener status, actual listening port, elapsed uptime, connected
  players (0/1 or 1/1), and protocol version.
- **Session:** connection, selected world, active area, unsaved progress and the
  last successful explicit save observed in this connection.
- **World:** original world ID, seed, entrance-region size, generator version,
  and presence of a save file. Presence is not a compatibility guarantee.

The active area uses its retained map name, including generated villages.
Creating this status snapshot does not open or regenerate a settlement file.
An accepted trade marks unsaved progress. Opening, paging and closing trade
leave the save timestamp unchanged; only an explicit successful save updates it.
Trade refusals appear as warnings, including `trade_active`, `trade_not_active`
and `trade_rejected`. Preparing the dashboard does not inspect or refill stock.
The [trade contract](../architecture/economy.md) describes the authoritative
wallet, stock and complete save validation.
Accepted rest also marks progress unsaved without updating the last save time.
Its clock, payment and healing are one prepared reply. An unaffordable offer
does not change game resources; rejected confirmations use the existing
`dialogue_rejected` warning. The dashboard's uptime, UTC log timestamps and
save timestamp are real time, separate from the action-based game clock shown
by the client. See [time and rest](../architecture/time-and-rest.md).
Weather and home recognition are derived projections. They add no background
worker or per-render log traffic. Read-only news preserves dirty/save facts;
an unavailable topic uses the existing dialogue rejection path. The dashboard
shows protocol 22 and retains its existing administration controls.
Complete-world deletion also removes `settlements/` definitions; its existing
connection exclusion and confirmation rules still apply.

The large **Live log / UTC** panel fills the remaining space. It displays
timestamp, severity and text, with a scrollbar and All, Info, Warnings and
Errors filters. Rejected requests are warnings. Filters preserve the shared
history of 128 entries; older entries are evicted. Unknown kinds are info.
Control characters are replaced by spaces and each diagnostic is limited to
256 characters, so one event cannot inject extra terminal rows.

Failed save and Continue operations emit an error naming the operation, world
and detailed persistence cause, including invalid save contents or a missing,
invalid or unreadable referenced level. The separate warning records the
sanitized rejection sent to the client. Storage paths and low-level causes
remain server-side. Successful operations and lifecycle/overwrite guards do
not produce persistence errors. Delivery retains the existing best-effort
queue policy; slow or closed log consumers cannot change a session outcome.

UTC timestamps describe emission time. The last save time remains unknown
after reconnecting or selecting another world until a successful explicit
save is observed. Failed save requests leave the previous save time and dirty
state unchanged. Disconnecting clears the session/world panels and retains logs.
Typed server snapshots update summaries separately from text; updates never
load saves or generate world content. No persistent log file is added.
Returned startup/listener errors are explicitly logged and mark the server as
stopped. Runtime background failures also clear the session and world panels;
an open settings dialog keeps its draft and valid focus.

At narrower widths, tall terminals stack the three summaries. Short terminals
use a compact summary so the log and controls remain usable. Resizing preserves
the selected filter and clamps the scroll position. Very small windows clip
safely rather than allocating negative layout dimensions.

## Controls and settings

- Tab moves between actionable controls.
- Up/Down, PageUp/PageDown and Home scroll the focused log.
- Scrolling away from the newest page pauses following. End, or scrolling back
  to the newest page, resumes it. New entries preserve a paused retained anchor.
- F3 cycles All, Info, Warnings and Errors; the buttons select a filter directly.
- F2 opens Settings. Seed and entrance-region defaults are validated and saved
  atomically to the current `server.toml`; existing world parameters remain fixed.
- F4 or Worlds opens the world list, including incompatible worlds and their save status.
- Escape closes Settings. Settings capture focus and block log/filter commands.
- Alt+X, Ctrl+C and Stop server close the console and its owned server tasks.

The dashboard is a server administration view. It has no controls for moving the
player, editing world parameters or bypassing gameplay save/discard guards.

## Deleting worlds

Open **Worlds (F4)**, select a row with Up/Down and choose **Delete world** or D.
The confirmation names the selected world and starts with Cancel focused.
**Delete permanently** or Y removes the entire world directory: metadata,
chunks, dungeon levels and its save. N or Escape cancels without changing files.
Escape/F4 closes the list. Refresh/R reads the catalog again; Previous/Next
page through lists that exceed the terminal's visible rows.

Deletion is available for incompatible or incomplete worlds too. It validates
the directory identity and refuses linked world directories. It is permanent
and does not use the operating system's recycle bin. Filesystem failures are
shown and logged; removal can be partial, so inspect the reason before retrying.

Disconnect the player before confirming deletion. The operation reserves the
same single permit as the listener's connection admission, preventing both
deletion during an admitted connection and a new admission during deletion.
The dashboard's best-effort connection snapshot never authorizes this operation.
The list refreshes after successful deletion. Reconnect or refresh the client
catalog to remove deleted entries there too.

The console does not load games or change the client world-selection flow.
