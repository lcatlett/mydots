export AH_SSH_CONFIG="${HOME}/.ssh/ah_config"

# include AH profile
if [ -f ~/.ah_profile ]; then
  . ~/.ah_profile
fi


if [ -f ~/.bashrc ]; then
  . ~/.zshrc
fi
# for file in ~/.{exports,aliases,functions,extra}; do
# 	[ -r "$file" ] && [ -f "$file" ] && source "$file";
# done;
# unset file;

# Include Drush bash customizations.
if [ -f "/Users/lindsey.catlett/.drush/drush.bashrc" ] ; then
  source /Users/lindsey.catlett/.drush/drush.bashrc
fi

# Include Drush prompt customizations.
if [ -f "/Users/lindsey.catlett/.drush/drush.prompt.sh" ] ; then
  source /Users/lindsey.catlett/.drush/drush.prompt.sh
fi
