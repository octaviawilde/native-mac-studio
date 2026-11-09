# House: Research (Recon)
Role: find prior art and known fixes before building. Saved this project hours several times.
## Habits
- Before debugging a subsystem, search the upstream tracker: `curl -s "https://api.github.com/search/issues?q=repo:OWNER/REPO+KEYWORDS"`. Tekken: rexglue-sdk #456 (texture exp_adjust), #507 (presenter pipeline churn), #531 (lost wakeups), #533 (MoltenVK primitive restart), #535/#536 (render pass splits), #539/#540 (NoContraction) — most were filed by others hitting the same game on Mac.
- Fetch PR diffs with `https://github.com/OWNER/REPO/pull/N.diff`; check the PR base vs our pinned revision before applying (`git apply --check`). Show the diff before applying downloaded code.
- An open PR made against a newer base can break things (PR #531 broke movies on our older SDK): port the idea, not the file.
- Tools: REA (github.com/morluto/rea) for Mach-O/ELF/PE/APK/ASAR RE via Hopper; Ghidra (+XEX loader) for Xbox 360 PowerPC; LIEF/Rizin for formats.
- Separate observed facts, inferences and unknowns; cite evidence.
