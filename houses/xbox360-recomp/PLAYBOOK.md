# House: Xbox 360 Recompilation
Role: turn an Xbox 360 XEX into a native arm64 macOS program (ReXGlue SDK, Xenia-derived static recompiler).
## Pipeline (Tekken 6)
1. Disc: Redump .iso (7.84 GB, XGD2) -> `xdvdfs unpack` -> `game/` (needs `default.xex`/`Default.xex`).
2. SDK: rexglue-sdk (pinned tag), `rexglue codegen <manifest.toml>` -> generated C++ (hundreds of files). Existing community project (tekken6-recomp) supplied manifest/config/hooks; a new game needs its own manifest: functions, switch tables, midasm hooks, rexcrt memcpy/memset addresses.
3. Build: CMake+Ninja, Release, Vulkan on, D3D12 off. Patch SDK via tools/apply_rexglue_patches.py (`--refresh` saves local SDK edits into the patch). Keep a separate Mac-only delta patch.
## Mac/ARM pitfalls fixed
- PPC `sync/lwsync/eieio` emitted as no-ops (x86 assumption) -> emit real ARM fences.
- POSIX event emulation: auto-reset events must hand the signal to an already-waiting thread; SignalAndWait must register before signaling; manual-reset set-then-reset pulses must release current waiters (generation counter). Symptoms: black screen after frame 1, freezes while loading.
- macOS is case-insensitive: never name two files that differ only by case.
- Extract title assets: `rexglue init --project-name X --xex-path X.xex achievements X.xex OUT` writes icons incl. title.png (XDBF image 0x8000).
- Apple Silicon has 16 KB pages; check page-size assumptions in memory watch code.
- 16 GB Macs: build big generated projects with `nice -n 15 ... -j 3`; -j 6+ or optimizing the huge *_register.cpp (compile it with -O0) runs out of memory and macOS kills apps.

## Lessons from Alice: Madness Returns (UE3)
- Bulk-declared function starts must follow a terminator (blr, bctr, unconditional b) or padding.
  Starts that fall through from the previous instruction split real functions and cause
  "Unresolved branch" FATALs. Of 1209 scanned candidates, only 369 were safe.
- Code after virtual-call thunks (lwz; mtctr; bctr) is often a separate function that the analyzer
  skips. Declare it unless a *conditional* branch spans it. Unconditional b spans are tail calls
  and don't block it. This added 663 functions and got past the logos.
- Launch test builds through a small dev .app with `open -n`, never as a child of the coding tool or terminal
  that built them. Otherwise macOS blames that parent app in the crash dialog.
- InputSystem had no lock. Games that rumble (SetState) on another thread race RefreshDevices
  and crash with a double free. Fixed with a recursive mutex in input_system.cpp/.h; this fix
  belongs in the Tekken SDK patch too.
- Background keystrokes don't reach SDL. Drive menus with TEKKEN6_VIRTUAL_PAD_SCRIPT, set in
  run/dev-env.sh.
