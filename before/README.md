# Legacy ARC (RunnerDeployment) — The Before State

## Overview

This directory now represents the **legacy Actions Runner Controller (ARC)** model that many customers adopted before **Runner Scale Sets**.

Legacy ARC is based on the community-maintained controller:

- `summerwind/actions-runner-controller`
- CRDs such as `RunnerDeployment`, `RunnerReplicaSet`, and `Runner`
- `cert-manager` as a prerequisite
- pre-created runner pools that stay online waiting for work

## Architecture

```text
                      ┌─────────────────────────────┐
                      │         GitHub.com          │
                      │   Jobs routed by labels     │
                      └──────────────┬──────────────┘
                                     │
                                     ▼
                    ┌──────────────────────────────────┐
                    │  summerwind ARC controller       │
                    │  (community-maintained)          │
                    └──────────────┬───────────────────┘
                                   │
                     requires      │ watches CRDs
                    certs/webhooks │
                                   ▼
                         ┌──────────────────┐
                         │   cert-manager   │
                         │  required dep    │
                         └──────────────────┘
                                   │
                                   ▼
                 ┌────────────────────────────────────────┐
                 │ RunnerDeployment / RunnerReplicaSet    │
                 │ HorizontalRunnerAutoscaler             │
                 └─────────────────┬──────────────────────┘
                                   │
                     pre-creates runner pool
                                   ▼
                  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
                  │ Runner pod  │ │ Runner pod  │ │ Runner pod  │
                  │ long-lived  │ │ long-lived  │ │ long-lived  │
                  │ idle often  │ │ handles     │ │ consumes     │
                  │ consumes $   │ │ many jobs   │ │ cluster res. │
                  └─────────────┘ └─────────────┘ └─────────────┘
```

## Key Characteristics of Legacy ARC

- Uses CRDs: `RunnerDeployment`, `RunnerReplicaSet`, `Runner`
- Requires `cert-manager` before the controller can be installed
- Uses long-lived runner pods instead of one fresh pod per job
- Scaling often depends on `HorizontalRunnerAutoscaler`
- Webhook-based scaling requires extra plumbing and secret management
- Runners are pre-created as a pool, so idle capacity still costs money
- Registration uses longer-lived token flows than the newer JIT model
- Labels are assigned at the `RunnerDeployment` level
- More YAML and CRD lifecycle management for platform teams

## Example RunnerDeployment

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: legacy-arc-repo-runners
  namespace: actions-runner-system
spec:
  replicas: 2
  template:
    spec:
      repository: seandorsett/scale-set-demo
      labels:
        - legacy-arc
        - repo-demo
      dockerdWithinRunnerContainer: true
      resources:
        requests:
          cpu: "500m"
          memory: "1Gi"
```

## Example HorizontalRunnerAutoscaler

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: legacy-arc-repo-runners-autoscaler
  namespace: actions-runner-system
spec:
  scaleTargetRef:
    kind: RunnerDeployment
    name: legacy-arc-repo-runners
  minReplicas: 2
  maxReplicas: 10
  scaleDownDelaySecondsAfterScaleOut: 300
  metrics:
    - type: TotalNumberOfQueuedAndInProgressWorkflowRuns
      repositoryNames:
        - seandorsett/scale-set-demo
```

## Pain Points to Highlight

### 1. cert-manager dependency

- You must install and maintain `cert-manager` before legacy ARC
- Another control-plane dependency means more upgrades, more failure modes, and more YAML

### 2. Complex CRD model

- Operators manage `RunnerDeployment`, `RunnerReplicaSet`, `Runner`, and often `HorizontalRunnerAutoscaler`
- The mental model is heavier than a simpler scale-set-based approach

### 3. Webhook scaling complexity

- Scaling can be pull-based or webhook-based
- Webhook mode needs extra config, secrets, ingress, and tuning
- More moving parts means harder troubleshooting during a demo or production incident

### 4. Idle runner costs

- Runners are pre-created and wait for jobs
- If you keep a warm pool, idle pods still consume cluster resources

### 5. Long-lived runners and tokens

- Runner pods are long-lived and may process multiple jobs over time
- Token and registration handling is less streamlined than the newer just-in-time flow

## Live Demo

For the live demo in this repo:

- The workflows still run on `ubuntu-latest` for reliability
- Comments and log output explain what the **legacy ARC** `runs-on` labels would have looked like
- Use the workflows to narrate the old model:
  - pre-created runner pools
  - idle cost
  - complex autoscaler/webhook setup
  - more YAML and CRD overhead

## Files in This Folder

| File | Purpose |
|------|---------|
| `setup-runner.sh` | Demo setup script for legacy ARC installation |
| `runner-deployment.yaml` | Example `RunnerDeployment` manifest |
| `horizontal-runner-autoscaler.yaml` | Example `HorizontalRunnerAutoscaler` manifest |
| `workflow-repo-level.yml` | Repo-level legacy ARC demo workflow |
| `workflow-org-level.yml` | Org-level legacy ARC demo workflow |
