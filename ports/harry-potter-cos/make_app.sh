#!/bin/zsh
# Builds "Harry Potter CoS.app" from a finished psxrecomp build of YOUR OWN disc.
# The result contains game data: local use only, never publish it.
# Usage: ./make_app.sh <build_dir> <disc_dir> [output_dir]
#   build_dir   the project's build-release folder (after tools/prebuild_overlays.sh)
#   disc_dir    folder holding your disc image (.cue + .bin)
#   output_dir  defaults to dist/ next to this script
# The boot executable is taken from <build_dir>/../disc/SLUS_015.03 (override: BOOT_EXE=/path).
set -e
here=${0:A:h}; src=$here/app
[[ $# -ge 2 ]] || { sed -n '2,8p' $0 >&2; exit 1; }
b=${1:A}; discdir=${2:A}; out=${${3:-$here/dist}:A}
bootexe=${BOOT_EXE:-$b/../disc/SLUS_015.03}
[[ -x $b/HarryPotterCoS ]] || { echo "missing $b/HarryPotterCoS" >&2; exit 1; }
[[ -d $b/cache ]] || { echo "missing $b/cache: run tools/prebuild_overlays.sh first" >&2; exit 1; }
[[ -e $bootexe ]] || { echo "missing $bootexe" >&2; exit 1; }
app="$out/Harry Potter CoS.app"; c=$app/Contents; g=$c/Resources/game
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
rm -rf "$app"; mkdir -p $c/MacOS $g/disc
# Main executable: a tiny Mach-O that starts the zsh launcher.
cc -O2 -arch arm64 -mmacosx-version-min=14.0 -o $c/MacOS/starter $src/starter.c
cp $src/launch-harry $c/MacOS/; chmod +x $c/MacOS/*
# Icon: drawn on this Mac by icon.swift (the image is not kept in the kit).
(cd $work && swift $src/icon.swift && mkdir AppIcon.iconset &&
  for s in 16 32 128 256 512; do
    sips -z $s $s icon1024.png --out AppIcon.iconset/icon_${s}x${s}.png >/dev/null
    sips -z $((s*2)) $((s*2)) icon1024.png --out AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
  done && iconutil -c icns AppIcon.iconset -o AppIcon.icns)
cp $work/AppIcon.icns $c/Resources/
cp $src/fonts/CinzelDecorative-Bold.ttf $c/Resources/title-font.ttf; cp $src/fonts/OFL.txt $c/Resources/title-font-OFL.txt
cp $b/HarryPotterCoS $g/
for d in bios assets mods psx_execution native-cpu-spans native-idle-wait overlay_captures.json.d cache; do cp -R $b/$d $g/; done
for f in game_options.toml input.ini keybinds.ini overlay_captures.json; do cp $b/$f $g/; done
cp "$discdir"/*.cue "$discdir"/*.bin $bootexe $g/disc/
cue=$(cd $g/disc && ls *.cue)
sed -e "s|^disc = .*|disc = \"disc/$cue\"|" \
    -e "s|^window_title = .*|window_title = \"${HP_WINDOW_TITLE:-Harry Potter and the Chamber of Secrets}\"|" \
    -e 's|^memcard_dir = .*|memcard_dir = "saves"|' $b/game.toml > $g/game.toml
# Graphics defaults (players can change them in the in-game menu): sharp at the display's
# resolution (lowered automatically only if frames would be missed), no wobbly polygons,
# no warping textures.
python3 - "$g/game.toml" <<'PY'
import sys, re
p = sys.argv[1]; t = open(p).read()
keys = {"internal_resolution": '"auto"', "geometry_correction": "true", "perspective_texturing": "true"}
head, sep, rest = t.partition("[video]\n")
if not sep: head, sep, rest = t + "\n", "[video]\n", ""
for k, v in keys.items():
    rest = re.sub(rf"(?m)^{k}\s*=.*\n", "", rest)
rest = "".join(f"{k} = {v}\n" for k, v in keys.items()) + rest
open(p, "w").write(head + sep + rest)
PY
find $g/cache -name "*.lock" -delete; find $g/cache -name "*.pair-lock" -delete
cat > $c/Info.plist <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Harry Potter CoS</string>
<key>CFBundleDisplayName</key><string>Harry Potter CoS</string>
<key>CFBundleIdentifier</key><string>local.hp-cos-mac</string>
<key>CFBundleExecutable</key><string>starter</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.9</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>ArcadeTagline</key><string>la camera dei segreti è stata aperta</string>
<key>LSApplicationCategoryType</key><string>public.app-category.games</string>
<key>NSHighResolutionCapable</key><true/>
<key>GCSupportsControllerUserInteraction</key><true/>
</dict></plist>
PL
codesign --force --deep -s - "$app"
echo built "$app"; du -sh "$app"
