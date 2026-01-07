# ~/.zshenv - Environment for ALL zsh instances (login, interactive, scripts)
# CRITICAL: This file runs BEFORE .zprofile and .zshrc
# Keep this minimal and ensure PATH has basics before using external commands

# ==============================================================================
# BOOTSTRAP: Ensure minimal PATH exists FIRST
# ==============================================================================
# Some environments (certain terminal apps, cron, launchd) start with empty PATH
# We need /usr/bin and /bin available before we can use sort, tail, ls, etc.

if [[ -z "$PATH" ]] || [[ "$PATH" != *"/usr/bin"* ]]; then
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
fi

# Add Homebrew early (needed for many tools)
[[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# ==============================================================================
# CARGO/RUST
# ==============================================================================
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# ==============================================================================
# NVM - Add default Node to PATH for non-interactive shells
# ==============================================================================
# This enables Claude Code, scripts, and other non-interactive contexts to find node/npm
export NVM_DIR="$HOME/.nvm"

if [[ -d "$NVM_DIR/versions/node" ]]; then
  # Read default alias (could be "22", "lts/*", or full version)
  NVM_ALIAS=$(/bin/cat "$NVM_DIR/alias/default" 2>/dev/null)
  
  # Resolve alias to actual version directory
  if [[ -n "$NVM_ALIAS" ]]; then
    # Try direct match first (e.g., "v22.21.1")
    if [[ -d "$NVM_DIR/versions/node/$NVM_ALIAS" ]]; then
      NVM_DEFAULT="$NVM_ALIAS"
    # Try with v prefix
    elif [[ -d "$NVM_DIR/versions/node/v$NVM_ALIAS" ]]; then
      NVM_DEFAULT="v$NVM_ALIAS"
    # Resolve major version alias (e.g., "22" -> "v22.x.x")
    # Use absolute paths to ensure commands work even with minimal PATH
    else
      NVM_DEFAULT=$(/bin/ls -d "$NVM_DIR/versions/node/v${NVM_ALIAS}"* 2>/dev/null | /usr/bin/sort -V | /usr/bin/tail -1 | /usr/bin/xargs basename 2>/dev/null)
    fi
  fi
  
  # Fallback to latest installed version
  if [[ -z "$NVM_DEFAULT" ]]; then
    NVM_DEFAULT=$(/bin/ls "$NVM_DIR/versions/node" 2>/dev/null | /usr/bin/sort -V | /usr/bin/tail -1)
  fi
  
  # Add to PATH if valid
  if [[ -d "$NVM_DIR/versions/node/$NVM_DEFAULT/bin" ]]; then
    export PATH="$NVM_DIR/versions/node/$NVM_DEFAULT/bin:$PATH"
  fi
fi
