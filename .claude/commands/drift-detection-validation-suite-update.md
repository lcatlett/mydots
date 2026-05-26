---
name: drift-detection-validation-suite-update
description: Workflow command scaffold for drift-detection-validation-suite-update in mydots.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /drift-detection-validation-suite-update

Use this workflow when working on **drift-detection-validation-suite-update** in `mydots`.

## Goal

Adds or updates tests in the validation suite to detect configuration drift, update test logic, or add new checks.

## Common Files

- `tests/validate.sh`
- `CLAUDE.md`
- `README.md`
- `bin/mise-audit`
- `.gitignore`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Edit or add tests in tests/validate.sh
- Update documentation (CLAUDE.md, README.md) to reflect new or changed tests
- Optionally update related bin scripts (e.g., bin/mise-audit)
- Remove or add files to .gitignore if validation artifacts are generated

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.