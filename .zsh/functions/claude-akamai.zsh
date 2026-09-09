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
#   - NODE_EXTRA_CA_CERTS is scoped to the one process, not every Node app on the box.
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
# Gateway deployment name. EMPTY BY DEFAULT — no --model flag is passed, so the gateway
# serves its own default. Set this once you know a valid deployment name:
#   export AKAMAI_CLAUDE_MODEL="<name>"      (in ~/.exports, or per-invocation)
#
# Note: the IT setup script hardcodes "claude-sonnet-4-6", which is not a valid Claude
# model id in any provider — current models are the Claude 5 family (claude-opus-5,
# claude-sonnet-5) and claude-haiku-4-5-20251001. Do not copy that value.
: ${AKAMAI_CLAUDE_MODEL:=""}

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

  if [[ ! -r "$AKAMAI_CLAUDE_CA_FILE" ]]; then
    print -ru2 -- "claude-akamai: CA bundle not readable at $AKAMAI_CLAUDE_CA_FILE"
    print -ru2 -- "  Node ignores the macOS keychain, so the corporate CA must be passed explicitly."
    print -ru2 -- "  Override with: AKAMAI_CLAUDE_CA_FILE=/path/to/bundle claude-akamai"
    return 1
  fi

  # CLAUDE_CONFIG_DIR is deliberately NOT set — inherited from the shell, so account
  # switching and config-dir switching stay independent. Both accounts share whatever
  # config dir is active: same plugins, skills, hooks, settings and history.
  #
  # Everything set here dies with the process.
  env -u CLAUDE_CODE_OAUTH_TOKEN CLAUDE_CODE_USE_FOUNDRY=1 \
      ANTHROPIC_FOUNDRY_API_KEY="$key" \
      ANTHROPIC_FOUNDRY_BASE_URL="$AKAMAI_CLAUDE_BASE_URL" \
      ANTHROPIC_CUSTOM_HEADERS="user-id: ${AKAMAI_CLAUDE_USER_ID}" \
      NODE_EXTRA_CA_CERTS="$AKAMAI_CLAUDE_CA_FILE" \
      CLAUDE_CODE_ENABLE_FINE_GRAINED_TOOL_STREAMING=1 \
      ${AKAMAI_CLAUDE_DEBUG:+ANTHROPIC_LOG=debug} \
      command claude ${AKAMAI_CLAUDE_MODEL:+--model "$AKAMAI_CLAUDE_MODEL"} "$@"
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
    || print -r -- "  CA bundle:   MISSING ($AKAMAI_CLAUDE_CA_FILE)"
  print -r -- "  config dir:  ${CLAUDE_CONFIG_DIR:-~/.claude (inherited)}"
  print -r -- "  model:       ${AKAMAI_CLAUDE_MODEL:-<gateway default>}"
}
