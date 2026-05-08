# Runner Scale Sets with ARC — The "After" State

## Overview

This directory demonstrates the **modern approach** to self-hosted runners using **Actions Runner Controller (ARC)** and **Runner Scale Sets**. This replaces the manual, static approach with declarative, auto-scaling infrastructure.

## 🖥️ Live Demo

This is the part of the presentation that uses the **actual runner scale set** on your local Kubernetes cluster.

- ARC controller is running in `arc-systems`
- Runner scale set `arc-runner-set-repo` is running in `arc-runners`
- Workflows target the real scale set, so the audience can watch runner pods get created and removed live

Trigger a workflow from GitHub Actions or with:

```bash
gh workflow run "workflow-name" --repo seandorsett/super-tribble
```

While the workflow starts, watch the cluster with:

```bash
kubectl get pods -n arc-runners
kubectl get pods -n arc-runners -w
```

What to show:

- The listener/controller is already in place before the workflow starts
- A new runner pod appears in `arc-runners` when the workflow is queued
- The pod exists only for the duration of the job
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

## How Runner Scale Sets Work

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub.com                               │
│                                                                  │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                     │
│  │  Repo A │    │  Repo B │    │  Repo C │                     │
│  └────┬────┘    └────┬────┘    └────┬────┘                     │
│       │               │              │                           │
│       └───────────────┼──────────────┘                          │
│                       │ Jobs assigned to scale set               │
│                       ▼                                          │
│            ┌─────────────────────┐                              │
│            │  Runner Scale Set   │ ◄── Single label/name        │
│            │  "arc-runner-set"   │     assignment                │
│            └──────────┬──────────┘                              │
└───────────────────────┼─────────────────────────────────────────┘
                        │ Scale set assignment
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                              │
│                                                                  │
│  ┌──────────────────────────────────────┐  arc-systems ns       │
│  │  ARC Controller                       │                      │
│  │  • Monitors GitHub for queued jobs   │                      │
│  │  • Creates runner pods on demand     │                      │
│  │  • Destroys pods after job completes │                      │
│  └──────────────────┬───────────────────┘                      │
│                     │                                           │
│  ┌──────────────────┼────────────────────┐  arc-runners ns     │
│  │                  ▼                     │                      │
│  │  ┌──────┐  ┌──────┐  ┌──────┐        │                     │
│  │  │Pod 1 │  │Pod 2 │  │Pod 3 │  ...   │ ← Auto-scaled      │
│  │  │ 🆕   │  │ 🆕   │  │ 🆕   │        │   Ephemeral         │
│  │  │fresh!│  │fresh!│  │fresh!│        │   Clean state ✅    │
│  │  └──┬───┘  └──┬───┘  └──┬───┘        │                     │
│  │     │ job     │ job     │ job         │                     │
│  │     │ done    │ done    │ done        │                     │
│  │     ▼         ▼         ▼             │                     │
│  │  💥 destroyed after each job 💥       │                     │
│  └───────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

## Benefits (Presentation Talking Points)

### ✅ Automatic Scaling
- **Scale to zero**: No cost when idle (minRunners: 0)
- **Scale to demand**: Runners created as jobs arrive
- **Cost ceiling**: maxRunners prevents runaway costs
- **Warm capacity**: minRunners keeps runners ready for fast starts

### ✅ Ephemeral Runners (Security & Reliability)
- Fresh pod for every job — **no state drift**
- No credentials leaked between jobs
- No cross-repository contamination
- Deterministic builds — same environment every time

### ✅ Declarative Configuration
- Everything in version-controlled YAML files
- Reproducible deployments via Helm
- No imperative scripts or manual steps
- Easy to audit and review changes

### ✅ Centralized Management
- One ARC controller manages all runner scale sets
- Runner groups for access control
- Kubernetes-native monitoring and alerting
- Rolling updates via Helm upgrades

### ✅ Authentication
- GitHub App authentication (no PAT rotation needed)
- Kubernetes secrets for credential management
- No tokens stored on runner filesystems

## Deployment Flow (Automated)

```
Platform Team                    Kubernetes                      GitHub
     │                               │                              │
     │── helm install arc ───────────►│                              │
     │   (one time)                   │── Controller pod starts ────►│
     │                               │                              │
     │── helm install scale-set ─────►│                              │
     │   (per scale set)              │── Listener connects ────────►│
     │                               │                              │
     │                               │◄─── Job queued ─────────────│
     │                               │                              │
     │                               │── Create runner pod          │
     │                               │── Pod executes job ─────────►│
     │                               │── Pod destroyed ✅           │
     │                               │                              │
     │   (automatic from here)        │◄─── More jobs ─────────────│
     │                               │── Scale up pods...           │
     │                               │                              │
     │                               │   (idle timeout)             │
     │                               │── Scale down to minRunners   │
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

| Metric | Runner Scale Sets |
|--------|-------------------|
| Time to add capacity | Seconds (automatic) |
| Scale-up time | ~30 seconds (pod startup) |
| Scale-down | Automatic (configurable) |
| State isolation | Complete (ephemeral pods) |
| Recovery from failure | Automatic (Kubernetes restarts) |
| Configuration drift | Eliminated (declarative) |
