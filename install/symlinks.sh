#!/usr/bin/env bash
# Symlink dot-files from dots/ into ~/
# Run via: dotfiles symlinks  OR  bash install/install.sh

export DOTFILES_DIR
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# ---------------------------------------------------------------------------
# Config files → ~/
# ---------------------------------------------------------------------------
ln -sfv "$DOTFILES_DIR/dots/.exports"         ~
ln -sfv "$DOTFILES_DIR/dots/.aliases"         ~
ln -sfv "$DOTFILES_DIR/dots/.gitconfig"       ~
ln -sfv "$DOTFILES_DIR/dots/.gitignore"       ~
ln -sfv "$DOTFILES_DIR/dots/.gitignore_global" ~
ln -sfv "$DOTFILES_DIR/dots/.inputrc"         ~
ln -sfv "$DOTFILES_DIR/dots/.bash_profile"    ~
ln -sfv "$DOTFILES_DIR/dots/.bashrc"          ~
ln -sfv "$DOTFILES_DIR/dots/.zshrc"           ~
ln -sfv "$DOTFILES_DIR/dots/.profile"         ~
ln -sfv "$DOTFILES_DIR/dots/.editorconfig"    ~

# ---------------------------------------------------------------------------
# mise — tool manager config
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.config/mise"
ln -sfv "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"

# ---------------------------------------------------------------------------
# bin/ scripts → ~/bin/
# ---------------------------------------------------------------------------
mkdir -p ~/bin

for script in \
    audit-system \
    claude-safe \
    code \
    dotfiles \
    dusage \
    gcb \
    hurl \
    image2svg \
    kill-claude \
    mise-audit \
    rename-commit \
    ssh-manager \
    symlink-audit \
    syscheck
do
    ln -sfv "$DOTFILES_DIR/bin/$script" ~/bin/
done
