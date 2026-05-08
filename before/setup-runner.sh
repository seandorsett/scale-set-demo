#!/bin/bash
# =============================================================================
# Legacy ARC Setup Script (RunnerDeployment Model)
# =============================================================================
# This script demonstrates the OLD community-maintained ARC setup:
# - install cert-manager first
# - install summerwind/actions-runner-controller
# - create a RunnerDeployment
# - create a HorizontalRunnerAutoscaler
#
# PRESENTATION TALKING POINTS:
# - extra dependency on cert-manager
# - multiple CRDs to manage
# - webhook / autoscaling setup is more complex
# - runners are pre-created and sit idle waiting for jobs
# =============================================================================

set -euo pipefail

NAMESPACE="actions-runner-system"
RELEASE_NAME="actions-runner-controller"
GITHUB_CONFIG_URL="https://github.com/seandorsett/scale-set-demo"

echo "==> Step 1: Install cert-manager (required dependency)"
echo "PAIN POINT: Legacy ARC requires cert-manager before the controller can run."
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

echo ""
echo "==> Step 2: Install legacy ARC controller (summerwind/actions-runner-controller)"
echo "PAIN POINT: Community-maintained controller plus separate chart lifecycle."
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update
helm upgrade --install "${RELEASE_NAME}" actions-runner-controller/actions-runner-controller \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set authSecret.create=true \
  --set authSecret.github_token="${GITHUB_TOKEN:-replace-me}"

echo ""
echo "==> Step 3: Create RunnerDeployment CRD"
echo "PAIN POINT: Labels, replicas, repo/org targeting, and pod behavior all live in CRDs."
cat <<'EOF' > runner-deployment.yaml
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
EOF

kubectl apply -f runner-deployment.yaml

echo ""
echo "==> Step 4: Create HorizontalRunnerAutoscaler CRD"
echo "PAIN POINT: Scaling requires extra CRDs and often webhook-based configuration."
cat <<'EOF' > horizontal-runner-autoscaler.yaml
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
EOF

kubectl apply -f horizontal-runner-autoscaler.yaml

echo ""
echo "Legacy ARC demo setup complete."
echo ""
echo "Reminder of legacy ARC pain points:"
echo " - cert-manager dependency"
echo " - multiple CRDs (RunnerDeployment, RunnerReplicaSet, Runner, HRA)"
echo " - webhook/pull autoscaling complexity"
echo " - pre-created runner pools consume resources while idle"
echo " - long-lived runner pods can process multiple jobs over time"
