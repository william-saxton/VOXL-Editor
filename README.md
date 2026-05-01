# VOXL-Editor

A standalone voxel tile editor for the VOXL game engine, built in Godot 4.6.

VOXL-Editor is the authoring tool for the content the game runtime consumes: voxel tiles (small 3D grids of coloured voxels with edge flags, spawn points, and shader/particle metadata), palettes, biomes, and WFC (Wave Function Collapse) structures. The editor ships separately from the game and is the recommended way to design assets that the runtime later assembles into worlds.

The editor itself — every mode, tool, panel, and shortcut — is documented in the user guide:
**<https://william-saxton.github.io/VOXL-Editor/>**

## Relationship to the `voxl` repo

This repo is the editor only. The C++ native GDExtension (`libvoxl_native`) that powers both the game and the editor lives in the [`voxl`](https://github.com/william-saxton/voxl) repo and is published as a release artifact there. VOXL-Editor consumes that artifact rather than building it.

Some scripts and resources are duplicated between the two repos (`scripts/wfc/`, `scripts/sync/`, `scripts/material_registry.gd`, `resources/`). Changes in those areas must be mirrored on both sides until they're extracted into a shared addon.

## Repo layout

| Path | Purpose |
|---|---|
| `scripts/voxel_editor/` | Editor UI, tools, palette, scene logic |
| `scripts/wfc/` | WFC tile/biome definitions (shared with `voxl`) |
| `scripts/sync/` | Asset sync manager for remote palette/tile uploads (shared) |
| `scripts/material_registry.gd` | Voxel material catalogue (shared) |
| `scenes/voxel_editor/` | Editor scenes — entry point: `voxel_editor.tscn` |
| `themes/` | Editor UI theme + icons |
| `addons/` | `godot-css-theme` (theme tooling) + `world_map_editor` (in-Godot map painter) |
| `resources/` | Fluid material resources (shared) |
| `bin/` | Compiled native library (not committed; fetched from `voxl` releases) |
| `docs/` | Source for the user guide hosted on GitHub Pages |

## Building locally

```bash
# Fetch the native lib from the latest voxl release
./scripts/fetch_native_lib.sh
# or pin a specific version:
./scripts/fetch_native_lib.sh v1.2.0

# Import + validate
godot --headless --import

# Export
godot --headless --export-release "Windows Desktop" build/VOXL-Editor.exe
godot --headless --export-release "Linux"           build/VOXL-Editor.x86_64
```

The `voxl_native.gdextension` manifest references the binaries in `bin/` via `res://bin/...`, so the fetch step must run before importing.

## Releases

`.github/workflows/release.yml` builds Windows and Linux on tag push or manual dispatch:
1. Downloads the latest `voxl` release's native lib artifact
2. Imports and exports the Godot project
3. Bundles the native lib alongside the executable
4. Publishes a GitHub Release of `VOXL-Editor`

Pre-built editor archives ship with the native lib in `bin/` next to the executable — extract and run, no separate setup.

## Conventions

GDScript follows Godot style: `snake_case` for functions and variables, `PascalCase` for classes. Editor-only code lives under `scripts/voxel_editor/`; anything under `scripts/wfc/`, `scripts/sync/`, or the shared resources is duplicated from `voxl` and must be kept in sync.
