# Architecture Comparison: Traditional vs. Runner Scale Sets

## Side-by-Side Architecture

### Traditional Self-Hosted Runners

```
┌───────────────────────────────────────────────────────────────┐
│                        TRADITIONAL                             │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  GitHub.com ─── Jobs ──► Label Matching ──► Runner Pool       │
│                                              │                │
│                                    ┌─────────┼─────────┐     │
│                                    ▼         ▼         ▼     │
│                              ┌──────┐  ┌──────┐  ┌──────┐   │
│                              │ VM 1 │  │ VM 2 │  │ VM 3 │   │
│                              │      │  │      │  │      │   │
│                              │ 🔴   │  │ 🔴   │  │ 🔴   │   │
│                              │dirty │  │dirty │  │dirty │   │
│                              │state │  │state │  │state │   │
│                              └──────┘  └──────┘  └──────┘   │
│                                 ▲         ▲         ▲        │
│                                 │         │         │        │
│                              Manual    Manual    Manual       │
│                              setup     setup     setup        │
│                                                               │
│  Scaling: ❌ Manual          State: ❌ Persistent             │
│  Recovery: ❌ Manual         Auth: ❌ Token-based              │
│  Config: ❌ Imperative       Cost: ❌ Always running           │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Runner Scale Sets (with ARC)

```
┌───────────────────────────────────────────────────────────────┐
│                     RUNNER SCALE SETS                          │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  GitHub.com ─── Jobs ──► Scale Set ──► ARC Controller         │
│                                          │                    │
│                              Kubernetes  │  (auto-managed)    │
│                          ┌───────────────┼───────────────┐    │
│                          │               ▼               │    │
│                          │  ┌──────┐  ┌──────┐  ┌─────┐│    │
│                          │  │Pod 1 │  │Pod 2 │  │ ... ││    │
│                          │  │      │  │      │  │     ││    │
│                          │  │ ✅   │  │ ✅   │  │ ✅  ││    │
│                          │  │fresh │  │fresh │  │fresh││    │
│                          │  │state │  │state │  │state││    │
│                          │  └──┬───┘  └──┬───┘  └──┬──┘│    │
│                          │     💥         💥        💥   │    │
│                          │  (destroyed after each job)   │    │
│                          └───────────────────────────────┘    │
│                                                               │
│  Scaling: ✅ Automatic     State: ✅ Ephemeral                │
│  Recovery: ✅ Automatic    Auth: ✅ GitHub App / Secrets       │
│  Config: ✅ Declarative    Cost: ✅ Scale to zero              │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Scaling Behavior Comparison

### Traditional: Static Capacity

```
Runners ▲
   5    │ ████████████████████████████████████████████  (always 5)
   4    │ ████████████████████████████████████████████
   3    │ ████████████████████████████████████████████
   2    │ ████████████████████████████████████████████
   1    │ ████████████████████████████████████████████
   0    ├────────────────────────────────────────────► Time
        6am         12pm         6pm         12am
        
        Jobs: ░░▓▓▓▓▓▓▓▓░░░░▓▓▓▓▓░░░░░░░░░░░░░░░░░░
        
        ⚠️  Peak: Jobs queue (not enough runners)
        ⚠️  Off-peak: Runners idle (wasted cost)
```

### Runner Scale Sets: Dynamic Capacity

```
Runners ▲
  10    │              ██                               maxRunners: 10
   8    │            ██████
   6    │          ██████████
   4    │        ██████████████        ████
   2    │ ██████████████████████████████████████████   minRunners: 2
   0    ├────────────────────────────────────────────► Time
        6am         12pm         6pm         12am
        
        Jobs: ░░▓▓▓▓▓▓▓▓░░░░▓▓▓▓▓░░░░░░░░░░░░░░░░░░
        
        ✅ Peak: Auto-scales to handle demand
        ✅ Off-peak: Scales down to save cost
        ✅ Cost-capped: Never exceeds maxRunners
```

## Job Lifecycle Comparison

### Traditional Runner

```
Time ──►

Job 1 arrives:                    Job 2 arrives:
┌─────────────────────────┐      ┌─────────────────────────┐
│ Runner picks up job      │      │ Same runner picks up    │
│ ├─ checkout              │      │ ├─ checkout             │
│ ├─ install deps          │      │ ├─ ⚠️  old deps cached  │
│ ├─ run tests             │      │ ├─ run tests            │
│ ├─ build                 │      │ ├─ ⚠️  old build cached │
│ └─ job complete          │      │ └─ job complete         │
│                          │      │                         │
│ Runner PERSISTS ─────────┼─────►│ STATE CARRIED OVER ⚠️   │
│ • node_modules remains   │      │ • stale packages        │
│ • build cache remains    │      │ • potential conflicts   │
│ • env vars may leak      │      │ • unpredictable builds  │
└─────────────────────────┘      └─────────────────────────┘
```

### Runner Scale Set (Ephemeral)

```
Time ──►

Job 1 arrives:                    Job 2 arrives:
┌─────────────────────────┐      ┌─────────────────────────┐
│ ARC creates Pod          │      │ ARC creates NEW Pod     │
│ ├─ checkout              │      │ ├─ checkout             │
│ ├─ install deps          │      │ ├─ fresh deps install   │
│ ├─ run tests             │      │ ├─ run tests            │
│ ├─ build                 │      │ ├─ clean build          │
│ └─ job complete          │      │ └─ job complete         │
│                          │      │                         │
│ Pod DESTROYED 💥 ────────┘      │ Pod DESTROYED 💥        │
│ • Nothing persists               │ • Nothing persists      │
│ • Clean slate guaranteed         │ • Deterministic builds  │
│ • No security leaks              │ • No "works on my      │
│                                  │    runner" issues       │
└──────────────────────────       └─────────────────────────┘
```

## Component Comparison

| Component | Traditional | Runner Scale Sets |
|-----------|-------------|-------------------|
| **Runner registration** | Manual script + token | Helm chart + GitHub App |
| **Scaling** | Human operator | ARC controller (automatic) |
| **Runner lifecycle** | Long-lived (days/months) | Ephemeral (minutes) |
| **Configuration** | Per-machine scripts | Centralized values.yaml |
| **Updates** | Manual SSH + restart | Helm upgrade (rolling) |
| **Monitoring** | Custom (varies) | Kubernetes-native |
| **Cost model** | Fixed (always running) | Variable (scale to zero) |
| **State** | Persistent (risky) | Ephemeral (clean) |
| **Network** | Direct internet | Kubernetes networking + proxy support |
| **Recovery** | Manual restart | Automatic (Kubernetes) |

## Security Comparison

| Security Aspect | Traditional | Runner Scale Sets |
|----------------|-------------|-------------------|
| Job isolation | ❌ Shared filesystem | ✅ Separate pods |
| Credential handling | ❌ Tokens on disk | ✅ K8s secrets |
| Cross-repo leakage | ❌ Possible | ✅ Prevented |
| Network isolation | ❌ Shared network | ✅ Namespace policies |
| Privilege escalation | ❌ Often root | ✅ Pod security contexts |
| Audit trail | ❌ Manual logging | ✅ K8s audit logs |
