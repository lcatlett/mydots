# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
#/usr/local/bin/keychain $HOME/.ssh/id_rsa

for file in ~/.{exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

unset file;

ZSH_DISABLE_COMPFIX=true

# Path to your oh-my-zsh installation.
export ZSH="REDACTED-HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

plugins=(

)
source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# Appends every command to the history file once it is executed


setopt inc_append_history
# Reloads the history whenever you use it
setopt share_history

fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure

# better shell history search
#eval "$(mcfly init zsh)"



test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


function blt() {
  if [[ ! -z ${AH_SITE_ENVIRONMENT} ]]; then
    PROJECT_ROOT="/var/www/html/${AH_SITE_GROUP}.${AH_SITE_ENVIRONMENT}"
  elif [ "`git rev-parse --show-cdup 2> /dev/null`" != "" ]; then
    PROJECT_ROOT=$(git rev-parse --show-cdup)
  else
    PROJECT_ROOT="."
  fi

  if [ -f "$PROJECT_ROOT/vendor/bin/blt" ]; then
    $PROJECT_ROOT/vendor/bin/blt "$@"

  # Check for local BLT.
  elif [ -f "./vendor/bin/blt" ]; then
    ./vendor/bin/blt "$@"

  else
    echo "You must run this command from within a BLT-generated project."
    return 1
  fi
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -s "REDACTED-HOME/google-cloud-sdk/path.zsh.inc" ]

[ -s "REDACTED-HOME/google-cloud-sdk/completion.zsh.inc" ]


   # source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
   # source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# The next line updates PATH for the Google Cloud SDK.
#if [ -f "REDACTED-HOME/google-cloud-sdk/path.zsh.inc" ]; then . "REDACTED-HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
#if [ -f "REDACTED-HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "REDACTED-HOME/google-cloud-sdk/completion.zsh.inc"; fi

#eval "$(rbenv init -)"
export PANTHEON_CERT="REDACTED-HOME/certs/REDACTED@example.com.pem"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PANTHEON_CERT="REDACTED-HOME/certs/REDACTED@example.com.pem"

export GOPATH="$HOME/go"; export GOROOT="$HOME/.go"; export PATH="$GOPATH/bin:$PATH"; # g-install: do NOT edit, see https://github.com/stefanmaric/g
alias ggovm="$GOPATH/bin/g"; # g-install: do NOT edit, see https://github.com/stefanmaric/g


# We only want to run gpg-agent on our local workstation. We accomplish that by trying to
# detect if this shell was spawned from ssh or not. If the SSH_CLIENT env var is set, then
# this is probably a remote login and we don't want to run gpg-agent.


if [ ! -n "$SSH_CLIENT" ]; then
	gpgconf --launch gpg-agent

	if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
		export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
	fi

	GPG_TTY=$(tty)
	export GPG_TTY
	# only necessary if using pinentry in the tty (instead of GUI)
	echo UPDATESTARTUPTTY | gpg-connect-agent > /dev/null 2>&1
fi
export PATH="/usr/local/opt/openssl@3/bin:$PATH"

unalias egrep
unalias fgrep
unalias grep
    unset GREP_OPTIONS EXC_FOLDERS

 #source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


export PATH=/opt/homebrew/bin:$PATH

