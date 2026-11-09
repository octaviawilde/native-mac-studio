#!/bin/zsh
# Compiles every level-code overlay the game has loaded so far into <build_dir>/cache,
# so the packaged app never needs a compiler on the player's Mac.
# Play through the parts you want covered first: overlays are captured as they load.
# Usage: tools/prebuild_overlays.sh <build_dir> <disc_dir>
#   build_dir  the project's build-release folder (holds overlay_toolchain/ and game.toml)
#   disc_dir   folder holding the boot executable SLUS_015.03 (the project's disc/ folder)
set -e
[[ $# -eq 2 ]] || { sed -n '2,7p' $0 >&2; exit 1; }
here=${0:A:h}; b=${1:A}; disc=${2:A}
[[ -e $disc/SLUS_015.03 ]] || { echo "missing $disc/SLUS_015.03" >&2; exit 1; }
cd $b
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT   # merged captures hold game code: not kept
overlay_toolchain/python/bin/python3 $here/merge_captures.py . $tmp/allcaps.json
MACOSX_DEPLOYMENT_TARGET=14.0 overlay_toolchain/python/bin/python3 overlay_toolchain/compile_overlays.py \
  --captures $tmp/allcaps.json --game-toml game.toml \
  --recompiler overlay_toolchain/psxrecomp-game --runtime-include overlay_toolchain/include \
  --project-root overlay_toolchain --out-dir cache --compiler gcc --gcc /usr/bin/gcc \
  --main-exe $disc/SLUS_015.03
