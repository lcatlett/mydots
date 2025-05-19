


if [ -f ~/.bashrc ]; then
  . ~/.zshrc
fi
# for file in ~/.{exports,aliases,functions,extra}; do
# 	[ -r "$file" ] && [ -f "$file" ] && source "$file";
# done;
# unset file;

# Include Drush bash customizations.
if [ -f "~/.drush/drush.bashrc" ] ; then
  source /Users/lindsey.catlett/.drush/drush.bashrc
fi

# Include Drush prompt customizations.
if [ -f "~/.drush/drush.prompt.sh" ] ; then
  source ~/.drush/drush.prompt.sh
fi
ssh-add -A 2>/dev/null
. "$HOME/.cargo/env"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :

. "$HOME/.local/bin/env"
