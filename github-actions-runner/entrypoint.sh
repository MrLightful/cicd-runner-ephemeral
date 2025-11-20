#!/bin/sh -l

# Construct URLs from scope, org, and repo
if [ "$GITHUB_SCOPE" = "org" ]; then
  GH_REGISTER_RUNNER_URL="https://api.github.com/orgs/$GITHUB_ORG/actions/runners/registration-token"
  GH_URL="https://github.com/$GITHUB_ORG"
else
  GH_REGISTER_RUNNER_URL="https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/actions/runners/registration-token"
  GH_URL="https://github.com/$GITHUB_ORG/$GITHUB_REPO"
fi

# Retrieve a short lived runner registration token using the PAT
GH_RUNNER_REGISTRATION_TOKEN="$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $GITHUB_PAT" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$GH_REGISTER_RUNNER_URL" \
  | jq -r '.token')"

./config.sh --url $GH_URL --token $GH_RUNNER_REGISTRATION_TOKEN --labels $GITHUB_RUNNER_LABELS --unattended --ephemeral && ./run.sh
