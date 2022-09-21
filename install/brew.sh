# Install Homebrew

if ( brew --version ) < /dev/null > /dev/null 2>&1; then
    echo 'Homebrew is already installed!'
else
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
fi

if ( brew cask --version; ) < /dev/null > /dev/null 2>&1; then
    echo 'Caskroom tapped already'
else
    brew tap homebrew/cask;
fi

if ( brew bundle check; ) < /dev/null > /dev/null 2>&1; then
    echo 'Brewfiles enabled'
else
    brew tap Homebrew/bundle;
    brew bundle;
fi

brew cleanup;
brew prune;
brew doctor;

# Wait a bit before moving on...
sleep 1

# ...and then.
echo "Success! Brew applications are installed."
