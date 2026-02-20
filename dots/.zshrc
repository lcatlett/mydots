# ~/.zshrc - Cleaned and Optimized Configuration
# Generated: 2026-02-19

# --- Interactive TTY safety tweaks (only when interactive) ---
if [[ -o interactive ]] && [[ -t 0 ]]; then
  stty -tostop 2>/dev/null      # Don't stop bg jobs on output
  stty susp undef 2>/dev/null   # Disable ^Z suspend
fi

# --- Load modular config files if present ---
for file in ~/.{exports,aliases}; do
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
#   2. ~/.local/bin             - Direct installs
#   3. Homebrew                 - System packages
#   4. System paths             - /usr/bin, etc.
#   5. Language-specific        - Go, PHP, Rust, etc.
#   6. Package managers (LAST)  - pnpm, bun (can't shadow above)
# ==============================================================================

typeset -U path

# --- Priority 1-2: Your overrides and direct installs ---
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
)

# --- Priority 3: Homebrew ---
path+=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/opt/homebrew/opt/curl/bin"
  "/usr/local/opt/curl/bin"
  "/opt/homebrew/opt/openssl@3/bin"
  "/usr/local/opt/openssl@3/bin"
)

# --- Priority 4: System paths ---
path+=(
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
)


# --- Priority 5: Language-specific tools ---
# Cargo/Rust
path+=("$HOME/.cargo/bin")

# Go
export GOPATH="$HOME/go"
path+=("$GOPATH/bin")

# Composer
export COMPOSER_MEMORY_LIMIT=-1
# path+=("$HOME/.composer/vendor/bin")

# # PHP versions
# path+=(
#   "/opt/homebrew/opt/php@8.1/bin"
#   "/opt/homebrew/opt/php@8.1/sbin"
#   "/opt/homebrew/opt/php@8.3/bin"
#   "/opt/homebrew/opt/php@8.3/sbin"
# )

# Database clients — guard against non-existent paths
for _mysqlv in 8.4 8.0; do
  [[ -d "/opt/homebrew/opt/mysql@${_mysqlv}/bin" ]] && \
    path+=("/opt/homebrew/opt/mysql@${_mysqlv}/bin")
  [[ -d "/opt/homebrew/opt/mysql-client@${_mysqlv}/bin" ]] && \
    path+=("/opt/homebrew/opt/mysql-client@${_mysqlv}/bin")
done
unset _mysqlv

# Work tools
[[ -d "$HOME/scripts/tasks/bin" ]] && path+=("$HOME/scripts/tasks/bin")
#path+=("$HOME/.platform-nestle-cli/bin")

# --- Priority 6: Package managers (LAST - cannot shadow above) ---
# PNPM - APPENDED not prepended
#export PNPM_HOME="$HOME/Library/pnpm"
#path+=("$PNPM_HOME")

# Bun

export PATH


# --- GPG agent handling ---
# GPG agent for commit signing only — SSH auth is handled by macOS launchd agent
# (SSH config: UseKeychain yes + AddKeysToAgent yes handles key loading automatically)
if command -v gpgconf >/dev/null 2>&1 && [[ -z "$SSH_CLIENT" ]]; then
    if ! pgrep -u "$USER" gpg-agent >/dev/null; then
        gpgconf --launch gpg-agent >/dev/null 2>&1 &
    fi
    export GPG_TTY=$(tty)
    # NOTE: SSH_AUTH_SOCK intentionally NOT overridden here.
    # Overriding it with the GPG socket breaks --apple-use-keychain and macOS Keychain integration.
fi

# --- Bun completion ---


# --- Platform.sh Nestlé CLI configuration ---
#[[ -f "$HOME/.platform-nestle-cli/shell-config.rc" ]] && source "$HOME/.platform-nestle-cli/shell-config.rc"


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

# --- Activate mise for CLI tools like zoxide, starship ---
eval "$(mise activate zsh)"
unalias npm 2>/dev/null

# --- zoxide (must load after compinit) ---
eval "$(zoxide init zsh)"


# --- Zsh completion cache configuration ---
export ZSH_CACHE_DIR="$HOME/.zsh/cache"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"

# --- Final PATH export and deduplication ---
typeset -U path
export PATH

# --- Claude Code (runs in tmux to work around macOS PTY bug) ---
#alias claude='claude-safe'
#alias cc='claude-safe'
# Direct access to raw claude if needed (will have TUI issues outside tmux)
#alias claude-raw='/opt/homebrew/bin/claude'

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
#export BUN_INSTALL="$HOME/.bun"
#export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Fix mise wrapper bugs - use mise exec for reliable execution
alias npm='mise exec -- npm'
alias npx='mise exec -- npx'
alias php='mise exec -- php'
alias composer='mise exec -- composer'
alias uv='mise exec -- uv'
alias uvx='mise exec -- uvx'
alias bun='mise exec -- bun'

# --- Starship prompt ---
export STARSHIP_CONFIG=~/.config/starship-minimal.toml
eval "$(starship init zsh)"


# Suppress Node.js deprecation warnings (e.g. punycode)
export NODE_OPTIONS="--no-deprecation"
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
