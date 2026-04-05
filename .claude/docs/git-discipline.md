## Git Discipline — Full Reference

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
