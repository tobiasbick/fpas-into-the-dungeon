# README images

These captures show the implementation at `8c56d79`, with world generator 7,
level format 2, and protocol 14. They replace the previous README images.

The images use the production client and server dashboard views, rendered
through `TuiApplication.SurfaceSnapshot()` at 144 by 45 terminal cells. The
surface glyphs and resolved colors are rasterized as PNGs with Cascadia Mono
and a symbol-font fallback. The images contain no desktop or terminal chrome.

Gameplay comes from a fresh server-created world with seed `12345` and an
entrance-region size of four chunks. Normal client intentions walk from spawn
to its entrance, enter the stored dungeon, approach a skeleton, turn to inspect
the room, save explicitly, and open the exploration map. Fog of War stays
enabled. The dashboard consumes the real listener/session log events and typed
status snapshots from the same local TCP session; log text is not fabricated.

When refreshing the images, capture the current views and palettes with a fresh
world and no private runtime data. Check glyphs, panel clipping, stored names,
and visibility before replacing the PNGs. Keep the descriptions and current
feature claims in the root README consistent with the captured version.
