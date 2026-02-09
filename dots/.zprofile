#eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
#source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Run log symlink updater at login iin background

# Only run this if the symlink ~/logs-current does not exist

#if [ ! -L ~/logs-current ]; then
 # ~/scripts/log-analysis/update-log-symlink.sh
#fi





#~/scripts/log-analysis/update-log-symlink.sh &
#export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"



# Ensure ~/bin comes before ~/.local/bin (so wrappers win)
# Ensure ~/bin comes first (so wrappers win)
#export PATH