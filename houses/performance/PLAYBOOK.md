# House: Performance & Timing
Role: smooth 60 fps. Measure frame-time distribution, not averages.
## Measure
- Log per 5 s: frames, frames >20 ms, >34 ms, max; presents/s vs new guest frames/s; draws/frame (fights >400).
- A/B by alternating runs (random stages) or toggling within one run; score only "fight" windows.
- `sample <pid> 6` + per-thread busy analysis; `ioreg ... "Device Utilization %"` for GPU without sudo. Watch background load (Photos mediaanalysisd can eat 2 cores).
## Wins (Tekken, M4 base)
- Thread QoS USER_INTERACTIVE on emulator threads (P-cores): late frames halved.
- Precise vblank (sleep to deadline, not 1 ms polling).
- `-mcpu=apple-m1` instead of `-march=armv8-a`: +3-7 fps.
- GPU wait polling spin (`gpu_wait_reg_mem_poll_us=-1`).
- Upstream #536 render-pass hoisting (+3 fps), #507 presenter fix, UI repaint cap (60/s).
- Building for macOS 14 (Apple libc++ headers) costs ~3-4 fps vs targeting the newest macOS.
## Non-wins
Lower resolution, fast math in shaders (#540, vertex contraction), FIFO vsync presents (pacing worse).
