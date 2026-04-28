# Mise shims must come before Homebrew — used by GUI apps (Zed, etc.) and
# non-interactive shells that source .zshenv but not .zshrc.
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"
