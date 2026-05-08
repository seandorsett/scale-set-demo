# Traditional Self-Hosted Runners — The "Before" State

## Overview

This directory demonstrates the **traditional approach** to self-hosted runners in GitHub Actions. This is the method that Runner Scale Sets aims to replace.

## What's Here

| File | Purpose |
|------|---------|
| `setup-runner.sh` | Manual runner registration script |
| `workflow-repo-level.yml` | Workflow targeting a repo-level self-hosted runner |
| `workflow-org-level.yml` | Workflow targeting an org-level runner (with runner groups) |

## How Traditional Self-Hosted Runners Work

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub.com                            │
│                                                         │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐              │
│  │  Repo A │   │  Repo B │   │  Repo C │              │
│  └────┬────┘   └────┬────┘   └────┬────┘              │
│       │              │              │                    │
│       └──────────────┼──────────────┘                   │
│                      │ Jobs assigned by label matching   │
└──────────────────────┼──────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │Runner 1 │   │Runner 2 │   │Runner 3 │
   │(VM/bare │   │(VM/bare │   │(VM/bare │
   │ metal)  │   │ metal)  │   │ metal)  │
   │         │   │         │   │         │
   │ STATE:  │   │ STATE:  │   │ STATE:  │
   │ dirty ⚠️│   │ dirty ⚠️│   │ dirty ⚠️│
   └─────────┘   └─────────┘   └─────────┘
        ▲              ▲              ▲
        │              │              │
   Manually       Manually       Manually
   provisioned    provisioned    provisioned
```

## Pain Points (Presentation Talking Points)

### 🔴 No Auto-Scaling
- Runners must be **manually provisioned** for each machine
- If demand spikes, jobs queue until someone adds more runners
- During low demand, idle runners waste resources

### 🔴 Persistent State (Security & Reliability Risk)
- Runners retain filesystem state between jobs
- Credentials, build artifacts, and temp files can leak between jobs
- Must add manual cleanup steps in workflows

### 🔴 Manual Lifecycle Management
- Registration tokens expire after **1 hour**
- Runner software must be manually updated
- OS patching requires taking runners offline
- No self-healing if a runner process crashes

### 🔴 Limited Scaling Controls
- No concept of min/max runners
- No ability to drain jobs for maintenance
- Runner groups help with access but not capacity

### 🔴 Operational Overhead
- Each runner is independently managed
- No centralized declarative configuration
- Monitoring and alerting must be custom-built
- Runner removal requires explicit de-registration

## The Registration Flow (Manual)

```
Admin Machine                    GitHub API                     Runner Machine
     │                               │                              │
     │── Generate PAT ──────────────►│                              │
     │◄── PAT returned ─────────────│                              │
     │                               │                              │
     │── Request reg token ─────────►│                              │
     │◄── Token (expires 1hr) ──────│                              │
     │                               │                              │
     │── SSH to runner machine ─────────────────────────────────────►│
     │                               │                              │
     │   Download runner package ───────────────────────────────────►│
     │   Run config.sh with token ──────────────────────────────────►│
     │   Install as service ────────────────────────────────────────►│
     │                               │                              │
     │                               │◄──── Runner polls for jobs ──│
     │                               │                              │
     └── Repeat for EVERY runner ───────────────────────────────────►│
```

## Key Metrics to Highlight

| Metric | Traditional Approach |
|--------|---------------------|
| Time to add a runner | 15-30 minutes (manual) |
| Scale-up time | Hours (requires human) |
| Scale-down | Manual removal |
| State isolation | None (shared filesystem) |
| Recovery from failure | Manual intervention |
| Configuration drift | High risk |
