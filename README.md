# Dotfiles

Personal macOS dotfiles for Apple Silicon. This repo bootstraps a fresh Mac to a
working development environment and keeps config files synced via symlinks — no
magic, no frameworks. Tools are managed with a mise-first philosophy: language
runtimes and CLI tools go through [mise](https://mise.jdx.dev/), Homebrew is
reserved for system libraries and GUI apps. Portable enough to re-run on any
Apple Silicon Mac.

![Terminal](https://raw.githubusercontent.com/lcatlett/mydots/master/screenshot.png)

---

## Quick Start

```bash
xcode-select --install
git clone https://github.com/lcatlett/mydots ~/dotfiles
~/dotfiles/bin/dotfiles install
```

This installs Homebrew packages, creates symlinks, and installs mise-managed
tools. See [BOOTSTRAP.md](BOOTSTRAP.md) for the full step-by-step guide
(secrets setup, macOS defaults, GPG/SSH keys, troubleshooting).

---

## Repository Structure

```
dotfiles/
├── bin/          Scripts → ~/bin/ (includes the `dotfiles` CLI)
├── dots/         Config files → ~/ (symlinked)
├── mise/         mise global config → ~/.config/mise/ (symlinked)
├── install/      Bootstrap scripts (install.sh, symlinks.sh, brew.sh, Brewfile)
├── macos/        macOS defaults scripts (defaults.sh, extended.sh, dock.sh)
├── iterm/        iTerm2 color schemes
└── fonts/        FiraCode, Hack Nerd Font, Inconsolata
```

Live config files are symlinks into this repo. Editing `~/.zshrc` **is** editing
`dots/.zshrc`. Symlinks are managed by `install/symlinks.sh`.

---

## Tool Management

<!-- Source of truth for the brew/mise split: install/Brewfile header comment
     and mise/config.toml. Update this section if either changes. -->

### mise manages runtimes and CLI tools

[mise](https://mise.jdx.dev/) is a single polyglot tool version manager that
replaces nvm, pyenv, rbenv, and most Homebrew CLI installs. The global config is
tracked at `mise/config.toml` in this repo and symlinked to
`~/.config/mise/config.toml` during setup.

**Language runtimes:** Node.js, Python, Go, PHP (8.2/8.3/8.4), Ruby, Rust, Bun, uv

**CLI tools:** bat, eza, fd, fzf, ripgrep, jq, yq, delta, zoxide, starship,
direnv, tmux, gum, glow, broot, gh, act, git-cliff, shellcheck, hadolint,
hyperfine, dust, duf, cmake, mkcert, and more (~55 tools total)

```bash
mise ls                        # List installed tools
mise use --global node@latest  # Install latest Node globally
mise use node@20               # Pin Node 20 for current project
mise install                   # Install everything from config
mise outdated                  # Check for updates
```

### Homebrew manages system libraries and GUI apps

Homebrew is reserved for things mise can't handle — compilation libraries, system
services, and macOS GUI apps. The full list is in `install/Brewfile`.

**Libraries:** openssl, gnupg + pinentry-mac, imagemagick, mysql-client, curl,
libffi, libyaml, zlib, and build dependencies

**GUI apps (casks):** iTerm2, Raycast, Sequel Ace, GPG Suite, OrbStack, ngrok

**Rule of thumb:** before adding to the Brewfile, check `mise ls-remote <tool>`.
If mise has it, use mise.

---

## Shell Architecture

<!-- Source of truth: dots/.zshrc. Update this section if startup order changes. -->

### Startup order

```
.zshrc
  → .exports (env vars — EDITOR, tokens, build flags)
  → .aliases
  → ~/.zsh/functions/*.zsh (auto-sourced modular functions)
  → History config
  → PATH construction (typeset -U, priority order)
  → GPG agent + SSH keys (async, non-blocking)
  → rg/fd/pigz wrappers (override grep/find/gzip)
  → compinit (cached daily)
  → mise activate
  → zoxide init
  → Starship prompt init
```

Startup target: under 300ms.

### Key files

| File | Purpose |
|------|---------|
| `dots/.zshrc` | Main shell config — PATH construction + startup orchestration |
| `dots/.exports` | Environment variables (EDITOR, tokens, build flags) — **gitignored** |
| `dots/.aliases` | Shell aliases |
| `dots/.gitconfig` | Git config + ~30 aliases + delta pager settings |
| `dots/.gitignore_global` | Global gitignore (applies to all repos) |
| `install/Brewfile` | Homebrew packages, casks, fonts, VS Code extensions |
| `install/symlinks.sh` | Defines every managed symlink |
| `mise/config.toml` | Global mise tool versions |
| `bin/dotfiles` | CLI entry point (`dotfiles help` for commands) |

### PATH priority

```
~/.local/share/mise/shims   → mise-managed tools (injected by mise activate)
~/bin                        → Personal scripts (from this repo)
~/.local/bin                 → Direct installs
/opt/homebrew/bin            → Homebrew (Apple Silicon)
/usr/bin                     → System
```

### Git config highlights

- **Pager:** delta (syntax-highlighted, side-by-side diffs, VS Code hyperlinks)
- **Defaults:** `pull.rebase=true`, `fetch.prune=true`, `push.autoSetupRemote=true`
- **Conflict style:** `zdiff3` (shows base in three-way conflicts)
- **rerere:** enabled (reuse recorded conflict resolutions)
- **Signing:** GPG via gpg-agent (also handles SSH auth)

Useful aliases: `git s` (short status), `git wip` (quick savepoint), `git undo`
(soft reset last commit), `git ahead` (unpushed commits), `git lol` (graph log).

---

## What's Not Here

This repo does **not** contain — and never will contain:

- **SSH keys** — generate per-machine (`ssh-keygen -t ed25519`)
- **GPG keys** — generate per-machine (`gpg --full-generate-key`)
- **secrets** — `dots/.exports` is gitignored; it holds tokens and credentials

A template for `.exports` is provided at `dots/.exports.template`. Copy it to
`dots/.exports` and fill in your values. See [BOOTSTRAP.md](BOOTSTRAP.md) for
details.

---

## Making Changes

**Edit shell config** — edit directly in `dots/`; changes are live via symlink:
```bash
source ~/.zshrc   # reload, or open a new shell
```

**Add a Homebrew package** — add to `install/Brewfile`, then:
```bash
brew bundle --file=install/Brewfile
```

**Add a mise tool:**
```bash
mise use --global <tool>@latest
```

**Add a new dotfile** — add the file to `dots/`, add a `ln -sfv` line to
`install/symlinks.sh`, then:
```bash
dotfiles symlinks
```

**Add a new script** — add to `bin/`, add the script name to the loop in
`install/symlinks.sh`, then run `dotfiles symlinks`.

---

## dotfiles CLI

```bash
dotfiles help          # Show all commands
dotfiles install       # Full bootstrap (brew, mise, symlinks, macOS defaults)
dotfiles update        # Update OS, Homebrew, and mise tools
dotfiles symlinks      # Re-run symlink creation
dotfiles brew          # Run brew install only
dotfiles defaults      # Apply macOS defaults
dotfiles dock          # Configure Dock layout
dotfiles clean         # Clean brew caches
```
