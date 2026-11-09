# House: Identity (look & feel)
- App icon: never box art, store art or console branding. The public scripts ship no icon;
  players can make their own (a 1024x1024 picture at `assets/icon-1024.png`), or the icon is
  drawn on the Mac at build time (see `ports/harry-potter-cos/app/icon.swift`).
- Build .icns with an iconset (16..512 @1x/@2x) via iconutil.
- Window title override: `REX_WINDOW_TITLE` (ReXGlue ports), `HP_WINDOW_TITLE` at packaging time
  (psxrecomp port). Public defaults are the plain game names.
- macOS caches icons (Games app especially): touch + lsregister -f, restart if needed.

## Window titles with personality
- Unicode letter styles (Fraktur 𝔄𝔩𝔦𝔠𝔢, bold 𝗧𝗘𝗞𝗞𝗘𝗡, script 𝒜𝓁𝒾𝒸ℯ, double-struck 𝔸𝕝𝕚𝕔𝕖) plus themed
  emoji render in the native title bar with no code. Map with a script; Fraktur C/H/I/R/Z live
  at ℭ ℌ ℑ ℜ ℨ.
- A real custom font needs native title-bar code plus a bundled OFL font. Both exist now:
  `REX_WINDOW_TITLE_FONT` (`src/ui/title_font_mac.mm` in the SDK patch) and
  `PSX_WINDOW_TITLE_FONT` (psxrecomp title-font patch). Fonts used: Anton, UnifrakturMaguntia,
  Cinzel Decorative (all SIL OFL, shipped with their license text).
