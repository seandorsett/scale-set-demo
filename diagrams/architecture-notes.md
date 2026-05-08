# Architecture Comparison: Legacy ARC vs. Runner Scale Sets

This demo now compares a **customer's current state (legacy ARC)** with the **upgrade target (Runner Scale Sets)**.

## Side-by-Side Architecture Diagrams

### Legacy ARC

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                                LEGACY ARC                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  GitHub.com                                                                  │
│      │                                                                       │
│      ├── Webhook events / API polling                                        │
│      ▼                                                                       │
│  HorizontalRunnerAutoscaler                                                  │
│      │                                                                       │
│      ▼                                                                       │
│  ARC Controller (summerwind)                                                 │
│      │                                                                       │
│      ├── manages RunnerDeployment CRD                                        │
│      ├── creates RunnerReplicaSet CRD                                        │
│      └── keeps runner pods pre-created                                       │
│      ▼                                                                       │
│  RunnerDeployment ──► RunnerReplicaSet ──► Runner Pods (idle pool)          │
│                                                                              │
│                      ▲                                                       │
│                      │                                                       │
│                cert-manager                                                  │
│                (dependency)                                                  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

- HorizontalRunnerAutoscaler watches webhook events or polls the GitHub API
- Runners are long-lived and can process multiple jobs over time
- Scaling depends on the CRD chain: `RunnerDeployment` → `RunnerReplicaSet` → runner pods

### Runner Scale Sets

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                           RUNNER SCALE SETS                                  │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  GitHub.com                                                                  │
│      │                                                                       │
│      ▼                                                                       │
│  Listener Pod                                                                │
│      │                                                                       │
│      ▼                                                                       │
│  ARC Controller (GitHub official)                                            │
│      │                                                                       │
│      └── creates ephemeral runner pods on demand                             │
│          ▼                                                                   │
│      Ephemeral Runner Pods (one job per pod)                                 │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

- No `cert-manager` dependency
- Listener directly connects to the GitHub API
- Pods are created for a job and destroyed immediately after it finishes

## Scaling Behavior Comparison

### Legacy ARC: Pool-Based Scaling

```text
Time ─────────────────────────────────────────────────────────────────────────►

Queued jobs:      ▁▁▃▃▆▇▇▅▃▂▁
Idle runner pool: ████ ████ ████ ████

Behavior:
- Capacity is managed as a pool of pre-created runners
- HorizontalRunnerAutoscaler reacts to webhook or polling signals
- Idle pods may sit waiting between bursts
- Busy periods can still queue while the pool catches up
```

### Runner Scale Sets: Per-Job Scaling

```text
Time ─────────────────────────────────────────────────────────────────────────►

Queued jobs:      ▁▁▃▃▆▇▇▅▃▂▁
Runner pods:      ▁▁▃▃▆▇▇▅▃▂▁

Behavior:
- Each queued job results in a fresh runner pod
- Capacity tracks demand more directly
- No need to keep a large idle pool warm
- Pods disappear after the job completes
```

## CRD / Manifest Complexity Comparison

| Area | Legacy ARC | Runner Scale Sets |
|------|------------|-------------------|
| Primary scaling objects | `RunnerDeployment`, `RunnerReplicaSet`, `HorizontalRunnerAutoscaler` | Scale set + listener + ephemeral runners |
| Scaling model | Multi-CRD chain | Simplified control loop |
| Dependency footprint | Includes `cert-manager` | No `cert-manager` required |
| Manifest sprawl | More objects to explain and troubleshoot | Fewer moving parts |
| Operational model | Summerwind-era ARC patterns | GitHub-official runner scale set model |

## Job Lifecycle Comparison

### Legacy ARC

```text
Job arrives
   │
   ▼
Existing runner pod picks up work
   │
   ├─ checkout
   ├─ build/test/deploy
   └─ job finishes
   │
   ▼
Runner pod stays alive
   ├─ caches remain
   ├─ workspace can persist
   └─ same runner may process the next job
```

### Runner Scale Sets

```text
Job arrives
   │
   ▼
Listener signals ARC
   │
   ▼
Fresh runner pod is created
   │
   ├─ checkout
   ├─ build/test/deploy
   └─ job finishes
   │
   ▼
Runner pod is destroyed
   ├─ no reused workspace
   ├─ no residual processes
   └─ next job gets a brand-new pod
```

## Component Comparison Table

| Component | Legacy ARC | Runner Scale Sets |
|-----------|------------|-------------------|
| Controller | Summerwind ARC controller | GitHub-official ARC controller |
| Event intake | Webhook and/or polling via HRA | Listener pod |
| Scale trigger | HorizontalRunnerAutoscaler | Listener-driven demand |
| Runner abstraction | `RunnerDeployment` / `RunnerReplicaSet` | Scale set runners |
| Runner lifetime | Long-lived | Ephemeral |
| Warm capacity | Idle pool of ready runners | Optional minimums, otherwise on-demand |
| Extra dependency | `cert-manager` | None required for this flow |
| Operational focus | Maintain pool health | Fulfill jobs per pod |

## Security Comparison Table

| Security Aspect | Legacy ARC | Runner Scale Sets |
|----------------|------------|-------------------|
| Job isolation | Lower — runner pods can serve multiple jobs | Higher — one pod per job |
| Workspace reuse | Possible | Eliminated by default |
| Residual process risk | Higher on long-lived runners | Reduced with pod teardown |
| Credential exposure window | Longer-lived runner lifetime | Shorter-lived runner lifetime |
| Attack surface | More components, including `cert-manager` | Fewer components |
| Drift over time | More likely on persistent runners | Reduced through fresh pods |

## Migration Path Notes

- Treat this as an **ARC-to-ARC modernization**, not a move from standalone runners
- The "before" state is already Kubernetes-based, but it uses the **legacy summerwind model**
- The upgrade path is about replacing:
  - webhook / polling-based HRA scaling
  - `RunnerDeployment` / `RunnerReplicaSet` objects
  - long-lived runner pools
  - `cert-manager` dependency
- The target state is:
  - listener-based job intake
  - GitHub-official ARC
  - ephemeral per-job runners
  - simpler manifests and operations
- Presentation framing: **same platform goal, cleaner architecture**
