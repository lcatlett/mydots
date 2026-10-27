for file in ~/.{exports,aliases}; do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

# --- Load modular function files ---
if [[ -d "$HOME/.zsh/functions" ]]; then
  for func_file in ~/.zsh/functions/*.zsh; do
    [[ -r "$func_file" ]] && source "$func_file"
  done
  unset func_file
fi

. "$HOME/.local/bin/env"

#. "$HOME/.cargo/env"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init bash)"; fi
eval "$(COMPLETE=bash prek)"


# Claudia shell helpers (`claudia` from anywhere; `claudia codex|claude|grok|voice` selects a surface)
[ -f "$HOME/.claudia/shell-init.sh" ] && source "$HOME/.claudia/shell-init.sh"

# dcg: warn if hook was silently removed from Claude Code settings
if command -v dcg &>/dev/null && command -v jq &>/dev/null; then
  if [ -f "$HOME/.claude/settings.json" ] && \
     ! jq -e '.hooks.PreToolUse[]? | select(.hooks[]?.command | test("dcg\"?$"))' \
       "$HOME/.claude/settings.json" &>/dev/null; then
    printf '\033[1;33m[dcg] Hook missing from ~/.claude/settings.json — run: dcg install\033[0m\n'
  fi
fi
