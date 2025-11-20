# Self-hosted CI/CD runner images

Github Actions Runner & Azure Pipeline Agent docker images for self-hosting.

Automatically registers the runner with the repository, with de-registration at the end.

Use-case: hosting with Azure Container Apps, so the runner is scaled up and down gracefully.

Based on [Microsoft's tutorial](https://learn.microsoft.com/azure/container-apps/tutorial-ci-cd-runners-jobs).

