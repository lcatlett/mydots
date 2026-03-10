#!/usr/bin/env bash
# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Map hostname to Brewfile suffix
case "$(hostname -s)" in
    ghost)  HOST_BREWFILE="ghost" ;;
    *)      HOST_BREWFILE="laptop" ;;
esac

# Install common packages
echo "Installing common Brewfile..."
brew bundle install --file="$DOTFILES_DIR/install/Brewfile"

# Install host-specific packages
if [[ -f "$DOTFILES_DIR/install/Brewfile.$HOST_BREWFILE" ]]; then
    echo "Installing Brewfile.$HOST_BREWFILE..."
    brew bundle install --file="$DOTFILES_DIR/install/Brewfile.$HOST_BREWFILE"
else
    echo "No Brewfile.$HOST_BREWFILE found — skipping."
fi

echo "Success! Brew applications are installed."
