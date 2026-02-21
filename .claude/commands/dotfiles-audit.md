# /dotfiles-audit

Run a structured dotfiles audit using the 5-phase process defined in AUDIT-PROCESS.md.

## Arguments

- `phase:<N>` — run only a specific phase (1-5)
- `version:<N>` — explicitly set the audit version number

## What This Command Does

1. **Reads context**: Loads AUDIT-PROCESS.md, CLAUDE.md, and BOOTSTRAP.md for current state
2. **Sets up output dir**: Creates `~/notes/ai-outputs/wip-automation/dotfile-audit-vN/`
3. **Creates feature branch**: Prompts for branch name following CLAUDE.md conventions
4. **Runs selected phases**: Works through each phase's checklist sequentially
5. **Writes artifacts**: Saves notes, research docs, and deferred items to the output dir
6. **Commits changes**: One commit per phase, conventional commit format, body required

## Starting a Full Audit

```
/dotfiles-audit
```

Claude will:
- Determine the current audit version (N = last version + 1)
- Ask which phases to run (default: all 5)
- Create `~/notes/ai-outputs/wip-automation/dotfile-audit-vN/` as the working dir
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

## Reference

Full process documentation: `AUDIT-PROCESS.md` in the repo root.
Past audit artifacts: `~/notes/ai-outputs/wip-automation/dotfile-audit-vN/`
