# Filesystem Functions
# Source: Modularized from ~/.functions

autoload -U colors && colors

# trash: Function to moves a file to the MacOS trash
trash() {
    command mv "$@" ~/.Trash;
}

# zipf: Function to create a ZIP archive of a folder
zipdir() { 
  zip -r "$1".zip "$1"
}


# Show how much RAM application uses
# $ ram safari
# # => safari uses 154.69 MBs of RAM
ram() {
  local sum
  local items
  local app="$1"
  if [ -z "$app" ]; then
    echo "First argument - pattern to grep from processes"
  else
    sum=0
    for i in `ps aux | grep -i "$app" | grep -v "grep" | awk '{print $6}'`; do
      sum=$(($i + $sum))
    done
    sum=$(echo "scale=2; $sum / 1024.0" | bc)
    if [[ $sum != "0" ]]; then
      echo "${fg[blue]}${app}${reset_color} uses ${fg[green]}${sum}${reset_color} MBs of RAM"
    else
      echo "There are no processes with pattern '${fg[blue]}${app}${reset_color}' are running."
    fi
  fi
}

# $ size dir1 file2.js
size() {
  dust -s "$@"
}

# cat: use bat for interactive display, fall back to real cat for pipes/scripts
cat() {
  if [[ -t 1 ]] && command -v bat >/dev/null 2>&1; then
    command bat --theme auto:system --theme-dark default --theme-light GitHub "$@"
  else
    command cat "$@"
  fi
}

# ramsi: Remove ANSI escape sequences from a file (in-place)
# Usage: ramsi <file>
ramsi() {
  if [[ -z "$1" ]]; then
    echo "Usage: ramsi <file>"
    return 1
  fi
  if [[ ! -f "$1" ]]; then
    echo "ramsi: file not found: $1"
    return 1
  fi
  sed -i '' -E "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" "$1"
}

# Create directory and enter it
mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <directory_path>" >&2
        return 1
    fi
    mkdir -p -- "$1" && cd -- "$1"
}

# Climb up <n> levels
up() {
  local d=""
  for ((i=1;i<=$1;i++)); do
    d+="../"
  done
  cd "$d"
}

# fix_claude_permissions: restore owner-write on Claude Code session transcripts.
# Fixes "Transcript writes are failing (permission denied — EACCES)".
# Cause: mode bits stripped (dr-x------ / -r--------), e.g. by a forensic copy
# that set its output read-only. Not caused by com.apple.provenance: that xattr
# is kernel-protected (xattr -d exits 0 but it stays) and does not block writes.
# Usage: fix_claude_permissions [claude_root]   (default: $CLAUDE_CONFIG_DIR, then ~/.claude)
fix_claude_permissions() {
    local claude_root="${1:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}"
    local projects_dir="$claude_root/projects"

    if [[ ! -d "$projects_dir" ]]; then
        echo "Error: projects directory not found: $projects_dir" >&2
        return 1
    fi

    local before after
    before=$(command find "$projects_dir" ! -perm -u+w | wc -l | tr -d ' ')
    if (( before == 0 )); then
        echo "No read-only session paths in: $projects_dir"
        return 0
    fi

    echo "Read-only paths (top-level project dirs):"
    command find "$projects_dir" -mindepth 1 -maxdepth 1 -type d ! -perm -u+w | sed 's/^/  /'
    command chmod -R u+w "$projects_dir"

    after=$(command find "$projects_dir" ! -perm -u+w | wc -l | tr -d ' ')
    echo "Restored owner-write: $before read-only path(s) before, $after after, in: $projects_dir"
    (( after == 0 ))
}
