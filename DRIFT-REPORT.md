# Drift Detection Report

**Date:** 2026-02-26
**Branch:** `feat/drift-detection`
**Suite:** `tests/validate.sh`

## Summary

| Test | Initial | After Fix |
|------|---------|-----------|
| Shell startup < 2s | PASS | PASS |
| No secrets in tracked files | PASS | PASS |
| Brewfile consistency | FAIL | PASS |
| Dotfiles sync (symlinks) | PASS | PASS |
| SSH permissions | FAIL | PASS |
| No deprecated brew entries | PASS | PASS |

## Findings

### 1. SSH config permissions (FIXED)

- **What drifted:** `~/.ssh/config` had permissions `644` (world-readable)
- **Root cause:** Likely set during a manual edit or copy operation that didn't preserve restrictive permissions
- **Fix applied:** `chmod 600 ~/.ssh/config`
- **Verification:** `stat -f '%A' ~/.ssh/config` → `600`

### 2. Brewfile dependency mismatch (FIXED)

- **What drifted:** Four Brewfile entries were not satisfied on the local system:
  - `augment.vscode-augment` (VS Code extension) — not installed
  - `zencoderai.zencoder` (VS Code extension) — not installed
  - `grafana` (formula) — needed install/update
  - `mise` (formula) — needed install/update
- **Root cause:** Extensions added to Brewfile but not yet installed; formulae fell behind on updates
- **Fix applied:** `brew bundle install --file=install/Brewfile`
- **Verification:** `brew bundle check --file=install/Brewfile` → exit 0

## No Issues Found

- **Shell startup:** Under 2 seconds
- **Secrets scan:** No tokens or API keys in git-tracked files (`dots/.exports` is gitignored by design)
- **Symlink integrity:** All 11 dotfile symlinks + mise config point to correct repo paths
- **Deprecated formulae:** None detected in current Brewfile
