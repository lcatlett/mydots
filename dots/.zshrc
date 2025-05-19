zmodload zsh/zprof

#export NVM_LAZY_LOAD=true
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Suppress Powerlevel10k instant prompt warning
#typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
#export NVM_LAZY_LOAD=true
#source ~/.zsh-nvm/zsh-nvm.plugin.zsh

n ()
{
    # Block nesting of nnn in subshells
    [ "${NNNLVL:-0}" -eq 0 ] || {
        echo "nnn is already running"
        return
    }

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #      NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The command builtin allows one to alias nnn to n, if desired, without
    # making an infinitely recursive alias
    command nnn -xR "$@"

    [ ! -f "$NNN_TMPFILE" ] || {
        . "$NNN_TMPFILE"
        rm -f "$NNN_TMPFILE" > /dev/null
    }
}

fpath=(~/.zsh/completions $fpath)


#export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH



# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
#/usr/local/bin/keychain $HOME/.ssh/id_rsa

for file in ~/.{exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

unset file;

ZSH_DISABLE_COMPFIX=true

# Path to your oh-my-zsh installation.
#export ZSH="REDACTED-HOME/.oh-my-zsh"

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
#DSABLE_UNTRACKED_FILES_DIRTY="true"

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
#source $ZSH/oh-my-zsh.sh

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

#fpath+=$HOME/.zsh/pure
#autoload -U promptinit; promptinit
#prompt pure

# better shell history search
#eval "$(mcfly init zsh)"






# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#[ -s "REDACTED-HOME/google-cloud-sdk/path.zsh.inc" ]

#[ -s "REDACTED-HOME/google-cloud-sdk/completion.zsh.inc" ]


   # source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
   # source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# The next line updates PATH for the Google Cloud SDK.
#if [ -f "REDACTED-HOME/google-cloud-sdk/path.zsh.inc" ]; then . "REDACTED-HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
#if [ -f "REDACTED-HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "REDACTED-HOME/google-cloud-sdk/completion.zsh.inc"; fi

#eval "$(rbenv init -)"
export PANTHEON_CERT="REDACTED-HOME/certs/REDACTED@example.com.pem"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PANTHEON_CERT="REDACTED-HOME/certs/REDACTED@example.com.pem"




# aliases to unset

#unalias egrep
#unalias fgrep
#unalias grep
unset GREP_OPTIONS EXC_FOLDERS



export PATH=/opt/homebrew/bin:$PATH

export PATH=$HOME/bin:$PATH

export PATH="/usr/local/opt/openssl@3/bin:$PATH"

#fpath+=/opt/homebrew/share/zsh/site-functions

#autoload -U promptinit; promptinit
#prompt pure

#eval "$(zoxide init zsh)"



export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"



eval "$(mcfly init zsh)"


#eval $(ssh-agent)
#eval "$(ssh-agent -s)"


export COMPOSER_MEMORY_LIMIT=-1

 # We only want to run gpg-agent on our local workstation. We accomplish that by trying to
# detect if this shell was spawned from ssh or not. If the SSH_CLIENT env var is set, then
# this is probably a remote login and we don't want to run gpg-agent.

#ssh-add -K

# if [ ! -n “$SSH_CLIENT” ]; then
# gpgconf --launch gpg-agent
#  if [ “${gnupg_SSH_AUTH_SOCK_by:-0}” -ne $$ ]; then
#    export SSH_AUTH_SOCK=“$(gpgconf --list-dirs agent-ssh-socket)”
#  fi
#  GPG_TTY=$(tty)
#  export GPG_TTY
# fi
# gkill() {
#  killall -9 gpg-agent
#  gpgconf --launch gpg-agent
#  #if [ “${gnupg_SSH_AUTH_SOCK_by:-0}” -ne $$ ]; then
#  if [ ! -n “$SSH_CLIENT” ]; then
#   export SSH_AUTH_SOCK=“$(gpgconf --list-dirs agent-ssh-socket)”
#  fi
#  GPG_TTY=$(tty)
#  export GPG_TTY
#  ssh-add -L
# }

# Uncomment when yubukey support container is updatee

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


#ssh-add --apple-use-keychain ~/.ssh/id_rsa_bastion_lindsey >/dev/null 2>&1
# #ssh-add --apple-use-keychain ~/.ssh/id_rsa
ssh-add --apple-use-keychain ~/.ssh/id_rsa_migration >/dev/null 2>&1

# ssh-add --apple-use-keychain ~/.ssh/id_rsa_drupalorg

ssh-add --apple-use-keychain ~/.ssh/id_rsa >/dev/null 2>&1
ssh-add --apple-load-keychain -q >/dev/null 2>&1

#ssh-add --apple-load-keychain ~/.ssh/id_rsa


# env=~/.ssh/agent.env

# agent_load_env () { test -f "$env" && . "$env" >| /dev/null ; }

# agent_start () {
#     (umask 077; ssh-agent >| "$env")
#     . "$env" >| /dev/null ; }

# agent_load_env

# # agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
# agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

# if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
#     agent_start
#     ssh-add $HOME/.ssh/id_rsa
# elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
#     ssh-add $HOME/.ssh/id_rsa
# fi

# unset env

# SSH_ENV=$HOME/.ssh/environment

# # start the ssh-agent
# function start_agent {
#     echo "Initializing new SSH agent..."
#     # spawn ssh-agent
#     /usr/bin/ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
#     echo succeeded
#     chmod 600 ${SSH_ENV}
#     . ${SSH_ENV} > /dev/null
#     /usr/bin/ssh-add ~/.ssh/id_rsa
# }

# if [ -f "${SSH_ENV}" ]; then
#    . ${SSH_ENV} > /dev/null
#    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
#     start_agent
#   }
# else
#   start_agent
# fi

ssh_agent_init() {
  if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval "$(ssh-agent -s)"
    ssh-add -KA ~/.ssh/id_rsa
    #ssh-add -K ~/.ssh/id_rsa_bastion_lindsey
    ssh-add -K ~/.ssh/id_rsa_migration
    ssh-add -K ~/.ssh/id_rsa_drupalorg
  else
    ssh-add -l > /dev/null || {
      eval "$(ssh-agent -s)"
      ssh-add -KA ~/.ssh/id_rsa
      #ssh-add -KA ~/.ssh/id_rsa_bastion_lindsey
      ssh-add -KA ~/.ssh/id_rsa_migration
      ssh-add -KA ~/.ssh/id_rsa_drupalorg
    }
  fi
}

#ssh_agent_init




export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/bin/pkgconfig"

# If you come from bash you might have to change your $PATH.
# need this for x86_64 brew
export PATH=$HOME/bin:/usr/local/bin:$PATH

# if [ "$(sysctl -n sysctl.proc_translated)" = "1" ]; then
#     local brew_path="/usr/local/homebrew/bin"
#     local brew_opt_path="/usr/local/opt"
#     local nvm_path="$HOME/.nvm-x86"
# else
#     local brew_path="/opt/homebrew/bin"
#     local brew_opt_path="/opt/homebrew/opt"
#     local nvm_path="$HOME/.nvm"
# fi

export PATH="${brew_path}:${PATH}"
#export NVM_DIR="${nvm_path}"

# [ -s "${brew_opt_path}/nvm/nvm.sh" ] && . "${brew_opt_path}/nvm/nvm.sh"  # This loads nvm
# [ -s "${brew_opt_path}/nvm/etc/bash_completion.d/nvm" ] && . "${brew_opt_path}/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

 #export NVM_DIR="$HOME/.nvm"
#  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
 #[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
# for intel x86_64 brew
alias axbrew='arch -x86_64 /usr/local/homebrew/bin/brew'



#export MYSQL_CONFIG="$HOMEBREW_PREFIX/bin/mysql_config"

# export PERCONA_TOOLKIT_BRANCH=${HOME}/scripts/mariadb-tools
# export PERL5LIB=${HOME}/scripts/mariadb-tools/lib
# export PERCONA_TOOLKIT_SANDBOX=`which mysql`


export PATH="/opt/homebrew/sbin:$PATH"

#export PATH="/opt/homebrew/opt/mysql@5.7/bin:$PATH"

##export LDFLAGS="-L/opt/homebrew/opt/mysql@5.7/lib"
#export CPPFLAGS="-I/opt/homebrew/opt/mysql@5.7/include"
#export PATH="/opt/homebrew/opt/php@8.0/bin:$PATH"
#export PATH="/opt/homebrew/opt/php@8.0/sbin:$PATH"


#export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
##export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

#export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"


# test -d "$HOME/.tea" && source <("$HOME/.tea/tea.xyz/v*/bin/tea" --magic=zsh --silent)
#export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
##export PATH="/opt/homebrew/opt/php@8.2/bin:$PATH"

# Lando
#export PATH="REDACTED-HOME/.lando/bin${PATH+:$PATH}"; #landopathexport PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"
#export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"
#export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"
#eval "$(pyenv init --path)"
#eval "$(pyenv virtualenv-init -)"
#eval "$(pyenv init --path)"
#eval "$(pyenv virtualenv-init -)"
#export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client@8.0/bin:$PATH"
#export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"
#export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"

# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh



source ~/powerlevel10k/powerlevel10k.zsh-theme


# Init nvm
export NVM_DIR="$HOME/.nvm"
# NVM_STATE=$(cat REDACTED-HOME/.scripts/nvm.state)
# if [ $NVM_STATE = 1 ]; then
#     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#     [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# else
#     echo 'Warning: NVM not yet loaded'
#     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm
#     [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# fi



# if [ -f REDACTED-HOME/.scripts/nvm.state ]; then
#     NVM_STATE=$(cat REDACTED-HOME/.scripts/nvm.state)[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#     [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This
# else
#   #  echo "Warning: NVM state file not found"
#   #  echo 'Warning: NVM not yet loaded'
#     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm
#     [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet



#export PYENV_ROOT="$HOME/.pyenv"
#[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init - zsh)"

#[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

#zprof
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"
export PATH="/opt/homebrew/opt/php@8.3/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.3/sbin:$PATH"


#[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

#zprof