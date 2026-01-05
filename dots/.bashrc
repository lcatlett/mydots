for file in ~/.{exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

unset file;


#. "$HOME/.cargo/env"

bash -c zsh

export NVM_DIR="$HOME/.nvm-x86"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
alias gdrive="/Users/lindseycatlett/go/bin/skicka"
alias gdrive="/usr/local/bin/gdrive"

. "$HOME/.local/bin/env"

# E2E Performance Testing Framework completion
source /Users/lindseycatlett/.bash_completion.d/e2e

. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

alias claude-mem='bun "/Users/lindseycatlett/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
