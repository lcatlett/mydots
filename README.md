# Dotfiles
Dotfiles I use with MacOS Xenial mostly for PHP Web Development.

![iTerm2.app](https://raw.githubusercontent.com/lcatlett/mydots/master/screenshot.png)

Contains:
  1. [System defaults](https://github.com/lcatlett/mydots/blob/master/macos/defaults.sh) and [Dock icons setup](https://github.com/lcatlett/mydots/blob/master/macos/dock.sh)
  2. [Git config with aliases](https://github.com/lcatlett/mydots/blob/master/dots/.gitconfig), [Git global ignore](https://github.com/lcatlett/mydots/blob/master/dots/.gitignore_global)
  3. [Global aliases](https://github.com/lcatlett/mydots/blob/master/dots/.aliases)
  4. [Functions](https://github.com/lcatlett/mydots/blob/master/dots/.functions), `extract` extracts any compressed file,  `trash` moves a file to the MacOS trash, `my_ps` lists processes owned by a user, `loc` counts lines of code in the current directory, taking file extension as argument, `ram` to get the total ram consumed by an application, `quickdrupal` create and install a drupal 8 site of the latest stable release using the demo_umami profile.
  5. `Hack` font used in iTerm2
  6. iTerm2 profile
  7. `ssh-manager` command to manage ssh config hosts and keys, including copy public keys to clipboard, transfer to server and more with autocomplete
  8. Packages / CLI (brew, brew cask, dockutil, htop, iftop, openssl, composer, nmap, php70, php71, php72, brew-php-switcher, git, nvm with node/npm (node 6.2 with latest working npm, LTS node with latest working npm), python3, thefuck, wget, yarn, zsh, zsh-completions)
  9.  Applications (alfred, google-chrome, slack, spotify, sublime-text, vscode, sequel-pro, postman, iterm2, dashlane)
  10. `dotfiles` binary to manage dotfiles functions with autocomplete

## Install on a Fresh macOS Setup

These instructions are for when you've already set up your dotfiles. If you want to get started with your own dotfiles you can [find instructions below](#your-own-dotfiles).

### Before you re-install

First, go through the checklist below to make sure you didn't forget anything before you wipe your hard drive.

- Did you commit and push any changes/branches to your git repositories?
- Did you remember to save all important documents from non-iCloud directories?
- Did you save all of your work from apps which aren't synced through iCloud?
- Did you remember to export important data from your local database?
- Did you update [mackup](https://github.com/lra/mackup) to the latest version and ran `mackup backup`?

### Installing macOS cleanly

After going to our checklist above and making sure you backed everything up, we're going to cleanly install macOS with the latest release. Follow [this article](https://www.imore.com/how-do-clean-install-macos) to cleanly install the latest macOS.


On fresh installation of MacOS:

    sudo softwareupdate -i -a
    xcode-select --install

Clone and install dotfiles:

    git clone https://github.com/lcatlett/mydots.git ~/dotfiles
    cd ~/dotfiles
    cd ~/dotfiles/install
    chmod +wx install.sh
    chmod -R +wx ~/dotfiles/bin
    cp ~/dotfiles/bin/* /usr/local/bin/
    ./install.sh

## Additional steps

1. Install fonts
2. In iterm `Preferences > General > Load preferences from a custom folder or URL` and set it to `~/dotfiles/iterm`
3. Restore preferences by running `mackup restore`
4. Restart your computer to finalize the process
5. Enjoy

## The `dotfiles` command

    $ dotfiles
    ￫ Usage: dotfiles <command>

    Commands:
    help             This help message
    update           Update packages and pkg managers (OS, brew, node, npm, yarn, commposer)
    clean            Clean up caches (brew, npm, yarn, composer)
    symlinks         Run symlinks script
    brew             Run brew script
    node             Run node setup script
    ohmyzsh          Run oh my zsh script
    hosts            Run hosts script
    defaults         Run MacOS defaults script
    osxextended      Run MacOS extended config script
    dock             Run MacOS dock script

## The `ssh-manager` command

    $ ssh-manager
    ￫ Usage: ssh-manager <command>

    Commands:
    help             This help message
    list             List of all SSH keys and hosts in SSH config
    list-keys        List of all SSH keys
    copy             Copy public SSH key
    new              Generate new SSH key
    host             Add host to SSH config, use --key to generate new key
    remove           Remove host from SSH config
    list-host        List of all hosts in SSH config


    ## Your Own Dotfiles

If you want to start with your own dotfiles from this setup, it's pretty easy to do so. First of all you'll need to fork this repo. After that you can tweak it the way you want.

**Please note that the instructions below assume you already have set up Oh My Zsh so make sure to first [install Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh#getting-started) before you continue.**

Go through the [`macos`](./macos) files and adjust the settings to your liking. Settings are organizaed into three files for default, extended, and dock configuration. You can find many more settings in [the original script by Mathias Bynens](https://github.com/mathiasbynens/dotfiles/blob/master/.macos) and [Kevin Suttle's macOS Defaults project](https://github.com/kevinSuttle/MacOS-Defaults).

Check out the [`Brewfile`](./install/Brewfile) file and adjust the apps you want to install for your machine. Use [their search page](https://caskroom.github.io/search) to check if the app you want to install is available.

Check out the [`.aliases`](./dots/aliases) file and add your own aliases. If you need to tweak your `$PATH` check out the [`.exports`](./dots/.exports) file. These files get loaded in because the `$ZSH_CUSTOM` setting points to the `.dotfiles` directory. You can adjust the [`.zshrc`](./dots/.zshrc) file to your liking to tweak your Oh My Zsh setup. More info about how to customize Oh My Zsh can be found [here](https://github.com/robbyrussell/oh-my-zsh/wiki/Customization).

When installing these dotfiles for the first time you'll need to backup all of your settings with Mackup. Install Mackup and backup your settings with the commands below. Your settings will be synced to iCloud so you can use them to sync between computers and reinstall them when reinstalling your Mac. If you want to save your settings to a different directory or different storage than iCloud, [checkout the documentation](https://github.com/lra/mackup/blob/master/doc/README.md#storage).

```zsh
brew install mackup
mackup backup
```

You can tweak the shell theme, the Oh My Zsh settings and much more. Go through the files in this repo and tweak everything to your liking.

## Credits

Many thanks to the [dotfiles community](http://dotfiles.github.io/) and the creators of the incredibly useful tools.
