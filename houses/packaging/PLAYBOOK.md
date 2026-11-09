# House: Packaging & Distribution
Role: a drag-and-drop .app that runs on another Mac with no setup.
- Separate portable build: Apple clang, `CMAKE_OSX_DEPLOYMENT_TARGET=14.0`, `-mcpu=apple-m1`; check `otool -L` (system libs only) and `otool -l ... minos`. Homebrew LLVM + its libc++ ties the binary to the build Mac's macOS.
- Bundle: Contents/MacOS/{binary, dylibs (@executable_path rpath), vulkan/ (loader, MoltenVK, ICD json)}, Resources/{game data, AppIcon.icns}; launcher script as CFBundleExecutable (name must differ from the binary beyond case!). No LSArchitecturePriority on a script executable.
- Per-user data in ~/Library/Application Support/<App> and ~/Library/Logs/<App>; app stays read-only.
- Signing: compiled parts keep ad-hoc signatures; do not seal a script-executable bundle. First launch takes ~1 min (macOS scan); "Open Anyway" in Privacy & Security if quarantined.
- APFS clones (`cp -c`) avoid duplicating multi-GB data locally. Check USB format limits (FAT32 4 GB per file).
- Ship a HOW TO PLAY.txt next to the app.
