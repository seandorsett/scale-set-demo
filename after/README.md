# Runner Scale Sets with ARC — The "After" State

## Overview

This directory demonstrates the **modern GitHub-supported ARC model** using **Runner Scale Sets**. The "before" state is **legacy ARC** (summerwind controller with `RunnerDeployment` and `HorizontalRunnerAutoscaler` CRDs). The "after" state keeps Kubernetes-based runners, but replaces that older ARC architecture with a simpler Helm-based model.

## 🖥️ Live Demo

This is the part of the presentation that uses the **actual runner scale set** on your local Kubernetes cluster.

- ARC controller is running in `arc-systems`
- Runner scale set `arc-runner-set-repo` is running in `arc-runners`
- Workflows target the real scale set, so the audience can watch runner pods get created and removed live

Trigger a workflow from GitHub Actions or with:

```bash
gh workflow run "workflow-name" --repo seandorsett/scale-set-demo
```

While the workflow starts, watch the cluster with:

```bash
kubectl get pods -n arc-runners
kubectl get pods -n arc-runners -w
```

What to show:

- The controller and listener are already in place before the workflow starts
- A new runner pod appears in `arc-runners` only when a job is queued
- Unlike legacy ARC's pre-created runner pool, the pod exists only for that job
- After the run completes, the runner pod is destroyed automatically

This is the key "aha" moment: **run workflow → watch pod appear → job finishes → pod disappears**.

## What's Here

| File | Purpose |
|------|---------|
| `01-install-arc-controller.sh` | One-time ARC controller installation |
| `02-deploy-scaleset-repo.sh` | Deploy a repo-level runner scale set |
| `03-deploy-scaleset-org.sh` | Deploy an org-level runner scale set |
| `values-repo.yaml` | Helm values for repo-level configuration |
| `values-org.yaml` | Helm values for org-level configuration |
| `workflow-repo-level.yml` | Workflow using repo-level scale set |
| `workflow-org-level.yml` | Workflow using org-level scale set |

## Runner Scale Sets vs. Legacy ARC

```
LEGACY ARC (before)                              RUNNER SCALE SETS (after)

GitHub job queue                                GitHub job queue
      │                                                │
      ▼                                                ▼
summerwind controller                           GitHub ARC controller
      │                                          + listener
      │                                                │
      ▼                                                ▼
RunnerDeployment CRD                            Helm release + values.yaml
HorizontalRunnerAutoscaler CRD                        │
      │                                                │
      ▼                                                ▼
Pre-created runner pool                         Pod created only when job queues
(often idle even with no work)                  (listener-driven scaling)
      │                                                │
      ▼                                                ▼
Long-lived registration tokens                  Short-lived per-job tokens
More YAML / CRD management                      No RunnerDeployment / HRA CRDs
cert-manager commonly required                  No cert-manager dependency
community-maintained summerwind                 GitHub-managed and supported
```

## Benefits (Presentation Talking Points)

### ✅ Simpler Installation than Legacy ARC
- **No cert-manager dependency**
- **Official GitHub Helm charts**, not the legacy summerwind controller
- **No CRD YAML management** for `RunnerDeployment` or `HorizontalRunnerAutoscaler`
- One controller install plus one Helm release per scale set

### ✅ Better Scaling Model
- **Listener-based scaling** instead of legacy ARC webhook/poll patterns
- **Per-job ephemeral runners** instead of a pre-created legacy runner pool
- **Scale to zero** when idle, instead of always paying for idle runners
- `maxRunners` still provides a clear safety ceiling

### ✅ Simpler Routing and Operations
- **Single label/name per scale set** keeps workflow routing straightforward
- One `values.yaml` file replaces multiple legacy ARC custom resources
- Easier upgrades through standard Helm workflows
- GitHub-managed architecture reduces operational guesswork

### ✅ Stronger Security Posture
- **Short-lived per-job tokens** instead of long-lived registration tokens
- Fresh pod for every job — **no state drift**
- No credentials or workspace leftovers between jobs
- Cleaner isolation across repos and workloads

## Deployment Flow (Automated)

```
Platform Team                    Kubernetes                      GitHub
     │                               │                              │
     │── helm install controller ────►│                              │
     │   (one time, official chart)   │── Controller starts ───────►│
     │                               │                              │
     │── helm install scale-set ─────►│                              │
     │   (no CRDs to author)          │── Listener connects ───────►│
     │                               │                              │
     │                               │◄─── Job queued ─────────────│
     │                               │                              │
     │                               │── Create one runner pod      │
     │                               │── Pod executes job ─────────►│
     │                               │── Pod destroyed ✅           │
     │                               │                              │
     │   (automatic from here)        │◄─── More jobs ─────────────│
     │                               │── Create more pods as needed │
     │                               │                              │
     │                               │   (idle)                     │
     │                               │── Scale down to zero/min     │
```

## Repo vs. Org Level Comparison

| Feature | Repo-Level Scale Set | Org-Level Scale Set |
|---------|---------------------|---------------------|
| Scope | Single repository | All repos in org |
| Access control | Implicit (repo only) | Runner groups |
| `githubConfigUrl` | `github.com/org/repo` | `github.com/org` |
| Use case | Dedicated workloads | Shared infrastructure |
| Typical scaling | 0-10 runners | 2-50 runners |
| Auth recommendation | PAT or GitHub App | GitHub App |

## Key Metrics to Highlight

| Metric | Runner Scale Sets | Legacy ARC |
|--------|-------------------|------------|
| Capacity model | Per-job ephemeral pods | Pre-created runner pool |
| Scale trigger | Listener-based | Webhook/poll/HRA driven |
| Idle cost | Can scale to zero | Often idle runners remain |
| Routing | Single scale set label/name | Multiple labels / CRDs |
| Token model | Short-lived per-job tokens | Long-lived registration tokens |
| Kubernetes objects | Helm release + values | RunnerDeployment + HRA CRDs |
| Support model | GitHub-managed | Community-maintained summerwind |
