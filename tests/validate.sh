#!/usr/bin/env bash
# tests/validate.sh — Dotfiles drift detection suite
#
# Run: bash tests/validate.sh
# Exit: 0 = all tests passed, non-zero = number of failures

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Counters ---
PASS=0
FAIL=0
SKIP=0
FAILURES=()

# --- Runner ---
run_test() {
  local name="$1"
  local func="$2"
  printf "${BOLD}  %-40s${RESET}" "$name"
  local output
  if output=$("$func" 2>&1); then
    printf "${GREEN}PASS${RESET}\n"
    PASS=$((PASS + 1))
  else
    printf "${RED}FAIL${RESET}\n"
    if [[ -n "$output" ]]; then
      echo "$output" | sed 's/^/    /'
    fi
    FAIL=$((FAIL + 1))
    FAILURES+=("$name")
  fi
}

skip_test() {
  local name="$1"
  local reason="$2"
  printf "${BOLD}  %-40s${RESET}" "$name"
  printf "${YELLOW}SKIP${RESET} (%s)\n" "$reason"
  SKIP=$((SKIP + 1))
}

# ---------------------------------------------------------------------------
# Test 1: Shell startup time < 2 seconds
# ---------------------------------------------------------------------------
test_shell_startup() {
  local start end elapsed
  start=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')
  zsh -i -c exit 2>/dev/null
  end=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')
  # macOS date doesn't support %N — fall back to python
  if [[ "$start" == *N ]] || [[ "$end" == *N ]]; then
    elapsed=$(python3 -c "
import subprocess, time
s = time.time()
subprocess.run(['zsh', '-i', '-c', 'exit'], capture_output=True)
print(f'{time.time() - s:.2f}')
")
  else
    elapsed=$(python3 -c "print(f'{($end - $start) / 1e9:.2f}')")
  fi
  echo "Startup: ${elapsed}s"
  python3 -c "exit(0 if float('$elapsed') < 2.0 else 1)"
}

# ---------------------------------------------------------------------------
# Test 2: No secrets in tracked files
# ---------------------------------------------------------------------------
test_no_secrets() {
  local matches
  # Only scan git-tracked files — dots/.exports is gitignored by design
  matches=$(cd "$DOTFILES_DIR" && git ls-files -z | xargs -0 grep -lE \
    '(ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})' \
    2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    echo "Secrets found in tracked files:"
    echo "$matches"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Test 3: Brewfile consistency
# ---------------------------------------------------------------------------
test_brewfile_consistency() {
  if ! command -v brew &>/dev/null; then
    echo "brew not found"
    return 1
  fi
  local errors=0
  brew bundle check --file="$DOTFILES_DIR/install/Brewfile" 2>&1 || errors=$((errors + 1))
  local host_brewfile
  host_brewfile="$DOTFILES_DIR/install/Brewfile.$(hostname -s)"
  if [[ -f "$host_brewfile" ]]; then
    brew bundle check --file="$host_brewfile" 2>&1 || errors=$((errors + 1))
  fi
  return "$errors"
}

# ---------------------------------------------------------------------------
# Test 4: Dotfiles sync (symlink integrity)
# ---------------------------------------------------------------------------
test_dotfiles_sync() {
  local errors=()

  # Config files that should symlink ~/.<file> → dotfiles/dots/.<file>
  local dot_files=(
    .zshrc .gitconfig .exports .aliases .gitignore .gitignore_global
    .inputrc .bash_profile .bashrc .profile .editorconfig
  )

  for f in "${dot_files[@]}"; do
    local link_path="$HOME/$f"
    local expected="$DOTFILES_DIR/dots/$f"
    if [[ ! -L "$link_path" ]]; then
      errors+=("$f: not a symlink")
    else
      local target
      target=$(readlink "$link_path")
      if [[ "$target" != "$expected" ]]; then
        errors+=("$f: points to '$target', expected '$expected'")
      fi
    fi
  done

  # ghostty config
  local ghostty_config_link="$HOME/.config/ghostty/config"
  local ghostty_config_expected="$DOTFILES_DIR/dots/ghostty/config"
  if [[ ! -L "$ghostty_config_link" ]]; then
    errors+=("ghostty/config: not a symlink")
  else
    local ghostty_config_target
    ghostty_config_target=$(readlink "$ghostty_config_link")
    if [[ "$ghostty_config_target" != "$ghostty_config_expected" ]]; then
      errors+=("ghostty/config: points to '$ghostty_config_target', expected '$ghostty_config_expected'")
    fi
  fi

  local ghostty_themes_link="$HOME/.config/ghostty/themes"
  local ghostty_themes_expected="$DOTFILES_DIR/dots/ghostty/themes"
  if [[ ! -L "$ghostty_themes_link" ]]; then
    errors+=("ghostty/themes: not a symlink")
  else
    local ghostty_themes_target
    ghostty_themes_target=$(readlink "$ghostty_themes_link")
    if [[ "$ghostty_themes_target" != "$ghostty_themes_expected" ]]; then
      errors+=("ghostty/themes: points to '$ghostty_themes_target', expected '$ghostty_themes_expected'")
    fi
  fi

  # mise config
  local mise_link="$HOME/.config/mise/config.toml"
  local mise_expected="$DOTFILES_DIR/mise/config.toml"
  if [[ -L "$mise_link" ]]; then
    local mise_target
    mise_target=$(readlink "$mise_link")
    if [[ "$mise_target" != "$mise_expected" ]]; then
      errors+=("mise/config.toml: points to '$mise_target', expected '$mise_expected'")
    fi
  elif [[ -e "$mise_link" ]]; then
    errors+=("mise/config.toml: exists but is not a symlink")
  fi

  if [[ ${#errors[@]} -gt 0 ]]; then
    printf '%s\n' "${errors[@]}"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Test 5: SSH permissions
# ---------------------------------------------------------------------------
test_ssh_permissions() {
  local errors=()

  # Portable octal-permission read: GNU coreutils stat first (this machine's
  # PATH is GNU-first), BSD/macOS stat as fallback. The old `stat -f '%A'`
  # idiom mixed a BSD flag with a GNU field and produced a false FAIL here.
  _perms() { stat -c '%a' "$1" 2>/dev/null || stat -f '%OLp' "$1" 2>/dev/null; }

  # ~/.ssh/config must be 600
  if [[ -f "$HOME/.ssh/config" ]]; then
    local config_perms
    config_perms=$(_perms "$HOME/.ssh/config")
    if [[ "$config_perms" != "600" ]]; then
      errors+=("$HOME/.ssh/config is $config_perms (expected 600)")
    fi
  fi

  # Private keys must be 600 (skip .pub files)
  while IFS= read -r -d '' keyfile; do
    local perms
    perms=$(_perms "$keyfile")
    if [[ "$perms" != "600" ]]; then
      errors+=("$(basename "$keyfile") is $perms (expected 600)")
    fi
  done < <(find "$HOME/.ssh" -maxdepth 1 -name 'id_*' ! -name '*.pub' -print0 2>/dev/null)

  if [[ ${#errors[@]} -gt 0 ]]; then
    printf '%s\n' "${errors[@]}"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Test 6: No deprecated Homebrew entries
# ---------------------------------------------------------------------------
test_brew_no_deprecated() {
  if ! command -v brew &>/dev/null; then
    echo "brew not found"
    return 1
  fi
  local err_count=0
  local brewfiles=("$DOTFILES_DIR/install/Brewfile")
  local host_brewfile
  host_brewfile="$DOTFILES_DIR/install/Brewfile.$(hostname -s)"
  [[ -f "$host_brewfile" ]] && brewfiles+=("$host_brewfile")

  for bf in "${brewfiles[@]}"; do
    local output
    output=$(brew bundle check --verbose --file="$bf" 2>&1)
    if echo "$output" | grep -qi 'deprecated\|disabled'; then
      echo "Deprecated entries in $(basename "$bf"):"
      echo "$output" | grep -i 'deprecated\|disabled'
      err_count=$((err_count + 1))
    fi
  done
  return "$err_count"
}

# ---------------------------------------------------------------------------
# Test 7: VS Code extensions sync (laptop only)
# ---------------------------------------------------------------------------
test_vscode_extensions() {
  local laptop_brewfile="$DOTFILES_DIR/install/Brewfile.laptop"
  if [[ ! -f "$laptop_brewfile" ]]; then
    echo "Brewfile.laptop not found"
    return 1
  fi
  if ! command -v code &>/dev/null; then
    echo "code CLI not found"
    return 1
  fi

  # Extract extension IDs from Brewfile.laptop (vscode "publisher.name" lines)
  local expected_exts
  expected_exts=$(grep -E '^vscode "' "$laptop_brewfile" | sed 's/vscode "//; s/"//' | tr '[:upper:]' '[:lower:]' | sort)

  # Installed extensions (lowercased — code outputs mixed case)
  local installed_exts
  installed_exts=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort)

  local missing=()
  local extra=()

  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    if ! echo "$installed_exts" | grep -qi "^${ext}$"; then
      missing+=("$ext")
    fi
  done <<< "$expected_exts"

  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    if ! echo "$expected_exts" | grep -qi "^${ext}$"; then
      extra+=("$ext")
    fi
  done <<< "$installed_exts"

  local err_count=0
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Extensions in Brewfile.laptop but NOT installed:"
    printf '  %s\n' "${missing[@]}"
    err_count=$((err_count + 1))
  fi
  if [[ ${#extra[@]} -gt 0 ]]; then
    echo "Extensions installed but NOT in Brewfile.laptop:"
    printf '  %s\n' "${extra[@]}"
    err_count=$((err_count + 1))
  fi
  return "$err_count"
}

# ---------------------------------------------------------------------------
# Test 8: Mise audit (doctor, PATH conflicts, Homebrew overlaps)
# ---------------------------------------------------------------------------
test_mise_audit() {
  local audit_script="$DOTFILES_DIR/bin/mise-audit"
  if [[ ! -x "$audit_script" ]]; then
    echo "bin/mise-audit not found or not executable"
    return 1
  fi
  if ! command -v mise &>/dev/null; then
    echo "mise not found"
    return 1
  fi
  # mise-audit exits with issue count (0 = clean)
  bash "$audit_script" 2>&1
}

# ---------------------------------------------------------------------------
# Test 9: Repository-managed Codex MCP policy
# ---------------------------------------------------------------------------
test_codex_config_policy() {
  "$DOTFILES_DIR/bin/codex-config" check \
    --config "$DOTFILES_DIR/codex/config.toml" \
    --policy "$DOTFILES_DIR/codex/policy.toml"
}

# ---------------------------------------------------------------------------
# Test 10: LLM agent commit signing (.zsh/functions/llm-agent-signing.zsh)
# ---------------------------------------------------------------------------
# The zsh wrappers and Codex's [shell_environment_policy.set] must carry the same
# GIT_CONFIG_* entries; the wrapper must keep inherited entries, append its own and
# not append twice when one agent starts another.
test_llm_agent_signing() {
  local fn="$DOTFILES_DIR/.zsh/functions/llm-agent-signing.zsh"
  local zsh_pairs toml_pairs out expected
  zsh_pairs=$(zsh -f -c 'source "$1"; for k v in "${LLM_AGENT_SIGNING_CONFIG[@]}"; do print -r -- "$k=$v"; done' _ "$fn") || return 1
  toml_pairs=$(mise exec --no-deps python@3.13 -- python -c '
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    s = tomllib.load(f)["shell_environment_policy"]["set"]
for i in range(int(s["GIT_CONFIG_COUNT"])):
    print(s[f"GIT_CONFIG_KEY_{i}"] + "=" + s[f"GIT_CONFIG_VALUE_{i}"])
' "$DOTFILES_DIR/codex/config.toml") || return 1
  if [[ "$zsh_pairs" != "$toml_pairs" ]]; then
    echo "codex/config.toml GIT_CONFIG_* differ from LLM_AGENT_SIGNING_CONFIG:"
    diff <(echo "$zsh_pairs") <(echo "$toml_pairs")
    return 1
  fi

  if [[ ! -r "$HOME/.ssh/llm_agents_signing.pub" ]]; then
    echo "agent key absent: parity checked, wrapper behaviour not checked"
    return 0
  fi
  # One inherited entry (as Copilot CLI adds), then a nested wrapper call.
  local probe='echo $GIT_CONFIG_COUNT $GIT_CONFIG_KEY_0 $GIT_CONFIG_KEY_1; git config --get user.signingkey'
  out=$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor GIT_CONFIG_VALUE_0=false \
    FN="$fn" PROBE="$probe" zsh -f -c '
      source "$FN"
      llm-agent-signing-exec zsh -f -c '\''source "$FN"; llm-agent-signing-exec sh -c "$PROBE"'\''
    ')
  expected="6 core.fsmonitor gpg.format
$HOME/.ssh/llm_agents_signing.pub"
  if [[ "$out" != "$expected" ]]; then
    printf 'wrapper output:\n%s\nexpected:\n%s\n' "$out" "$expected"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test 11: Functions work in agent shells (no single-underscore helpers)
# ---------------------------------------------------------------------------
# Claude Code runs commands in a shell rebuilt from a snapshot of your functions, and
# the snapshot leaves out every function whose name starts with a single underscore
# (it keeps __-prefixed ones). A function in .zsh/functions that calls such a helper is
# captured without the helper and fails there with "command not found". This is how
# `claude` broke in agent shells after llm-agent-signing.zsh added
# _llm_agent_signing_exec: the test above runs under `zsh -f`, where the helper exists.
# Completion functions registered with `compdef` are exempt.
test_agent_shell_helpers() {
  local dir="$DOTFILES_DIR/.zsh/functions" helper hits bad=0
  local -a helpers
  while IFS= read -r helper; do
    [[ -n "$helper" ]] && helpers+=("$helper")
  done < <(grep -hoE '^[[:space:]]*(function[[:space:]]+)?_[A-Za-z][A-Za-z0-9_-]*[[:space:]]*\(\)' "$dir"/*.zsh \
             | sed -E 's/^[[:space:]]*(function[[:space:]]+)?//; s/[[:space:]]*\(\)$//' | sort -u)
  for helper in "${helpers[@]+"${helpers[@]}"}"; do
    if grep -qE "^[[:space:]]*compdef([[:space:]].*)?[[:space:]]$helper([[:space:]]|$)" "$dir"/*.zsh; then
      continue
    fi
    # Every non-comment reference other than the definition itself.
    hits=$(grep -nE "(^|[^A-Za-z0-9_-])$helper([^A-Za-z0-9_-]|$)" "$dir"/*.zsh \
             | grep -vE "^[^:]+:[0-9]+:[[:space:]]*#" \
             | grep -vE "^[^:]+:[0-9]+:[[:space:]]*(function[[:space:]]+)?$helper[[:space:]]*\(\)")
    if [[ -n "$hits" ]]; then
      echo "$helper is dropped from Claude Code's shell snapshot but is used by:"
      echo "${hits//$DOTFILES_DIR\//}" | sed 's/^/  /'
      bad=1
    fi
  done
  return "$bad"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo ""
echo "${BOLD}Dotfiles Drift Detection Suite${RESET}"
echo "${BOLD}==============================${RESET}"
echo ""

if [[ "${1:-}" == "--only" && "${2:-}" == "codex" ]]; then
  run_test "Codex MCP config policy" test_codex_config_policy
  exit "$FAIL"
fi

if [[ "${1:-}" == "--only" && "${2:-}" == "agent-shell" ]]; then
  run_test "Functions work in agent shells"  test_agent_shell_helpers
  exit "$FAIL"
fi

run_test "Shell startup time < 2s"         test_shell_startup
run_test "No secrets in tracked files"     test_no_secrets
run_test "Codex MCP config policy"          test_codex_config_policy
run_test "LLM agent commit signing"        test_llm_agent_signing
run_test "Functions work in agent shells"  test_agent_shell_helpers

if command -v brew &>/dev/null; then
  run_test "Brewfile consistency"          test_brewfile_consistency
else
  skip_test "Brewfile consistency"         "brew not installed"
fi

run_test "Dotfiles sync (symlinks)"        test_dotfiles_sync
run_test "SSH permissions"                 test_ssh_permissions

if command -v brew &>/dev/null; then
  run_test "No deprecated brew entries"    test_brew_no_deprecated
else
  skip_test "No deprecated brew entries"   "brew not installed"
fi

if command -v code &>/dev/null && [[ -f "$DOTFILES_DIR/install/Brewfile.laptop" ]]; then
  run_test "VS Code extensions sync"       test_vscode_extensions
else
  skip_test "VS Code extensions sync"      "code CLI or Brewfile.laptop not found"
fi

if command -v mise &>/dev/null; then
  run_test "Mise audit"                    test_mise_audit
else
  skip_test "Mise audit"                   "mise not installed"
fi

echo ""
echo "${BOLD}Results:${RESET} ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET}, ${YELLOW}${SKIP} skipped${RESET}"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo ""
  echo "${RED}Failures:${RESET}"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
fi

echo ""
exit "$FAIL"
