# Changelog

All notable changes to this dotfiles repo are documented here.

## [unreleased]

### New Features

- *(mise)* Track global mise config in dotfiles repo
- *(ci)* Add shellcheck GitHub Actions workflow

### Bug Fixes

- *(zshrc)* Remove redundant mise exec aliases and wrapper functions
- *(shell)* Resolve shellcheck errors across install and macos scripts

### Other

- Initial commit.
- Update screenshot path.
- Update readme.
- Updates to bin scripts.
- Update README.md
- Remove acquia config.
- Update README.md
- Recent updates.
- Delete settings.jar
- Merge pull request #1 from lcatlett/lcatlett-patch-1

Delete settings.jar
- Delete Preferences.sublime-settings
- Merge pull request #2 from lcatlett/lcatlett-patch-2

Delete Preferences.sublime-settings
- Update node_setup.sh
- Removed cruft,dupes, and updated homebrew packages.
- Updating templates with latest changes.
- Update brew packages.
- Update for M1 mac.
- Update for refreshing comp.
- Update dotfiles.
- Update for migrating laptop.
- Update brew packages
- Update bin files.
- Update default bin scripts.
- Update dotfiles.
- Export packages.
- Remove Pantheon exports/creds, fix broken credential helper, add modern git defaults
- Remove Pantheon functions, sync live .zshrc (v3 cleaned version)
- Add modular zsh function files (complete v2 task 5.6)
- Expand gitignore: protect .exports, add OS/editor/AI artifact patterns
- Remove Pantheon scripts (siteme/collect-logz), clean brew.bak taps
- Update README: replace 8yr-old content with current mise/Starship setup
- Expand README: mise explainer, full tool inventory, shell architecture, git aliases
- Dotfile audit: security fixes, dead code removal, POSIX compat

Critical / High:
- Remove hardcoded ANTHROPIC_VERTEX_PROJECT_ID from gcloud.zsh (C10)
- Replace bash-isms with POSIX-compatible constructs across .zshrc, .bash_profile, .bashrc
- Fix BSD-incompatible ps flags in dev.zsh (H19)
- Quote all unquoted $1/$2 variables in filesystem.zsh (H13)
- Add missing autoload for colors in filesystem.zsh (H14)
- Remove dead npm() and php() wrapper functions from dev.zsh (H12)
- Fix trailing colon in network.zsh curl -o flag (L8)
- Remove useless cat|pax pipe in filesystem.zsh (M15)

Install chain cleanup:
- Delete node_setup.sh (cloned EOL nvm, installed Node 10)
- Delete yarn.sh (contained only `yarn global add gulp`)
- Delete composer.sh (empty file)
- Delete oh-my-zsh.sh (oh-my-zsh no longer used)
- Remove deleted scripts from install.sh invocation chain
- Remove dead oh-my-zsh theme files and autocomplete stubs

Brewfile cleanup:
- Remove go, node, python@3.9/3.10/3.11/3.12 (use mise instead)
- Remove diff-so-fancy (superseded by git-delta)
- Remove rust (use rustup instead)
- Remove cask (not a real formula)
- Remove thefuck (non-functional without eval)
- Remove nicoverbruggen/cask tap (no entries used it)
- Remove grunt-cli (not installed; use npx instead)
- Fix restart_service on php entries (keep only active php@8.2)

Config cleanup:
- Remove ~/.functions symlink from symlinks.sh (not sourced)
- Rename RED/GREEN/NC color vars to _DOTFILES_ namespace (L9)
- Delete dots/.extra (5-byte empty file still sourced by .bashrc)
- Delete dots/.hyper.js (unmaintained terminal, iTerm2 used instead)
- Remove or namespace-scope miscellaneous globals
- Add standalone utility scripts to bin/

- audit-system: macOS memory/process analysis (extracted from dev.zsh)
- claude-safe: run Claude Code in tmux to work around PTY escape bug
- code: editor switcher shim (VSCode/Cursor toggle)
- kill-claude: terminate Claude + MCP daemons (supports --dry-run)
- mise-audit: audit mise config and log issues (supports --fix)
- symlink-audit: detect and report broken symlinks
- syscheck: quick memory pressure and stuck process health check
- Reset Brewfile to clean baseline from brew.bak

Replace over-expanded Brewfile (generated dump with 250 lines of vscode
extensions and unsanctioned taps) with the known-good brew.bak baseline,
applying the same audit cleanup decisions:

- openssl@1.1 → openssl@3
- restart_service: true → :changed (httpd, php@8.0, redis)
- Remove: cask (not a formula), diff-so-fancy (→ git-delta), go/python@3.9/3.11
  (use mise), grunt-cli (use npx), thefuck (non-functional), nvm (use mise)
- Remove: deprecated homebrew/cask-fonts tap, implicit homebrew/bundle tap
- Remove: vscode extensions block (not managed via Brewfile)
- Add: git-delta (replacement for diff-so-fancy), php@8.2 link:true
- Remove php@8.2 — not in brew.bak baseline
- Remove PHP from Brewfile — managed via mise instead
- Fix Brewfile: resolve all brew bundle errors

- homebrew/services tap removed (deprecated, services now built-in)
- talal/tap removed (failed to clone, orphaned)
- drud/ddev tap + formula → ddev/ddev (ancient tap migration)
- lbzip2 removed (deprecated July 2025)
- box-project/box/box removed (unreadable formula)
- google-cloud-sdk cask → gcloud-cli (renamed)
- git-credential-manager-core cask → commented out (pkg installer
  requires interactive sudo; install manually via brew cask)
- redis-stack/redis-stack tap + cask removed (project discontinued)

brew bundle now completes cleanly: 122 dependencies, 0 failures
- Add CLAUDE.md and clean up install/shell config

- Add CLAUDE.md with project conventions, architecture, and guardrails
- Update README with current tool inventory and shell architecture
- Refactor bin/dotfiles CLI (cleaner subcommand dispatch)
- Remove bin/grab-logs (unused utility)
- Remove dots/.hushlogin (no longer needed)
- Update dots/.zshrc with mise exec aliases and startup optimizations
- Update install/symlinks.sh with current script list
- Update install/brew.sh and install/install.sh for current setup
- Update install/Brewfile with current package baseline
- Add fonts, cleanup.
- Fix ssh.
- Pre-publication cleanup: remove personal data, untrack sensitive files

- Untrack dots/.exports (was gitignored but still indexed)
- Remove iterm/com.googlecode.iterm2.plist (contained client project paths)
- Remove iterm/iTerm2 State.itermexport (11MB personal terminal state)
- Gitignore both iTerm files permanently
- Parameterize COMPUTER_NAME in macos/defaults.sh
- Remove outdated screenshot embed from README
- Add updated terminal screenshot to README

### Documentation

- *(exports)* Add .exports.template for fresh-machine setup
- Add BOOTSTRAP.md for fresh Mac setup
- *(readme)* Restructure for public audience
- *(claude)* Add git discipline section

### Maintenance

- *(gitignore)* Ignore .claude/ local tool state
- *(bin)* Remove compiled binaries from history, document replacements
- *(install)* Remove dead requirers.sh
- *(brewfile)* Remove tools duplicated in mise config
- Add MIT license and finalize .gitignore
- *(iterm)* Add README with color theme import instructions
