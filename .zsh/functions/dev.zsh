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

# Universal wrapper for mise-managed tools
mise_wrap() {
  local tool="$1"
  shift
  if mise which "$tool" > /dev/null 2>&1; then
    mise exec "$tool" -- "$tool" "$@"
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      return $exit_code
    fi
  else
    command "$tool" "$@"
  fi
}

# Apply the enforcer to your tools
node() { mise_wrap node "$@"; }
python() { mise_wrap python "$@"; }
# npm and php are handled by aliases in .zshrc (aliases take precedence over functions)

# audit-system: Comprehensive memory and process analysis for macOS
audit-system() {
  # Check for gum dependency
  if ! command -v gum &>/dev/null; then
    echo "Error: gum is required but not installed."
    echo "Install with: brew install gum"
    return 1
  fi

  # Parse arguments
  local json_output=false
  local mem_threshold=500  # MB
  local cpu_threshold=80   # percent
  local top_count=10
  local use_color=true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        echo "Usage: audit-system [OPTIONS]"
        echo ""
        echo "Comprehensive memory and process analysis for macOS"
        echo ""
        echo "Options:"
        echo "  --json           Output results in JSON format"
        echo "  --no-color       Disable colored output"
        echo "  --mem-threshold  Memory threshold in MB (default: 500)"
        echo "  --cpu-threshold  CPU threshold in percent (default: 80)"
        echo "  --top N          Show top N processes (default: 10)"
        echo "  --help, -h       Show this help message"
        echo ""
        echo "Examples:"
        echo "  audit-system                      # Run with defaults"
        echo "  audit-system --json               # Output as JSON"
        echo "  audit-system --no-color | less    # Pipe without colors"
        echo "  audit-system --mem-threshold 1000 # Flag processes over 1GB"
        return 0
        ;;
      --json) json_output=true; shift ;;
      --no-color) use_color=false; shift ;;
      --mem-threshold) mem_threshold="$2"; shift 2 ;;
      --cpu-threshold) cpu_threshold="$2"; shift 2 ;;
      --top) top_count="$2"; shift 2 ;;
      *) echo "Unknown option: $1"; return 1 ;;
    esac
  done

  # Set gum color mode
  local gum_env=""
  if ! $use_color; then
    gum_env="NO_COLOR=1"
  fi

  # Progress bar helper
  _progress_bar() {
    local pct=$1 width=${2:-20}
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done
    echo "$bar"
  }

  # ═══════════════════════════════════════════════════════════════════════════
  # COLLECT SYSTEM METRICS (optimized - single ps call, cached results)
  # ═══════════════════════════════════════════════════════════════════════════

  # Get memory info efficiently
  local page_size=$(sysctl -n hw.pagesize)
  local total_mem_bytes=$(sysctl -n hw.memsize)
  local total_mem_mb=$((total_mem_bytes / 1024 / 1024))

  # Parse vm_stat in one awk call
  local vm_stats=$(vm_stat | awk '
    /Pages free/ {gsub(/\./,"",$3); free=$3}
    /Pages active/ {gsub(/\./,"",$3); active=$3}
    /Pages inactive/ {gsub(/\./,"",$3); inactive=$3}
    /Pages speculative/ {gsub(/\./,"",$3); spec=$3}
    /Pages wired down/ {gsub(/\./,"",$4); wired=$4}
    /Pages occupied by compressor/ {gsub(/\./,"",$5); comp=$5}
    END {print free, active, inactive, spec, wired, comp}
  ')
  local pages_free pages_active pages_inactive pages_speculative pages_wired pages_compressed
  read pages_free pages_active pages_inactive pages_speculative pages_wired pages_compressed <<< "$vm_stats"

  # Handle empty values
  : ${pages_free:=0} ${pages_active:=0} ${pages_inactive:=0}
  : ${pages_speculative:=0} ${pages_wired:=0} ${pages_compressed:=0}

  local free_mem_mb=$(( (pages_free + pages_speculative) * page_size / 1024 / 1024 ))
  local active_mem_mb=$(( pages_active * page_size / 1024 / 1024 ))
  local inactive_mem_mb=$(( pages_inactive * page_size / 1024 / 1024 ))
  local wired_mem_mb=$(( pages_wired * page_size / 1024 / 1024 ))
  local compressed_mem_mb=$(( pages_compressed * page_size / 1024 / 1024 ))
  local used_mem_mb=$(( total_mem_mb - free_mem_mb ))

  # Memory pressure
  local mem_pressure="normal"
  local mem_percent=$(( used_mem_mb * 100 / total_mem_mb ))
  (( mem_percent > 90 )) && mem_pressure="critical"
  (( mem_percent > 75 && mem_percent <= 90 )) && mem_pressure="warning"

  # Get swap usage in one awk call
  local swap_stats=$(sysctl -n vm.swapusage 2>/dev/null | awk '{
    gsub(/M/,"",$3); gsub(/M/,"",$6); gsub(/M/,"",$9);
    print $3, $6, $9
  }')
  local swap_total swap_used swap_free
  read swap_total swap_used swap_free <<< "${swap_stats:-0 0 0}"
  : ${swap_total:=0} ${swap_used:=0} ${swap_free:=0}

  # Single ps call for all process data - cache it
  local ps_cache=$(ps -axo pid=,rss=,pcpu=,user=,stat=,comm= 2>/dev/null)

  # Get counts from cached data
  local total_procs=$(echo "$ps_cache" | wc -l | tr -d ' ')
  local zombie_count=$(echo "$ps_cache" | awk '$5 ~ /Z/ {count++} END {print count+0}')

  # Get top memory processes from cache (using awk for efficiency)
  local top_mem_procs=$(echo "$ps_cache" | sort -k2 -rn | head -n "$top_count")
  local top_cpu_procs=$(echo "$ps_cache" | sort -k3 -rn | head -n "$top_count")

  # Get process count by user from cache
  local procs_by_user=$(echo "$ps_cache" | awk '{print $4}' | sort | uniq -c | sort -rn)

  # Find high memory/CPU processes from cache (threshold in KB for rss)
  local mem_thresh_kb=$((mem_threshold * 1024))
  local high_mem_procs=$(echo "$ps_cache" | awk -v thresh="$mem_thresh_kb" '$2 >= thresh {print $0}')
  local high_cpu_procs=$(echo "$ps_cache" | awk -v thresh="$cpu_threshold" '$3 >= thresh {print $0}')

  # Find duplicate processes from cache
  local duplicate_procs=$(echo "$ps_cache" | awk '{print $6}' | sort | uniq -c | sort -rn | awk '$1 > 3 {print $0}' | head -10)

  # ═══════════════════════════════════════════════════════════════════════════
  # HELPER: Parse process line efficiently (no subshells)
  # ═══════════════════════════════════════════════════════════════════════════
  _parse_proc() {
    # Input: line from ps output
    # Sets: _pid, _rss, _cpu, _user, _cmd, _mem_mb
    local line="$1"
    _pid=${line%% *}; line=${line#* }
    line=${line##[[:space:]]}
    _rss=${line%% *}; line=${line#* }
    line=${line##[[:space:]]}
    _cpu=${line%% *}; line=${line#* }
    line=${line##[[:space:]]}
    _user=${line%% *}; line=${line#* }
    line=${line##[[:space:]]}
    # Skip stat field
    line=${line#* }
    line=${line##[[:space:]]}
    _cmd=${line}
    _cmd=${_cmd##[[:space:]]}
    _cmd=${_cmd%%[[:space:]]}
    _mem_mb=$(( ${_rss:-0} / 1024 ))
  }

  # ═══════════════════════════════════════════════════════════════════════════
  # GENERATE OUTPUT
  # ═══════════════════════════════════════════════════════════════════════════

  if $json_output; then
    # Build JSON arrays efficiently with awk
    local mem_json=$(echo "$top_mem_procs" | head -5 | awk '{
      pid=$1; rss=$2; cpu=$3; user=$4; cmd=$6;
      mem_mb=int(rss/1024);
      printf "    {\"pid\": %d, \"memory_mb\": %d, \"cpu_percent\": %s, \"user\": \"%s\", \"command\": \"%s\"}", pid, mem_mb, cpu, user, cmd;
      if (NR < 5) printf ",";
      printf "\n"
    }')

    local cpu_json=$(echo "$top_cpu_procs" | head -5 | awk '{
      pid=$1; rss=$2; cpu=$3; user=$4; cmd=$6;
      mem_mb=int(rss/1024);
      printf "    {\"pid\": %d, \"memory_mb\": %d, \"cpu_percent\": %s, \"user\": \"%s\", \"command\": \"%s\"}", pid, mem_mb, cpu, user, cmd;
      if (NR < 5) printf ",";
      printf "\n"
    }')

    cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "system": {
    "memory": {
      "total_mb": $total_mem_mb,
      "used_mb": $used_mem_mb,
      "free_mb": $free_mem_mb,
      "active_mb": $active_mem_mb,
      "inactive_mb": $inactive_mem_mb,
      "wired_mb": $wired_mem_mb,
      "compressed_mb": $compressed_mem_mb,
      "percent_used": $mem_percent,
      "pressure": "$mem_pressure"
    },
    "swap": {
      "total_mb": ${swap_total:-0},
      "used_mb": ${swap_used:-0},
      "free_mb": ${swap_free:-0}
    },
    "processes": {
      "total": $total_procs,
      "zombies": $zombie_count
    }
  },
  "top_memory_processes": [
$mem_json
  ],
  "top_cpu_processes": [
$cpu_json
  ],
  "issues": [],
  "recommendations": []
}
EOF
    return 0
  fi

  # ═══════════════════════════════════════════════════════════════════════════
  # HUMAN-READABLE OUTPUT (using gum)
  # ═══════════════════════════════════════════════════════════════════════════

  # Set color mode for gum
  local -a gum_opts=()
  if ! $use_color; then
    export NO_COLOR=1
  fi

  # Header
  env ${gum_env:-} gum style --border double --border-foreground 6 --align center --padding "0 2" --width 78 \
    "SYSTEM AUDIT REPORT" "$(date '+%Y-%m-%d %H:%M:%S')"
  echo ""

  # Memory Dashboard
  local mem_bar=$(_progress_bar "$mem_percent" 20)
  local pressure_label
  local pressure_color
  case "$mem_pressure" in
    critical) pressure_label="CRITICAL"; pressure_color=1 ;;
    warning)  pressure_label="WARNING"; pressure_color=3 ;;
    *)        pressure_label="NORMAL"; pressure_color=2 ;;
  esac

  local mem_content
  mem_content=$(printf "%s %d%%  Used: %d MB / %d MB  Free: %d MB\n" "$mem_bar" "$mem_percent" "$used_mem_mb" "$total_mem_mb" "$free_mem_mb")
  mem_content+=$(printf "\nActive: %d MB  Inactive: %d MB  Wired: %d MB  Comp: %d MB" "$active_mem_mb" "$inactive_mem_mb" "$wired_mem_mb" "$compressed_mem_mb")
  mem_content+=$(printf "\nPressure: ")

  env ${gum_env:-} gum style --border rounded --border-foreground 6 --padding "0 1" --width 78 \
    "$(env ${gum_env:-} gum style --bold 'MEMORY OVERVIEW')" \
    "$mem_content$(env ${gum_env:-} gum style --foreground $pressure_color --bold "$pressure_label")"
  echo ""

  # Swap Dashboard
  local swap_pct=0
  if (( ${swap_total%.*} > 0 )); then
    swap_pct=$(( ${swap_used%.*} * 100 / ${swap_total%.*} ))
  fi
  local swap_bar=$(_progress_bar "$swap_pct" 10)

  env ${gum_env:-} gum style --border rounded --border-foreground 6 --padding "0 1" --width 78 \
    "$(env ${gum_env:-} gum style --bold 'SWAP USAGE')" \
    "$(printf "%s %d%%  Used: %.1f MB / %.1f MB  Free: %.1f MB" "$swap_bar" "$swap_pct" "${swap_used:-0}" "${swap_total:-0}" "${swap_free:-0}")"
  echo ""

  # Process Summary
  env ${gum_env:-} gum style --border rounded --border-foreground 6 --padding "0 1" --width 78 \
    "$(env ${gum_env:-} gum style --bold 'PROCESS SUMMARY')" \
    "$(printf "Total Processes: %d    Zombies: %d" "$total_procs" "$zombie_count")"
  echo ""

  # Top Memory Consumers - using gum table
  local mem_csv="PID,MEM,CPU,USER,COMMAND"
  mem_csv+="\n$(echo "$top_mem_procs" | awk '{
    pid=$1; rss=$2; cpu=$3; user=$4; cmd=$6;
    mem_mb=int(rss/1024);
    n=split(cmd, parts, "/");
    short_cmd=parts[n];
    if (length(short_cmd) > 20) short_cmd=substr(short_cmd,1,17)"...";
    if (length(user) > 10) user=substr(user,1,7)"...";
    printf "%d,%dMB,%.1f%%,%s,%s\n", pid, mem_mb, cpu, user, short_cmd
  }')"

  echo "$(env ${gum_env:-} gum style --bold --foreground 6 'TOP MEMORY CONSUMERS')"
  echo -e "$mem_csv" | env ${gum_env:-} gum table --print --border rounded --border.foreground 6
  echo ""

  # Top CPU Consumers - using gum table
  local cpu_csv="PID,MEM,CPU,USER,COMMAND"
  cpu_csv+="\n$(echo "$top_cpu_procs" | awk '{
    pid=$1; rss=$2; cpu=$3; user=$4; cmd=$6;
    mem_mb=int(rss/1024);
    n=split(cmd, parts, "/");
    short_cmd=parts[n];
    if (length(short_cmd) > 20) short_cmd=substr(short_cmd,1,17)"...";
    if (length(user) > 10) user=substr(user,1,7)"...";
    printf "%d,%dMB,%.1f%%,%s,%s\n", pid, mem_mb, cpu, user, short_cmd
  }')"

  echo "$(env ${gum_env:-} gum style --bold --foreground 6 'TOP CPU CONSUMERS')"
  echo -e "$cpu_csv" | env ${gum_env:-} gum table --print --border rounded --border.foreground 6
  echo ""

  # ═══════════════════════════════════════════════════════════════════════════
  # DETECTED ISSUES
  # ═══════════════════════════════════════════════════════════════════════════

  local issues=""

  # Check memory pressure
  if [[ "$mem_pressure" == "critical" ]]; then
    issues+="$(env ${gum_env:-} gum style --foreground 1 --bold '[CRITICAL]') Memory pressure is critical (${mem_percent}% used)\n"
  elif [[ "$mem_pressure" == "warning" ]]; then
    issues+="$(env ${gum_env:-} gum style --foreground 3 '[WARNING]') Memory pressure elevated (${mem_percent}% used)\n"
  fi

  # Check swap usage
  if (( ${swap_used%.*} > 1000 )); then
    issues+="$(env ${gum_env:-} gum style --foreground 3 '[WARNING]') High swap usage: ${swap_used%.*}MB\n"
  fi

  # Check zombies
  if (( zombie_count > 0 )); then
    issues+="$(env ${gum_env:-} gum style --foreground 4 '[INFO]') ${zombie_count} zombie process(es) detected\n"
  fi

  # Check high memory processes
  if [[ -n "$high_mem_procs" ]]; then
    local count=$(echo "$high_mem_procs" | wc -l | tr -d ' ')
    issues+="$(env ${gum_env:-} gum style --foreground 3 '[WARNING]') ${count} process(es) exceeding ${mem_threshold}MB memory threshold\n"
  fi

  # Check high CPU processes
  if [[ -n "$high_cpu_procs" ]]; then
    local count=$(echo "$high_cpu_procs" | wc -l | tr -d ' ')
    issues+="$(env ${gum_env:-} gum style --foreground 3 '[WARNING]') ${count} process(es) exceeding ${cpu_threshold}% CPU threshold\n"
  fi

  # Check for duplicate processes
  if [[ -n "$duplicate_procs" ]]; then
    issues+="$(env ${gum_env:-} gum style --foreground 4 '[INFO]') Multiple duplicate process groups detected\n"
  fi

  if [[ -z "$issues" ]]; then
    issues="$(env ${gum_env:-} gum style --foreground 2 '[OK]') No significant issues detected"
  fi

  env ${gum_env:-} gum style --border rounded --border-foreground 6 --padding "0 1" --width 78 \
    "$(env ${gum_env:-} gum style --bold 'DETECTED ISSUES')" \
    "$(echo -e "$issues")"
  echo ""

  # ═══════════════════════════════════════════════════════════════════════════
  # RECOMMENDED ACTIONS
  # ═══════════════════════════════════════════════════════════════════════════

  local recs=""
  local rec_count=0

  # Check for VS Code processes
  local code_mem=$(echo "$ps_cache" | awk '/Code|Electron/ {sum+=$2} END {printf "%.0f", sum/1024}')
  if [[ -n "$code_mem" ]] && (( code_mem > 500 )); then
    (( rec_count++ ))
    recs+="${rec_count}. Restart VS Code to recover ~${code_mem}MB\n"
    recs+="   Command: kill-code --dry-run\n\n"
  fi

  # Check for node processes
  local node_stats=$(echo "$ps_cache" | awk -v IGNORECASE=1 '/node/ {count++; sum+=$2} END {printf "%d %d", count, sum/1024}')
  local node_procs node_mem
  read node_procs node_mem <<< "$node_stats"
  if (( node_procs > 5 )) && (( node_mem > 200 )); then
    (( rec_count++ ))
    recs+="${rec_count}. Kill excess node processes (${node_procs} instances, ~${node_mem}MB)\n"
    recs+="   Command: kill-runaway node --dry-run\n\n"
  fi

  # Check for MySQL
  local mysql_stats=$(echo "$ps_cache" | awk '/mysql/ {count++; sum+=$2} END {printf "%d %d", count, sum/1024}')
  local mysql_count mysql_mem
  read mysql_count mysql_mem <<< "$mysql_stats"
  if (( mysql_count > 0 )); then
    (( rec_count++ ))
    recs+="${rec_count}. MySQL is running (${mysql_count} process(es), ~${mysql_mem}MB)\n"
    recs+="   Command: killmysql --dry-run\n\n"
  fi

  # High memory processes - use awk to build recommendations
  if [[ -n "$high_mem_procs" ]]; then
    local high_mem_recs=$(echo "$high_mem_procs" | head -3 | awk -v start_count="$rec_count" '{
      pid=$1; rss=$2; cmd=$6;
      mem_mb=int(rss/1024);
      n=split(cmd, parts, "/");
      short_cmd=parts[n];
      if (length(short_cmd) > 20) short_cmd=substr(short_cmd,1,17)"...";
      start_count++;
      printf "%d. Kill %s (PID %d) to recover ~%dMB\\n", start_count, short_cmd, pid, mem_mb;
      printf "   Command: kill-runaway %s --dry-run\\n\\n", short_cmd;
    }')
    recs+="$high_mem_recs"
    rec_count=$((rec_count + $(echo "$high_mem_procs" | head -3 | wc -l)))
  fi

  if (( rec_count == 0 )); then
    recs="System appears healthy. No immediate actions recommended."
  fi

  env ${gum_env:-} gum style --border rounded --border-foreground 6 --padding "0 1" --width 78 \
    "$(env ${gum_env:-} gum style --bold 'RECOMMENDED ACTIONS')" \
    "$(echo -e "$recs")"
  echo ""

  # ═══════════════════════════════════════════════════════════════════════════
  # PROCESSES BY USER
  # ═══════════════════════════════════════════════════════════════════════════

  local users_content=$(echo "$procs_by_user" | head -5 | awk '{printf "%s %s\n", $1, $2}')

  env ${gum_env:-} gum style --border rounded --border-foreground 6 --padding "0 1" --width 78 \
    "$(env ${gum_env:-} gum style --bold 'PROCESSES BY USER')" \
    "$users_content"

  # Clean up
  unset NO_COLOR 2>/dev/null || true
}