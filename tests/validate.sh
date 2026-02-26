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
  brew bundle check --file="$DOTFILES_DIR/install/Brewfile" 2>&1
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

  # ~/.ssh/config must be 600
  if [[ -f "$HOME/.ssh/config" ]]; then
    local config_perms
    config_perms=$(stat -f '%A' "$HOME/.ssh/config")
    if [[ "$config_perms" != "600" ]]; then
      errors+=("~/.ssh/config is $config_perms (expected 600)")
    fi
  fi

  # Private keys must be 600 (skip .pub files)
  while IFS= read -r -d '' keyfile; do
    local perms
    perms=$(stat -f '%A' "$keyfile")
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
  local output
  output=$(brew bundle check --verbose --file="$DOTFILES_DIR/install/Brewfile" 2>&1)
  # Check for deprecation warnings
  if echo "$output" | grep -qi 'deprecated\|disabled'; then
    echo "Deprecated entries found:"
    echo "$output" | grep -i 'deprecated\|disabled'
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Test 7: Mise audit (doctor, PATH conflicts, Homebrew overlaps)
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
# Main
# ---------------------------------------------------------------------------
echo ""
echo "${BOLD}Dotfiles Drift Detection Suite${RESET}"
echo "${BOLD}==============================${RESET}"
echo ""

run_test "Shell startup time < 2s"         test_shell_startup
run_test "No secrets in tracked files"     test_no_secrets

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
