#!/bin/bash
# Leak guard: refuses commits that would publish game data, big files or personal info.
# Usage: tools/leak_guard.sh          check the staged files (this is what the pre-commit hook runs)
#        tools/leak_guard.sh --all    check every file in the index
# Install: ln -sf ../../tools/leak_guard.sh .git/hooks/pre-commit
# Extra private patterns (your name, e-mail, machine name; one regex per line) go in
# .git/leak_guard_private, which is never published.
# Images are refused unless their path is listed in tools/leak_guard.allow (one path per line).
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
max_bytes=$((5 * 1024 * 1024))
private=.git/leak_guard_private
allow=tools/leak_guard.allow
fail=0
hit() { printf 'LEAK GUARD: %-22s %s\n' "$1" "$2"; fail=1; }

list() {
  if [[ "${1:-}" == "--all" ]]; then git ls-files -z
  else git diff --cached --name-only --diff-filter=ACMR -z; fi
}

while IFS= read -r -d '' f; do
  lower=$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')
  base=${lower##*/}

  case "$lower" in
    *.xex|*.exe|*.iso|*.bin|*.cue|*.img|*.chd|*.mcd|*.sav|*.7z|*.rar|*.dmp|*.dump|*.ppm|*.icns|\
    *.dylib|*.wav|*.ogg|*.mp3|*.xma|*.xwb|*.vag|*.str)
      hit "forbidden extension" "$f" ;;
    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.tga|*.tiff|*.webp)
      if ! { [[ -f $allow ]] && grep -qxF -- "$f" "$allow"; }; then
        hit "image not allow-listed" "$f"
      fi ;;
  esac
  case "$base" in
    slus*|scus*|sles*|sces*|default.xex) hit "game executable" "$f" ;;
  esac
  case "/$lower" in
    */generated/*|*/game/*|*/disc/*|*/dist/*|*/build/*|*/out/*|*/saves/*|*.app/*)
      hit "forbidden path" "$f" ;;
  esac

  size=$(git cat-file -s ":$f" 2>/dev/null || echo 0)
  if (( size > max_bytes )); then hit "larger than 5 MB" "$f ($((size / 1024 / 1024)) MB)"; fi

  # Content checks on the staged version (text files only).
  if git show ":$f" 2>/dev/null | grep -Iq . ; then
    if [[ "$lower" == *.json ]] && git show ":$f" | grep -q 'bytes_b64'; then
      hit "captured game code" "$f (bytes_b64)"
    fi
    n=$(git show ":$f" | grep -nE '/(Users|home)/[A-Za-z0-9._-]+/' | grep -vE '/Users/(Shared|you|me|name|username)/' | head -1)
    [[ -n $n ]] && hit "absolute home path" "$f:${n%%:*}"
    n=$(git show ":$f" | grep -niE '[A-Za-z0-9._%+-]+@(icloud|me|mac|gmail|googlemail|hotmail|outlook|live|yahoo|proton|protonmail|pm)\.[a-z.]+' | head -1)
    [[ -n $n ]] && hit "personal e-mail" "$f:${n%%:*}"
    n=$(git show ":$f" | grep -nE 'BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9_-]{30,}|AKIA[0-9A-Z]{16}' | head -1)
    [[ -n $n ]] && hit "key or token" "$f:${n%%:*}"
    if [[ -s $private ]]; then
      n=$(git show ":$f" | grep -niEf "$private" | head -1)
      [[ -n $n ]] && hit "private pattern" "$f:${n%%:*}"
    fi
  fi
done < <(list "${1:-}")

me=$(git config user.email 2>/dev/null || true)
if [[ -n $me && ! -s $private ]]; then
  echo "leak guard: note: no $private file; add your name and e-mail patterns to it." >&2
fi

if (( fail )); then
  echo "Commit refused. Remove the files above, or fix them, then try again." >&2
  exit 1
fi
echo "leak guard: clean"
