# Native Mac Studio

Native, plug-and-play macOS ports of console games for Apple Silicon Macs (macOS 14 or newer).
This repository holds the recipes: patches, configs, build and packaging scripts, and the
notes on how each problem was solved. It does not hold any game.

## The golden rule

Players bring their own legally obtained games. There is no game data, no recompiled game
code and no box art here, and none may be added. `tools/leak_guard.sh` checks every commit.

## What's in here

| Path | What |
|---|---|
| `ports/tekken6/` | Tekken 6 (Xbox 360): our macOS changes only (a patch for tekken6-recomp, an SDK patch on top of theirs, run and packaging scripts). Get tekken6-recomp from its own repository; see `UPSTREAM.txt` |
| `ports/alice/` | Alice: Madness Returns (Xbox 360) recipe: project files, config, function lists, SDK patch with the shader-stutter fix |
| `ports/harry-potter-cos/` | Harry Potter and the Chamber of Secrets (PS1) recipe: psxrecomp patches (noncommercial only), config, launcher, packaging |
| `ports/common/` | Shared pieces: app starter, shader-pack merge tool, SPIRV-Cross patch |
| `arcade/` | Arcade: a SwiftUI game hub driven by controller or keyboard (Italian UI) |
| `houses/` | Playbooks: what we learned about recompilation, graphics, input, performance, packaging, testing |
| `VILLAGE.md`, `village-map.html` | How the studio's work is organised |
| `fonts/` | Title fonts (SIL Open Font License) |
| `tools/` | `leak_guard.sh`, the pre-commit check |

Start with `ports/README.md`.

## Status

| Game | System | Status |
|---|---|---|
| Tekken 6 | Xbox 360 | Done |
| Alice: Madness Returns | Xbox 360 | Done, including the shader-stutter fix |
| Harry Potter and the Chamber of Secrets | PS1 | Playable; first level tested |

## Contributing

Install the check once after cloning:

```sh
ln -sf ../../tools/leak_guard.sh .git/hooks/pre-commit
```

## Credits

- [ReXGlue SDK](https://github.com/rexglue/rexglue-sdk), the Xbox 360 static recompiler (derived from Xenia)
- [psxrecomp](https://github.com/mstan/psxrecomp), the PS1 static recompiler
- [skullburglar](https://github.com/nlwstein/skullburglar), source of the async pipeline and background shader precompile work used in the Alice patch
- [tekken6-recomp](https://github.com/mahmoud-mess/tekken6-recomp), the community project the Tekken 6 port builds on (not included here)
- MoltenVK, SPIRV-Cross and SDL3
- Built with help from AI coding tools
- Fonts: Anton, UnifrakturMaguntia, Rubik Wet Paint, Silkscreen, Cinzel Decorative (all SIL OFL)

## License

- Our own work is under the MIT license (`LICENSE`).
- Patches against other projects keep those projects' licenses (ReXGlue SDK and skullburglar:
  BSD-3-Clause; SPIRV-Cross: Apache-2.0).
- The psxrecomp patches in `ports/harry-potter-cos/psxrecomp-patches/` are derivative of
  psxrecomp (PolyForm Noncommercial 1.0.0) and are **noncommercial only**; see the
  `LICENSE-NOTICE.md` in that folder.
- tekken6-recomp has no license, so none of its files are here. The Tekken 6 and Alice
  patches contain only our changes and are applied on top of it.
- Fonts: SIL Open Font License 1.1.

Full details: `THIRD_PARTY_NOTICES.md`.

Not affiliated with or endorsed by the games' publishers or the console makers.
