# Dotfiles Audit Process

A recurring audit process for keeping this dotfiles repo healthy, current, and public-ready.

---

## What a Dotfiles Audit Is

An audit reviews the repo's current state across five dimensions and produces changes that:
- Remove dead code and unused files
- Migrate config to modern tools and patterns
- Validate that the bootstrap install sequence still works
- Keep the public-facing presentation accurate
- Document process improvements for the next cycle

Audits are versioned (v1, v2, ...). Each one builds on the prior and defers lower-priority items explicitly.

---

## When to Run

- Before making the repo public for the first time
- After a major tool change (new terminal, new version manager, new shell config)
- When `dots/.functions` or other source files have drifted from target locations
- Periodically (quarterly) to catch stale config and retired tools

---

## 5-Phase Audit Structure

### Phase 1: Repo Hygiene

Goal: no dead code, no stale files, git history is clean.

- [ ] Identify untracked files that should be tracked or gitignored
- [ ] Remove compiled binaries and generated files from git history
- [ ] Remove client-specific or credential-containing content
- [ ] Verify `.gitignore` covers all generated/local files
- [ ] Run `shellcheck` on all shell scripts; fix errors

Artifacts: shellcheck CI workflow, `.shellcheckrc`, updated `.gitignore`

### Phase 2: Tool Manager Audit

Goal: mise manages all language runtimes and CLI tools; Homebrew is only for GUI apps and system libs.

- [ ] List all tools currently in Brewfile
- [ ] For each tool: check `mise ls-remote <tool>` availability
- [ ] Move eligible tools from Brewfile → `mise/config.toml`
- [ ] Document deviations in `~/.claude/mise-issues.log`
- [ ] Run `mise doctor` to verify no conflicts

Artifacts: updated `Brewfile`, updated `mise/config.toml`

### Phase 3: Bootstrap Sequence Audit

Goal: `bash install/install.sh` brings a fresh Mac to a working state in one run.

- [ ] Read `install/install.sh` → map actual execution order
- [ ] Verify each script handles its own dependencies
- [ ] Test symlink deployment: `dotfiles symlinks` → spot-check 5 symlinks
- [ ] Verify `.zsh/functions/*.zsh` are symlinked (not plain copies)
- [ ] Document gaps and missing automation in `BOOTSTRAP.md`
- [ ] Ensure `dots/.exports.template` documents all required env vars

Artifacts: `BOOTSTRAP.md`, updated `install/symlinks.sh`

### Phase 4: Public Polish

Goal: repo is presentable to external viewers on GitHub.

- [ ] `README.md` accurately describes current state (not aspirational)
- [ ] `BOOTSTRAP.md` is accurate and complete
- [ ] License file exists
- [ ] No secrets in git history (run `git log -S <secret>` spot-check)
- [ ] No hardcoded credentials or project IDs in any tracked file
- [ ] Changelog is current: `git-cliff --output CHANGELOG.md`

Artifacts: updated `README.md`, `LICENSE`, `CHANGELOG.md`

### Phase 5: Maintenance Scaffolding

Goal: the next audit is easier than this one.

- [ ] Document deferred items in a new `audit-vN-deferred.md`
- [ ] Update `AUDIT-PROCESS.md` with lessons from this audit
- [ ] Update CLAUDE.md if any conventions changed
- [ ] Create changelog entry: `git-cliff --output CHANGELOG.md`

Artifacts: `audit-vN-deferred.md`, updated `AUDIT-PROCESS.md`

---

## Artifact Locations

All audit outputs (notes, research docs, deferred lists) go in:

```
~/notes/ai-outputs/wip-automation/dotfile-audit-vN/
```

Files in this directory are never committed to the repo. They are working notes for the audit session.

---

## Claude Code Execution

The `/dotfiles-audit` slash command runs this process interactively. To start an audit:

```
/dotfiles-audit
```

This loads the full process context and prompts for the audit version and scope.

For targeted audits of a specific phase:
```
/dotfiles-audit phase:2    # Tool manager audit only
/dotfiles-audit phase:3    # Bootstrap audit only
```

---

## Non-Negotiable Rules

These apply to every change made during an audit:

1. **Feature branch required.** Never commit directly to `master`. Branch naming:
   - `fix/` — bug fixes
   - `feat/` — new capabilities
   - `chore/` — maintenance and cleanup
   - `docs/` — documentation only

2. **Conventional commits.** Format: `type(scope): description`. Body required for non-trivial changes.

3. **Read before editing.** Never modify a file without reading it first in the current session.

4. **Syntax check before committing.** After editing any `.zsh` / `.zshrc` file:
   ```bash
   zsh -n <file>
   ```
   After editing install scripts:
   ```bash
   bash -n <file>
   ```

5. **Verify before claiming completion.** Run the verification command and show the output.

6. **Mise-first policy.** Check `mise ls-remote <tool>` before reaching for Homebrew.

---

## Deferred Items Log Format

When deferring an item to a future audit, record it in `audit-vN-deferred.md`:

```markdown
## Deferred from v[N] — [date]

| Item | Reason for Deferral | Target Audit |
|------|---------------------|--------------|
| Migrate Ghostty config | v5 research complete; migration is Day 2 work | v6 |
| Remove iterm/ directory | Pending Ghostty migration | v6 |
```

---

## Audit History

| Version | Date | Focus | Branch(es) |
|---------|------|-------|------------|
| v1 | 2024 | Initial cleanup and zsh migration | Various |
| v2 | 2024 | Aliases audit, Brewfile cleanup | Various |
| v3 | 2025-01 | Function modularization to .zsh/functions/ | Various |
| v4 | 2025-12 | mise-first policy, CI (shellcheck), changelog, git discipline | Various |
| v5 | 2026-02 | Complete .functions migration, symlink gap fix, terminal research | feat/complete-functions-migration, docs/audit-process |
