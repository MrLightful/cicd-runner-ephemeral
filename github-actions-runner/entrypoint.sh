#!/bin/bash -l

set -eo pipefail

# --- Helper: base64url encode (no padding) ---
base64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# --- Helper: Generate a JWT for GitHub App authentication ---
generate_jwt() {
  local app_id="$1"
  local private_key="$2"

  local header='{"alg":"RS256","typ":"JWT"}'
  local now
  now=$(date +%s)
  local iat=$((now - 60))
  local exp=$((now + 600))
  local payload
  payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$iat" "$exp" "$app_id")

  local header_b64
  header_b64=$(printf '%s' "$header" | base64url)
  local payload_b64
  payload_b64=$(printf '%s' "$payload" | base64url)

  local unsigned="${header_b64}.${payload_b64}"
  local key_file
  key_file=$(mktemp)
  printf '%s' "$private_key" > "$key_file"
  local signature
  signature=$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "$key_file" | base64url)
  rm -f "$key_file"

  printf '%s.%s' "$unsigned" "$signature"
}

# --- Helper: Get an installation access token from a GitHub App ---
get_installation_token() {
  local app_id="$1"
  local private_key="$2"
  local installation_id="$3"

  local jwt
  jwt=$(generate_jwt "$app_id" "$private_key")

  local response
  response=$(curl -sS -X POST \
    -H 'Accept: application/vnd.github.v3+json' \
    -H "Authorization: Bearer $jwt" \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "https://api.github.com/app/installations/${installation_id}/access_tokens")

  local token
  token=$(printf '%s' "$response" | jq -r '.token // empty')

  if [ -z "$token" ]; then
    echo "Error: Failed to obtain installation access token from GitHub App." >&2
    echo "API response: $response" >&2
    exit 1
  fi

  printf '%s' "$token"
}

# --- Determine authentication method ---
if [ -n "$GITHUB_APP_ID" ] && [ -n "$GITHUB_APP_INSTALLATION_ID" ]; then
  # GitHub App auth: resolve the private key from a file or env var
  if [ -n "$GITHUB_APP_PRIVATE_KEY_FILE" ] && [ -f "$GITHUB_APP_PRIVATE_KEY_FILE" ]; then
    GITHUB_APP_PRIVATE_KEY=$(cat "$GITHUB_APP_PRIVATE_KEY_FILE")
  fi

  if [ -z "$GITHUB_APP_PRIVATE_KEY" ]; then
    echo "Error: GITHUB_APP_PRIVATE_KEY (or GITHUB_APP_PRIVATE_KEY_FILE) must be set when using GitHub App authentication." >&2
    exit 1
  fi

  # Normalize PEM newlines: Azure Key Vault / Container App secrets often escape
  # real newlines to literal '\n' characters, which breaks OpenSSL key parsing.
  if printf '%s' "$GITHUB_APP_PRIVATE_KEY" | grep -q '\\n'; then
    GITHUB_APP_PRIVATE_KEY=$(printf '%b' "$GITHUB_APP_PRIVATE_KEY")
  fi

  echo "Authenticating as GitHub App (App ID: $GITHUB_APP_ID, Installation ID: $GITHUB_APP_INSTALLATION_ID)..."
  GH_TOKEN=$(get_installation_token "$GITHUB_APP_ID" "$GITHUB_APP_PRIVATE_KEY" "$GITHUB_APP_INSTALLATION_ID")
elif [ -n "$GITHUB_PAT" ]; then
  GH_TOKEN="$GITHUB_PAT"
else
  echo "Error: No authentication configured. Set GITHUB_PAT, or set GITHUB_APP_ID, GITHUB_APP_PRIVATE_KEY, and GITHUB_APP_INSTALLATION_ID." >&2
  exit 1
fi

# --- Construct URLs from scope, org, and repo ---
if [ "$GITHUB_SCOPE" = "org" ]; then
  GH_REGISTER_RUNNER_URL="https://api.github.com/orgs/$GITHUB_ORG/actions/runners/registration-token"
  GH_URL="https://github.com/$GITHUB_ORG"
else
  GH_REGISTER_RUNNER_URL="https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/actions/runners/registration-token"
  GH_URL="https://github.com/$GITHUB_ORG/$GITHUB_REPO"
fi

# --- Retrieve a short-lived runner registration token ---
REG_RESPONSE=$(curl -sS -X POST \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$GH_REGISTER_RUNNER_URL")

GH_RUNNER_REGISTRATION_TOKEN=$(printf '%s' "$REG_RESPONSE" | jq -r '.token // empty')

if [ -z "$GH_RUNNER_REGISTRATION_TOKEN" ]; then
  echo "Error: Failed to obtain runner registration token." >&2
  echo "API response: $REG_RESPONSE" >&2
  exit 1
fi

./config.sh --url "$GH_URL" --token "$GH_RUNNER_REGISTRATION_TOKEN" --labels "$GITHUB_RUNNER_LABELS" --unattended --ephemeral && ./run.sh
