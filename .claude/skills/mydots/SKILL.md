```markdown
# mydots Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill teaches the core development patterns, coding conventions, and operational workflows for the `mydots` repository—a TypeScript-based dotfiles and shell configuration management system. It covers how to manage shell functions, symlinks, Homebrew and mise tool management, validation testing, and documentation updates. The guide is designed to help contributors maintain consistency and efficiency when working with this codebase.

## Coding Conventions

- **File Naming:**  
  Use `camelCase` for file names.  
  _Example:_  
  ```
  install/symlinks.sh
  dots/.zshrc
  mise/config.toml
  ```

- **Import Style:**  
  Use **relative imports** in TypeScript files.  
  _Example:_  
  ```typescript
  import { myFunction } from './utils/myFunction';
  ```

- **Export Style:**  
  Use **named exports**.  
  _Example:_  
  ```typescript
  // utils/myFunction.ts
  export function myFunction() { ... }
  ```

- **Commit Messages:**  
  Follow the **conventional commit** format with prefixes: `feat`, `fix`, `chore`, `docs`.  
  _Example:_  
  ```
  feat: add new zsh function for git branch cleanup
  ```

## Workflows

### Shell Function Migration and Symlink Management
**Trigger:** When migrating or refactoring shell functions or updating how dotfiles are symlinked into the home directory  
**Command:** `/migrate-function`

1. Move or refactor shell function files (e.g., from `dots/.functions` to `.zsh/functions/*`)
2. Update or consolidate functions as needed; retire obsolete ones
3. Update `install/symlinks.sh` to manage new or changed symlinks
4. Test symlink creation and function availability
5. Remove obsolete source files

_Example:_
```bash
mv dots/.functions/git.zsh .zsh/functions/git.zsh
./install/symlinks.sh
source ~/.zshrc
```

---

### Drift Detection Validation Suite Update
**Trigger:** When adding new drift detection logic, updating validation scripts, or reflecting repo state changes in tests  
**Command:** `/update-validation`

1. Edit or add tests in `tests/validate.sh`
2. Update documentation (`CLAUDE.md`, `README.md`) to reflect new or changed tests
3. Optionally update related bin scripts (e.g., `bin/mise-audit`)
4. Update `.gitignore` if validation artifacts are generated

_Example:_
```bash
vim tests/validate.sh
# Add new validation logic
./tests/validate.sh
```

---

### Mise Tool Version and Backend Update
**Trigger:** When a mise backend changes, a tool version needs to be pinned/unpinned, or a tool is added/removed from mise management  
**Command:** `/update-mise`

1. Edit `mise/config.toml` to update tool versions or backends
2. Optionally update related bin scripts (e.g., `bin/mise-audit`)
3. Document changes in commit message or documentation

_Example:_
```toml
# mise/config.toml
[node]
version = "18.16.0"
```

---

### Brewfile Host Split and Cleanup
**Trigger:** When adding host-specific packages, removing mise-managed tools from Brewfile, or restructuring Homebrew management  
**Command:** `/update-brewfile`

1. Edit `install/Brewfile`, `install/Brewfile.laptop`, and/or `install/Brewfile.ghost`
2. Update `install/brew.sh` to map hostnames to Brewfiles
3. Update `.zshrc` or other shell files for host-specific logic
4. Update documentation (`CLAUDE.md`, etc.)
5. Optionally update validation scripts for new Brewfile structure

_Example:_
```bash
vim install/Brewfile.laptop
# Add or remove packages
./install/brew.sh
```

---

### Dotfiles Documentation and Command Update
**Trigger:** When documenting a new process, updating an audit workflow, or adding a new Claude Code slash command  
**Command:** `/update-docs`

1. Create or update markdown documentation (e.g., `AUDIT-PROCESS.md`, `BOOTSTRAP.md`, `.claude/commands/*.md`)
2. Update `.gitignore` to ensure docs/commands are tracked
3. Update main documentation files (`CLAUDE.md`, `README.md`) to reference new docs or commands

_Example:_
```markdown
# .claude/commands/update-mise.md
Describes how to update mise-managed tools.
```

---

### Shell RC and Aliases Update
**Trigger:** When adding new aliases, updating environment variables, or fixing shell startup/configuration issues  
**Command:** `/update-shellrc`

1. Edit relevant shell rc files (`.zshrc`, `.zshenv`, `.bashrc`, `.aliases`, `.profile`)
2. Optionally update or add supporting scripts or config (e.g., `symlinks.sh`, install scripts)
3. Test shell startup and new/changed aliases or variables

_Example:_
```bash
# dots/.aliases
alias gs='git status'
source ~/.zshrc
```

---

## Testing Patterns

- **Test Framework:** Unknown (shell-based validation scripts detected)
- **Test File Pattern:** Files matching `*.test.*` and scripts like `tests/validate.sh`
- **How to Run:**  
  Run validation scripts directly:
  ```bash
  ./tests/validate.sh
  ```

- **Test Example:**
  ```bash
  # tests/validate.sh
  if [ ! -f ~/.zshrc ]; then
    echo "Missing .zshrc"
    exit 1
  fi
  ```

## Commands

| Command           | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| /migrate-function | Migrate/refactor shell functions and update symlinks           |
| /update-validation| Update or add drift detection and validation tests              |
| /update-mise      | Update mise-managed tool versions or backends                   |
| /update-brewfile  | Edit/split Brewfiles and update Homebrew management            |
| /update-docs      | Add or update documentation and slash command references        |
| /update-shellrc   | Update shell rc files, aliases, or environment variables       |
```