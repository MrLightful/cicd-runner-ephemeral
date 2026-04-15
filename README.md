# Self-hosted CI/CD runner images

Github Actions Runner & Azure Pipeline Agent docker images for self-hosting.

Automatically registers the runner with the repository and de-registers at the end.

Use-case: hosting with Azure Container Apps, so the runner is scaled up and down gracefully.

Based on [Microsoft's tutorial](https://learn.microsoft.com/azure/container-apps/tutorial-ci-cd-runners-jobs).

## Usage

### Prerequisites

- Docker installed and running
- A GitHub Personal Access Token (PAT) **or** a GitHub App
- Access to the GitHub repository or organization where you want to register runners

### Available Images

This repository provides two types of ephemeral CI/CD runners:

| Image | Purpose | GitHub Container Registry | Docker Hub |
|-------|---------|---------------------------|------------|
| GitHub Actions Runner | Self-hosted GitHub Actions runner | `ghcr.io/mrlightful/gh-actions-runner-ephemeral:latest` | `mrlightful/gh-actions-runner-ephemeral:latest` |
| Azure Pipelines Agent | Self-hosted Azure DevOps agent | `ghcr.io/mrlightful/az-pipelines-agent-ephemeral:latest` | `mrlightful/az-pipelines-agent-ephemeral:latest` |

**Supported Platforms:** linux/amd64, linux/arm64

**Available Tags:**
- `latest` - Latest stable version
- `v{version}` - Specific semantic version (e.g., `v1.2.3`)
- `{major}.{minor}` - Major.minor version (e.g., `1.2`)
- `{major}` - Major version (e.g., `1`)
- `commit-{sha}` - Specific commit builds

### Quick Start

```bash
# For repository-scoped runner
docker run --rm \
  -e GITHUB_PAT="ghp_your_token_here" \
  -e GITHUB_SCOPE="repo" \
  -e GITHUB_ORG="OWNER" \
  -e GITHUB_REPO="REPO" \
  -e GITHUB_RUNNER_LABELS="docker,linux,self-hosted" \
  mrlightful/gh-actions-runner-ephemeral:latest
```

```bash
# For organization-scoped runner
docker run --rm \
  -e GITHUB_PAT="ghp_your_token_here" \
  -e GITHUB_SCOPE="org" \
  -e GITHUB_ORG="OWNER" \
  -e GITHUB_RUNNER_LABELS="docker,linux,self-hosted" \
  mrlightful/gh-actions-runner-ephemeral:latest
```

```bash
# Using a GitHub App instead of a PAT
docker run --rm \
  -e GITHUB_APP_ID="123456" \
  -e GITHUB_APP_INSTALLATION_ID="78901234" \
  -e GITHUB_APP_PRIVATE_KEY="$(cat your-app.pem)" \
  -e GITHUB_SCOPE="repo" \
  -e GITHUB_ORG="OWNER" \
  -e GITHUB_REPO="REPO" \
  -e GITHUB_RUNNER_LABELS="docker,linux,self-hosted" \
  mrlightful/gh-actions-runner-ephemeral:latest
```

### Environment Variables

Authentication — provide **either** a PAT **or** the GitHub App variables (not both). If both are set, GitHub App takes priority.

| Variable | Description | Example |
|----------|-------------|----------|
| `GITHUB_PAT` | GitHub Personal Access Token | `ghp_xxxxxxxxxxxxxxxxxxxx` |
| `GITHUB_APP_ID` | App ID of your GitHub App | `123456` |
| `GITHUB_APP_INSTALLATION_ID` | Installation ID for the target org/repo | `78901234` |
| `GITHUB_APP_PRIVATE_KEY` | PEM-encoded private key (supports escaped `\n` from Azure Key Vault) | Contents of the `.pem` file |
| `GITHUB_APP_PRIVATE_KEY_FILE` | Path to a PEM private key file (alternative to `GITHUB_APP_PRIVATE_KEY`) | `/run/secrets/app.pem` |
| `GITHUB_SCOPE` | Runner scope: `repo` for repository-scoped, `org` for organization-scoped | `repo` or `org` |
| `GITHUB_ORG` | GitHub organization or user name | `myorg` |
| `GITHUB_REPO` | GitHub repository name (required only for repository-scoped runners) | `myrepo` |
| `GITHUB_RUNNER_LABELS` | Comma-separated labels for the runner | `docker,linux,self-hosted,gpu` |

### Authentication

#### Option A: Personal Access Token (PAT)

1. In GitHub, select your profile picture in the upper-right corner and select Settings.

2. Select Developer settings.

3. Under Personal access tokens, select Fine-grained tokens.

4. Select Generate new token.

5. In the New fine-grained personal access token screen, enter the following values.

| Setting | Value |
|---------|-------|
| Token name | Enter a name for your token. |
| Expiration | Select 30 days. |
| Repository access | Select Only select repositories and select the repository you created. |

Enter the following values for Repository permissions:

| Setting | Value |
|---------|-------|
| Actions | Select Read-only |
| Administration | Select Read and write |
| Metadata | Select Read-only |

If you use organization-scoped runner, then you need Organization permission:
| Setting | Value |
|---------|-------|
| Self-hosted runners | Select Read and write |

6. Select Generate token.

#### Option B: GitHub App

GitHub Apps provide better security than PATs — tokens are short-lived, scoped to specific installations, and don't depend on a personal account.

1. Go to your organization **Settings → Developer settings → GitHub Apps** and select **New GitHub App**.

2. Fill in the required fields (homepage URL can be any valid URL) and **disable the Webhook** (uncheck *Active*).

3. Set the following **Repository permissions**:

| Permission | Access |
|------------|--------|
| Actions | Read-only |
| Administration | Read and write |
| Metadata | Read-only |

If you use organization-scoped runners, also set this **Organization permission**:

| Permission | Access |
|------------|--------|
| Self-hosted runners | Read and write |

4. Select **Create GitHub App**. Note the **App ID** shown on the app's settings page.

5. Under **Private keys**, select **Generate a private key**. A `.pem` file will be downloaded.

6. Go to **Install App** in the sidebar and install the app on the target organization or repository. Note the **Installation ID** from the URL (`/installations/{id}`).

7. Pass the values to the container via `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and either `GITHUB_APP_PRIVATE_KEY` or `GITHUB_APP_PRIVATE_KEY_FILE`.

> **Tip:** If you store the private key as a secret in Azure Key Vault, newlines may be escaped as literal `\n`. The runner handles this automatically.