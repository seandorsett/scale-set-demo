# Runner Scale Sets with ARC — The After State

## Live Demo

This folder supports the **live** portion of the presentation.

Use the actual runner scale set in `arc-runners` to show:

- one ephemeral pod for **AFTER: Runner Scale Set Demo**
- multiple ephemeral pods for **AFTER: Scale Set Multi-Job Demo**
- automatic teardown and scale-to-zero after jobs complete

## Recommended Demo Sequence

### 1. Single-job proof

Trigger **AFTER: Runner Scale Set Demo** and point out:

- pod hostname
- fresh workspace
- no leftover state
- direct contrast with legacy ARC

### 2. Parallel scaling proof

Trigger **AFTER: Scale Set Multi-Job Demo** and point out:

- three jobs start at once
- ARC creates multiple pods simultaneously
- each job runs in its own isolated pod
- the summary job lands on a new pod after the first three finish

## Commands

```bash
kubectl get pods -n arc-runners
kubectl get pods -n arc-runners -w
gh workflow run "AFTER: Runner Scale Set Demo" --repo seandorsett/scale-set-demo
gh workflow run "AFTER: Scale Set Multi-Job Demo" --repo seandorsett/scale-set-demo
gh run list --repo seandorsett/scale-set-demo --limit 10
```

## Why This Lands Well In A Demo

- The audience sees pods appear only when jobs are queued
- The audience sees multiple pods appear for parallel jobs
- The audience sees pods disappear after completion
- The comparison to legacy ARC is immediate and visual
