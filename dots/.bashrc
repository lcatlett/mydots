for file in ~/.{exports,aliases,functions}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

unset file;

#. "$HOME/.cargo/env"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

. "$HOME/.local/bin/env"

alias claude-mem='bun "/Users/lcatlett/.claude/plugins/cache/thedotmack/claude-mem/10.5.2/scripts/worker-service.cjs"'

