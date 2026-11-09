# Harry Potter and the Chamber of Secrets (PS1) for macOS

A recipe for building the PlayStation 1 game (USA, SLUS-01503) as a native Apple Silicon
Mac app with [psxrecomp](https://github.com/mstan/psxrecomp), a static recompiler.
This folder holds only what we wrote: three psxrecomp patches, the project config, the
app launcher and packaging scripts. You supply your own legally obtained disc.

## Status
Works:
- Boot, language screen, title menu, story scenes, 3D play, sound
- Saves (memory card), kept per user; optional "cartridge" mode when run from an external drive
- Controllers, plug and play, with keyboard fallback; Switch-layout pad (PDP Afterglow Deluxe+)
  confirms on the button labelled A
- Sharp internal resolution ("auto": matches the display, measured 4x),  geometry correction (no wobbly polygons), perspective-correct textures
- macOS 14 or newer on Apple Silicon; one self-contained app, no compiler or other install
  needed on the player's Mac

Not tested:
- Anything past the first level
- M1 hardware (built and played on an M4)
- PS4 controller

## What's here
| Path | What |
|---|---|
| `psxrecomp-patches/` | Our three patches to psxrecomp; `BASE.txt` names the upstream commit. **Noncommercial only** (PolyForm Noncommercial 1.0.0, like psxrecomp itself): see `LICENSE-NOTICE.md` there |
| `game.toml` | Project config template (set `disc` to your own image) |
| `input-afterglow-mapping.ini` | Controller block to append to the game's `input.ini` |
| `tools/prebuild_overlays.sh`, `tools/merge_captures.py` | Precompile level code so players need no compiler |
| `make_app.sh` | Packages the `.app` |
| `app/` | Launcher (`launch-harry`), main executable source (`starter.c`), icon script, title font (Cinzel Decorative, SIL OFL) |
| `UPSTREAM-ISSUE-cdrom.md` | Draft bug report for psxrecomp (not posted) |

The patches:
- `psxrecomp-cdrom-log-and-no-queue.patch`: the fix that makes the game run. A CD command
  written while an interrupt is unacknowledged now runs at once (as Beetle PSX does) instead of
  being queued; the game hung after the language screen otherwise. On by default,
  `PSX_CD_NO_QUEUE=0` restores the old behaviour. Also adds `PSX_CD_CMD_LOG=1` tracing.
- `psxrecomp-p1-auto-keyboard-fallback.patch`: player 1 uses the first controller, or the
  keyboard while none is connected.
- `psxrecomp-title-font.patch`: macOS window title in a custom font (`PSX_WINDOW_TITLE_FONT`).

## Build
Needs Xcode command line tools, CMake, Ninja, Python 3, and your own disc dump (`.cue` + `.bin`).

1. Get psxrecomp at the commit in `psxrecomp-patches/BASE.txt`:
   ```sh
   git clone --recurse-submodules https://github.com/mstan/psxrecomp.git
   cd psxrecomp && git checkout <commit from BASE.txt> && git submodule update --init --recursive
   ```
2. Generate the project from your disc with psxrecomp's own flow (see its
   `docs/GAME_PROJECT_SETUP.md`); name it `HarryPotterCoS` and answer Y to Generate:
   ```sh
   sh tools/new_project_layout/setup_project.sh --disc /path/to/your/game.cue --dir ~/src
   ```
   This stages the disc, extracts `disc/SLUS_015.03` and writes `game.toml` and `generated/`.
3. In the new project, apply our patches to its `psxrecomp` submodule:
   ```sh
   cd psxrecomp && for p in /path/to/kit/harry-potter-cos/psxrecomp-patches/*.patch; do git apply "$p"; done
   ```
4. Compare the project's `game.toml` with the one here. Ours adds `p1_device = "auto"` under
   `[controller]`; `disc` must point at your image.
5. Configure and build (static SDL3 fetched by the build, no external libraries, macOS 14 target).
   psxrecomp's `rebuild` command also stages `overlay_toolchain/` next to the game binary:
   ```sh
   CMAKE_GENERATOR=Ninja python3 psxrecomp/psxrecomp_cli.py rebuild \
     --config game.toml --project-root . --build-dir build-release --no-pgo
   cmake -S . -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
     -DCMAKE_DISABLE_FIND_PACKAGE_OpenSSL=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_SDL3=TRUE
   cmake --build build-release
   ```
6. Run `build-release/HarryPotterCoS` once and play the parts you want precompiled. Level code
   is captured as it loads. Append `input-afterglow-mapping.ini` to `build-release/input.ini`
   if you use that pad.
7. Precompile the captured level code, then package:
   ```sh
   tools/prebuild_overlays.sh ~/src/HarryPotterCoS/build-release ~/src/HarryPotterCoS/disc
   ./make_app.sh ~/src/HarryPotterCoS/build-release /path/to/your/disc/folder
   ```
   The app lands in `dist/` (about 900 MB, it holds your disc). It is for your own use.

Saves and logs: `~/Library/Application Support/HarryPotterCoS` and `~/Library/Logs/HarryPotterCoS`.

## Not in here, on purpose
- The disc image, `SLUS_015.03`, or any other game file
- `generated/` (C recompiled from the game) and seed lists
- `overlay_captures.json*` and `cache/` (captured game code and what is compiled from it)
- Box art, and the rendered app icon (it uses Apple's emoji artwork; `icon.swift` draws it on your Mac)
- Prebuilt apps or binaries

`game.toml` keeps the disc's size and checksums. They identify the right dump and contain no game data.
