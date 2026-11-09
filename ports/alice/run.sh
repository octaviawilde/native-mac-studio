#!/bin/zsh
# Launch the macOS build. Usage: [LOG_LEVEL=debug] ./run.sh [fbo|fsi] [extra args...]
#
# Keyboard (always on; a connected controller such as a DualSense works too):
#   Arrows = D-pad (menus, movement)   W/A/S/D = left stick
#   Return = Start   Tab = Back
#   Space or J = A (confirm)   Escape, Backspace or K = B (back)
#   Tekken attacks: U = X (left punch)  I = Y (right punch)  J = A (left kick)  K = B (right kick)
#   O = left bumper  L = right bumper  P = left trigger  Semicolon = right trigger
#   F3 = FPS overlay
# DualSense (USB-C or Bluetooth; connect before or after launch, keyboard keeps working):
#   Square = left punch  Triangle = right punch  Cross = left kick  Circle = right kick
#   Options = Start (pause)  Create = Back  D-pad / left stick = move  L1 R1 L2 R2 as on Xbox
#   PS button and touchpad click are ignored (add --guide_button=true to pass PS through)
# Nintendo Switch Joy-Cons (Bluetooth): a left + right pair is one controller by default.
#   F6 toggles co-op mode: each Joy-Con is its own controller (player 1, 2, ...) held sideways.
#   The choice is remembered (run/joycon-mode.txt).
here=${0:A:h}
bin=${TEKKEN6_BIN:-$here/alice-recomp/build/mac-arm64}
rt=${1:-fbo}; (( $# )) && shift
mkdir -p $here/run/user $here/run/cache-$rt $here/run/crashes
export TEKKEN6_YIELD_STARTUP_SPIN=1 REX_FULLSCREEN=0 TEKKEN6_CRASH_DIR=$here/run/crashes
export TEKKEN6_JOYCON_MODE_FILE=$here/run/joycon-mode.txt
# Title drawn in a gothic blackletter font (OFL, Google Fonts).
export REX_WINDOW_TITLE_FONT=$here/../../fonts/unifrakturmaguntia-UnifrakturMaguntia-Book.ttf REX_WINDOW_TITLE_FONT_SIZE=19
export REX_WINDOW_TITLE="${REX_WINDOW_TITLE:-Alice: Madness Returns}"
# --execute_unclipped_draw_vs_on_cpu=true (below): the game clears depth with an unclipped 4x MSAA
# draw. Without measuring its real size, that clear is treated as covering the whole EDRAM,
# steals the scene's tiles, and fights flicker black. Upstream Xenia enables this by default.
# --gpu_wait_reg_mem_poll_us=-1 (below): the GPU command thread spins instead of sleeping while it
# waits for the game's CPU side. Those hand-offs happen many times per frame; costs one busy core.
# Strict Metal math, so translated Xbox shaders keep IEEE NaN/inf rules.
export MVK_CONFIG_FAST_MATH_ENABLED=${MVK_CONFIG_FAST_MATH_ENABLED:-0}
# Apple M1/M2 GPUs misread the skinning bone tables from Metal constant memory (stretched
# faces); our MoltenVK reads them through device memory when this is set.
case "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" in
  "Apple M1"*|"Apple M2"*) export REX_MSL_UBO_AS_DEVICE=1 ;;
esac
keys=(
  --mnk_mode=true
  --keybind_a=Space,J --keybind_b=Escape,Backspace,K --keybind_x=U --keybind_y=I
  --keybind_start=Return --keybind_back=Tab --keybind_guide=F24
  --keybind_dpad_up=Up --keybind_dpad_down=Down --keybind_dpad_left=Left --keybind_dpad_right=Right
  --keybind_lstick_up=W --keybind_lstick_down=S --keybind_lstick_left=A --keybind_lstick_right=D
  --keybind_rstick_up=F24 --keybind_rstick_down=F24 --keybind_rstick_left=F24 --keybind_rstick_right=F24
  --keybind_lstick_press=F24 --keybind_rstick_press=F24
  --keybind_left_shoulder=O --keybind_right_shoulder=L
  --keybind_left_trigger=P --keybind_right_trigger=Semicolon
)
cd $here/run
exec $bin/alice --game_data_root=$here/game --user_data_root=$here/run/user \
  --cache_root=$here/run/cache-$rt --fullscreen=false \
  --log_file=$here/run/alice-$rt.log --log_level=${LOG_LEVEL:-info} \
  --gpu_backend=vulkan --render_target_path_vulkan=$rt \
  --async_shader_compilation=true --anisotropic_override=0 \
  --gpu_plugin=xenos --execute_unclipped_draw_vs_on_cpu=true \
  --gpu_wait_reg_mem_poll_us=-1 \
  $keys "$@"
