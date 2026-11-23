Into the Dungeon will be a console-based text adventure with ASCII graphics and a large language model (LLM) as the game master.

## Start screen

The frame follows the terminal edges. A centered copper and ember forest fills
the interior at 80 × 25. The FPAS cell grid packs two vertical RGB pixels into
each Unicode upper half block. On larger terminals, a stationary haze samples
the colors at the edges of the forest and fades into the dark background.
Smaller terminals use a compact scene from 60 × 18 and a menu-only layout below
that size. Resizing preserves the selected action.

The artwork is sampled from the selected Glut unter Wurzeln mockup. The
embedded row-major RGB files use three bytes per pixel. The full scene uses
78 × 46 pixels and the compact scene uses 58 × 32 pixels.

The menu has separate layouts for new and returning players. The current
prototype shows the returning-player layout. Arrow keys move the selection,
and Enter or a click activates an entry. Exit closes the terminal session.

The menu follows the system's UI culture. The game project owns the English
fallback in `Resources/Strings.resx` and the German translation in
`Resources/Strings.de.resx`.

The local feed in `.tmp/feed` needs matching packages for `Fpas.NET.Sdk`,
`Fpas.Ui`, `Fpas.Ui.Mvu`, and `Fpas.Ui.Tui`.
