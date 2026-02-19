#!/usr/bin/env bash
export DOTFILES_DIR EXTRA_DIR
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# include my library helpers for colorized echo and require_brew, etc
. "$DOTFILES_DIR/install/echos.sh"

# Install brew with packages & casks via Brewfile
. "$DOTFILES_DIR/install/brew.sh"

# Bunch of symlinks
. "$DOTFILES_DIR/install/symlinks.sh"

# Setup macos defaults
. "$DOTFILES_DIR/macos/defaults.sh"

# Setup macos defaults (extended)
. "$DOTFILES_DIR/macos/extended.sh"

# Setup dock icons
. "$DOTFILES_DIR/macos/dock.sh"

# Clear cache
. "$DOTFILES_DIR/bin/dotfiles" clean

# Add keys from keychain to ssh agent
ssh-add -A 2>/dev/null;
