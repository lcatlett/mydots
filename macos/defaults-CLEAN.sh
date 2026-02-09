COMPUTER_NAME="lindseycatlett"

###############################################################################
# Backup Current Settings                                                    #
###############################################################################

BACKUP_DIR="$HOME/.dotfiles-backups"
BACKUP_FILE="$BACKUP_DIR/macos-defaults-$(date +%Y%m%d-%H%M%S).plist"

mkdir -p "$BACKUP_DIR"

echo "Creating backup of current macOS defaults..."
defaults read > "$BACKUP_FILE" 2>/dev/null

echo "✓ Backup saved to: $BACKUP_FILE"
echo ""
echo "To restore these settings:"
echo "  defaults import - \"$BACKUP_FILE\""
echo ""

osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "$COMPUTER_NAME"
sudo scutil --set HostName "$COMPUTER_NAME"
sudo scutil --set LocalHostName "$COMPUTER_NAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Dashboard settings removed - Dashboard was discontinued in macOS Catalina (2019)

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# # Require password immediately after sleep or screen saver begins
# defaults write com.apple.screensaver askForPassword -int 1
# defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable screenshot shadow
defaults write com.apple.screencapture disable-shadow -bool true

# Show/Hide icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Set the icon size of Dock items to 35 pixels
defaults write com.apple.dock tilesize -int 35

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Set format of date & hours in menu bar
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  HH:mm"

###############################################################################
# Developer / Software Architect Configurations                              #
###############################################################################

running "Show ~/Library folder (essential for developers)"
chflags nohidden ~/Library

running "Show ~/Library in Finder sidebar"
defaults write com.apple.finder ShowLibraryInSidebar -bool true

running "Set default Finder location to $HOME instead of Recent Files"
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

running "Enable 'Quit Finder' menu option"
defaults write com.apple.finder QuitMenuItem -bool true

###############################################################################
# Screenshot Configuration                                                    #
###############################################################################

running "Create dedicated Screenshots directory"
mkdir -p ~/screenshots

running "Save screenshots to ~/screenshots (not Desktop)"
defaults write com.apple.screencapture location -string "${HOME}/screenshots"

running "Include date in screenshot filenames"
defaults write com.apple.screencapture include-date -bool true

running "Disable screenshot thumbnail preview (faster workflow)"
defaults write com.apple.screencapture show-thumbnail -bool false

###############################################################################
# Performance & Visual Optimizations                                          #
###############################################################################

running "Disable transparency effects for better performance"
defaults write com.apple.universalaccess reduceTransparency -bool true

running "Faster window resize animations"
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

running "Disable window opening/closing animations"
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

running "Increase window resize speed"
defaults write NSGlobalDomain NSDocumentRevisionsWindowTransformAnimation -bool false

###############################################################################
# Terminal & Development Security                                             #
###############################################################################

running "Enable secure keyboard entry in Terminal (prevents keylogging)"
defaults write com.apple.Terminal SecureKeyboardEntry -bool true

running "Set unlimited scrollback in Terminal"
defaults write com.apple.Terminal "ScrollbackLines" -int 0

running "Close terminal windows when process exits"
defaults write com.apple.Terminal "ShellExitAction" -int 2

###############################################################################
# Mission Control & Spaces Optimizations                                      #
###############################################################################

running "Disable Mission Control window grouping by app"
defaults write com.apple.dock "expose-group-apps" -bool false

running "Don't automatically rearrange Spaces based on recent use"
defaults write com.apple.dock mru-spaces -bool false

running "Speed up Mission Control animations"
defaults write com.apple.dock expose-animation-duration -float 0.1

###############################################################################
# Keyboard & Input Enhancements                                               #
###############################################################################

running "Enable key repeat globally (disable press-and-hold for accents)"
defaults write -g ApplePressAndHoldEnabled -bool false

running "Set fastest keyboard repeat rate"
defaults write NSGlobalDomain KeyRepeat -int 1

running "Set shortest delay until key repeat"
defaults write NSGlobalDomain InitialKeyRepeat -int 10

running "Enable three-finger drag (accessibility trackpad feature)"
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Disk & File System Optimizations                                            #
###############################################################################

running "Avoid creating .DS_Store files on USB drives"
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

running "Enable AirDrop over Ethernet"
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

running "Show all file extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

###############################################################################
# Menu Bar & System UI                                                        #
###############################################################################

running "Show battery percentage in menu bar"
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

running "Show date and time in menu bar with custom format"
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  HH:mm"

running "Flash clock time separators (aesthetic preference)"
defaults write com.apple.menuextra.clock FlashDateSeparators -bool false

running "Show volume in menu bar"
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.volume" -bool true

# Kill all apps at once (10x faster)
killall "Calendar" "Contacts" "Dock" "Finder" "Mail" "Safari" "SystemUIServer" &> /dev/null

# Wait a bit before moving on...
sleep 1

# ...and then.
echo "Success! Defaults are set."
echo "Some changes will not take effect until you reboot your machine."
