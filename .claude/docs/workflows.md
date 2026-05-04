## Making Changes — Full Reference

### Editing shell config
Edit directly in `dots/` — changes are live immediately since they're symlinked.
```bash
# After editing dots/.zshrc:
source ~/.zshrc   # or open new shell
```

### Adding a Homebrew package
Add to the appropriate Brewfile:
- `install/Brewfile` — shared packages (both machines)
- `install/Brewfile.laptop` — laptop-only (GUI casks, VS Code, PHP/Drupal)
- `install/Brewfile.ghost` — ghost-only (AI/compute tools)

Then run:
```bash
bash install/brew.sh   # auto-detects hostname, installs common + host-specific
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
