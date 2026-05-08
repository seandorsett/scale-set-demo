#!/bin/bash
# =============================================================================
# AFTER: Deploy Runner Scale Set (Repository Level)
# =============================================================================
# This script deploys a runner scale set that targets a specific repository.
# Runners will auto-scale based on job demand.
#
# PRESENTATION TALKING POINT:
# "With one Helm command, we get auto-scaling ephemeral runners.
#  No manual registration, no token management, no state drift."
# =============================================================================

set -e

# --- Configuration -----------------------------------------------------------
INSTALLATION_NAME="arc-runner-set-repo"    # This becomes the 'runs-on' value!
NAMESPACE="arc-runners"                     # Isolated from controller namespace
GITHUB_CONFIG_URL="https://github.com/your-org/your-repo"
GITHUB_PAT="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"              # Or use GitHub App (see values-repo.yaml)

echo "🚀 Deploying Runner Scale Set (Repository Level)"
echo "=================================================="
echo "  Scale Set Name: ${INSTALLATION_NAME}"
echo "  Target Repo:    ${GITHUB_CONFIG_URL}"
echo "  Namespace:      ${NAMESPACE}"
echo ""

# --- Deploy the runner scale set ---------------------------------------------
# KEY DIFFERENCE: Declarative, reproducible, version-controlled
helm install "${INSTALLATION_NAME}" \
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
echo "WHAT'S DIFFERENT FROM BEFORE:"
echo "  ✓ Runners are EPHEMERAL — fresh state for every job"
echo "  ✓ Auto-scales from 0 to maxRunners based on demand"
echo "  ✓ No manual token rotation — ARC handles authentication"
echo "  ✓ Declarative config — stored in version control"
echo "  ✓ Use 'runs-on: ${INSTALLATION_NAME}' in workflows"
echo "=============================================="
