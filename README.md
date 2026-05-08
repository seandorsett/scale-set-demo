# GitHub Actions Runner Scale Sets — Presentation Demo

> **A before-and-after comparison of self-hosted runner management**

## 📋 What This Demo Covers

This repository provides a complete **presentation-ready demo** comparing:

| | Traditional Runners | Runner Scale Sets (ARC) |
|---|---|---|
| **Scaling** | Manual | Automatic |
| **State** | Persistent (dirty) | Ephemeral (clean) |
| **Setup** | Imperative scripts | Declarative Helm charts |
| **Cost** | Fixed | Pay-per-use (scale to zero) |
| **Security** | Shared filesystem | Pod isolation |

---

## 🗂️ Repository Structure

```
├── before/                          ← "The Old Way"
│   ├── README.md                    Pain points & architecture
│   ├── setup-runner.sh              Manual runner registration
│   ├── workflow-repo-level.yml      Workflow (repo runner)
│   └── workflow-org-level.yml       Workflow (org runner)
│
├── after/                           ← "The New Way"
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

### Slide 1: The Problem

> "How many of you have manually SSH'd into a machine to register a runner?"

- Open `before/setup-runner.sh` — walk through the manual steps
- Highlight: tokens expire, manual scaling, no self-healing

### Slide 2: Traditional Workflow

> "Here's what a workflow looks like targeting traditional runners"

- Open `before/workflow-repo-level.yml`
- Point out the cleanup step — "Why do we need this?"
- Open `before/workflow-org-level.yml`
- Discuss shared state concerns with org-level runners

### Slide 3: The Architecture Problem

> "Let's visualize why this doesn't scale"

- Open `diagrams/architecture-notes.md` — show the "Traditional" diagram
- Show the "Static Capacity" scaling chart
- Key message: "You're either over-provisioned or under-provisioned"

### Slide 4: Enter Runner Scale Sets

> "What if runners could scale like your application?"

- Open `after/README.md` — show the new architecture diagram
- Key concepts:
  - **ARC Controller**: One brain managing all runners
  - **Runner Scale Set**: A named group that auto-scales
  - **Ephemeral pods**: Fresh state, every time

### Slide 5: The Setup (One-Time)

> "Let's see how much simpler this is"

- Open `after/01-install-arc-controller.sh`
- Compare to `before/setup-runner.sh`
- Key message: "One install manages ALL your runners"

### Slide 6: Deploying Scale Sets

> "Now let's add capacity — at both repo and org level"

- Open `after/values-repo.yaml` — "Infrastructure as Code for CI"
- Open `after/values-org.yaml` — "Org-level with runner groups"
- Highlight `maxRunners`, `minRunners`, `runnerGroup`
- Open `after/02-deploy-scaleset-repo.sh` and `03-deploy-scaleset-org.sh`

### Slide 7: The New Workflow

> "What changes for the developer?"

- Open `after/workflow-repo-level.yml` side-by-side with `before/workflow-repo-level.yml`
- Key differences:
  - `runs-on: arc-runner-set-repo` (name, not labels)
  - No cleanup step needed
  - Same actions, simpler workflow

### Slide 8: Scaling Behavior

> "Watch what happens under load"

- Open `diagrams/architecture-notes.md` — show scaling comparison
- Traditional: flat line (static), jobs queue during peaks
- Scale sets: matches demand, cost-efficient

### Slide 9: Security Wins

> "Security teams love this"

- Open `diagrams/architecture-notes.md` — security comparison table
- Key wins: job isolation, no credential leakage, audit trails
- Show ephemeral job lifecycle diagram

### Slide 10: Summary & Q&A

> "From manual to automatic, from risky to secure"

| Before | After |
|--------|-------|
| 15-30 min to add a runner | ~30 seconds (automatic) |
| Manual scaling | Auto-scaling |
| State drift | Ephemeral (guaranteed clean) |
| Token management | GitHub App authentication |
| Fixed cost | Scale to zero |

---

## 🔑 Key Terms for the Audience

| Term | Definition |
|------|-----------|
| **ARC** | Actions Runner Controller — Kubernetes operator that manages runners |
| **Runner Scale Set** | A named group of homogeneous, auto-scaling runners |
| **Ephemeral runner** | A runner that exists only for a single job, then is destroyed |
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
- No live Kubernetes cluster is required to walk through the concepts
- All scripts include comments marked with `PRESENTATION TALKING POINT` for easy reference
- The `diagrams/` folder contains text-based diagrams suitable for terminal display or copying into slides
