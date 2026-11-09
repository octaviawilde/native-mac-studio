# House: QA Lab (test harness)
Role: let agents "play" and judge without a human.
- Scripted virtual controller: `TEKKEN6_VIRTUAL_PAD_SCRIPT="15000:start 2500:a ..."` (ms delay:button, SDL names). Wall-clock timed: anything slowing the game (readback, dumps, first launch) shifts menus -> verify with captures.
- In-app frame capture + contact sheets; brightness/saturation metrics for black or blown-out frames.
- One-line metric scripts (fight fps, late-frame %, worst frame) keep token use low.
- Mute audio in automated runs (`--audio_mute=true`); never kill a game someone may be playing; check with them first.
