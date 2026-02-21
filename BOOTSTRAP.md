# Bootstrap — Fresh Mac Setup

Estimated time: **~30 minutes to a working shell** (plus downloads).

This guide covers the full sequence from a blank Mac to a working development
environment using this dotfiles repo. It assumes Apple Silicon (M-series).

---

## Prerequisites

Before you start:

1. **Xcode Command Line Tools** — needed for git, compilers, and Homebrew.
   ```bash
   xcode-select --install
   ```
2. **Apple ID signed in** — required for any App Store apps in the Brewfile.
3. **Network access** — Homebrew and mise both download packages.

---

## Step-by-Step Install

### 1. Clone the repo

```bash
git clone https://github.com/lcatlett/mydots ~/dotfiles
cd ~/dotfiles
```

### 2. Install Homebrew and Brewfile packages

```bash
bash install/brew.sh
```

This installs Homebrew (if missing) and runs `brew bundle` against `install/Brewfile`.
It installs formulae, casks, fonts, and VS Code extensions.

After it finishes, make sure Homebrew is on your PATH for the rest of this session:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3. Create symlinks

```bash
bash install/symlinks.sh
```

This symlinks everything in `dots/` to `~/` and everything in `bin/` to `~/bin/`.
It also creates `~/.config/mise/` and symlinks the mise config.

### 4. Set up dots/.exports

```bash
cp dots/.exports.template dots/.exports
```

Open `dots/.exports` and fill in values. At minimum, set `EDITOR`. See the
template comments for what each variable does and where to get tokens.

The symlink from step 3 already points `~/.exports` at this file.

### 5. Install mise tools

```bash
mise install
```

This reads `~/.config/mise/config.toml` (symlinked in step 3) and installs all
language runtimes and CLI tools — Node, Python, Go, PHP, Ruby, Bun, bat, eza,
fd, fzf, ripgrep, delta, starship, zoxide, and ~40 more.

### 6. Open a new shell and verify

```bash
exec zsh -l
```

The shell should start cleanly with the Starship prompt. If you see errors,
check the Troubleshooting section below.

### 7. Apply macOS defaults (review first)

Read through `macos/defaults.sh` before running it. It changes trackpad
behavior, Finder settings, screenshot format, Dock size, keyboard repeat,
and other system preferences. Some changes require a reboot.

```bash
bash macos/defaults.sh
```

### 8. Configure the Dock (review first)

Read `macos/dock.sh` — it clears the entire Dock and adds specific apps.
Make sure those apps are installed first.

```bash
bash macos/dock.sh
```

Requires `dockutil`. If missing: `brew install dockutil`.

---

## Day 2 — Manual Steps

These cannot be scripted and need to be done by hand.

### SSH keys

Generate a new key or transfer an existing one:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Add the public key to GitHub: `cat ~/.ssh/id_ed25519.pub | pbcopy`, then paste
at https://github.com/settings/keys.

Create `~/.ssh/config` if it doesn't exist:

```
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

### GPG key (for commit signing)

Generate or import a GPG key. `gnupg` and `pinentry-mac` are already installed
via Brewfile.

```bash
gpg --full-generate-key
```

Then tell git to use it:

```bash
gpg --list-secret-keys --keyid-format=long
git config --global user.signingkey <KEY_ID>
```

### iTerm2 profile

Import the color scheme and profile from `iterm/`:

1. Open iTerm2 > Settings > Profiles > Colors > Color Presets > Import
2. Select the `.itermcolors` file from `~/dotfiles/iterm/`

### 1Password or secrets manager

Set up your secrets manager first if you need tokens for `dots/.exports`
(e.g., `HOMEBREW_GITHUB_API_TOKEN`).

### App Store apps

Any apps not covered by the Brewfile need to be installed manually from the
App Store. Check `install/Brewfile` for what's already handled.

---

## Verification

Run these to confirm the setup is working:

```bash
# mise is installed and active
which mise && mise --version

# Starship prompt is installed
which starship && starship --version

# Dotfiles repo is clean
git -C ~/dotfiles status

# PATH has the right entries (mise shims, ~/bin, Homebrew)
echo $PATH | tr ':' '\n' | head -10
```

Expected PATH order (top = highest priority):

```
~/.local/share/mise/shims
~/bin
~/.local/bin
/opt/homebrew/bin
/opt/homebrew/sbin
/usr/bin
/usr/sbin
```

---

## Troubleshooting

### "command not found: mise"

Homebrew installed mise but your shell doesn't see it yet.

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

If that fixes it, open a new shell — `.zshrc` should handle this on startup.

### Shell startup errors

Check for syntax errors in the shell config:

```bash
zsh -n ~/.zshrc
```

If `.exports` is missing or empty, you'll get warnings about unset variables.
Make sure you completed step 4.

### Symlinks broken or missing

Re-run symlinks:

```bash
bash ~/dotfiles/install/symlinks.sh
```

Or use the CLI shortcut (if `~/bin` is on PATH):

```bash
dotfiles symlinks
```

### mise tools not installed

If `mise install` ran before symlinks were set up, the config wasn't in place.
Re-run it after symlinks:

```bash
mise install
```

### Starship prompt not showing

Verify starship is installed and zshrc is initializing it:

```bash
which starship
grep starship ~/.zshrc
```

If `which starship` returns nothing, run `mise install` — starship is a mise-managed tool.
