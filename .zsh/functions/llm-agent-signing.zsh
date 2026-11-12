#!/usr/bin/env zsh
# llm-agent-signing.zsh — commits and tags made by an LLM CLI are signed with the
# agent SSH key; commits typed in your own shell keep signing with your GPG key.
#
# Mechanism: git's per-process config overrides (GIT_CONFIG_COUNT, GIT_CONFIG_KEY_<n>,
# GIT_CONFIG_VALUE_<n>; see ENVIRONMENT in git-config(1)). The wrappers below export them
# only into the CLI process they start, so the CLI, its shells, hooks and MCP servers,
# and any agent CLI those start, all inherit them. Your interactive shell never has
# them, so dots/.gitconfig (gpg, commit.gpgsign, tag.gpgsign) stays in force there.
#
# Entries are APPENDED after any GIT_CONFIG_* already in the environment (Copilot CLI
# adds its own three to its shells and keeps inherited ones, verified 2026-11-11), and
# are skipped when already present, so an agent starting another agent adds nothing.
#
# Coverage per CLI (verified 2026-11-11):
#   claude   wrapper below; claude-akamai and claude-max in claude-akamai.zsh call
#            through _llm_agent_signing_exec. The claude-multiprofile aliases in .zshrc
#            expand to `claude`, so they use the wrapper.
#   codex    wrapper below, plus [shell_environment_policy.set] in codex/config.toml,
#            which also covers Codex started outside this shell (desktop app).
#            tests/validate.sh fails if the two lists differ.
#   agy      wrapper below. agy has no setting for the environment of its commands.
#   copilot  wrapper below. Copilot CLI has no environment setting.
# Not covered: an agent started without going through an interactive zsh (IDE
# extensions, desktop apps other than Codex). Claude Code's own "env" key in
# ~/.claude/settings.json would cover those launches; that file belongs to the
# cc-global repo, not this one.
#
# Key material (not in this repo): ~/.ssh/llm_agents_signing{,.pub} and
# ~/.config/llm-agents/allowed_signers. Without the key the wrappers warn on stderr and
# start the CLI with your default signing, so agent commits still work.
#
# Check the active state: llm-agent-signing-status

# Key/value pairs, in order. Mirrored in codex/config.toml [shell_environment_policy.set].
typeset -ga LLM_AGENT_SIGNING_CONFIG=(
  gpg.format                 ssh
  user.signingkey            "$HOME/.ssh/llm_agents_signing.pub"
  commit.gpgsign             true
  tag.gpgsign                true
  gpg.ssh.allowedSignersFile "$HOME/.config/llm-agents/allowed_signers"
)

# Run "$@" with the agent signing config appended to GIT_CONFIG_*. The variables are
# function-local exports: they reach the child process and vanish when it exits.
_llm_agent_signing_exec() {
  emulate -L zsh
  local pub=${LLM_AGENT_SIGNING_CONFIG[4]}
  if [[ ! -r $pub || ! -e ${pub%.pub} ]]; then
    print -ru2 -- "llm-agent-signing: $pub or its private key is missing;" \
      "$1 starts with your default git signing."
    command "$@"
    return
  fi

  local n=${GIT_CONFIG_COUNT:-0} i name
  if [[ $n != <-> ]]; then
    print -ru2 -- "llm-agent-signing: GIT_CONFIG_COUNT='$n' is not a number;" \
      "$1 starts without the agent signing config."
    command "$@"
    return
  fi

  # Already injected by an outer wrapper: nothing to add.
  for (( i = 0; i < n; i++ )); do
    name=GIT_CONFIG_KEY_$i
    if [[ ${(P)name} == user.signingkey ]]; then
      name=GIT_CONFIG_VALUE_$i
      if [[ ${(P)name} == $pub ]]; then
        command "$@"
        return
      fi
    fi
  done

  local key value
  for key value in "${LLM_AGENT_SIGNING_CONFIG[@]}"; do
    local -x "GIT_CONFIG_KEY_$n=$key" "GIT_CONFIG_VALUE_$n=$value"
    (( n++ ))
  done
  local -x GIT_CONFIG_COUNT=$n
  command "$@"
}

claude()  { _llm_agent_signing_exec claude "$@"; }
codex()   { _llm_agent_signing_exec codex "$@"; }
agy()     { _llm_agent_signing_exec agy "$@"; }
copilot() { _llm_agent_signing_exec copilot "$@"; }

# Print the signing config a git command would use here, and what an agent launched
# from here would get.
llm-agent-signing-status() {
  emulate -L zsh
  print -r -- "this shell:     gpg.format=$(git config --get gpg.format || print -n openpgp)" \
    "user.signingkey=$(git config --get user.signingkey)" \
    "commit.gpgsign=$(git config --get commit.gpgsign)" \
    "tag.gpgsign=$(git config --get tag.gpgsign)"
  print -r -- "agent launched: gpg.format=$(_llm_agent_signing_exec git config --get gpg.format)" \
    "user.signingkey=$(_llm_agent_signing_exec git config --get user.signingkey)"
}
