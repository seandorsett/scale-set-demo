#!/bin/bash
# =============================================================================
# AFTER: Deploy Runner Scale Set (Organization Level)
# =============================================================================
# This script deploys a runner scale set at the organization level.
# It can serve jobs from any repository in the org (controlled by runner groups)
# without using the legacy ARC RunnerDeployment CRD model.
#
# PRESENTATION TALKING POINT:
# "Legacy ARC needed multiple CRDs and pre-created runners.
#  Here, one Helm release gives shared capacity plus ephemeral runners."
# =============================================================================

set -e

# --- Configuration -----------------------------------------------------------
INSTALLATION_NAME="arc-runner-set-org"     # This becomes the 'runs-on' value!
NAMESPACE="arc-runners-org"                 # Separate namespace for org runners
GITHUB_CONFIG_URL="https://github.com/seandorsett"
GITHUB_PAT="${GITHUB_PAT:?Error: Set GITHUB_PAT environment variable}"              # Needs admin:org scope

echo "🚀 Deploying Runner Scale Set (Organization Level)"
echo "===================================================="
echo "  Scale Set Name: ${INSTALLATION_NAME}"
echo "  Target Org:     ${GITHUB_CONFIG_URL}"
echo "  Namespace:      ${NAMESPACE}"
echo "  Runner Group:   production-runners"
echo ""

# --- Deploy the runner scale set ---------------------------------------------
# Compared to legacy ARC, there is no RunnerDeployment YAML to create and no
# HorizontalRunnerAutoscaler resource to tune separately.
helm upgrade --install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values values-org.yaml \
  --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
  --set githubConfigSecret.github_token="${GITHUB_PAT}" \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

# --- Verify ------------------------------------------------------------------
echo ""
echo "✅ Verifying deployment..."
helm list -n "${NAMESPACE}"
kubectl get pods -n "${NAMESPACE}"

echo ""
echo "=============================================="
echo "✅ Org-Level Runner Scale Set deployed!"
echo ""
echo "KEY DIFFERENCES FROM LEGACY ARC:"
echo "  ✓ Serves all repos in the organization"
echo "  ✓ Runner group 'production-runners' controls access"
echo "  ✓ Single scale set name replaces multi-label RunnerDeployment routing"
echo "  ✓ Listener-based scaling reacts to queued jobs"
echo "  ✓ Ephemeral runners avoid cross-repo state contamination"
echo "  ✓ Short-lived per-job tokens replace legacy registration tokens"
echo "  ✓ GitHub-supported ARC replaces community-maintained summerwind"
echo "=============================================="
