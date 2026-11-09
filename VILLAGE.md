# Native Mac Studio — village registry

Umbrella: **native macOS software**. Branches (types): **Games** (first: Tekken 6, Xbox 360 -> Mac),
next planned: **Creative tools** (screen-drawing toolkit: a Photoshop-style tool bar that draws
directly over the live screen, then screenshots the result).

Each house is a body of work. Size = effort spent building it; distance = how closely it worked
with its neighbours in the real process; founding order = when the need for it became clear.

| # | House | Agent | Size | Founded during | Nearest houses |
|---|-------|-------|------|----------------|----------------|
| 1 | Xbox 360 Recompilation | xbox360-recompiler | L | first build + black screen | GPU & Graphics, Research |
| 2 | GPU & Graphics | mac-gpu-engineer | XL | white/cyan 3D, black fights | Recompilation, QA Lab, Performance |
| 3 | Input & Controllers | mac-input-engineer | M | keyboard, DualSense, Joy-Cons | QA Lab |
| 4 | QA Lab | mac-qa-tester | L | needed to test without a person at the keyboard | GPU, Performance, Input |
| 5 | Research | studio-researcher | M | upstream issues kept matching our bugs | Recompilation, GPU, Performance |
| 6 | Performance & Timing | mac-perf-engineer | XL | fights stuttered and ran below 60 fps | QA Lab, GPU, Packaging |
| 7 | Packaging & Distribution | mac-packager | M | sharing the game on a USB stick, with nothing else to install | Performance (build flags), Identity |
| 8 | Housekeeping | mac-caretaker | S | disk at 91% | Packaging |
| 9 | Identity | mac-caretaker | S | icon + window title | Packaging |

Village hall: **studio-lead** routes new requests to houses and founds new houses when none fits.

## Projects
- Tekken 6: done; see `ports/tekken6/README.md` for status.
- Alice: Madness Returns: done, from the player's own Xbox 360 disc dump. No community recomp project
  existed, so Recompilation built the manifest from scratch; see `ports/alice/`.
- Harry Potter and the Chamber of Secrets (PS1): playable; see `ports/harry-potter-cos/README.md`.
- screen-draw-toolkit (planned): new branch "Creative tools"; expect new houses (overlay/windowing,
  drawing engine, tool palette UI, capture/export).
