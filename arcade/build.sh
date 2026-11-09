#!/bin/zsh
# Builds dist/Arcade.app: a native arm64 game hub for macOS 14+.
set -euo pipefail
here=${0:A:h}
app="$here/dist/Arcade.app"
c="$app/Contents"
work="$here/build"

rm -rf "$app"
mkdir -p "$c/MacOS" "$c/Resources/fonts" "$work"

swiftc -O -swift-version 5 -target arm64-apple-macos14.0 -parse-as-library \
  -framework AppKit -framework SwiftUI -framework GameController -framework CoreText \
  "$here"/Sources/*.swift -o "$c/MacOS/Arcade"

cp "$here"/assets/fonts/*.ttf "$here"/assets/fonts/*-OFL.txt "$c/Resources/fonts/"

# Icon, drawn from code with the hub's title font.
if [[ ! -f "$work/AppIcon.icns" || "$here/tools/make_icon.swift" -nt "$work/AppIcon.icns" ]]; then
  swift "$here/tools/make_icon.swift" "$here/assets/fonts/RubikWetPaint-Regular.ttf" "$work/icon-1024.png"
  set=$work/AppIcon.iconset; rm -rf "$set"; mkdir "$set"
  for s in 16 32 128 256 512; do
    sips -z $s $s "$work/icon-1024.png" --out "$set/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$work/icon-1024.png" --out "$set/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$set" -o "$work/AppIcon.icns"
fi
cp "$work/AppIcon.icns" "$c/Resources/AppIcon.icns"

cat > "$c/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Arcade</string>
<key>CFBundleIdentifier</key><string>local.studio.arcade</string>
<key>CFBundleName</key><string>Arcade</string>
<key>CFBundleDisplayName</key><string>Arcade</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSApplicationCategoryType</key><string>public.app-category.games</string>
<key>GCSupportsControllerUserInteraction</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF

codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"
echo "Built: $app ($(du -sh "$app" | cut -f1))"
