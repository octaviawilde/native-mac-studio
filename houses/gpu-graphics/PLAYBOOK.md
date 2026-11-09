# House: GPU & Graphics (Vulkan on MoltenVK/Metal)
Role: make translated Xbox GPU output correct on Metal.
## Method
- Capture frames from inside the app (`TEKKEN6_CAPTURE_DIR` -> PPM every N frames; screencapture needs permission). Contact sheets (pure-python PPM tiler) to scan many frames cheaply.
- Per-frame draw/resolve log (shaders, RT config, textures, constants) for chosen frames; compare a good vs bad frame.
- Dump shader ucode (`--dump_shaders` + `--store_shaders=false`) and read disassembly.
- Knockout tests: skip a category of draws every other phase to measure cost.
## Bugs found (Tekken)
- Texture exp_adjust read from wrong fetch word -> white/cyan/magenta (upstream #456).
- Metal can't disable primitive restart for strips -> dropped draws (#533): force restart on for strips on Apple.
- Unclipped 4x MSAA depth-clear draw judged as covering all EDRAM -> fights flicker black: `--execute_unclipped_draw_vs_on_cpu=true`.
- fsi (fragment shader interlock) path tears at 1024x576 (unsolved); use host render targets (fbo).
- Ruled out: Metal fast math, gamma ramp, exponent bias, readback.
