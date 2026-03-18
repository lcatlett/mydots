# CLAUDE.md — dotfiles

Personal macOS dotfiles for Apple Silicon. PHP/Drupal development focus.

---

## What This Repo Is

A bootstrap + ongoing sync system for developer environment config. The repo has two jobs:
1. **First-time install** — bring up a fresh Mac to a working state
2. **Ongoing sync** — keep config files tracked in git via symlinks

Live config files are symlinks into this repo. Editing `~/.zshrc` *is* editing `dots/.zshrc`.

---

## Key Conventions

### Symlink Pattern
- `dots/` → `~/` (config files)
- `bin/` → `~/bin/` (scripts)
- Managed by `install/symlinks.sh` using `ln -sfv`
- Adding a new dotfile: add to `dots/`, add `ln -sfv` line in `symlinks.sh`
- Adding a new script: add to `bin/`, add the script name to the loop in `symlinks.sh`

### `dotfiles` CLI Pattern
`bin/dotfiles` dispatches subcommands via `sub_<command>()` functions. Each function sources its target script. To add a new subcommand:
1. Add a `sub_newcommand()` function
2. Add it to the `sub_help` output
3. That's it — the `case` at the bottom handles routing automatically

### Shell Config Ownership
- `.zshrc` is the **authoritative PATH builder** — don't add PATH in `.exports`
- `.exports` is for env vars that aren't PATH (EDITOR, tokens, build flags)
- `.aliases` is for aliases only — functions go in `~/.zsh/functions/*.zsh`
- New modular function files: drop a `.zsh` file in `~/.zsh/functions/` — it auto-sources

---

## Directory Structure

```
dotfiles/
├── bin/          Scripts → ~/bin/ (the dotfiles CLI lives here)
├── dots/         Config files → ~/
├── install/      Bootstrap scripts (install.sh, symlinks.sh, brew.sh, Brewfile)
├── macos/        macOS defaults scripts (defaults.sh, extended.sh, dock.sh)
├── tests/        Drift detection and validation (validate.sh)
├── dots/ghostty/ Ghostty terminal config + themes → ~/.config/ghostty/
├── iterm/        iTerm2 color schemes (fallback)
└── fonts/        FiraCode, Hack Nerd Font, Inconsolata
```

---

@.claude/docs/reference.md

---

## Making Changes

Edit `dots/` directly (symlinked live). Brewfile changes: add to appropriate file, run `bash install/brew.sh`.
Mise tools: `mise use --global <tool>@latest`. Symlinks: `dotfiles symlinks`.

@.claude/docs/workflows.md

### Running drift detection
```bash
bash tests/validate.sh
```
Checks shell startup time, secrets in tracked files, Brewfile consistency, symlink integrity, SSH permissions, and deprecated Homebrew entries. Exit 0 = all green.

---

## Git Discipline

**Non-negotiable: all changes require a feature branch. Never commit directly to master.**
Conventional commits, kebab-case branch names (fix/, feat/, chore/, docs/).
Test before committing: `zsh -n` for shell files, `bash -n` for install scripts.

@.claude/docs/git-discipline.md

---

## What NOT to Do

- Don't add `PATH` assignments to `.exports` — `.zshrc` owns PATH
- Don't install language runtimes or CLIs via Homebrew if mise has them
- Don't source blocking commands in `.zshrc` (gpg, ssh-add are already async)
- Don't commit secrets — `dots/.gitconfig` had a token removed from history via `git filter-repo`
- Don't create new files for one-off scripts — add to an existing `bin/` script or function file
