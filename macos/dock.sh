#!/bin/sh

dockutil --no-restart --remove all
dockutil --no-restart --add "/Applications/Google Chrome.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "/Applications/Sequel Ace.app"
dockutil --no-restart --add "/Applications/Slack.app"

killall Dock

echo "Success! Dock is set."
