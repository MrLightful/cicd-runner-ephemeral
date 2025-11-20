# Self-hosted CI/CD runner images

Github Actions Runner & Azure Pipeline Agent docker images for self-hosting.

Automatically registers the runner with the repository and de-registers at the end.

Use-case: hosting with Azure Container Apps, so the runner is scaled up and down gracefully.

Based on [Microsoft's tutorial](https://learn.microsoft.com/azure/container-apps/tutorial-ci-cd-runners-jobs).

## Usage

### Prerequisites

- Docker installed and running
- GitHub Personal Access Token (PAT)
- Access to the GitHub repository where you want to register runners

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

**From GitHub Container Registry:**
```bash
docker run --rm \
  -e GITHUB_PAT="ghp_your_token_here" \
  -e REGISTRATION_TOKEN_API_URL="https://api.github.com/repos/OWNER/REPO/actions/runners/registration-token" \
  -e GH_URL="https://github.com/OWNER/REPO" \
  -e RUNNER_LABELS="docker,linux,self-hosted" \
  ghcr.io/mrlightful/gh-actions-runner-ephemeral:latest
```

**Or from Docker Hub:**
```bash
docker run --rm \
  -e GITHUB_PAT="ghp_your_token_here" \
  -e REGISTRATION_TOKEN_API_URL="https://api.github.com/repos/OWNER/REPO/actions/runners/registration-token" \
  -e GH_URL="https://github.com/OWNER/REPO" \
  -e RUNNER_LABELS="docker,linux,self-hosted" \
  mrlightful/gh-actions-runner-ephemeral:latest
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GITHUB_PAT` | GitHub Personal Access Token | `ghp_xxxxxxxxxxxxxxxxxxxx` |
| `REGISTRATION_TOKEN_API_URL` | GitHub API endpoint for registration tokens | `https://api.github.com/repos/myorg/myrepo/actions/runners/registration-token` |
| `GH_URL` | GitHub repository URL | `https://github.com/myorg/myrepo` |
| `RUNNER_LABELS` | Comma-separated labels for the runner | `docker,linux,self-hosted,gpu` |

### Creating a GitHub Personal Access Token

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