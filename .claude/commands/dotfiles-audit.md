# /dotfiles-audit

Run a structured dotfiles audit using the 5-phase process defined in AUDIT-PROCESS.md.

## Arguments

- `phase:<N>` — run only a specific phase (1-5)
- `version:<N>` — explicitly set the audit version number

## What This Command Does

1. **Reads context**: Loads AUDIT-PROCESS.md, CLAUDE.md, and BOOTSTRAP.md for current state
2. **Sets up output dir**: Creates `~/dotfiles/dotfiles-audits/dotfile-audit-vN/`
3. **Creates feature branch**: Prompts for branch name following CLAUDE.md conventions
4. **Runs selected phases**: Works through each phase's checklist sequentially
5. **Writes artifacts**: Saves notes, research docs, and deferred items to the output dir
6. **Commits changes**: One commit per phase, conventional commit format, body required

## Current Repo State (v6+)

Key facts to load before auditing — these are established state, not open questions:

- **Dual-machine setup**: `bos-mpotu` (laptop, primary) + `ghost` (Mac Studio, headless compute). Hostnames differ from Brewfile role names (`laptop`/`ghost`).
- **Bifrost proxy**: LLM gateway running on ghost (Docker, port 8080). `$HOME/.bifrost/bin` in PATH is intentional. `ANTHROPIC_BASE_URL` in `.exports` is toggled per-machine — do not flag or modify without asking.
- **`.exports` is gitignored on both machines** — secrets and bifrost config live there, never in tracked files.
- **`.zshenv`** is tracked and symlinked — sources `.exports` for non-interactive shells (hooks, Remote-SSH, launchd). This is intentional architecture.
- **Brewfiles are split by role**: `Brewfile` (common), `Brewfile.laptop`, `Brewfile.ghost`. The hostname→role mapping is: `ghost` → `ghost`, everything else → `laptop`. Mirror the `case` in `brew.sh` when checking Brewfiles.
- **Ghostty** is the active terminal (migrated from iTerm2). Config at `dots/ghostty/config` and `dots/ghostty/themes/` — both symlinked into `~/.config/ghostty/`.
- **Editor**: Switched from VS Code to Zed, but still need support for VS Code due to extension gaps in Zed for some tasks. Adding Zed to Brewfile is a follow-on task.
- **mise-first policy**: All language runtimes and CLI tools go through mise. `cargo:starship`, `cargo:mcfly`, and all others are mise-managed. Check `mise ls-remote <tool>` before reaching for Homebrew.
- **Starship config**: `~/.claude/starship-rtfi.toml` — has RTFI statusline integration. `STARSHIP_CONFIG` in `.zshrc` must point here.

## Starting a Full Audit

```
/dotfiles-audit
```

Claude will:
- Determine the current audit version (N = last version + 1, currently v7)
- Ask which phases to run (default: all 5)
- Create `~/dotfiles/dotfiles-audits/dotfile-audit-vN/` as the working dir
- Start Phase 1 and proceed through each phase

## Starting a Targeted Audit

```
/dotfiles-audit phase:2
```

Runs only Phase 2 (Tool Manager Audit). Still creates the versioned output directory and feature branch.

## Rules (Non-Negotiable)

- All code changes go on a feature branch — never commit to master directly
- Read every file before modifying it
- Run `zsh -n <file>` after editing any `.zsh` file
- Run `bash -n <file>` after editing any shell script
- Show verification output before claiming a phase is complete
- Use conventional commits with a body for every non-trivial change
- Never flag `$HOME/.bifrost/bin` or `ANTHROPIC_BASE_URL` as issues without confirming with user first

## Reference

Full process documentation: `AUDIT-PROCESS.md` in the repo root.
Past audit artifacts: `~/dotfiles/dotfiles-audits/dotfile-audit-vN/`
