# ~/.zshrc - Cleaned and Optimized Configuration
# Generated: $(date +"%Y-%m-%d %H:%M:%S")

# --- Bootstrap PATH (ensures basic commands work during shell init) ---
# This minimal PATH is set early so that shadow detection and other init code
# can use basic utilities. The full PATH is constructed later with proper priorities.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# --- Interactive TTY safety tweaks (only when interactive) ---
if [[ -o interactive ]] && [[ -t 0 ]]; then
  stty -tostop 2>/dev/null
  stty susp undef 2>/dev/null
fi

# ==============================================================================
# CRITICAL TOOL SHADOW DETECTION
# ==============================================================================
# Blocks shell startup if critical tools are shadowed by unexpected sources.
# This prevents silent failures where the wrong version of a tool runs.
#
# To fix: Remove the shadowing binary or adjust PATH order.
# To bypass temporarily: SKIP_SHADOW_CHECK=1 zsh
# ==============================================================================

if [[ -z "$SKIP_SHADOW_CHECK" && -o interactive ]]; then
  _shadow_check_failed=0
  _shadow_errors=()

  # Define expected tool locations
  # Format: "tool_name:expected_path_pattern"
  _expected_tools=(
    "claude:$HOME/.local/bin/claude"
    "gemini:$HOME/.nvm/versions/node/*/bin/gemini"
  )

  for _tool_spec in "${_expected_tools[@]}"; do
    _tool_name="${_tool_spec%%:*}"
    _expected_pattern="${_tool_spec#*:}"

    _actual_path=$(command -v "$_tool_name" 2>/dev/null)

    if [[ -n "$_actual_path" ]]; then
      # Check if actual path matches expected pattern
      if [[ ! "$_actual_path" == ${~_expected_pattern} ]]; then
        _shadow_errors+=("$_tool_name: expected '$_expected_pattern' but found '$_actual_path'")
        _shadow_check_failed=1
      fi
    fi
  done

  if [[ $_shadow_check_failed -eq 1 ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║  ⛔ CRITICAL: Tool shadowing detected - shell startup blocked               ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    for _err in "${_shadow_errors[@]}"; do
      printf "║  %-74s ║\n" "$_err"
    done
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    echo "║  Fix: Remove the shadowing binary or check PATH order in ~/.zshrc           ║"
    echo "║  Bypass: SKIP_SHADOW_CHECK=1 zsh                                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Return to prevent rest of zshrc from loading
    # User gets a minimal shell to fix the issue
    return 1
  fi

  unset _shadow_check_failed _shadow_errors _expected_tools _tool_spec _tool_name _expected_pattern _actual_path _err
fi

# --- Powerlevel10k instant prompt ---
# Re-enable this if Claude Code TUI duplication is resolved
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# --- Load modular config files if present ---
for file in ~/.{exports,aliases,extra}; do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

# --- Load modular function files ---
if [[ -d "$HOME/.zsh/functions" ]]; then
  for func_file in ~/.zsh/functions/*.zsh; do
    [[ -r "$func_file" ]] && source "$func_file"
  done
  unset func_file
fi

# --- History Configuration ---
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt inc_append_history
setopt share_history
setopt extended_history        # Save timestamp
setopt hist_ignore_dups        # Don't save duplicates
setopt hist_ignore_space       # Ignore commands starting with space
setopt hist_reduce_blanks      # Remove extra blanks

# ==============================================================================
# PATH CONSTRUCTION - SINGLE AUTHORITATIVE LOCATION
# ==============================================================================
# Priority order (first wins):
#   1. ~/bin                    - Your explicit overrides (always wins)
#   2. ~/.local/bin             - Direct installs, Claude Code auto-updater
#   3. NVM bin                  - Node tools from your default NVM version
#   4. Homebrew                 - System packages
#   5. System paths             - /usr/bin, etc.
#   6. Language-specific        - Go, PHP, Rust, etc.
#   7. Package managers (LAST)  - pnpm, bun (can't shadow above)
# ==============================================================================

typeset -U path

# --- NVM lazy loader preparation (resolve default version BEFORE PATH construction) ---
export NVM_DIR="$HOME/.nvm"

# Resolve NVM default version for PATH (handles aliases like "22" -> "v22.21.1")
_nvm_default_bin=""
if [[ -d "$NVM_DIR/versions/node" ]]; then
  _nvm_alias=$(/bin/cat "$NVM_DIR/alias/default" 2>/dev/null)
  if [[ -n "$_nvm_alias" ]]; then
    # Try direct match (e.g., "v22.21.1"), then resolve alias (e.g., "22" -> "v22.x.x")
    if [[ -d "$NVM_DIR/versions/node/$_nvm_alias" ]]; then
      _nvm_default_bin="$NVM_DIR/versions/node/$_nvm_alias/bin"
    elif [[ -d "$NVM_DIR/versions/node/v$_nvm_alias" ]]; then
      _nvm_default_bin="$NVM_DIR/versions/node/v$_nvm_alias/bin"
    else
      # Use absolute paths to ensure commands work even with minimal PATH
      _nvm_ver=$(/bin/ls -d "$NVM_DIR/versions/node/v${_nvm_alias}"* 2>/dev/null | /usr/bin/sort -V | /usr/bin/tail -1)
      [[ -d "$_nvm_ver/bin" ]] && _nvm_default_bin="$_nvm_ver/bin"
    fi
  fi
  # Fallback to latest installed version
  if [[ -z "$_nvm_default_bin" ]]; then
    _nvm_latest=$(/bin/ls "$NVM_DIR/versions/node" 2>/dev/null | /usr/bin/sort -V | /usr/bin/tail -1)
    [[ -d "$NVM_DIR/versions/node/$_nvm_latest/bin" ]] && _nvm_default_bin="$NVM_DIR/versions/node/$_nvm_latest/bin"
  fi
fi

# --- Priority 1-2: Your overrides and direct installs ---
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
)

# --- Priority 3: NVM (resolved above) ---
[[ -n "$_nvm_default_bin" ]] && path+=("$_nvm_default_bin")

# --- Priority 4: Homebrew ---
path+=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/usr/local/opt/curl/bin"
  "/usr/local/opt/openssl@3/bin"
)

# --- Priority 5: System paths ---
path+=(
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
)

# --- Pantheon certs + CA ---
export CA_CERT="$HOME/certs/ca.crt"
export PANTHEON_CA_CERT="$HOME/certs/ca.crt"
export PANTHEON_CERT="$HOME/certs/lindsey.catlett@getpantheon.com.pem"
export TERMINUS_HOST_CERT="$HOME/certs/lindsey.catlett@getpantheon.com.pem"

# --- Priority 6: Language-specific tools ---
# Cargo/Rust
path+=("$HOME/.cargo/bin")

# Go
export GOPATH="$HOME/go"
export GOROOT="$(brew --prefix golang 2>/dev/null)/libexec"
[[ -n "$GOROOT" && -d "$GOROOT" ]] && path+=("$GOPATH/bin" "$GOROOT/bin")

# Composer
export COMPOSER_MEMORY_LIMIT=-1
path+=("$HOME/.composer/vendor/bin")

# PHP versions
path+=(
  "/opt/homebrew/opt/php@8.1/bin"
  "/opt/homebrew/opt/php@8.1/sbin"
  "/opt/homebrew/opt/php@8.3/bin"
  "/opt/homebrew/opt/php@8.3/sbin"
)

# PHPVM
export PHPVM_DIR="$HOME/.phpvm"
path+=("$PHPVM_DIR/bin")
[[ -s "$PHPVM_DIR/phpvm.sh" ]] && source "$PHPVM_DIR/phpvm.sh"

# Database clients
path+=(
  "/opt/homebrew/opt/mysql@8.4/bin"
  "/opt/homebrew/opt/mysql-client@8.4/bin"
  "/opt/homebrew/opt/postgresql@15/bin"
)

# Work tools
path+=("$HOME/scripts/tasks/bin")
path+=("$HOME/.antigravity/antigravity/bin")
path+=("$HOME/.platform-nestle-cli/bin")

# --- Priority 7: Package managers (LAST - cannot shadow above) ---
# PNPM - APPENDED not prepended
export PNPM_HOME="$HOME/Library/pnpm"
path+=("$PNPM_HOME")

# Bun
export BUN_INSTALL="$HOME/.bun"
path+=("$BUN_INSTALL/bin")

export PATH

# --- McFly ---
eval "$(mcfly init zsh)"
export MCFLY_FUZZY=2
export MCFLY_INTERFACE_VIEW=BOTTOM

# --- SSH / GPG agent handling ---
# Start ssh-agent and add keys if needed
ssh_agent_init() {
  if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
  fi

  # If no identities are loaded, add them
  if ! ssh-add -l >/dev/null 2>&1; then
    ssh-add --apple-use-keychain ~/.ssh/id_rsa >/dev/null 2>&1
    ssh-add --apple-use-keychain ~/.ssh/id_rsa_migration >/dev/null 2>&1
    ssh-add --apple-use-keychain ~/.ssh/id_rsa_drupalorg >/dev/null 2>&1
  fi
}
ssh_agent_init

# Only run gpg-agent locally (not over SSH)
if [[ -z "$SSH_CLIENT" ]]; then
  gpgconf --launch gpg-agent >/dev/null 2>&1
  if [[ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  fi
  export GPG_TTY="$(tty)"
  echo UPDATESTARTUPTTY | gpg-connect-agent >/dev/null 2>&1
fi

# --- NVM lazy loader functions (prevents slow startup) ---
nvm_loader() {
  unset -f nvm node npm npx
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

nvm()  { nvm_loader; nvm "$@"; }
node() { nvm_loader; node "$@"; }
npm()  { nvm_loader; npm "$@"; }
npx()  { nvm_loader; npx "$@"; }

# --- Bun completion ---
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# --- Platform.sh Nestlé CLI configuration ---
[[ -f "$HOME/.platform-nestle-cli/shell-config.rc" ]] && source "$HOME/.platform-nestle-cli/shell-config.rc"

# --- Claude Code with Vertex AI configuration ---
export CLAUDE_CODE_USE_VERTEX=1
export ANTHROPIC_VERTEX_PROJECT_ID="ai-lindseycatlett-477117"
export CLOUD_ML_REGION="us-east5"

# --- Performance tool aliases (rg/fd/pigz wrappers) ---
if command -v rg >/dev/null 2>&1; then
  grep() {
    local args=()
    local fixed=0
    for arg in "$@"; do
      case "$arg" in
        -E) ;;
        -F) fixed=1 ;;
        *)  args+=("$arg") ;;
      esac
    done
    if [[ $fixed -eq 1 ]]; then
      command rg -F "${args[@]}"
    else
      command rg "${args[@]}"
    fi
  }

  egrep() { grep -E "$@"; }
  fgrep() { grep -F "$@"; }

  alias oldgrep='command grep'
  alias search='rg'
  alias search-logs='rg --type-add "log:*.log*" -t log'
  alias search-code='rg --type-add "code:*.{js,py,sh,php,go}" -t code'
fi

if command -v fd >/dev/null 2>&1; then
  alias find-files='fd --type f'
  alias find-dirs='fd --type d'
  alias find-logs='fd -e log'
  alias oldfind='command find'
  alias ff='fd --type f'
  alias fdir='fd --type d'
fi

if command -v pigz >/dev/null 2>&1; then
  gzip()   { command pigz "$@"; }
  gunzip() { command pigz -d "$@"; }
  zcat()   { command pigz -dc "$@"; }
  alias oldgzip='command gzip'
  alias oldzcat='command zcat'
fi

# --- Completions with cache optimization ---
if [[ -d "$HOME/.local/share/zsh" ]]; then
  fpath+=("$HOME/.local/share/zsh")
fi
fpath=("$HOME/.zsh-complete" $fpath)

autoload -Uz compinit
# Only rebuild cache once per day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# --- zoxide (must load after compinit) ---
eval "$(zoxide init zsh)"

# --- Powerlevel10k theme ---
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Zsh completion cache configuration ---
export ZSH_CACHE_DIR="$HOME/.zsh/cache"
mkdir -p "$ZSH_CACHE_DIR"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"

# --- Final PATH export and deduplication ---
typeset -U path
export PATH
