# Tekken 6 (Xbox 360) on macOS

Our macOS (Apple Silicon) changes for building Tekken 6 as a native app, on top of the
community project [tekken6-recomp](https://github.com/mahmoud-mess/tekken6-recomp) and the
[ReXGlue SDK](https://github.com/rexglue/rexglue-sdk).

This folder holds **our changes only**. tekken6-recomp itself is not included (it has no
license file); you get it from its repository. No game data is included either: bring your
own legally obtained copy of the game.

## Status

Playable start to finish on Apple Silicon, macOS 14 or newer, with the Vulkan FBO renderer
through MoltenVK. Fights run at about 55 to 59 fps on a base M4. Keyboard, PS5 DualSense and
Nintendo Joy-Cons work (Joy-Con co-op mode was only checked with a virtual controller).

## What's here

| File | What |
|---|---|
| `UPSTREAM.txt` | Exact upstream commits and the patch order |
| `tekken6-recomp-mac.patch` | Our change to tekken6-recomp (`CMakeLists.txt`: x86-only flags gated, `REXGLUE_ROOT` set) |
| `sdk-patch/rexglue-sdk-mac.patch` | Our ReXGlue SDK changes, as a diff on top of tekken6-recomp's own SDK patch |
| `sdk-patch/BASE.txt` | The ReXGlue SDK commit everything starts from |
| `run.sh` | Runs a development build (keyboard layout in its header) |
| `make_app.sh` | Packages a self-contained, signed `Tekken 6.app` |
| `HOW TO PLAY.txt` | Player instructions to ship next to the app |

## Build

You need Xcode command line tools, CMake, Ninja, LLVM (Homebrew) and a way to unpack your
disc image (for example `xdvdfs`).

1. Follow `UPSTREAM.txt`: clone tekken6-recomp at the named commit into this folder, apply
   `tekken6-recomp-mac.patch`, fetch the SDK submodule, apply their SDK patch, then ours.
2. Unpack your own disc into `game/` in this folder (it must contain `Default.xex`;
   tested with "Tekken 6 (USA, Europe) Rev 1") and link it: `ln -s ../game tekken6-recomp/game`.
3. Build the SDK's `rexglue` tool (`mac-arm64` preset in `third_party/rexglue-sdk`) and run
   codegen on `tekken6_manifest.toml`.
4. Configure and build the game with Ninja, Release, Vulkan on, D3D12 off, and
   `-DCMAKE_C_FLAGS=-mcpu=apple-m1 -DCMAKE_CXX_FLAGS=-mcpu=apple-m1`, into
   `tekken6-recomp/build/mac-arm64`.
5. `./run.sh` starts it (`./run.sh fsi` picks the other renderer; `LOG_LEVEL=debug` for more
   logs, written to `run/`).
6. `./make_app.sh [build_dir] [output_dir]` packages the app. It defaults to a
   `build/mac-portable` build (Apple clang, macOS 14 deployment target). The app contains your
   game files, so it is for your own use only.

The window title defaults to "Tekken 6"; set `REX_WINDOW_TITLE` to change it. For an app
icon, put your own picture at `assets/icon-1024.png` (no console branding, no box art).

## What our SDK changes fix

- **Black screen after the first frame, freezes while loading:** lost wakeups in
  `src/core/threading_posix.cpp`. Auto-reset events now hand the signal to the oldest waiter,
  pulsed manual-reset events release every wait in progress, and `SignalAndWait` queues before
  signaling (related: rexglue-sdk#531).
- **ARM64 memory ordering:** codegen emitted nothing for `sync`/`lwsync`/`eieio`; it now emits
  barriers. Codegen must be re-run after applying the patch.
- **Wrong colors in 3D (white, cyan, magenta):** `tfetch` read `exp_adjust` from the wrong
  fetch-constant word (rexglue-sdk#456); Metal cannot disable primitive restart on strips, so
  it is forced on for strips on Apple (rexglue-sdk#533).
- **Fights flickering black:** run with `--execute_unclipped_draw_vs_on_cpu=true` (Xenia's
  default), already set in `run.sh`.
- **Shader cache wiped at every launch on macOS:** a file opened with `"a+b"` reads from the
  end; `fseek(0)` added in `src/graphics/vulkan/pipeline_cache.cpp`.
- **Performance and smoothness:** presenter no longer rebuilds its pipeline every frame (#507),
  uploads moved ahead of the render pass (#535, #536), UI-only repaints capped at 60 per second,
  guest threads run at user-interactive QoS (performance cores), the vblank thread sleeps to the
  exact deadline, and `--gpu_wait_reg_mem_poll_us=-1` lets the GPU command thread spin.
  Building with `-mcpu=apple-m1` instead of the ARM64 baseline gave 3 to 7 fps in fights.
- **Input:** DualSense and Joy-Cons through SDL3 HIDAPI; F6 toggles Joy-Con co-op (each Joy-Con
  its own controller); a recursive-mutex race in the input system fixed.
- **Window title:** `REX_WINDOW_TITLE`, optionally drawn in a custom font
  (`REX_WINDOW_TITLE_FONT`, new file `src/ui/title_font_mac.mm`).

Test aids, all off unless their environment variable is set: `TEKKEN6_VIRTUAL_PAD=1` (SDL
virtual DualSense, scriptable with `TEKKEN6_VIRTUAL_PAD_SCRIPT`), `TEKKEN6_AUTO_PRESS`,
`TEKKEN6_CAPTURE_DIR`, `TEKKEN6_LOG_DRAWS_FRAME`, `TEKKEN6_LOG_RT_CONFIGS`,
`TEKKEN6_TRACE_WAITS`. Disable switches: `TEKKEN6_THREAD_QOS=0`, `TEKKEN6_VBLANK_PRECISE=0`.

## Known issues

- The `fsi` renderer tears the lower part of 3D scenes into horizontal strips at the native
  1024x576 internal size (`TEKKEN6_INTERNAL_RESOLUTION=768x432` renders cleanly). Use `fbo`,
  the default.
- Heavy stages still miss some frames; background system work costs a few fps.
- Rumble and real Joy-Con hardware are untested.
- Harmless log noise: missing `cache:` device, MoltenVK "primitive restart" warnings, missing
  `gamecontrollerdb.txt`.
- Upstream tekken6-recomp has since added its own macOS support; these patches target the
  older commit named in `UPSTREAM.txt` and were not rebased.
