#!/bin/bash
# =============================================================================
# AFTER: Deploy Runner Scale Set (Organization Level)
# =============================================================================
# This script deploys a runner scale set at the organization level.
# It can serve jobs from any repository in the org (controlled by runner groups).
#
# PRESENTATION TALKING POINT:
# "Organization-level scale sets serve multiple repos. Combined with runner
#  groups, you get fine-grained access control WITH auto-scaling."
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
echo "KEY FEATURES:"
echo "  ✓ Serves all repos in the organization"
echo "  ✓ Runner group 'production-runners' controls access"
echo "  ✓ Scales 2-50 runners based on job demand"
echo "  ✓ 2 idle runners always warm (minRunners: 2)"
echo "  ✓ Ephemeral — no cross-repo state contamination"
echo "=============================================="
