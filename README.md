# Dotfiles

Personal dotfiles for macOS (Apple Silicon) — PHP/Drupal web development setup.

![iTerm2.app](https://raw.githubusercontent.com/lcatlett/mydots/master/screenshot.png)

## What's in Here

- **Shell**: zsh with modular function files (`~/.zsh/functions/*.zsh`)
- **Prompt**: [Starship](https://starship.rs/) with minimal config
- **Tools**: Managed by [mise](https://mise.jdx.dev/) — node, python, php, go, bun, and 40+ CLI tools
- **Git**: delta pager, extensive aliases, modern defaults
- **Key files**: `.zshrc`, `.exports`, `.aliases`, `.gitconfig`, `.gitignore_global`

## Tool Management

All language runtimes and developer CLI tools are managed by **mise** (not Homebrew, not nvm/pyenv).

```bash
# See installed tools
mise ls

# Install a tool globally
mise use --global node@latest

# Health check
mise doctor
```

Config: `~/.config/mise/config.toml`

## Installation

```bash
# Clone
git clone https://github.com/lcatlett/mydots ~/dotfiles

# Run install script (symlinks dots/ files to ~/)
cd ~/dotfiles && bash install/install.sh

# Install Homebrew (Apple Silicon)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install mise
curl https://mise.run | sh
mise install
```

## Structure

| Path | Purpose |
|------|---------|
| `dots/` | Symlinked config files (`.zshrc`, `.aliases`, `.exports`, `.gitconfig`, etc.) |
| `.zsh/functions/` | Modular zsh function files (dev, filesystem, gcloud, network) |
| `bin/` | Personal scripts added to `~/bin` |
| `install/` | Install scripts and Brewfile |
| `macos/` | macOS defaults and Dock config |
| `iterm/` | iTerm2 profile |
| `editors/` | Editor configs |

## Notable Tools

- **[delta](https://github.com/dandavison/delta)** — better git diffs
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** — smarter `cd`
- **[starship](https://starship.rs/)** — fast prompt
- **[mise](https://mise.jdx.dev/)** — polyglot tool version manager
- **`ssh-manager`** — SSH key and config management
