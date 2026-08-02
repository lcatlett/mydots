# Terminal Functions
# Per-pane theming for Ghostty via OSC color sequences.
#
# Ghostty declares `ccc` + `initc` in its terminfo and implements OSC 4/10/11/12
# (and resets 104/110/111/112) through its unified color_operation handler.
# That means colors can be changed for a SINGLE pane at runtime, independently
# of the `theme =` line in config, which applies per-window only.

# tint — apply any theme file from the ghostty themes dir to the current pane.
# Usage: tint lindsey-plum
#        tint            (lists available themes)
#        tint --reset    (revert this pane to the configured theme)
tint() {
  local dir="${GHOSTTY_THEMES:-$HOME/.config/ghostty/themes}"

  if [[ "$1" == "--reset" || "$1" == "-r" ]]; then
    printf '\033]104\007\033]110\007\033]111\007\033]112\007'
    return 0
  fi

  if [[ -z "$1" ]]; then
    print -u2 "usage: tint <theme>|--reset"
    print -u2 "themes in $dir:"
    ls -1 "$dir" 2>/dev/null | sed 's/^/  /' >&2
    return 1
  fi

  local file="$dir/$1"
  if [[ ! -r "$file" ]]; then
    print -u2 "tint: no readable theme at $file"
    return 1
  fi

  local key val seq=""
  while IFS= read -r line; do
    [[ "$line" == \#* || -z "$line" ]] && continue
    key="${line%%=*}"; key="${key// /}"
    val="${line#*=}";  val="${val// /}"
    case "$key" in
      palette)
        # val is now "N=#rrggbb"
        seq+=$'\033]4;'"${val%%=*};${val#*=}"$'\007' ;;
      background)   seq+=$'\033]11;'"$val"$'\007' ;;
      foreground)   seq+=$'\033]10;'"$val"$'\007' ;;
      cursor-color) seq+=$'\033]12;'"$val"$'\007' ;;
    esac
  done < "$file"

  printf '%s' "$seq"
}

# ghost — ssh to the compute node with an automatic surface change on the way in,
# reverting on the way out (including on dropped connections, via the trap).
ghost() {
  tint lindsey-ghost-v2
  trap 'tint --reset' EXIT INT TERM
  ssh "${@:-lcatlett@ghost.local}"
  trap - EXIT INT TERM
  tint --reset
}
