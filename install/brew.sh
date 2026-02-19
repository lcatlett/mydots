# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install all packages, casks, and vscode extensions from Brewfile
brew bundle install --file="$DOTFILES_DIR/install/Brewfile"

brew cleanup

echo "Success! Brew applications are installed."
