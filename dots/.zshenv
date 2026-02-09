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

