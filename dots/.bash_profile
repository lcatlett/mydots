


if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
ssh-add -A 2>/dev/null
. "$HOME/.cargo/env"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :

. "$HOME/.local/bin/env"
