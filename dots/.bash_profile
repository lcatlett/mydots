


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
