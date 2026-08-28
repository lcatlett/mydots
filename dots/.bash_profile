
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
ssh-add -A 2>/dev/null
. "$HOME/.cargo/env"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :

. "$HOME/.local/bin/env"

# >>> open-knowledge cli >>>
# ! Contents within this block are managed by OpenKnowledge. Do not edit.
# ! Delete this whole block to opt out — OpenKnowledge will not re-add it.
[ -f "$HOME/.ok/env.sh" ] && . "$HOME/.ok/env.sh"
# <<< open-knowledge cli <<<

<<<<<<< HEAD
<<<<<<< HEAD


||||||| parent of 75bb83c (fix: mise and global package clean up.)
=======
>>>>>>> 75bb83c (fix: mise and global package clean up.)
||||||| parent of 61bc4e2 (wip housekeeping.)
=======

source /Users/lcatlett/.config/broot/launcher/bash/br
>>>>>>> 61bc4e2 (wip housekeeping.)
