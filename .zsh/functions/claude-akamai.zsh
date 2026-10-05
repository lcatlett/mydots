#!/usr/bin/env zsh
# claude-akamai.zsh — run Claude Code against Akamai's Microsoft Foundry gateway
# without disturbing the personal Max (keychain/OAuth) login.
#
# Design: per-invocation wrappers, NOT a persistent mode toggle.
#   - Which account you get is decided by which command you type, never by shell state.
#     CLAUDE_CODE_USE_FOUNDRY (the var that actually selects the provider) is set only
#     for the one process, so a stale shell can't silently bill the wrong account —
#     even though the API key itself is exported shell-wide by ~/.exports.
#   - CLAUDE_CONFIG_DIR is inherited, not overridden: both accounts share the same
#     plugins, skills, hooks, settings and history. Profile switching is independent.
#   - NODE_EXTRA_CA_CERTS is scoped to the one process, not every Node app on the box,
#     and only set when the file exists: the native binary already trusts the macOS
#     store (CLAUDE_CODE_CERT_STORE defaults to bundled,system), so the file is a
#     fallback for npm installs on Node < 22.15. Verified 2026-09-30.
#
# Shareable general-user version (setup, VS Code, IT-script cleanup):
#   ../akamai-claude-setup/, published at git.source.akamai.com ~lcatlett/toolbox.
#
# SECRETS: keychain-backed, matching the existing ~/.exports pattern — the secret value
# lives only in the macOS Keychain; the dotfile holds a lookup, never a value.
#
#   1. Store the key (once):
#        security add-generic-password -a "$USER" -s ANTHROPIC_FOUNDRY_API_KEY -w
#
#   2. Add to ~/.exports (gitignored, already sourced by ~/.zshrc):
#        export ANTHROPIC_FOUNDRY_API_KEY="$(security find-generic-password -a "$USER" -s "ANTHROPIC_FOUNDRY_API_KEY" -w 2>/dev/null)"
#        export AKAMAI_CLAUDE_USER_ID="lcatlett_prod"   # not a secret
#
# Install: this file belongs in ~/.zsh/functions/ — per dotfiles/CLAUDE.md, .aliases is
# for aliases only and functions live in ~/.zsh/functions/*.zsh, which .zshrc auto-sources.
#   cp claude-akamai.zsh ~/dotfiles/.zsh/functions/
#   ln -sfv ~/dotfiles/.zsh/functions/claude-akamai.zsh ~/.zsh/functions/claude-akamai.zsh
# No .zshrc, .aliases or symlinks.sh edit is needed.
#
# This file contains no secrets and is safe to track in git.

# ---- configuration -----------------------------------------------------------
: ${AKAMAI_CLAUDE_CA_FILE:="$HOME/certs/trusted_certs.pem"}
: ${AKAMAI_CLAUDE_BASE_URL:="https://claude-llm.dash.akamai.com/apim/claude"}
# Starting model. EMPTY BY DEFAULT: no --model flag, so Claude Code picks (the opus
# alias in the CLI, sonnet in VS Code). Set e.g. AKAMAI_CLAUDE_MODEL=sonnet to override.
: ${AKAMAI_CLAUDE_MODEL:=""}
# What the opus/sonnet/haiku aliases resolve to. Without these pins Claude Code uses
# its built-in Foundry defaults, and `opus` means claude-opus-4-6. Gateway deployments
# verified 2026-09-30: claude-opus-{5-5,5,4-8,4-7,4-6,4-5},
# claude-sonnet-{5-5,5,4-6,4-5}, claude-haiku-4-5 (the dated -20251001 id 404s).
: ${AKAMAI_CLAUDE_OPUS_MODEL:="claude-opus-5-5"}
: ${AKAMAI_CLAUDE_SONNET_MODEL:="claude-sonnet-5-5"}
: ${AKAMAI_CLAUDE_HAIKU_MODEL:="claude-haiku-4-5"}

# ---- Akamai / Foundry --------------------------------------------------------
claude-akamai() {
  emulate -L zsh

  # Fall back to a direct keychain read if ~/.exports hasn't been sourced in this shell.
  local key="$ANTHROPIC_FOUNDRY_API_KEY"
  if [[ -z "$key" ]]; then
    key=$(security find-generic-password -a "$USER" -s "ANTHROPIC_FOUNDRY_API_KEY" -w 2>/dev/null)
  fi
  if [[ -z "$key" ]]; then
    print -ru2 -- "claude-akamai: no Foundry API key found."
    print -ru2 -- "  Store it in the keychain (matches your ~/.exports pattern):"
    print -ru2 -- "    security add-generic-password -a \"\$USER\" -s ANTHROPIC_FOUNDRY_API_KEY -w"
    print -ru2 -- "  Then add the lookup to ~/.exports:"
    print -ru2 -- "    export ANTHROPIC_FOUNDRY_API_KEY=\"\$(security find-generic-password -a \"\$USER\" -s \"ANTHROPIC_FOUNDRY_API_KEY\" -w 2>/dev/null)\""
    return 1
  fi

  if [[ -z "$AKAMAI_CLAUDE_USER_ID" ]]; then
    print -ru2 -- "claude-akamai: AKAMAI_CLAUDE_USER_ID is not set."
    print -ru2 -- "  Add to ~/.exports (not a secret):"
    print -ru2 -- "    export AKAMAI_CLAUDE_USER_ID=\"lcatlett_prod\""
    return 1
  fi

  local -a ca=()
  [[ -r "$AKAMAI_CLAUDE_CA_FILE" ]] && ca=(NODE_EXTRA_CA_CERTS="$AKAMAI_CLAUDE_CA_FILE")

  # CLAUDE_CONFIG_DIR is deliberately NOT set — inherited from the shell, so account
  # switching and config-dir switching stay independent. Both accounts share whatever
  # config dir is active: same plugins, skills, hooks, settings and history.
  #
  # Also cleared: ANTHROPIC_FOUNDRY_AUTH_TOKEN outranks the API key, and the other
  # provider selectors would compete with Foundry. Everything set here dies with the
  # process.
  env -u CLAUDE_CODE_OAUTH_TOKEN -u ANTHROPIC_FOUNDRY_AUTH_TOKEN \
      -u ANTHROPIC_FOUNDRY_RESOURCE -u CLAUDE_CODE_SKIP_FOUNDRY_AUTH \
      -u CLAUDE_CODE_USE_BEDROCK -u CLAUDE_CODE_USE_VERTEX -u CLAUDE_CODE_USE_MANTLE \
      -u CLAUDE_CODE_USE_ANTHROPIC_AWS -u ANTHROPIC_LOG \
      CLAUDE_CODE_USE_FOUNDRY=1 \
      ANTHROPIC_FOUNDRY_API_KEY="$key" \
      ANTHROPIC_FOUNDRY_BASE_URL="$AKAMAI_CLAUDE_BASE_URL" \
      ANTHROPIC_CUSTOM_HEADERS="user-id: ${AKAMAI_CLAUDE_USER_ID}" \
      ANTHROPIC_DEFAULT_OPUS_MODEL="$AKAMAI_CLAUDE_OPUS_MODEL" \
      ANTHROPIC_DEFAULT_SONNET_MODEL="$AKAMAI_CLAUDE_SONNET_MODEL" \
      ANTHROPIC_DEFAULT_HAIKU_MODEL="$AKAMAI_CLAUDE_HAIKU_MODEL" \
      "${ca[@]}" \
      CLAUDE_CODE_ENABLE_FINE_GRAINED_TOOL_STREAMING=1 \
      ${AKAMAI_CLAUDE_DEBUG:+ANTHROPIC_LOG=debug} \
      command claude ${AKAMAI_CLAUDE_MODEL:+--model} ${AKAMAI_CLAUDE_MODEL:+"$AKAMAI_CLAUDE_MODEL"} "$@"
}

# ---- personal Max / OAuth ----------------------------------------------------
# Clears the Foundry vars so a shell that has them exported still lands on the OAuth
# (keychain) login. ANTHROPIC_FOUNDRY_API_KEY is exported in every interactive shell by
# ~/.exports; CLAUDE_CODE_USE_FOUNDRY is what actually selects the provider, but the whole
# set is cleared so nothing is picked up implicitly.
#
# Deliberately NOT touched — these are about routing/profile, not about who is billed,
# so clearing them here would silently undo settings enabled on purpose elsewhere:
#   ANTHROPIC_BASE_URL   (gateway routing)
#   ANTHROPIC_API_KEY / ANTHROPIC_AUTH_TOKEN
#   CLAUDE_CONFIG_DIR    (profile selection)
claude-max() {
  emulate -L zsh
  env -u CLAUDE_CODE_USE_FOUNDRY -u ANTHROPIC_FOUNDRY_API_KEY \
      -u ANTHROPIC_FOUNDRY_AUTH_TOKEN -u CLAUDE_CODE_SKIP_FOUNDRY_AUTH \
      -u ANTHROPIC_FOUNDRY_BASE_URL -u ANTHROPIC_FOUNDRY_RESOURCE \
      -u ANTHROPIC_CUSTOM_HEADERS -u NODE_EXTRA_CA_CERTS \
      -u ANTHROPIC_LOG -u CLAUDE_CODE_ENABLE_FINE_GRAINED_TOOL_STREAMING \
      -u CLAUDE_CODE_OAUTH_TOKEN \
      command claude "$@"
}

# ---- status ------------------------------------------------------------------
claude-whoami() {
  emulate -L zsh
  print -r -- "plain \`claude\` in this shell would use:"
  if [[ -n "$CLAUDE_CODE_USE_FOUNDRY" ]]; then
    print -r -- "  → FOUNDRY (Akamai) — CLAUDE_CODE_USE_FOUNDRY is exported here"
    print -r -- "    base_url: ${ANTHROPIC_FOUNDRY_BASE_URL:-<unset>}"
  elif [[ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]]; then
    print -r -- "  → CLAUDE_CODE_OAUTH_TOKEN is set — a long-lived CI token, NOT your"
    print -r -- "    interactive login. Whichever account issued it is billed."
  elif [[ -n "$ANTHROPIC_API_KEY" || -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
    print -r -- "  → an API key/token is exported — billed to that key, not your subscription"
  else
    print -r -- "  → personal Max account (keychain OAuth)"
  fi
  # Routing is independent of identity: a gateway can front any of the above.
  [[ -n "$ANTHROPIC_BASE_URL" ]] \
    && print -r -- "    routed via ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
  print -r -- ""
  print -r -- "claude-akamai wiring:"
  if [[ -n "$ANTHROPIC_FOUNDRY_API_KEY" ]]; then
    print -r -- "  api key:     set in shell (${#ANTHROPIC_FOUNDRY_API_KEY} chars, via ~/.exports)"
  elif security find-generic-password -a "$USER" -s "ANTHROPIC_FOUNDRY_API_KEY" -w >/dev/null 2>&1; then
    print -r -- "  api key:     in keychain, but not exported in this shell (source ~/.exports)"
  else
    print -r -- "  api key:     MISSING — not in shell or keychain"
  fi
  [[ -n "$AKAMAI_CLAUDE_USER_ID" ]] \
    && print -r -- "  user-id:     $AKAMAI_CLAUDE_USER_ID" \
    || print -r -- "  user-id:     MISSING — add AKAMAI_CLAUDE_USER_ID to ~/.exports"
  [[ -r "$AKAMAI_CLAUDE_CA_FILE" ]] \
    && print -r -- "  CA bundle:   $AKAMAI_CLAUDE_CA_FILE" \
    || print -r -- "  CA bundle:   not found ($AKAMAI_CLAUDE_CA_FILE); OK, macOS store is used"
  print -r -- "  config dir:  ${CLAUDE_CONFIG_DIR:-~/.claude (inherited)}"
  print -r -- "  model:       ${AKAMAI_CLAUDE_MODEL:-<Claude Code default>}"
  print -r -- "  aliases:     opus=$AKAMAI_CLAUDE_OPUS_MODEL sonnet=$AKAMAI_CLAUDE_SONNET_MODEL haiku=$AKAMAI_CLAUDE_HAIKU_MODEL"
}
