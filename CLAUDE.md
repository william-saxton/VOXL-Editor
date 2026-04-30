# VOXL-Editor

A Godot 4.6 voxel/tile editor that ships separately from the VOXL game runtime.

The editor lets users design voxel tiles, palettes, biomes, and WFC structures used by the game. It depends on the same native GDExtension as the game (`libvoxl_native`), but is a standalone Godot project that builds and ships independently.

## Project Structure

- `scripts/voxel_editor/` — editor UI, tools, palette, scene logic
- `scripts/wfc/` — WFC tile/biome definitions (shared with `voxl` game project)
- `scripts/sync/` — asset sync manager for remote palette/tile uploads (shared)
- `scripts/material_registry.gd` — voxel material catalogue (shared with game)
- `scenes/voxel_editor/` — editor scenes (entry point: `voxel_editor.tscn`)
- `themes/` — editor UI theme + icons
- `addons/` — `godot-css-theme` (theme tooling) + `world_map_editor` (in-Godot map painter)
- `resources/` — fluid material resources (shared)
- `bin/` — compiled native library (not committed; fetched from `voxl` releases)

## Native library

`voxl-editor` does NOT build the C++ native library. The library source lives in the `voxl` game repo. Releases of `voxl` publish the native lib as standalone artifacts. Use the helper script to fetch it:

```bash
scripts/fetch_native_lib.sh           # latest release
scripts/fetch_native_lib.sh v1.2.0    # specific version
```

The script downloads the appropriate platform archive from the latest `voxl` GitHub Release into `bin/`. The `voxl_native.gdextension` manifest references those binaries via `res://bin/...`.

## Building

```bash
# Fetch native lib first
./scripts/fetch_native_lib.sh

# Import / validate
godot --headless --import

# Export
godot --headless --export-release "Windows Desktop" build/VOXL-Editor.exe
godot --headless --export-release "Linux" build/VOXL-Editor.x86_64
```

## CI

`.github/workflows/release.yml` builds on tag push (or manual dispatch):
1. Downloads the latest `voxl` release's native lib artifact
2. Imports and exports the Godot project for Windows + Linux
3. Bundles the native lib alongside the executable
4. Publishes a GitHub Release of `VOXL-Editor`

## Conventions

- GDScript follows Godot style (snake_case functions, PascalCase classes)
- Shared code (`scripts/wfc/`, `scripts/sync/`, `scripts/material_registry.gd`, `resources/`) is duplicated from the `voxl` repo. When updating either side, mirror the change in the other repo. Eventually we may extract these to a shared addon.
