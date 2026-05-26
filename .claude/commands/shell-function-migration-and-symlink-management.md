---
name: shell-function-migration-and-symlink-management
description: Workflow command scaffold for shell-function-migration-and-symlink-management in mydots.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /shell-function-migration-and-symlink-management

Use this workflow when working on **shell-function-migration-and-symlink-management** in `mydots`.

## Goal

Migrates shell functions to new locations, consolidates or retires old ones, and updates symlink scripts to ensure correct linking and prevent drift.

## Common Files

- `.zsh/functions/*.zsh`
- `dots/.functions`
- `install/symlinks.sh`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Move or refactor shell function files (e.g., from dots/.functions to .zsh/functions/*)
- Update or consolidate functions as needed, possibly retiring old ones
- Update install/symlinks.sh to manage new or changed symlinks
- Test symlink creation and function availability
- Remove obsolete source files

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.