#!/bin/bash
# =============================================================================
# AFTER: Deploy Runner Scale Set (Repository Level)
# =============================================================================
# This script deploys a runner scale set that targets a specific repository.
# It replaces the legacy ARC pattern of authoring RunnerDeployment and
# HorizontalRunnerAutoscaler CRDs just to get scalable runners.
#
# PRESENTATION TALKING POINT:
# "Instead of managing RunnerDeployment YAML, we install one Helm release.
#  GitHub's listener creates a fresh runner pod per job."
# =============================================================================

set -e

# --- Configuration -----------------------------------------------------------
INSTALLATION_NAME="arc-runner-set-repo"    # This becomes the 'runs-on' value!
NAMESPACE="arc-runners"                     # Isolated from controller namespace
GITHUB_CONFIG_URL="https://github.com/seandorsett/super-tribble"
GITHUB_PAT="${GITHUB_PAT:?Error: Set GITHUB_PAT environment variable}"

echo "🚀 Deploying Runner Scale Set (Repository Level)"
echo "=================================================="
echo "  Scale Set Name: ${INSTALLATION_NAME}"
echo "  Target Repo:    ${GITHUB_CONFIG_URL}"
echo "  Namespace:      ${NAMESPACE}"
echo ""

# --- Deploy the runner scale set ---------------------------------------------
# KEY DIFFERENCE FROM LEGACY ARC:
# One Helm release replaces multiple custom resources and token plumbing.
helm upgrade --install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values values-repo.yaml \
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
echo "✅ Runner Scale Set deployed!"
echo ""
echo "WHAT'S DIFFERENT FROM LEGACY ARC:"
echo "  ✓ No RunnerDeployment or HorizontalRunnerAutoscaler CRDs"
echo "  ✓ Listener-based scaling replaces legacy webhook/poll behavior"
echo "  ✓ Runners are EPHEMERAL — one fresh pod per job"
echo "  ✓ Can scale from 0 to maxRunners instead of keeping idle runners around"
echo "  ✓ Short-lived per-job tokens replace long-lived registration tokens"
echo "  ✓ Use 'runs-on: ${INSTALLATION_NAME}' in workflows"
echo "=============================================="
