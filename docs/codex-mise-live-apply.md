# Codex: single install channel through mise — live-apply runbook

Moves the machine from three Codex channels (self-updating standalone in
`~/.local/bin`, Homebrew cask, app-server daemon package) to one: the exact
mise pin in `mise/config.toml`, with Codex's own update prompt switched off in
`codex/config.toml`. Everything below changes the live machine; run it only
when that change is approved.

Facts below were checked against the Codex source at tag `rust-v0.160.0`
(commit `a956835d020762cb2b570053af06f643a11c0ecc`) and mise `2026.10.0`.

## Ground rules

- `~/.codex/config.toml`, `~/.codex/config.toml.bak-*` and the step 5 backup
  hold plaintext MCP credentials. Never `cat`, `diff`, `grep` values from, or
  copy them; the one copy allowed is the step 5 backup. The only inspection
  allowed is `dotfiles codex-preflight` in step 0 (names only).
- Every command below that shows Codex configuration (greps of config files,
  `codex mcp list`, the review header) is piped through `dotfiles codex-redact`,
  which replaces anything secret-shaped with `<redacted>`; `bin/codex-config`
  filters everything it prints the same way. A private key (PEM of any type,
  PGP, PuTTY, or one inside a JSON string) is replaced whole, and one with no
  closing line is masked through the end of the input.
- Never `brew uninstall --zap codex`: the cask's zap stanza is `rmdir ~/.codex`.
- Close every running Codex session first (TUI, `codex exec`, reviews in
  Archon runs). Step 3 stops the daemon those sessions may be attached to.

## 0. Preconditions

The reviewed branch must be merged into the checkout that `dotfiles` and mise
read, because `dotfiles codex-release` copies `$DOTFILES_DIR/codex/config.toml`
and the global mise config is a symlink into the same checkout.

```bash
readlink ~/bin/dotfiles                 # -> ~/dotfiles/bin/dotfiles
readlink ~/.config/mise/config.toml     # -> ~/dotfiles/mise/config.toml
grep -n 'aqua:openai/codex' ~/dotfiles/mise/config.toml | dotfiles codex-redact   # "aqua:openai/codex" = "0.160.0"
grep -n -E '^(model|model_reasoning_effort|check_for_update_on_startup) ' ~/dotfiles/codex/config.toml | dotfiles codex-redact
# model = "gpt-6-astra" / model_reasoning_effort = "high" / check_for_update_on_startup = false
```

Record the starting state (paths and versions only):

```bash
which -a codex
ls -l ~/.local/bin/codex ~/.local/bin/codex-code-mode-host
ls -l ~/.codex/packages ~/.codex/packages/*/current
brew list --cask --versions codex
pgrep -fl 'codex app-server'
```

### MCP settings the release will drop

Step 5 replaces the live config with the reviewed one, so anything only the
live file has must be migrated before the machine changes. The preflight
compares, per MCP server, the `env` and `http_headers` keys and the variable
names each server inherits (`env_vars`, `bearer_token_env_var`,
`env_http_headers`), plus whether `command` and `url` are set. It prints server
names, keys and variable names only, never values. It refuses with exit 2 a
file where one of those holds secret-shaped material (a credential pasted into
a name) or a variable-name field holds anything but a variable name; the error
names the field, shows secret-shaped parts as `<redacted>` and echoes no value.
Fix that field by hand in an editor (export the credential from `~/.exports`,
leave its variable name in the field) and rerun:

```bash
dotfiles codex-preflight                # live ~/.codex/config.toml vs ~/dotfiles/codex/config.toml
```

```
[pal] both
  pal.env_vars.AZURE_OPENAI_API_KEY: live only, dropped by release
  pal.env_vars.OPENROUTER_API_KEY: release only, added
Codex config preflight: FAIL: unaccepted drops: 1; ...   (exit 1)
```

It exits 0 with `clean` when nothing differs and `PASS` when every difference
is an addition or an accepted drop; it exits 1 while any drop is unaccepted. For each `live only` server or
entry you want to keep: export the credential from `~/.exports` (never from
this repo), add it to the server in `codex/config.toml` (`env_vars = ["NAME"]`
for a credential), authorize the name under `inherited_env` in
`codex/policy.toml`, land that as its own reviewed change, merge it into
`~/dotfiles`, and rerun the preflight. Accept each drop you do mean by its id:

```bash
dotfiles codex-preflight --accept-drop pal.env_vars.AZURE_OPENAI_API_KEY --accept-drop legacy-server
```

A server id accepts everything a dropped server held; on a server the release
keeps, each entry needs its own `--accept-drop`. Continue only when the
preflight exits 0.

## 1. Install the pinned Codex with mise

```bash
cd ~ && mise install aqua:openai/codex
mise ls aqua:openai/codex               # 0.160.0  ~/.config/mise/config.toml  0.160.0
"$(mise which codex)" --version         # codex-cli 0.160.0
```

mise's default `minimum_release_age` is 24h. On 2026-10-05 it hid 0.160.1
(published 2026-10-05T18:29:37Z). To move the pin later, check
`mise latest aqua:openai/codex`, edit the pin on a branch, and repeat this step.

## 2. Remove the standalone channel

```bash
rm ~/.local/bin/codex ~/.local/bin/codex-code-mode-host   # symlinks into packages/standalone
rm -rf ~/.codex/packages/standalone
rm -f ~/.codex/version.json                               # cached "update available" state
```

The standalone installer (`https://chatgpt.com/codex/install.sh`) can also add a
`# >>> Codex installer >>>` PATH block to `~/.zprofile` on macOS zsh. None was
present on 2026-10-05; confirm:

```bash
grep -l 'Codex installer' ~/.zprofile ~/.zshrc ~/.zshenv ~/.bash_profile ~/.bashrc ~/.profile 2>/dev/null
# no output expected; if a file is listed, delete that marked block
```

## 3. Stop and remove the app-server daemon channel

The running daemon is a second self-updating Codex
(`~/.codex/packages/app-server-daemon`, 0.160.1 on 2026-10-05) with an hourly
updater loop (`pid-update-loop`). `codex` started from a terminal reuses a
running local daemon when it finds one (`tui/src/lib.rs`, `AppServerTarget::LocalDaemon
{ allow_embedded_fallback: true }`), so while it runs, sessions are served by
the daemon's binary, not the mise pin. Its updater runs `install.sh` with
`CODEX_INSTALL_DAEMON_ONLY=1`, which exits before touching `~/.local/bin`
(`scripts/install/install.sh` at the tag; the updater downloads the live
copy from chatgpt.com), so it cannot recreate the standalone symlink,
but it is still an unpinned channel.

```bash
~/.codex/packages/app-server-daemon/current/bin/codex app-server daemon stop
pgrep -fl 'codex app-server'            # if pid-update-loop is still listed: kill <its pid>
rm -rf ~/.codex/packages/app-server-daemon
find ~/.codex/app-server-daemon -maxdepth 1 -name 'daemon*' -delete   # pid, lock, socket, log files
```

So that a daemon bootstrapped later does not self-update, set its updater off.
The daemon reads `~/.codex/app-server-daemon/settings.json`
(`app-server-daemon/src/settings.rs`, `updater.autoUpdateEnabled`, default
`true`); the file did not exist on 2026-10-05:

```bash
test -e ~/.codex/app-server-daemon/settings.json && echo "exists: merge by hand" \
  || printf '{"updater":{"autoUpdateEnabled":false}}\n' > ~/.codex/app-server-daemon/settings.json
```

Residual: a later `codex app-server daemon start|bootstrap` installs the
current public daemon package once (the daemon owns its package regardless of
how the CLI was installed, `app-server-daemon/src/managed_install.rs`). Repeat
this step if that happens.

## 4. Remove the Homebrew cask

```bash
brew uninstall --cask codex             # not --zap
```

`install/Brewfile.laptop` no longer declares the cask, so `dotfiles brew` does
not reinstall it. The cask also generated shell completions; mise does not.
`codex completion zsh` regenerates them if they are wanted.

## 5. Back up the live config, then release the reviewed one

`--apply` keeps no copy of what it replaces, so back the live file up first, at
mode 0600, in a directory outside any git work tree:

```bash
backup_dir="$HOME/.codex-release-backup"
backup="$backup_dir/config.toml.pre-mise"
if git -C "$HOME" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "\$HOME is inside a git work tree: choose a backup_dir outside it"
elif test -e "$backup"; then
  echo "backup already exists: stop"
else
  install -d -m 700 "$backup_dir" && (umask 077 && cp ~/.codex/config.toml "$backup")
fi
stat -f '%Lp %N' "$backup_dir" "$backup"   # 700 .../.codex-release-backup, 600 .../config.toml.pre-mise
cmp -s ~/.codex/config.toml "$backup" && echo "backup matches live"
```

Do not run `--apply` unless both modes show and `backup matches live` prints.

Then release:

```bash
dotfiles codex-release                  # dry run
dotfiles codex-release --apply
dotfiles codex-check
```

Dry-run output from the branch on 2026-10-05:

```
Codex MCP policy: PASS
Codex config release dry run: would copy <checkout>/codex/config.toml to /Users/lcatlett/.codex/config.toml
```

`--apply` validates the reviewed file against `codex/policy.toml`, then
atomically replaces the live file with it at mode 0600 (`bin/codex-config`,
`command_release`). It does not merge: everything Codex wrote into the live
file that is not in the reviewed copy is discarded, including literal MCP
credentials (`codex mcp add --env KEY=VALUE` writes them to
`[mcp_servers.<name>.env]`). Neither the dry run nor `--apply` reads or prints
live values. `dotfiles codex-check` afterwards should report the live file as
policy PASS and drift clean.

If the release breaks something, restore the backup:

```bash
cp ~/.codex-release-backup/config.toml.pre-mise ~/.codex/config.toml && chmod 600 ~/.codex/config.toml
```

Step 6 deletes the backup.

## 6. Do MCP servers need to log in again?

- Servers authenticated by an environment variable (`env_vars`,
  `bearer_token_env_var`) keep working as long as the variable is exported.
- OAuth tokens from `codex mcp login` are not stored in `config.toml`: they live
  in the macOS Keychain service `Codex MCP Credentials`, or
  `~/.codex/.credentials.json` when no keyring is available, keyed by server
  name and URL (`rmcp-client/src/oauth.rs`; `mcp_oauth_credentials_store`,
  default `auto`). The release does not touch them, so an OAuth server present
  in the reviewed config under the same name and URL needs no new login.
- A server that only existed in the live file disappears with the release. Once
  it is added back through the reviewed config under the same name and URL, its
  stored OAuth token is found again; a new name or URL means `codex mcp login <name>`.
- After the release, `codex mcp list | dotfiles codex-redact` shows each
  server's auth status. Codex prints commands, args and URLs verbatim; the
  filter masks secret-shaped ones.

Once every server you kept shows as authenticated in `codex mcp list` (after
any `codex mcp login`), delete the step 5 backup:

```bash
rm ~/.codex-release-backup/config.toml.pre-mise && rmdir ~/.codex-release-backup
```

## 7. Verify

Each shell must list only paths under `~/.local/share/mise/` (the install dir
when `mise activate` has run, the shims dir otherwise):

```bash
zsh -ic 'which -a codex; codex --version'                 # operator's interactive shell
which -a codex; codex --version                           # Claude Code Bash tool
cd <an Archon worktree> && which -a codex && codex --version
# every codex --version: codex-cli 0.160.0
pgrep -fl 'codex app-server'                              # no daemon unless deliberately started
```

The review header shows the reviewed model and effort:

```bash
tmp=$(mktemp -d) && cd "$tmp" && git init -q && echo a > f && git add f \
  && git commit -qm init && echo b >> f && codex review --uncommitted 2>&1 | head -12 \
  | dotfiles codex-redact
# OpenAI Codex v0.160.0
# model: gpt-6-astra
# reasoning effort: high
```

Starting `codex` interactively must not offer an update: the prompt needs both
`check_for_update_on_startup = true` and a detected install method, and
neither holds (next section).

## Why the standalone updater cannot come back

1. `check_for_update_on_startup = false` in `codex/config.toml`. Documented in
   `codex-rs/config/src/config_toml.rs` ("Set to `false` only if your Codex
   updates are centrally managed", default `true`); it short-circuits the
   background version check and the update popup
   (`codex-rs/tui/src/updates.rs`, `get_upgrade_version` and
   `get_upgrade_version_for_popup`).
2. The install method is detected from the running binary's path
   (`codex-rs/install-context/src/lib.rs`, `install_method_from_exe`): only
   binaries under `~/.codex/packages/standalone/releases` are `Standalone`,
   only `/opt/homebrew` and `/usr/local` are `Brew`. A mise binary under
   `~/.local/share/mise/installs` is `Other`, which maps to no update action
   (`codex-rs/tui/src/update_action.rs`), so the prompt is skipped
   (`codex-rs/tui/src/update_prompt.rs`) and `codex update` stops with "Could
   not detect the Codex installation method" (`codex-rs/cli/src/main.rs`).
3. The daemon updater is the only other path that runs `install.sh`, and step 3
   removes it and turns its updater off.
