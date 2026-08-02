# ~/.zshrc - Cleaned and Optimized Configuration
# Generated: 2026-02-19

# --- Interactive TTY safety tweaks (only when interactive) ---
if [[ -o interactive ]] && [[ -t 0 ]]; then
  stty -tostop 2>/dev/null    # Don't stop bg jobs on output
  stty susp undef 2>/dev/null # Disable ^Z suspend
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

# Option names are case- and underscore-insensitive: SHARE_HISTORY == share_history.
# inc_append_history is deliberately NOT set — zshoptions states it "should be turned
# off" when share_history is in effect, which already appends incrementally.
# hist_ignore_dups is likewise omitted: hist_ignore_all_dups below is a strict superset.
setopt share_history          # append + import live across all tabs
setopt extended_history       # Save timestamp + duration
setopt hist_ignore_all_dups   # Remove older duplicate anywhere in history (not just consecutive)
setopt hist_ignore_space      # Ignore commands starting with space
setopt hist_reduce_blanks     # Remove extra blanks
setopt hist_expire_dups_first # Expire duplicates first when history is full

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

# --- Priority 2.5: Mise shims (before Homebrew so mise-managed tools always win) ---
# Shims here cover: initial shell load before `mise activate` runs, non-interactive
# subshells, and scripts. `mise activate` will prepend installs/ paths at first prompt.
[[ -d "$HOME/.local/share/mise/shims" ]] && path+=("$HOME/.local/share/mise/shims")

# --- Priority 3: Homebrew ---
path+=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/opt/homebrew/opt/curl/bin"
  "/opt/homebrew/opt/openssl@3/bin"
  "/opt/homebrew/opt/grep/libexec/gnubin"
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
#   "/opt/homebrew/opt/php@8.3/sbin"o
# )

# Database clients — guard against non-existent paths
for _mysqlv in 8.4 8.0; do
  [[ -d "/opt/homebrew/opt/mysql@${_mysqlv}/bin" ]] &&
    path+=("/opt/homebrew/opt/mysql@${_mysqlv}/bin")
  [[ -d "/opt/homebrew/opt/mysql-client@${_mysqlv}/bin" ]] &&
    path+=("/opt/homebrew/opt/mysql-client@${_mysqlv}/bin")
done
unset _mysqlv

# Work tools
[[ -d "$HOME/scripts/tasks/bin" ]] && path+=("$HOME/scripts/tasks/bin")

if [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi

# --- Priority 6: Package managers (LAST - cannot shadow above) ---
# PNPM - APPENDED not prepended
#export PNPM_HOME="$HOME/Library/pnpm"
#path+=("$PNPM_HOME")

# Bun — managed by mise; BUN_INSTALL is kept for bun's own use (completions, etc.)
# but the binary path is NOT added to PATH — mise shims handle resolution.
export BUN_INSTALL="$HOME/.bun"

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

# --- Performance tool aliases (rg/fd/pigz wrappers) ---
if command -v rg >/dev/null 2>&1; then
  # rg is NOT a drop-in grep. Two grep short flags collide with rg flags that take
  # a VALUE, so passing them through consumes the next argument:
  #   grep -E     (ERE)         -> rg -E is --encoding VALUE  (rg is ERE by default)
  #   grep -r/-R  (recursive)   -> rg -r is --replace VALUE   (rg recurses by default)
  # -E fails loudly ("unknown encoding"); -r fails SILENTLY — `grep -r hello .`
  # became `rg --replace hello .`, printing substituted text with exit 0.
  # Both must also be stripped from clustered short flags (-iE, -rn, ...), which rg
  # does split. -F needs no translation: rg supports --fixed-strings natively.
  grep() {
    local -a args
    local arg rest
    local endopts=0
    for arg in "$@"; do
      if (( endopts )); then
        args+=("$arg")
        continue
      fi
      case "$arg" in
      --)
        endopts=1
        args+=("$arg")
        ;;
      -E | --extended-regexp | -r | -R | --recursive) ;;
      -[A-Za-z]*)
        rest="${${arg#-}//[ErR]/}"
        [[ -n "$rest" ]] && args+=("-$rest")
        ;;
      *) args+=("$arg") ;;
      esac
    done
    # --no-ignore --hidden: rg skips .gitignore'd and dotfiles by default, so a
    # bare `grep -r secret .` found 1 of 3 matching files and looked successful.
    # A function named grep must not silently under-report. Use `rg`/`search`
    # directly when the gitignore-aware behaviour is what you want.
    command rg --no-ignore --hidden "${args[@]}"
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
  gzip() { command pigz "$@"; }
  gunzip() { command pigz -d "$@"; }
  zcat() { command pigz -dc "$@"; }
  alias oldgzip='command gzip'
  alias oldzcat='command zcat'
fi

# --- Completions with cache optimization ---
if [[ -d "$HOME/.local/share/zsh" ]]; then
  fpath+=("$HOME/.local/share/zsh")
fi
fpath=("$HOME/.zsh-complete" $fpath)

# --- Zsh completion cache configuration ---
export ZSH_CACHE_DIR="$HOME/.zsh/cache"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"

# compinit: -u skips insecure-dir check (Homebrew/OrbStack group-writable fpath dirs).
# Rebuild cache only when dump is missing or older than 24h; otherwise use -C fast path.
autoload -Uz compinit
if [[ -n $ZSH_COMPDUMP(#qN.mh-24) ]]; then
  compinit -u -C -d "$ZSH_COMPDUMP"
else
  compinit -u -d "$ZSH_COMPDUMP"
fi

# --- Activate mise (hook-based PATH management for all managed tools) ---
eval "$(mise activate zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- Starship prompt ---
export STARSHIP_CONFIG=~/.config/starship-minimal.toml
eval "$(starship init zsh)"

# --- worktrunk (must load after compinit) ---
if command -v wt >/dev/null 2>&1;
 then eval "$(command wt config shell init zsh)";
fi

# Suppress punycode deprecation noise from legacy npm packages.
# Scoped to --no-deprecation rather than blanket silencing so real warnings surface.
# Remove once upstream packages (e.g. inflight, glob) ship Node 22-compatible versions.
export NODE_OPTIONS="--no-deprecation"
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# Fix Ghostty bracketed paste: prevents ~ delay and M-on-Enter
# Keep near the end — re-registers the bracketed-paste widget after the zle
# widgets installed above. atuin binds ^R in its init at the end of this file.
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic



eval "$(COMPLETE=zsh prek)"

# --- zoxide completions (must load after compinit) ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# --- atuin (shell history; binds ^R) ---
# Guarded like the other integrations above: unguarded, a missing or broken atuin
# prints an error on every prompt. Install is mise-managed — never via
# setup.atuin.sh, which silently writes AI-agent hooks into ~/.claude and ~/.codex.
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

