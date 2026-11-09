# House: Input & Controllers
Role: keyboard, PS5 DualSense, Nintendo Joy-Cons, multiplayer slots.
- SDL3 (3.4.x) HIDAPI drivers: PS5/PS4/Xbox/Switch/Switch2. Default combines Joy-Con L+R; co-op = `SDL_HINT_JOYSTICK_HIDAPI_COMBINE_JOY_CONS=0` and restart the Joy-Con drivers (toggle SDL_HINT_JOYSTICK_HIDAPI_JOY_CONS / _SWITCH2). F6 toggle, saved in a mode file.
- SDL ignores pads while the app is in background unless SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS.
- Player slots: lowest free ordinal so reconnects keep player 1; keyboard merges into player 1.
- Test without hardware: SDL virtual joystick with real VID/PID (DualSense 054C:0CE6) + scripted button timeline; verify `first button press` log.
- Labels are positional (Xbox layout): bottom=A, right=B, left=X, top=Y.
- macOS: PS button may open Apple's Games app; another person's Bluetooth pad still connected to this Mac can drive the game.
