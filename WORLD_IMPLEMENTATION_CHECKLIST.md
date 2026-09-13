# Unbounded World Implementation Checklist

This file is the working checklist for the first unbounded outdoor world. It
keeps the implementation sequence visible without turning every later game
idea into a requirement. Canonical terminology and lasting architecture rules
must be copied into the appropriate files under `docs/` when their checklist
item is completed.

`[x]` means agreed or completed. `[ ]` means work remains.

## Agreed foundation

- [x] **W001** Outdoor regions may be practically unbounded.
- [x] **W002** Settlements, interiors, and dungeons remain finite areas unless
  a later requirement changes that decision.
- [x] **W003** A chunk is a storage, generation, and caching partition within
  an outdoor region, not an area or an area transition.
- [x] **W004** World-format version 1 uses fixed 128 by 128 cell chunks.
- [x] **W005** The server owns world coordinates, chunks, generation, terrain
  rules, and the authoritative player position.
- [x] **W006** The client receives a bounded visible window and does not know
  about chunk boundaries.
- [x] **W007** Required chunks are derived from the visible window rather than
  being limited to the current chunk and its immediate neighbors.
- [x] **W008** The server preloads one additional chunk around the required
  visible range and may evict chunks that are no longer needed.
- [x] **W009** Outdoor rendering uses `Std.Tui` `TuiCellGrid`, concrete colors,
  and the Functional Pascal Mandelbrot example as its technical reference.
- [x] **W010** Raycasting is reserved for the first-person view of interiors
  and dungeons.
- [x] **W011** One outdoor world cell occupies two terminal columns so the map
  reads as a colored world rather than an ASCII roguelike.
- [x] **W012** Initial terrain includes grass, forest, desert, mountains, sea,
  rivers, lakes, and paths.

## 1. Record the model

- [x] **W100** Add `Chunk`, `Chunk coordinate`, and `Visible window` to the
  canonical terminology in `docs/product/world-and-views.md`.
- [x] **W101** Clarify that chunk crossings are seamless movement, while area
  transitions enter or leave settlements, interiors, or dungeons.
- [x] **W102** Add an architecture document for world metadata, chunk files,
  coordinate conversion, generation, loading, caching, and ownership.
- [x] **W103** Update roadmap stage 4 from a fixed data-driven region to the
  first unbounded, chunked outdoor region.
- [x] **W104** Keep later world simulation, mutable objects, savegames, and
  polished procedural generation outside this stage.

## 2. Define coordinates and terrain

- [x] **W200** Define signed world coordinates that remain stable across chunk
  loads and client reconnects.
- [x] **W201** Define floor-based conversion between world, chunk, and local
  coordinates, including negative coordinates.
- [x] **W202** Add boundary tests for `-129`, `-128`, `-1`, `0`, `127`, and
  `128` on both axes.
- [x] **W203** Define a client-safe visible-cell representation that contains
  presentation meaning without exposing movement rules.
- [x] **W204** Separate base terrain from optional features so paths and later
  bridges can cross grass, desert, forest, or water deliberately.
- [x] **W205** Define the initial base terrain kinds: grass, sand, rock, and
  water.
- [x] **W206** Define the initial features and classifications: forest, path,
  river, sea, and lake.
- [x] **W207** Keep passability and terrain effects in the server-owned game
  module; the client maps visible kinds only to cells and colors.

## 3. Define world and chunk files

- [x] **W300** Define versioned `worlds/<world-id>/world.json` metadata with at
  least world id, seed, generator version, chunk size, and spawn position.
- [x] **W301** Define a stable filename layout for positive and negative chunk
  coordinates below `worlds/<world-id>/chunks/`.
- [x] **W302** Define the versioned chunk schema and compact terrain encoding.
- [x] **W303** Reject unsupported versions, mismatched ids, wrong chunk sizes,
  malformed rows, unknown terrain codes, and invalid spawn positions with
  useful errors.
- [x] **W304** Create a missing selected world and its first required chunks.
- [x] **W305** Never overwrite or silently repair an existing invalid world.
- [x] **W306** Write world metadata and chunks atomically.
- [x] **W307** Test first creation, unchanged reload, missing-chunk generation,
  invalid data, and interrupted-write safety with temporary data roots.

## 4. Build deterministic chunk generation

- [x] **W400** Generate every cell solely from world seed, generator version,
  and absolute coordinates so chunk order cannot affect results.
- [x] **W401** Establish deterministic height and moisture inputs without
  visible seams at chunk boundaries.
- [x] **W402** Generate grass as the neutral outdoor terrain.
- [x] **W403** Derive mountains, forests, deserts, and seas from continuous
  world-scale inputs.
- [x] **W404** Generate lakes that are distinguishable from seas without
  requiring traversal of an infinite connected water body.
- [x] **W405** Generate rivers as continuous features across chunk boundaries.
- [x] **W406** Generate paths as continuous features that can later connect
  settlements and locations.
- [x] **W407** Ensure the initial spawn and a useful surrounding area are
  traversable.
- [x] **W408** Add deterministic fixtures and cross-boundary tests for every
  initial terrain and feature kind.
- [x] **W409** If Functional Pascal lacks a required deterministic numeric,
  hashing, filesystem, JSON, or TUI capability, create a reproducible upstream
  issue before changing the design or adding a workaround.

## 5. Load, compose, and cache the world

- [x] **W500** Implement one server-owned module that loads an existing chunk
  or generates and atomically stores a missing chunk.
- [x] **W501** Compute the complete chunk rectangle intersecting any requested
  visible window.
- [x] **W502** Add a one-chunk prefetch margin without making it part of the
  visible result.
- [x] **W503** Compose one visible window seamlessly from any number of chunks.
- [x] **W504** Add a bounded cache with explicit retention and eviction rules.
- [x] **W505** Ensure simultaneous requests for the same missing chunk cannot
  produce conflicting files.
- [x] **W506** Test windows within one chunk, across an edge, across four
  corners, at negative coordinates, and across more than a 3 by 3 chunk range.

## 6. Extend the client-server view seam

- [x] **W600** Define how the client reports the primary-view size on connect
  and terminal resize.
- [x] **W601** Convert terminal columns to visible world-cell width while
  accounting for two terminal columns per world cell and optional panels.
- [x] **W602** Choose and document the initial configurable server limit for a
  requested visible window.
- [x] **W603** Reject or clamp unreasonable viewport requests deliberately and
  test the chosen behavior.
- [x] **W604** Extend visible state with the visible-window world origin and
  authoritative world position.
- [x] **W605** Choose a compact wire representation for visible terrain and
  features that remains practical for large terminals.
- [x] **W606** Bump the protocol version if the existing version cannot be
  extended compatibly.
- [x] **W607** Keep chunk coordinates and server-only terrain rules out of the
  client interface.

## 7. Render the colored outdoor world

- [x] **W700** Replace ASCII label rows in the primary map view with a
  `TuiCellGrid`.
- [x] **W701** Define a coherent truecolor palette for grass, forest, desert,
  mountains, sea, rivers, lakes, and paths.
- [x] **W702** Define restrained Unicode texture glyphs that supplement color
  without making the map resemble NetHack.
- [x] **W703** Render every world cell as two adjacent terminal cells.
- [x] **W704** Render the player with a distinct symbol and colors without
  changing the underlying terrain data.
- [x] **W705** Preserve the existing context panel, message panel, overlays,
  status line, and responsive layout.
- [x] **W706** Recalculate the requested visible window after terminal resize
  or panel visibility changes.
- [x] **W707** Keep the previous complete visible window on screen while a new
  one is pending.
- [x] **W708** Add headless assertions for concrete cell styles, terrain
  distinctions, player rendering, large terminals, and small terminals.

## 8. End-to-end completion

- [x] **W800** Start a new server data root and verify that it creates a valid
  world and initial chunks.
- [x] **W801** Connect the unchanged TUI shell and render a colored visible
  window assembled from generated chunks.
- [x] **W802** Walk across chunk edges in every direction without a visible
  transition or coordinate reset.
- [x] **W803** Resize across several chunk widths and verify that every required
  chunk is loaded or generated.
- [x] **W804** Restart the server and verify that existing world and chunk files
  are loaded without modification.
- [x] **W805** Verify that client code contains presentation mappings but no
  movement, generation, or passability rules.
- [x] **W806** Run formatting, workspace checks, all tests, and a real loopback
  session.
- [x] **W807** Synchronize the roadmap, architecture documents, canonical
  terminology, and implemented behavior.
- [x] **W808** Commit only project files and keep private idea material outside
  version control.

## Deferred deliberately

- [ ] Mutable terrain and persistent world changes
- [ ] Settlements and points of interest
- [ ] Bridges and terrain-dependent movement costs
- [ ] Weather, seasons, time, and world simulation
- [ ] Interior and dungeon generation
- [ ] First-person raycasting
- [ ] Save slots and player-state restoration
- [ ] LLM integration
