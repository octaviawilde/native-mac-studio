#!/bin/zsh
# Builds a self-contained "Tekken 6.app" that runs on any Apple Silicon Mac with macOS 14 or newer.
# Usage: ./make_app.sh [build_dir] [output_dir]
#   build_dir   defaults to tekken6-recomp/build/mac-portable (Apple clang, macOS 14 target)
#   output_dir  defaults to dist/
# The app holds the game files from game/ (your own disc), so it is about 7 GB.
# Saves, shader caches and logs live in ~/Library/Application Support/Tekken6 and
# ~/Library/Logs/Tekken6 on each Mac; the app itself is never written to.
set -euo pipefail
here=${0:A:h}
build=${1:-$here/tekken6-recomp/build/mac-portable}
out=${2:-$here/dist}
app="$out/Tekken 6.app"
c="$app/Contents"

for f in tekken6 librexruntime.dylib librexgpu-xenos.dylib vulkan/lib/libvulkan.1.dylib \
         vulkan/lib/libMoltenVK.dylib vulkan/share/vulkan/icd.d/MoltenVK_icd.json; do
  [[ -e $build/$f ]] || { echo "missing $build/$f" >&2; exit 1; }
done
[[ -e $here/game/default.xex || -e $here/game/Default.xex ]] || { echo "missing game/default.xex" >&2; exit 1; }

rm -rf "$app"
mkdir -p "$c/MacOS" "$c/Resources"
cp "$build/tekken6" "$build/librexruntime.dylib" "$build/librexgpu-xenos.dylib" "$c/MacOS/"
mkdir -p "$c/Resources"
cp -R "$build/vulkan" "$c/Resources/vulkan"
# Title font: Anton (SIL Open Font License, bundled with its license).
cp "$here/../../fonts/anton-Anton-Regular.ttf" "$c/Resources/title-font.ttf"
cp "$here/../../fonts/anton-OFL.txt" "$c/Resources/title-font-OFL.txt"
echo "Copying game files (several GB)..."
# On APFS, clone instead of copying so the app's copy takes no extra disk space here.
cp -cR "$here/game/" "$c/Resources/game" 2>/dev/null || cp -R "$here/game/" "$c/Resources/game"
# Icon: optional. Put your own 1024x1024 picture at assets/icon-1024.png (no console branding,
# no box art); without one the app gets the standard macOS icon.

# Launcher: the same settings as run.sh, with per-user data outside the app. Its name must not
# differ from "tekken6" only by case: macOS file names are case-insensitive.
cat > "$c/MacOS/launch-tekken6" <<'EOF'
#!/bin/zsh
contents=${0:A:h:h}
support="$HOME/Library/Application Support/Tekken6"
logs="$HOME/Library/Logs/Tekken6"
mkdir -p "$support/user" "$support/cache-fbo" "$support/crashes" "$logs"
cd "$support"
export TEKKEN6_YIELD_STARTUP_SPIN=1 REX_FULLSCREEN=0 TEKKEN6_CRASH_DIR="$support/crashes"
export TEKKEN6_JOYCON_MODE_FILE="$support/joycon-mode.txt"
export REX_WINDOW_TITLE_FONT="$contents/Resources/title-font.ttf" REX_WINDOW_TITLE_FONT_SIZE=17
export REX_WINDOW_TITLE="${REX_WINDOW_TITLE:-Tekken 6}"
export MVK_CONFIG_FAST_MATH_ENABLED=${MVK_CONFIG_FAST_MATH_ENABLED:-0}
# Saves stay on this Mac, unless the app runs straight from an external drive (a "cartridge").
# Then the player picks, once per Mac: saves only on the drive, or on the drive and this Mac.
user_dir="$support/user"
if [[ $contents == /Volumes/* ]]; then
  vol="/Volumes/${${contents#/Volumes/}%%/*}"
  cart="$vol/Arcade Saves/${support:t}"
  mkdir -p "$cart/user"
  mac_id=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}')
  mode_file="$cart/save-mode-$mac_id.txt"
  mode=$(cat "$mode_file" 2>/dev/null)
  if [[ $mode != drive && $mode != both ]]; then
    choice=$(osascript -e 'button returned of (display dialog "Stai giocando da un disco esterno.\nDove vuoi salvare i progressi?" buttons {"Solo sul disco", "Disco e questo Mac"} default button 2 with icon note)' 2>/dev/null)
    [[ $choice == "Solo sul disco" ]] && mode=drive || mode=both
    echo $mode > "$mode_file"
  fi
  if [[ $mode == both ]]; then
    newest() { find "$1" -type f ! -name '._*' -exec stat -f %m {} + 2>/dev/null | sort -n | tail -1 }
    mac_time=$(newest "$support/user"); drive_time=$(newest "$cart/user")
    # Never delete, never replace a newer save with an older one, and keep any replaced file
    # in a dated backup folder on the side it was replaced on.
    stamp=$(date +%Y-%m-%d_%H-%M-%S)
    (( ${mac_time:-0} > ${drive_time:-0} )) &&
      rsync -rtu --exclude='._*' --backup --backup-dir="$cart/save-backups/$stamp" "$support/user/" "$cart/user/"
    # Copy progress back to this Mac once the game (this same process, after exec) has quit.
    ( while kill -0 $$ 2>/dev/null; do sleep 2; done
      rsync -rtu --exclude='._*' --backup --backup-dir="$support/save-backups/$(date +%Y-%m-%d_%H-%M-%S)" \
        "$cart/user/" "$support/user/" ) &!
  fi
  user_dir="$cart/user"
fi
exec "$contents/MacOS/tekken6" \
  --game_data_root="$contents/Resources/game" --user_data_root="$user_dir" \
  --cache_root="$support/cache-fbo" --fullscreen=false \
  --log_file="$logs/tekken6.log" --log_level=info \
  --gpu_backend=vulkan --render_target_path_vulkan=fbo \
  --async_shader_compilation=true --anisotropic_override=0 \
  --execute_unclipped_draw_vs_on_cpu=true --gpu_wait_reg_mem_poll_us=-1 \
  --mnk_mode=true \
  --keybind_a=Space,J --keybind_b=Escape,Backspace,K --keybind_x=U --keybind_y=I \
  --keybind_start=Return --keybind_back=Tab --keybind_guide=F24 \
  --keybind_dpad_up=Up --keybind_dpad_down=Down --keybind_dpad_left=Left --keybind_dpad_right=Right \
  --keybind_lstick_up=W --keybind_lstick_down=S --keybind_lstick_left=A --keybind_lstick_right=D \
  --keybind_rstick_up=F24 --keybind_rstick_down=F24 --keybind_rstick_left=F24 --keybind_rstick_right=F24 \
  --keybind_lstick_press=F24 --keybind_rstick_press=F24 \
  --keybind_left_shoulder=O --keybind_right_shoulder=L \
  --keybind_left_trigger=P --keybind_right_trigger=Semicolon \
  "$@"
EOF
chmod +x "$c/MacOS/launch-tekken6"
# Compiled entry point: macOS silently blocks a script entry point from reading or writing
# the drive the app runs on (needed for saves when the app runs from a USB drive).
clang -O2 -arch arm64 -mmacosx-version-min=14.0 -DLAUNCH_SCRIPT='"launch-tekken6"' \
  "$here/../common/starter.c" -o "$c/MacOS/starter"

cat > "$c/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Tekken 6</string>
  <key>ArcadeTagline</key><string>spacca facce, non i controller</string>
  <key>CFBundleDisplayName</key><string>Tekken 6</string>
  <key>CFBundleIdentifier</key><string>local.tekken6-mac</string>
  <key>CFBundleExecutable</key><string>starter</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
  <key>NSBluetoothAlwaysUsageDescription</key><string>Tekken 6 uses Bluetooth game controllers such as the DualSense.</string>
</dict>
</plist>
EOF

icon_src="$here/assets/icon-1024.png"
if [[ -f "$icon_src" ]]; then
  tmp=$(mktemp -d); set=$tmp/AppIcon.iconset; mkdir -p $set
  for sz in 16 32 128 256 512; do
    sips -z $sz $sz "$icon_src" --out "$set/icon_${sz}x${sz}.png" >/dev/null
    sips -z $((sz*2)) $((sz*2)) "$icon_src" --out "$set/icon_${sz}x${sz}@2x.png" >/dev/null
  done
  iconutil -c icns "$set" -o "$c/Resources/AppIcon.icns"
  rm -rf "$tmp"
fi

# Apple Silicon only runs signed code. The compiled parts already carry the linker's ad-hoc
# signature; re-sign them in place so they stay valid, then seal the whole bundle. The Vulkan
# folder lives in Resources so the seal works; a sealed bundle needs only one "Open Anyway"
# after AirDrop, where an unsealed one leaves its inner binaries quarantined.
codesign --force --sign - "$c/Resources/vulkan/lib/libMoltenVK.dylib" "$c/Resources/vulkan/lib/libvulkan.1.dylib" \
  "$c/MacOS/librexruntime.dylib" "$c/MacOS/librexgpu-xenos.dylib" "$c/MacOS/tekken6"
for f in "$c/MacOS/tekken6" "$c/MacOS/librexruntime.dylib" "$c/MacOS/librexgpu-xenos.dylib" \
         "$c/Resources/vulkan/lib/libMoltenVK.dylib" "$c/Resources/vulkan/lib/libvulkan.1.dylib"; do
  codesign --verify "$f"
done
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"
echo "Built: $app ($(du -sh "$app" | cut -f1))"
