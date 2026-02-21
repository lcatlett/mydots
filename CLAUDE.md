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

### Tool Manager: mise-first
- **Always prefer mise** for language runtimes and CLI tools
- Check `mise ls-remote <tool>` before reaching for Homebrew
- Homebrew is reserved for: system libraries, GUI apps, tools not in mise
- When suggesting new tool installs, default to `mise use --global <tool>@latest`

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
├── iterm/        iTerm2 color schemes + profile
└── fonts/        FiraCode, Hack Nerd Font, Inconsolata
```

---

## Shell Startup Order

```
.zshrc
  → .exports (env vars)
  → .aliases
  → ~/.zsh/functions/*.zsh (auto-sourced)
  → History config
  → PATH construction (typeset -U, priority order)
  → GPG agent + SSH keys (async, non-blocking)
  → rg/fd/pigz wrappers (override grep/find/gzip)
  → compinit (cached daily)
  → mise activate
  → zoxide init
  → Starship prompt init
  → mise exec aliases (npm, npx, php, composer, uv, bun)
```

Startup performance target: under 300ms. Don't add blocking calls to `.zshrc`.

---

## Important Files

| File | Purpose |
|------|---------|
| `dots/.zshrc` | Main shell config — PATH + startup orchestration |
| `dots/.exports` | Env vars (EDITOR, tokens, build vars) |
| `dots/.aliases` | Shell aliases |
| `dots/.gitconfig` | Git config + ~30 aliases + delta pager settings |
| `dots/.gitignore_global` | Global gitignore (applies to all repos) |
| `install/Brewfile` | All Homebrew packages, casks, VS Code extensions |
| `install/symlinks.sh` | Defines every managed symlink |
| `bin/dotfiles` | Main CLI entry point |

---

## Git Config Highlights

- **Pager**: delta (side-by-side diffs, vscode hyperlinks, line numbers)
- **Conflict style**: `zdiff3` (shows base in conflicts)
- **rerere**: enabled (reuse recorded conflict resolutions)
- **Defaults**: `pull.rebase=true`, `fetch.prune=true`, `push.autoSetupRemote=true`
- **Signing**: GPG via gpg-agent (gpg-agent also handles SSH auth)

---

## Making Changes

### Editing shell config
Edit directly in `dots/` — changes are live immediately since they're symlinked.
```bash
# After editing dots/.zshrc:
source ~/.zshrc   # or open new shell
```

### Adding a Homebrew package
Add to `install/Brewfile`, then:
```bash
brew bundle --file=install/Brewfile
```

### Adding a mise tool
```bash
mise use --global <tool>@latest
# Document in README.md Installed Tools table
```

### Re-running symlinks
```bash
dotfiles symlinks
```

### Full system audit
```bash
audit-system   # or: symlink-audit, mise-audit, syscheck
```

---

## Git Discipline

**Non-negotiable: all changes require a feature branch. Never commit directly to master.**

### Branch Conventions

| Prefix | Use |
|--------|-----|
| `fix/` | Bug fixes (e.g., `fix/ssh-gpg-agent-conflict`) |
| `feat/` | New capabilities (e.g., `feat/mise-config-tracked`) |
| `chore/` | Maintenance, cleanup, removal of dead code |
| `docs/` | Documentation-only changes |

Branch names: kebab-case, descriptive, under 50 characters.

### Commit Message Format

[Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short description (imperative mood, under 72 chars)

Longer body explaining WHY (not what — the diff shows what).
Reference plan documents or prior decisions where relevant.
```

- **Types**: `fix`, `feat`, `chore`, `docs`, `refactor`, `test`, `ci`
- **Scope**: the file or area changed (`zshrc`, `brewfile`, `mise`, `install`, `bin`)
- **Body**: required for any non-trivial change

### Process

1. `git checkout -b <prefix>/<descriptive-name>`
2. Make the smallest focused change that accomplishes the goal
3. `git diff` — review before staging
4. `git add -p` — stage interactively when possible
5. `git commit` — write a conventional commit message with body
6. `git push -u origin <branch-name>`
7. Merge to master only after verifying the change works in a live shell

### Test Before Committing

- After editing any `.zsh` / `.zshrc` file: `zsh -n <file>` (syntax check)
- After editing install scripts: `bash -n <file>`
- After editing `symlinks.sh`: run `dotfiles symlinks` in a test context

### Updating the Changelog

After merging to master, regenerate CHANGELOG.md from commit history:
```bash
git-cliff --output CHANGELOG.md && git add CHANGELOG.md && git commit -m 'chore: update changelog'
```

---

## What NOT to Do

- Don't add `PATH` assignments to `.exports` — `.zshrc` owns PATH
- Don't install language runtimes or CLIs via Homebrew if mise has them
- Don't source blocking commands in `.zshrc` (gpg, ssh-add are already async)
- Don't commit secrets — `dots/.gitconfig` had a token removed from history via `git filter-repo`
- Don't create new files for one-off scripts — add to an existing `bin/` script or function file
