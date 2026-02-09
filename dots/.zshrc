# ~/.zshrc - Cleaned and Optimized Configuration
# Generated: $(date +"%Y-%m-%d %H:%M:%S")

# --- Bootstrap PATH (ensures basic commands work during shell init) ---
# This minimal PATH is set early so that shadow detection and other init code
# can use basic utilities. The full PATH is constructed later with proper priorities.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# --- Interactive TTY safety tweaks (only when interactive) ---
if [[ -o interactive ]] && [[ -t 0 ]]; then
  stty -tostop 2>/dev/null      # Don't stop bg jobs on output
  stty susp undef 2>/dev/null   # Disable ^Z suspend
fi



# --- Powerlevel10k instant prompt ---


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
  "/usr/local/opt/curl/bin"
  "/usr/local/opt/openssl@3/bin"
)

# --- Priority 4: System paths ---
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

# --- Priority 5: Language-specific tools ---
# Cargo/Rust
path+=("$HOME/.cargo/bin")

# Go
export GOPATH="$HOME/go"
#export GOROOT="$(brew --prefix golang 2>/dev/null)/libexec"
[[ -n "$GOROOT" && -d "$GOROOT" ]] && path+=("$GOPATH/bin" "$GOROOT/bin")

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

# --- Priority 6: Package managers (LAST - cannot shadow above) ---
# PNPM - APPENDED not prepended
#export PNPM_HOME="$HOME/Library/pnpm"
#path+=("$PNPM_HOME")

# Bun

export PATH

# --- McFly ---
eval "$(mcfly init zsh)"


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

# --- Bun completion ---


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
#eval "$(zoxide init zsh)"

# --- Powerlevel10k theme ---
#source ~/powerlevel10k/powerlevel10k.zsh-theme
#[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#eval "$(starship init zsh)"

# --- Zsh completion cache configuration ---
export ZSH_CACHE_DIR="$HOME/.zsh/cache"
mkdir -p "$ZSH_CACHE_DIR"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"

# --- Final PATH export and deduplication ---
typeset -U path
export PATH

eval "$(mise activate zsh)"


# --- Claude Code (runs in tmux to work around macOS PTY bug) ---
alias claude='claude-safe'
alias cc='claude-safe'
# Direct access to raw claude if needed (will have TUI issues outside tmux)
alias claude-raw='/opt/homebrew/bin/claude'

# bun completions
[ -s "/Users/lindseycatlett/.bun/_bun" ] && source "/Users/lindseycatlett/.bun/_bun"

# bun
#export BUN_INSTALL="$HOME/.bun"
#export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='bun "/Users/lindseycatlett/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Fix mise wrapper bugs - use mise exec for reliable execution
alias npm='mise exec -- npm'
alias npx='mise exec -- npx'
alias php='mise exec -- php'
alias composer='mise exec -- composer'

# 1. Point to your custom config file
export STARSHIP_CONFIG=~/.config/starship-minimal.toml

# 2. Initialize Starship
eval "$(starship init zsh)"

# 3. Transient Prompt Logic
# This makes previous prompts disappear, leaving only the '❯' symbol
function starship_zle-keymap-select {
  zle reset-prompt
}
zle -N starship_zle-keymap-select

starship_precmd() {
  # If the prompt contains our '❯' symbol, replace it with a clean version after Enter
  [[ $PS1 == *'❯'* ]] && export PS1="[❯](bold green) "
}
add-zsh-hook precmd starship_precmd


# Theme Swapper



# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.local/bin/env"
