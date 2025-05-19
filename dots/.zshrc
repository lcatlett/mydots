# ~/.zshrc

# --- Interactive TTY safety tweaks (only when interactive) ---
if [[ -o interactive ]] && [[ -t 0 ]]; then
  stty -tostop 2>/dev/null
  stty susp undef 2>/dev/null
fi

# --- Powerlevel10k instant prompt (must be near top) ---
# Disabled for Claude Code compatibility - causes TUI duplication
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# --- Load modular config files if present ---
for file in ~/.{exports,aliases,functions,extra}; do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

# --- History ---
setopt inc_append_history
setopt share_history

# --- PATH: build once, de-dup, keep your priorities ---
typeset -U path
path=(
  "$HOME/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/usr/local/opt/curl/bin"
  "/usr/local/opt/openssl@3/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  $path
)
export PATH

# --- Pantheon certs + CA ---
export CA_CERT="/Users/lindseycatlett/certs/ca.crt"
export PANTHEON_CA_CERT="/Users/lindseycatlett/certs/ca.crt"
export PANTHEON_CERT="/Users/lindseycatlett/certs/lindsey.catlett@getpantheon.com.pem"
export TERMINUS_HOST_CERT="/Users/lindseycatlett/certs/lindsey.catlett@getpantheon.com.pem"

# --- Go ---
export GOPATH="$HOME/go"
export GOROOT="$(brew --prefix golang 2>/dev/null)/libexec"
if [[ -n "$GOROOT" && -d "$GOROOT" ]]; then
  path+=("$GOPATH/bin" "$GOROOT/bin")
fi

# --- Composer ---
export COMPOSER_MEMORY_LIMIT=-1

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

yubinudge() {
  pkill gpg-agent
  pkill ssh-agent
  pkill pinentry
  gpg-connect-agent updatestartuptty /bye
  gpg --card-status
  ssh-add -L
}

yubitransport() {
  echo "[!] Remove Yubikey from device port."
  if read -q "REPLY?[?] Yubikey is unplugged? [Y/y]: "; then
    pkill gpg-agent
    pkill ssh-agent
    pkill pinentry
    echo -e "\nKilled gpg-agent, ssh-agent, and pinentry"
  else
    eval "$(gpg-agent --daemon --enable-ssh-support)"
  fi

  echo -e "\n[!] Reinsert Yubikey to device port."
  if read -q "REPLY?[?] Yubikey is attached? [Y/y]: "; then
    gpg-connect-agent updatestartuptty /bye
    gpg --card-status
    ssh-add -L
  else
    echo "Not launching GPG-agent"
  fi
}

# --- NVM lazy loader (prevents slow startup) ---
export NVM_DIR="$HOME/.nvm"

# Add NVM bin to PATH for non-shell processes (Python, etc.)
if [[ -d "$NVM_DIR/versions/node" ]]; then
  NVM_DEFAULT=$(cat "$NVM_DIR/alias/default" 2>/dev/null || ls "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -1)
  [[ -d "$NVM_DIR/versions/node/$NVM_DEFAULT/bin" ]] && path+=("$NVM_DIR/versions/node/$NVM_DEFAULT/bin")
fi
nvm_loader() {
  unset -f nvm node npm npx gemini
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

nvm()  { nvm_loader; nvm "$@"; }
node() { nvm_loader; node "$@"; }
npm()  { nvm_loader; npm "$@"; }
npx()  { nvm_loader; npx "$@"; }
gemini() { nvm_loader; gemini "$@"; }

# --- Bun ---
export BUN_INSTALL="$HOME/.bun"
path+=("$BUN_INSTALL/bin")
[[ -s "/Users/lindseycatlett/.bun/_bun" ]] && source "/Users/lindseycatlett/.bun/_bun"

# --- PNPM ---
export PNPM_HOME="/Users/lindseycatlett/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) path=("$PNPM_HOME" $path) ;;
esac

# --- PHPVM ---
export PHPVM_DIR="/Users/lindseycatlett/.phpvm"
path+=("$PHPVM_DIR/bin")
[[ -s "$PHPVM_DIR/phpvm.sh" ]] && source "$PHPVM_DIR/phpvm.sh"

# --- MySQL paths (pick what you want active; keeping your latest) ---
path+=(
  "/opt/homebrew/opt/mysql@8.4/bin"
  "/opt/homebrew/opt/mysql-client@8.4/bin"
)

# --- PHP paths (keeping your latest selections) ---
path+=(
  "/opt/homebrew/opt/php@8.1/sbin"
  "/opt/homebrew/opt/php@8.3/bin"
  "/opt/homebrew/opt/php@8.3/sbin"
)

# --- Agentic Control Framework path ---
path+=("/Users/lindseycatlett/scripts/tasks/bin")

# --- Antigravity ---
path+=("/Users/lindseycatlett/.antigravity/antigravity/bin")

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
        -E) ;;          # rg default is regex
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

# --- Completions (RUN ONCE) ---
# If you have custom completion scripts:
if [[ -d "$HOME/.local/share/zsh" ]]; then
  fpath+=("$HOME/.local/share/zsh")
fi
fpath=("$HOME/.zsh-complete" $fpath)

autoload -Uz compinit
compinit

# --- zoxide (must load after compinit) ---
# Disabled - install with: brew install zoxide
# eval "$(zoxide init zsh)"

# --- Powerlevel10k theme (keep near end) ---
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Platform.sh Nestlé CLI configuration ---
HOME=${HOME:-'/Users/lindseycatlett'}
export PATH="$HOME/.platform-nestle-cli/bin:$PATH"
if [[ -f "$HOME/.platform-nestle-cli/shell-config.rc" ]]; then
  source "$HOME/.platform-nestle-cli/shell-config.rc"
fi

# --- Final PATH export (after adding to `path` array) ---
typeset -U path
export PATH
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"

# Zsh completion cache configuration
# Added by cleanup script on Sat Dec 27 21:57:06 EST 2025
export ZSH_CACHE_DIR="$HOME/.zsh/cache"
mkdir -p "$ZSH_CACHE_DIR"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"
