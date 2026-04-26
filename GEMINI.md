# GEMINI.md — Dotfiles (Apple Silicon macOS)

Personal macOS dotfiles optimized for Apple Silicon (M-series) with a focus on PHP/Drupal and modern CLI tooling.

## Project Overview

This repository automates the bootstrapping and ongoing synchronization of a macOS development environment. It follows a "no-magic" philosophy, using standard symlinks and a clean split between tool managers.

- **Purpose:** Provision a fresh Mac and keep configuration files synced via git.
- **Architecture:** 
    - **`mise` (Primary):** Manages language runtimes (Node, Python, PHP, Go, Rust) and ~50+ CLI tools.
    - **Homebrew (Secondary):** Reserved for system libraries, GUI apps (casks), and items unavailable in `mise`.
    - **`dotfiles` CLI:** A custom bash entry point for managing the lifecycle (install, update, sync).
- **Core Stack:** Zsh, Ghostty/iTerm2, Starship, Zoxide, Fzf, Delta (git pager).

## Building and Running

### First-Time Bootstrap
```bash
# 1. Install Xcode Command Line Tools
xcode-select --install

# 2. Clone the repository
git clone https://github.com/lcatlett/mydots ~/dotfiles

# 3. Run the automated installer
~/dotfiles/bin/dotfiles install
```

### Management Commands
The `dotfiles` CLI (`bin/dotfiles`) is the primary interface for system maintenance:

- `dotfiles update`: Updates macOS, Homebrew, and `mise` tools.
- `dotfiles symlinks`: Re-runs the symlink creation from `dots/` to `~/`.
- `dotfiles brew`: Re-runs the Homebrew bundle installation from `install/Brewfile`.
- `dotfiles defaults`: Re-applies macOS system defaults and Dock configuration.
- `dotfiles clean`: Cleans up Homebrew caches.

### Validation
Run the drift detection suite to ensure the system state matches the repository:
```bash
bash tests/validate.sh
```
This suite checks for broken symlinks, secrets in tracked files, shell startup time (< 2s), and Brewfile consistency.

## Shell Architecture

The Zsh environment is modular and optimized for speed (< 300ms startup).

### Startup Sequence (`.zshrc`)
1. **`.exports`**: Environment variables (EDITOR, API tokens). *Note: This file is gitignored; use `.exports.template` as a base.*
2. **`.aliases`**: Shell aliases.
3. **`~/.zsh/functions/*.zsh`**: Auto-sources all modular function files.
4. **PATH Construction**: Prioritizes `mise` shims -> `~/bin` -> `Homebrew` -> `System`.
5. **Tool Init**: `mise activate`, `zoxide init`, `starship init`.

### Key Paths
- **Config Source:** `~/dotfiles/dots/`
- **Script Source:** `~/dotfiles/bin/` (Symlinked to `~/bin/`)
- **Global Tool Config:** `~/dotfiles/mise/config.toml` (Symlinked to `~/.config/mise/config.toml`)

## Development Conventions

- **Symlink Pattern:** Use `ln -sfv` in `install/symlinks.sh` to map repository files to the home directory.
- **Adding Scripts:** New scripts should be added to `bin/` and registered in the `install/symlinks.sh` loop.
- **Adding Functions:** Drop modular `.zsh` files into `.zsh/functions/` for automatic discovery.
- **PATH Management:** **Never** add PATH assignments to `.exports`. All PATH logic belongs in `.zshrc`.
- **Git Discipline:**
    - Always use feature branches (kebab-case).
    - Never commit directly to `master`.
    - Use Conventional Commits (e.g., `feat:`, `fix:`, `chore:`).
    - Run `zsh -n <file>` or `bash -n <file>` to syntax-check scripts before committing.
- **Secrets Policy:** Never commit credentials. Keep them in `.exports` (gitignored).
