# Google Cloud Functions
# Source: Modularized from ~/.functions

# unset-impersonate: Remove GCloud service account impersonation
unset_impersonate() {
    gcloud config unset auth/impersonate_service_account
}

alias unset-impersonate='unset_impersonate'

# vclaude: Run Claude Code with Vertex AI
vclaude() {
  export CLAUDE_CODE_USE_VERTEX=1
  export ANTHROPIC_VERTEX_PROJECT_ID="REDACTED-GCP-PROJECT-ID"
  export CLOUD_ML_REGION="us-east5"
  
  if ! command -v claude >/dev/null 2>&1; then
    echo "vclaude: 'claude' not found. Install @anthropic-ai/claude-code." >&2
    return 1
  fi

  if ! command -v gcloud >/dev/null 2>&1; then
    echo "vclaude: 'gcloud' CLI not installed." >&2
    return 1
  fi

  local project_id="${VCLAUDE_PROJECT_ID:-${ANTHROPIC_VERTEX_PROJECT_ID}}"
  local region="${VCLAUDE_REGION:-${CLOUD_ML_REGION:-global}}"

  if [[ -z "$project_id" ]]; then
    echo "vclaude: set VCLAUDE_PROJECT_ID or ANTHROPIC_VERTEX_PROJECT_ID." >&2
    return 1
  fi

  if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
    echo "vclaude: no ADC available. Run 'gcloud auth login --update-adc'." >&2
    return 1
  fi

  local current_project
  current_project="$(gcloud config get-value project 2>/dev/null)"
  if [[ -n "$current_project" && "$current_project" != "$project_id" ]]; then
    echo "vclaude: warning: gcloud default project is '$current_project' but Vertex project is '$project_id'." >&2
  fi

  local -a env_vars=()
  env_vars+=("CLAUDE_CODE_USE_VERTEX=1")
  env_vars+=("ANTHROPIC_VERTEX_PROJECT_ID=${project_id}")
  env_vars+=("CLOUD_ML_REGION=${region}")

  [[ -n "${ANTHROPIC_MODEL:-}" ]] && env_vars+=("ANTHROPIC_MODEL=${ANTHROPIC_MODEL}")
  [[ -n "${ANTHROPIC_SMALL_FAST_MODEL:-}" ]] && env_vars+=("ANTHROPIC_SMALL_FAST_MODEL=${ANTHROPIC_SMALL_FAST_MODEL}")

  env "${env_vars[@]}" claude "$@"
}

# re-auth: Re-authenticate gcloud and update application default credentials
gcloud-reauth() {
  gcloud auth login --update-adc
}