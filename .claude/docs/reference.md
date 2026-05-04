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
| `install/Brewfile` | Common Homebrew packages (both machines) |
| `install/Brewfile.laptop` | Laptop-specific: GUI casks, VS Code extensions, PHP/Drupal taps |
| `install/Brewfile.ghost` | Ghost-specific: ollama, orbstack, headless tools |
| `install/symlinks.sh` | Defines every managed symlink |
| `bin/dotfiles` | Main CLI entry point |
| `tests/validate.sh` | Drift detection suite (7 checks: startup time, secrets, Brewfile, symlinks, SSH perms, deprecated formulae, mise audit) |

---

## Git Config Highlights

- **Pager**: delta (side-by-side diffs, vscode hyperlinks, line numbers)
- **Conflict style**: `zdiff3` (shows base in conflicts)
- **rerere**: enabled (reuse recorded conflict resolutions)
- **Defaults**: `pull.rebase=true`, `fetch.prune=true`, `push.autoSetupRemote=true`
- **Signing**: GPG via gpg-agent (gpg-agent also handles SSH auth)
