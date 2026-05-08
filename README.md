# GitHub Actions Runner Scale Sets — Presentation Demo

> A compelling before-vs-after story for customers already using legacy ARC.

## Live Demo Framing

- **Before = presentation only.** Show the legacy ARC files on screen.
- **After = live demo.** Trigger GitHub Actions workflows that use the real runner scale set.
- **Cluster target:** `arc-runner-set-repo` in namespace `arc-runners`
- **Repo target:** `seandorsett/scale-set-demo`

## Presentation Flow

### 1. Show the legacy ARC story on screen

Walk through these files to show why the current model is complex:

- `before/setup-runner.sh`
- `before/runner-deployment.yaml`
- `before/horizontal-runner-autoscaler.yaml`
- `before/workflow-repo-level.yml`
- `before/workflow-org-level.yml`

Talking points:

- Legacy ARC used `RunnerDeployment` plus `HorizontalRunnerAutoscaler`
- `cert-manager` was another dependency to install and maintain
- Runner pools were pre-created and often sat idle
- Long-lived runners could accumulate state between jobs

### 2. Trigger **AFTER: Runner Scale Set Demo**

Use this as the first live moment:

- Trigger the workflow
- Watch a single pod appear in `arc-runners`
- Point out the pod hostname, fresh workspace, and teardown message in the logs
- Watch the pod disappear after the job finishes

### 3. Trigger **AFTER: Scale Set Multi-Job Demo**

Use this to show parallel scaling:

- Trigger the workflow
- Watch three runner pods appear at the same time
- Explain that each job gets its own isolated pod
- Let the summary job land on a fourth pod
- Watch everything scale back down when complete

### 4. Show kubectl output at each stage

What the audience should see:

1. No runner pods before the workflow starts
2. One pod for the single-job demo
3. Three pods simultaneously for the multi-job demo
4. Zero runner pods again after completion

## Commands to Keep Ready

```bash
kubectl get pods -n arc-systems
kubectl get pods -n arc-runners
kubectl get pods -n arc-runners -w
gh workflow list --repo seandorsett/scale-set-demo
gh workflow run "AFTER: Runner Scale Set Demo" --repo seandorsett/scale-set-demo
gh workflow run "AFTER: Scale Set Multi-Job Demo" --repo seandorsett/scale-set-demo
gh run list --repo seandorsett/scale-set-demo --limit 10
```

## Before vs After Summary

| | Before: Legacy ARC | After: Runner Scale Sets |
|---|---|---|
| Workflow demo mode | Presentation walkthrough only | Live workflow trigger |
| Scaling model | Pre-created pools | On-demand per-job pods |
| Kubernetes objects | RunnerDeployment + HRA CRDs | Helm release + listener |
| State | Long-lived runners | Fresh ephemeral runner per job |
| Idle cost | Warm pool can sit idle | Scale to zero |
| Dependencies | cert-manager + more CRDs | No cert-manager |

## Cheat Sheet

```bash
# Before: show files on screen
code before\setup-runner.sh
code before\runner-deployment.yaml
code before\horizontal-runner-autoscaler.yaml
code before\workflow-repo-level.yml
code before\workflow-org-level.yml

# After: live demo
kubectl get pods -n arc-runners -w
gh workflow run "AFTER: Runner Scale Set Demo" --repo seandorsett/scale-set-demo
gh workflow run "AFTER: Scale Set Multi-Job Demo" --repo seandorsett/scale-set-demo
```
