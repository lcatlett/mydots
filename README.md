# Dotfiles

Personal dotfiles for macOS (Apple Silicon) — PHP/Drupal web development setup.

![iTerm2 shell](https://raw.githubusercontent.com/lcatlett/mydots/master/screenshot.png)

---

## What's in Here

| Component | Details |
|-----------|---------|
| **Shell** | zsh with modular function files (`~/.zsh/functions/*.zsh`) |
| **Prompt** | [Starship](https://starship.rs/) — fast, minimal, git-aware |
| **Tool manager** | [mise](https://mise.jdx.dev/) — replaces nvm, pyenv, rbenv, and most Homebrew CLIs |
| **Search** | History: [McFly](https://github.com/cantino/mcfly) · Directory: [zoxide](https://github.com/ajeetdsouza/zoxide) |
| **Git pager** | [delta](https://github.com/dandavison/delta) — syntax-highlighted diffs with side-by-side mode |
| **Key config files** | `.zshrc`, `.exports`, `.aliases`, `.gitconfig`, `.gitignore_global` |

---

## Why mise?

Most developers have separate tools for managing different language runtimes:
- `nvm` or `fnm` for Node.js
- `pyenv` for Python
- `rbenv` for Ruby
- Homebrew for everything else

**mise replaces all of them.** It's a single polyglot tool version manager that:

- Installs and switches between language runtimes (Node, Python, Go, PHP, Ruby, etc.)
- Installs CLI tools the same way (ripgrep, delta, starship, jq, etc.)
- Supports **per-project versions** via `.mise.toml` or `.tool-versions` in any directory — so `cd my-project` automatically switches to the right Node/Python version
- Keeps everything in `~/.local/share/mise/installs/` instead of scattered across the system
- Uses a single config file: `~/.config/mise/config.toml`

```bash
# Common mise commands
mise ls                        # List installed tools and versions
mise use --global node@latest  # Install latest Node globally
mise use node@20               # Install Node 20 for current project
mise install                   # Install all tools defined in nearest config
mise doctor                    # Diagnose issues
mise outdated                  # Check for updates
```

The only things that still use Homebrew are macOS GUI apps, system libraries (openssl, libpq), and tools not available in mise.

---

## Installed Tools

### Language Runtimes (via mise)

| Tool | Versions | Notes |
|------|----------|-------|
| Node.js | latest | Via mise; `npm`/`npx` wrapped with `mise exec` |
| Python | 3.11, 3.12, 3.13, 3.14 | Multiple versions for compatibility testing |
| Go | latest | `GOPATH=~/go` |
| PHP | 8.2, 8.3, 8.4 | Via [adwinying/php](https://github.com/adwinying/php) provider |
| Bun | latest | JavaScript runtime + package manager |
| uv | latest | Fast Python package/project manager (replaces pip/venv) |

### Developer CLI Tools (via mise)

| Tool | Purpose |
|------|---------|
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement |
| [fd](https://github.com/sharkdp/fd) | Fast `find` replacement |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder (used in shell completion) |
| [jq](https://jqlang.github.io/jq/) | JSON processor |
| [yq](https://github.com/mikefarah/yq) | YAML/JSON/TOML processor |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast `grep` replacement (aliased as `rg`) |
| [delta](https://github.com/dandavison/delta) | Git diff pager with syntax highlighting |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` — jump to frecent directories |
| [starship](https://starship.rs/) | Fast, customizable shell prompt |
| [direnv](https://direnv.net/) | Auto-load `.envrc` files per directory |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [gum](https://github.com/charmbracelet/gum) | Pretty shell script UI components |
| [glow](https://github.com/charmbracelet/glow) | Render Markdown in the terminal |
| [broot](https://github.com/Canop/broot) | Interactive file tree navigator |
| [gh](https://cli.github.com/) | GitHub CLI |
| [act](https://github.com/nektos/act) | Run GitHub Actions locally |
| [git-cliff](https://github.com/orhun/git-cliff) | Changelog generator |
| [shellcheck](https://www.shellcheck.net/) | Shell script linter |
| [hadolint](https://github.com/hadrolint/hadolint) | Dockerfile linter |
| [hyperfine](https://github.com/sharkdp/hyperfine) | Command benchmarking |
| [dust](https://github.com/bootandy/dust) | Intuitive `du` replacement |
| [duf](https://github.com/muesli/duf) | Better `df` — disk usage |
| [cmake](https://cmake.org/) | Build system |
| [gemini-cli](https://github.com/google-gemini/gemini-cli) | Google Gemini CLI |

### System Packages (via Homebrew)

Homebrew is reserved for things mise can't handle — system libraries, macOS GUI apps, and tools that need deep system integration.

**Libraries / System tools:**
- `gnupg` + `pinentry-mac` — GPG keys and commit signing
- `imagemagick` — Image processing
- `mysql-client` — MySQL CLI (libmysqlclient for PHP extensions)
- `openssl@3`, `curl` — TLS and HTTP
- `git` — Git (system version, delta pager configured separately)
- `rclone` — Cloud storage sync
- `redis` — Local Redis server
- `pigz` — Parallel gzip
- `percona-toolkit` — MySQL analysis tools
- `mcfly` — Shell history search (requires Homebrew for shell integration)

**GUI applications (Homebrew Cask):**
- iTerm2 — Terminal
- Alfred — App launcher
- Sequel Ace — MySQL GUI
- GPG Suite — GPG key management UI
- Google Cloud SDK — `gcloud` CLI

---

## Shell Architecture

```
~/.zshrc                        # Main config — sourced for every interactive shell
~/.exports                      # Environment variables and PATH
~/.aliases                      # Shell aliases
~/.zsh/functions/               # Modular function files (auto-sourced)
    dev.zsh                     # Development helpers (mise wrappers, language tools)
    filesystem.zsh              # File/directory utilities
    gcloud.zsh                  # Google Cloud helpers
    network.zsh                 # Network diagnostics
~/.zprofile                     # Login shell — mise shims for non-interactive shells
```

**Shell startup order:**
1. `.zshrc` loads `.exports` → `.aliases`
2. Modular `~/.zsh/functions/*.zsh` files are sourced
3. GPG agent launches (handles SSH auth via gpg-agent SSH socket)
4. SSH keys load in the background (non-blocking)
5. mise activates (adds shims to PATH)
6. Completions initialize (cached, once per day)
7. Starship prompt initializes

### PATH Priority

```
~/bin           → Personal scripts (always wins)
~/.local/bin    → Direct installs
/opt/homebrew   → Homebrew (Apple Silicon path)
/usr/bin        → System
~/.cargo/bin    → Rust
~/go/bin        → Go binaries
```

mise shims are injected at the front of PATH automatically by `eval "$(mise activate zsh)"`.

---

## Installation on a Fresh Mac

```bash
# 1. Install Homebrew (Apple Silicon)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Install mise
curl https://mise.run | sh

# 3. Clone dotfiles
git clone https://github.com/lcatlett/mydots ~/dotfiles

# 4. Symlink config files (dots/ → ~/)
cd ~/dotfiles && bash install/install.sh

# 5. Install all mise tools
mise install

# 6. Install Homebrew packages
brew bundle --file=~/dotfiles/install/brew.bak
```

After step 4, `~/.zshrc`, `~/.gitconfig`, `~/.aliases`, etc. will be symlinks into `~/dotfiles/dots/`.

---

## Structure

```
dotfiles/
├── dots/               Config files symlinked to ~/
│   ├── .zshrc          Shell config
│   ├── .exports        Environment variables
│   ├── .aliases        Aliases
│   ├── .gitconfig      Git config with aliases and delta pager
│   ├── .gitignore_global
│   └── .functions      Legacy monolithic functions (kept for reference)
├── .zsh/
│   └── functions/      Modular function files (sourced by .zshrc)
├── bin/                Personal scripts → ~/bin
│   ├── dotfiles        Dotfile management
│   ├── ssh-manager     SSH key/config tool with autocomplete
│   ├── gcb             Git branch diff viewer
│   └── ...
├── install/
│   ├── install.sh      Symlink script
│   └── brew.bak        Homebrew packages list
├── macos/              macOS defaults and Dock config
├── iterm/              iTerm2 profile
└── editors/            Editor configs
```

---

## Git Setup

`.gitconfig` includes:

- **delta** as the pager (syntax-highlighted, side-by-side diffs)
- **Modern defaults**: `init.defaultBranch=main`, `fetch.prune=true`, `pull.rebase=true`, `merge.conflictstyle=zdiff3`
- **Useful aliases**: `git s` (short status), `git wip` (quick savepoint commit), `git undo` (soft reset last commit), `git ahead` (show unpushed commits), `git squash N` (squash last N commits)

```bash
# Handy aliases defined in .gitconfig
git s           # git status --short
git wip         # stage all + commit "wip: savepoint"
git undo        # undo last commit (keep changes staged)
git amend       # amend last commit without editing message
git ahead       # show commits not yet pushed
git squash 3    # squash last 3 commits interactively
git lol         # pretty graph log
```
