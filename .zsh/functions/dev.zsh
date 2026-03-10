# Development Functions
# Source: Modularized from ~/.functions

# Helper: Check if dry-run flag is present and remove it from args
# Usage: if _is_dry_run "$@"; then shift; fi
_is_dry_run() {
  [[ "$1" == "--dry-run" ]] || [[ "$1" == "-n" ]]
}

# Helper: Show usage for kill functions
_kill_usage() {
  local cmd="$1"
  local desc="$2"
  echo "Usage: $cmd [OPTIONS]"
  echo ""
  echo "$desc"
  echo ""
  echo "Options:"
  echo "  --dry-run, -n  Show what would be killed without killing"
  echo "  --force, -f    Use SIGKILL (-9) instead of SIGTERM"
  echo "  --help, -h     Show this help message"
}

# workspace: Create a VS Code workspace file
workspace() {
  local dir=${PWD##*/}
  local file="$dir.code-workspace"

  if [[ -f "$file" ]]; then
    echo "Workspace file '$file' already exists. Opening it."
    code "$file"
    return 0
  fi

  cat > "$file" << EOF
{
  "folders": [
    {
      "path": "."
    }
  ],
  "settings": {}
}
EOF

  code "$file"
}

# # phpv: Make switching PHP versions easy
# phpv() {
#     brew unlink php
#     brew link --overwrite --force "php@$1"
#     php -v
# }

# git_exclude: Add pattern to .git/info/exclude
git_exclude() {
  if [[ -z "$1" ]]; then
    echo "Usage: git_exclude <path or file eg /composer.lock>"
    return 1
  fi

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not inside a git repository"
    return 1
  fi

  local exclude_file="$(git rev-parse --git-dir)/info/exclude"
  echo "$1" >> "$exclude_file"
  echo "Added '$1' to $exclude_file"
}

# gde: git diff exclude files or folders
gde() {
  if [[ -z "$1" ]]; then
    echo "Usage: gde <path-to-exclude>"
    return 1
  fi
  git diff --cached HEAD^ -- ":!$1"
}

# help: Show help with bat syntax highlighting
help() {
  if [[ -z "$1" ]]; then
    echo "Usage: help <command>"
    return 1
  fi
  "$@" --help 2>&1 | bat --plain --language=help
}

# timezsh: Benchmark zsh startup time
timezsh() {
  local shell=${1-$SHELL}
  for _ in $(seq 1 10); do /usr/bin/time "$shell" -i -c exit; done
}

# my_ps: List processes owned by current user
my_ps() { ps "$@" -u "$USER" -o pid,%cpu,%mem,start,time,bsdtime,command; }

# killport: Kill process(es) listening on a TCP port
# Usage: killport <port> [--dry-run] [--force] [--help]
killport() {
  if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ -z "$1" ]]; then
    echo "Usage: killport <port> [OPTIONS]"
    echo ""
    echo "Kill the process listening on a TCP port"
    echo ""
    echo "Options:"
    echo "  --dry-run, -n  Show what would be killed without killing"
    echo "  --force, -f    Use SIGKILL (-9) instead of SIGTERM"
    echo "  --help, -h     Show this help message"
    return 0
  fi

  local port=""
  local dry_run=false
  local signal="-TERM"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --force|-f)   signal="-9"; shift ;;
      --help|-h)    killport --help; return 0 ;;
      -*) echo "Unknown option: $1"; return 1 ;;
      *)  port="$1"; shift ;;
    esac
  done

  if [[ -z "$port" ]]; then
    echo "Error: No port specified"
    return 1
  fi

  local pids
  pids=$(lsof -ti tcp:"$port" 2>/dev/null)
  if [[ -z "$pids" ]]; then
    echo "No process found listening on port $port"
    return 0
  fi

  if $dry_run; then
    echo "[dry-run] Would kill PID(s) $pids (port $port)"
  else
    echo "Killing PID(s) $pids (port $port)"
    kill $signal ${=pids}
  fi
}

# killmysql: Kill all MySQL processes
killmysql() {
  if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    _kill_usage "killmysql" "Kill all MySQL processes"
    return 0
  fi

  local dry_run=false
  local signal="-TERM"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --force|-f) signal="-9"; shift ;;
      *) shift ;;
    esac
  done

  local pids=$(pgrep mysql)
  if [[ -z "$pids" ]]; then
    echo "No MySQL processes found"
    return 0
  fi

  if $dry_run; then
    echo "[dry-run] Would kill MySQL processes: $pids"
  else
    kill $signal ${=pids} && echo "Sent $signal to MySQL processes: $pids"
  fi
}

# kill-code: Kill all VS Code processes
kill-code() {
  if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    _kill_usage "kill-code" "Kill all Visual Studio Code processes"
    return 0
  fi

  local dry_run=false
  local signal="-TERM"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --force|-f) signal="-9"; shift ;;
      *) shift ;;
    esac
  done

  local pids=$(pgrep -f "Visual Studio Code")
  if [[ -z "$pids" ]]; then
    echo "No VS Code processes found"
    return 0
  fi

  if $dry_run; then
    echo "[dry-run] Would kill VS Code processes: $pids"
  else
    kill $signal ${=pids} && echo "Sent $signal to VS Code processes: $pids"
  fi
}

# killproc: Kill all instances of a process (renamed from killall to avoid shadowing)
killproc() {
  if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: killproc <process-name> [OPTIONS]"
    echo ""
    echo "Kill all instances of a process by name"
    echo ""
    echo "Options:"
    echo "  --dry-run, -n  Show what would be killed without killing"
    echo "  --force, -f    Use SIGKILL (-9) instead of SIGTERM"
    echo "  --help, -h     Show this help message"
    return 0
  fi

  local process=""
  local dry_run=false
  local signal="-TERM"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --force|-f) signal="-9"; shift ;;
      -*) echo "Unknown option: $1"; return 1 ;;
      *) process="$1"; shift ;;
    esac
  done

  if [[ -z "$process" ]]; then
    echo "Error: No process name specified"
    echo "Usage: killproc <process-name> [--dry-run] [--force]"
    return 1
  fi

  local pids=$(pgrep "$process")
  if [[ -z "$pids" ]]; then
    echo "No processes matching '$process' found"
    return 0
  fi

  if $dry_run; then
    echo "[dry-run] Would kill processes matching '$process': $pids"
  else
    pkill $signal "$process" && echo "Sent $signal to processes matching '$process'"
  fi
}

# kill-bloat: Kill processes with too many children
kill-bloat() {
  # Display help message
  if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: kill-bloat [OPTIONS] [THRESHOLD]"
    echo ""
    echo "Kill processes with an atypically high number of child processes"
    echo ""
    echo "Arguments:"
    echo "  THRESHOLD      Number of children to trigger kill (default: 20)"
    echo ""
    echo "Options:"
    echo "  --dry-run, -n  Show what would be killed without killing"
    echo "  --force, -f    Use SIGKILL (-9) instead of SIGTERM"
    echo "  --help, -h     Show this help message"
    return 0
  fi

  # Default values
  local dry_run=false
  local signal="-15"  # SIGTERM
  local threshold=20

  # Parse command-line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --force|-f) signal="-9"; shift ;;  # SIGKILL
      [0-9]*) threshold="$1"; shift ;;
      *) echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  # Validate threshold is a positive integer
  if ! [[ "$threshold" =~ ^[0-9]+$ ]] || (( threshold < 1 )); then
    echo "Error: THRESHOLD must be a positive integer" >&2
    return 1
  fi

  # Collect process information efficiently
  local -A child_counts
  local -A proc_names
  local ps_output
  if ! ps_output=$(ps -axo "pid=,ppid=,comm=" 2>/dev/null); then
    echo "Error: Failed to retrieve process list" >&2
    return 1
  fi

  # Parse ps output and count children
  while read -r pid ppid comm; do
    # Skip invalid lines or kernel processes
    [[ -z "$pid" || -z "$ppid" ]] && continue
    (( child_counts[$ppid] += 1 ))
    proc_names[$pid]=$comm
  done <<< "$ps_output"

  # Find and handle processes exceeding threshold
  local found=false
  for pid in ${(k)child_counts}; do
    local count=${child_counts[$pid]}
    if (( count > threshold )); then
      found=true
      local proc_name=${proc_names[$pid]:-unknown}
      if $dry_run; then
        echo "[dry-run] Would kill $proc_name (PID $pid) with $count children"
      else
        echo "Killing $proc_name (PID $pid) with $count children"
        if ! kill $signal "$pid" 2>/dev/null; then
          echo "Warning: Failed to kill PID $pid (process may not exist or permission denied)" >&2
        fi
      fi
    fi
  done

  # Report if no processes found
  if ! $found; then
    echo "No processes found with more than $threshold children"
  fi
}

# kill-runaway: Kill processes by name that are consuming resources
# This is what you want for killing rg, claude, node processes etc.
kill-runaway() {
  if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ -z "$1" ]]; then
    echo "Usage: kill-runaway <process-name> [OPTIONS]"
    echo ""
    echo "Kill all instances of a process by name (for runaway processes)"
    echo ""
    echo "Examples:"
    echo "  kill-runaway rg --dry-run    # Preview killing all rg processes"
    echo "  kill-runaway claude --force  # Force-kill all claude processes"
    echo "  kill-runaway node            # Gracefully kill all node processes"
    echo ""
    echo "Options:"
    echo "  --dry-run, -n  Show what would be killed without killing"
    echo "  --force, -f    Use SIGKILL (-9) instead of SIGTERM"
    echo "  --help, -h     Show this help message"
    return 0
  fi

  local target=""
  local dry_run=false
  local signal="-TERM"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --force|-f) signal="-9"; shift ;;
      --help|-h) kill-runaway --help; return 0 ;;
      -*) echo "Unknown option: $1"; return 1 ;;
      *) target="$1"; shift ;;
    esac
  done

  if [[ -z "$target" ]]; then
    echo "Error: No process name specified"
    return 1
  fi

  # Get process list directly with all info in one call
  local proc_list
  proc_list=$(ps -axo pid=,rss=,pcpu=,comm= 2>/dev/null | command grep -i "$target")

  if [[ -z "$proc_list" ]]; then
    echo "No processes matching '$target' found"
    return 0
  fi

  local count=$(echo "$proc_list" | wc -l | tr -d ' ')
  echo "Found $count process(es) matching '$target':"
  echo ""

  # Process each line
  echo "$proc_list" | while IFS= read -r line; do
    local pid=$(echo "$line" | awk '{print $1}')
    local rss=$(echo "$line" | awk '{print $2}')
    local cpu=$(echo "$line" | awk '{print $3}')
    local cmd=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | xargs)
    local mem=$(awk "BEGIN {printf \"%.1fMB\", $rss/1024}")

    if $dry_run; then
      echo "  [dry-run] Would kill PID $pid (${mem}, ${cpu}% CPU) - $cmd"
    else
      echo "  Killing PID $pid (${mem}, ${cpu}% CPU) - $cmd"
      kill $signal "$pid" 2>/dev/null
    fi
  done
}

