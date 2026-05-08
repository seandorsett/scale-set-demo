# Legacy ARC (RunnerDeployment) — The Before State

## Presentation Walkthrough

This folder is **presentation reference only**.

- These files are **not** live workflows in `.github/workflows/`
- You should **walk through them on screen** to show what the customer's existing legacy ARC setup looked like
- The goal is to highlight complexity, not to trigger anything live

## Show These Files During The Talk

1. `setup-runner.sh`
2. `runner-deployment.yaml`
3. `horizontal-runner-autoscaler.yaml`
4. `workflow-repo-level.yml`
5. `workflow-org-level.yml`

## What To Highlight

### Legacy ARC operational model

- `RunnerDeployment` defined a runner pool
- `HorizontalRunnerAutoscaler` adjusted pool size separately
- `cert-manager` was another required dependency
- Multiple CRDs and controllers increased troubleshooting overhead

### Legacy ARC workflow model

- Workflows targeted label combinations like:
  `runs-on: [self-hosted, linux, x64, legacy-arc, repo-demo]`
- Jobs landed on long-lived runners from a pre-created pool
- Shared runners could retain state or drift over time
- Platform teams had to tune warm capacity versus idle cost

## Presentation Message

The customer already uses ARC.

This is not a story about moving from GitHub-hosted runners to Kubernetes. It is a story about moving from **legacy ARC complexity** to **Runner Scale Sets simplicity**.
