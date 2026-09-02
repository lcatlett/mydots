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


