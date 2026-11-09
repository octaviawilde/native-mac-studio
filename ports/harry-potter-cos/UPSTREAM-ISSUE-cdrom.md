# Draft issue for github.com/mstan/psxrecomp (not posted)

**Title:** CD-ROM: command written while an INT is unacked is queued, deadlocks Harry Potter and the Chamber of Secrets (SLUS-01503)

**Summary**
`queue_or_exec_command()` in `runtime/src/cdrom.c` holds back a command whenever `irq_flag != 0`
and only runs it after the pending interrupt is acknowledged. Beetle PSX runs the command
anyway (the new response replaces the old one in the IRQ buffer). Harry Potter and the
Chamber of Secrets depends on Beetle's behaviour and hangs right after the language screen
with the current code.

**Tested on** psxrecomp 3e343876 (2026-11-05), macOS 27 arm64 (M4), release build, bundled OpenBIOS.

**What happens**
1. The CD command sequences from native and from psx-beetle (port 4380) are identical up to one read.
2. There, a late INT1 (data ready, LBA 26301) from the previous read is pending just after Setloc's ack.
3. The game writes ReadN. Native queues it because `irq_flag != 0`.
4. The game never acks the old INT1 the way native expects, so ReadN never runs and its INT3 never arrives.
   `irq_flag=3 pend_int1=1`, `read_delay` frozen; the game polls the CD registers forever
   (`func_0006B510`, overlay at 0x65000) at 100 % CPU with no new frames.

**Workaround / proposed fix**
Run the command immediately even when an INT is pending, as Beetle does:

```c
if (irq_flag == 0 || no_queue) { exec_command(cmd); return; }
```

With that (on by default in my local patch; env `PSX_CD_NO_QUEUE=0` restores the queueing) the game reaches the title menu, starts a
new game, plays in 3D, creates a save on memory card 1, and loads it back after a restart.

I have not checked whether other games rely on the queueing, so it may need a check against your
regression set before becoming the default.
