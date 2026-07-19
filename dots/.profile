
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi


. "$HOME/.cargo/env"

. "$HOME/.local/bin/env"

. "$HOME/.atuin/bin/env"
