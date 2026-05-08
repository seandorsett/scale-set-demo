# GitHub Actions Runner Scale Sets — Presentation Demo

> **A before-and-after comparison of legacy ARC and Runner Scale Sets**

## 🖥️ Live Demo Setup

This presentation is ready for a **real-time ARC modernization demo** against a live Kubernetes cluster.

### Prerequisites already met

- Kubernetes cluster is running
- ARC controller is installed in the `arc-systems` namespace
- Runner scale set `arc-runner-set-repo` is deployed in the `arc-runners` namespace
- GitHub repository is `seandorsett/super-tribble`

### Verify before you present

```bash
kubectl get pods -n arc-systems
```

Optional quick checks:

```bash
kubectl get pods -n arc-runners
gh workflow list --repo seandorsett/super-tribble
```

### Keep these commands ready during the demo

Open one terminal to watch ARC and runner activity:

```bash
kubectl get pods -n arc-runners -w
```

Use a second terminal for GitHub workflow triggers:

```bash
gh workflow run "workflow-name" --repo seandorsett/super-tribble
gh run list --repo seandorsett/super-tribble --limit 5
```

What you want the audience to see:

- The controller is already healthy in `arc-systems`
- A workflow is triggered from the GitHub Actions tab or with `gh workflow run`
- A runner pod appears in `arc-runners`
- The pod disappears after the job completes, proving the new runner is ephemeral

---

## 📋 What This Demo Covers

This repository provides a complete **presentation-ready demo** comparing:

| | Legacy ARC | Runner Scale Sets |
|---|---|---|
| **Scaling** | Webhook/poll-driven pool scaling | Listener-driven per-job scaling |
| **State** | Long-lived runners | Ephemeral runners |
| **Architecture** | RunnerDeployment CRDs + cert-manager | Listener + official ARC controller |
| **Complexity** | More CRDs and dependencies | Simpler control plane |
| **Security** | Reused runner state | Clean pod per job |

---

## 🗂️ Repository Structure

```
├── before/                          ← "Legacy ARC / current state"
│   ├── README.md                    Pain points & architecture
│   ├── setup-runner.sh              Legacy setup reference
│   ├── workflow-repo-level.yml      Workflow (repo runner)
│   └── workflow-org-level.yml       Workflow (org runner)
│
├── after/                           ← "Runner Scale Sets / upgrade path"
│   ├── README.md                    Benefits & architecture
│   ├── 01-install-arc-controller.sh ARC controller setup
│   ├── 02-deploy-scaleset-repo.sh   Repo-level scale set
│   ├── 03-deploy-scaleset-org.sh    Org-level scale set
│   ├── values-repo.yaml            Helm config (repo)
│   ├── values-org.yaml             Helm config (org)
│   ├── workflow-repo-level.yml      Workflow (scale set - repo)
│   └── workflow-org-level.yml       Workflow (scale set - org)
│
└── diagrams/
    └── architecture-notes.md        Visual comparisons
```

---

## 🎤 Presentation Flow (Suggested Order)

### Slide 1: The Current State — Legacy ARC

> "This customer already runs ARC — but it's the legacy model."

- Open `diagrams/architecture-notes.md` — show the **Legacy ARC** diagram
- Call out:
  - `RunnerDeployment`
  - `RunnerReplicaSet`
  - webhook / polling scaling
  - `cert-manager`
- Key message: "The problem is not Kubernetes adoption — it's legacy ARC complexity"

### Slide 2: Legacy ARC Pain Point #1 — Scaling Model

> "Legacy ARC scales runner pools, not individual jobs."

- Show the pool-based scaling section in `diagrams/architecture-notes.md`
- Explain `HorizontalRunnerAutoscaler`
- Highlight idle capacity during quiet periods and lag during spikes

### Slide 3: Legacy ARC Pain Point #2 — Operational Complexity

> "There are too many moving parts for what should be a simple outcome."

- Show the CRD / manifest complexity table
- Open `before/README.md` or the legacy workflow examples as supporting material
- Highlight:
  - `RunnerDeployment` chain
  - more objects to troubleshoot
  - long-lived runner state

### Slide 4: Enter Runner Scale Sets

> "The upgrade path is Runner Scale Sets — still ARC, but redesigned."

- Open `after/README.md` — show the new architecture
- Open `diagrams/architecture-notes.md` — show **Runner Scale Sets**
- Key concepts:
  - **Listener pod**
  - **GitHub-official ARC controller**
  - **Ephemeral runner pods**

### Slide 5: Why This Is the Upgrade Path

> "This is not a replatform — it's a modernization of ARC itself."

- Compare legacy ARC to scale sets directly
- Highlight:
  - no `cert-manager`
  - listener-based job intake
  - simpler manifests
  - per-job lifecycle

### Slide 6: Deploying the New Model

> "Now let's show the scale set configuration."

- Open `after/values-repo.yaml` — "Infrastructure as Code for the new runner model"
- Open `after/values-org.yaml`
- Highlight `maxRunners`, `minRunners`, `runnerGroup`
- Open `after/02-deploy-scaleset-repo.sh` and `03-deploy-scaleset-org.sh`

### Slide 7: Side-by-Side Workflow Comparison

> "What changes in the workflow when you move from legacy ARC to scale sets?"

- Open `after/workflow-repo-level.yml` side-by-side with `before/workflow-repo-level.yml`
- Key differences:
  - `runs-on: arc-runner-set-repo`
  - less concern about reused runner state
  - workflows stay familiar while the platform improves underneath
- **LIVE DEMO:** Trigger the scale set-backed workflow and watch `kubectl get pods -n arc-runners -w`

### Slide 8: Scaling Behavior

> "Here is the behavioral difference under load."

- Open `diagrams/architecture-notes.md`
- Legacy ARC: pool-based scaling
- Runner Scale Sets: per-job scaling
- Key message: "Capacity follows jobs more directly"

### Slide 9: Security and Job Lifecycle

> "The biggest win is isolation."

- Open `diagrams/architecture-notes.md`
- Show:
  - job lifecycle comparison
  - security comparison table
- Key wins: one pod per job, less residual state, smaller dependency footprint

### Slide 10: Summary & Q&A

> "This is the migration from legacy ARC to Runner Scale Sets."

| Legacy ARC | Runner Scale Sets |
|------------|-------------------|
| RunnerDeployment-based | Listener + scale set model |
| Webhook/poll pool scaling | Per-job scaling |
| Long-lived runners | Ephemeral runners |
| cert-manager dependency | No cert-manager required |
| More CRDs to manage | Simpler operations |

---

## 🔑 Key Terms for the Audience

| Term | Definition |
|------|-----------|
| **Legacy ARC** | Older summerwind-style ARC model using `RunnerDeployment`, `RunnerReplicaSet`, and `HorizontalRunnerAutoscaler` |
| **ARC** | Actions Runner Controller — the Kubernetes operator for GitHub Actions runners |
| **Runner Scale Set** | The newer GitHub-supported ARC model for listener-driven, auto-scaling runners |
| **Ephemeral runner** | A runner that exists only for a single job, then is destroyed |
| **RunnerDeployment** | Legacy ARC CRD used to describe a scalable runner pool |
| **HorizontalRunnerAutoscaler** | Legacy ARC autoscaler that reacts to webhooks or polling |
| **Runner Group** | Access control mechanism — controls which repos can use runners |
| **Listener pod** | ARC component that monitors GitHub for queued jobs |
| **minRunners** | Minimum idle runners kept warm (reduces cold-start latency) |
| **maxRunners** | Maximum runners (cost ceiling) |

---

## 📚 References

- [Runner Scale Sets Documentation](https://docs.github.com/en/actions/concepts/runners/runner-scale-sets)
- [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller)
- [Quickstart for ARC](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller)
- [Deploying Runner Scale Sets](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/deploying-runner-scale-sets-with-actions-runner-controller)
- [ARC GitHub Repository](https://github.com/actions/actions-runner-controller)

---

## ⚠️ Demo Notes

- This demo is **reference/illustrative** — scripts are annotated for presentation
- A live Kubernetes cluster is optional for the talk-through, but recommended for the full ARC pod lifecycle demo
- All scripts include comments marked with `PRESENTATION TALKING POINT` for easy reference
- The `diagrams/` folder contains text-based diagrams suitable for terminal display or copying into slides
- Presentation framing is **legacy ARC → Runner Scale Sets**, not standalone runners → ARC

---

## Demo Commands Cheat Sheet

```bash
# Verify ARC controller is healthy
kubectl get pods -n arc-systems

# Check runner scale set namespace before starting
kubectl get pods -n arc-runners

# If you also want to reference legacy ARC objects
kubectl get runnerdeployments -A
kubectl get horizontalrunnerautoscalers -A

# Watch runner pods appear/disappear live
kubectl get pods -n arc-runners -w

# See recent workflow runs
gh run list --repo seandorsett/super-tribble --limit 10

# Trigger a legacy ARC "before" workflow
gh workflow run "workflow-name" --repo seandorsett/super-tribble

# Trigger a Runner Scale Sets "after" workflow
gh workflow run "workflow-name" --repo seandorsett/super-tribble

# Inspect a specific run after triggering
gh run view --repo seandorsett/super-tribble
```
