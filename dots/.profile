export PATH="$PATH:$HOME/.composer/vendor/bin"


export AH_SSH_CONFIG="${HOME}/.ssh/ah_config"

# include AH profile
if [ -f ~/.ah_profile ]; then
  . ~/.ah_profile
fi


if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

export PATH="$HOME/.cargo/bin:$PATH"
