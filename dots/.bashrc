for file in ~/.{exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

unset file;


#. "$HOME/.cargo/env"

bash -c zsh
