# Ports kit

The recipes for the studio's game ports: what **we** wrote, and nothing from the games.

| Folder | What |
|---|---|
| `tekken6/` | Tekken 6 (Xbox 360): **our changes only**. A patch for [tekken6-recomp](https://github.com/mahmoud-mess/tekken6-recomp) (which you get from its own repository), our ReXGlue SDK patch on top of theirs, and the launch (`run.sh`) and packaging (`make_app.sh`) scripts. Start with `tekken6/UPSTREAM.txt` |
| `alice/` | Alice: Madness Returns (Xbox 360): project files, config, the function-start lists found while porting, SDK patch (`alice/sdk-patch/README.txt`), launch and packaging scripts |
| `harry-potter-cos/` | Harry Potter and the Chamber of Secrets (PS1): psxrecomp patches (noncommercial only, see `psxrecomp-patches/LICENSE-NOTICE.md`), project config, launcher, packaging and overlay-prebuild scripts (own README with build steps) |
| `common/` | Shared pieces: app starter, shader-pack merge tool, and `spirv-cross-ubo-as-device.patch`, the SPIRV-Cross change MoltenVK is built with (Apple M1/M2 skinning fix, enabled by `REX_MSL_UBO_AS_DEVICE`) |

## Not in here, on purpose (never publish)
- Game discs, game data, `default.xex`
- `generated/` (code recompiled from the game: derived from copyrighted code)
- App icons with box art or console branding (players can make their own)
- tekken6-recomp's files (it has no license)

Players supply their own legally obtained copy of the game.

## Rebuilding an Xbox 360 port
The SDK patches here are diffs on top of tekken6-recomp's SDK patch, so the order is fixed:

1. Clone rexglue-sdk at the commit in `tekken6/sdk-patch/BASE.txt`.
2. Apply tekken6-recomp's `patches/rexglue/0001-tekken6-runtime.patch` (from its repository,
   at the commit in `tekken6/UPSTREAM.txt`).
3. Apply our patch: `tekken6/sdk-patch/rexglue-sdk-mac.patch` for Tekken 6, or
   `alice/sdk-patch/rexglue-sdk-alice.patch` for Alice (one or the other, not both).
4. Point the config at your own extracted game (`default.xex`) and run `rexglue codegen`.
5. Build (Apple clang, macOS 14 target, `-mcpu=apple-m1`); Alice has a `mac-portable` preset.
6. `make_app.sh` packages a signed, self-contained `.app`. The scripts expect the title fonts
   in `fonts/` at the repository root, the game in `game/` next to the script, and (optionally)
   your own icon at `assets/icon-1024.png`.

## Platforms
One build per operating system, not per chip: a single arm64 Mac build runs on every Apple
Silicon Mac (M1 and newer); chip quirks are switched at launch. Other systems (Windows, Linux,
Intel Macs) reuse these recipes with that system's toolchain (ReXGlue has Windows and Linux code).

## Known fixes worth upstreaming
- Shader/pipeline storage wiped every launch on macOS (`"a+b"` reads from EOF): `fseek(0)` in
  `src/graphics/vulkan/pipeline_cache.cpp`.
- Apple M1/M2 misread dynamically indexed constant-space arrays (skinned faces stretch).
- InputSystem race (recursive mutex), styled window titles on macOS.
