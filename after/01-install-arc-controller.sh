#!/bin/bash
# =============================================================================
# AFTER: Install Actions Runner Controller (ARC)
# =============================================================================
# This script installs the ARC controller into your Kubernetes cluster.
# ARC is the foundation that manages runner scale sets.
#
# PRESENTATION TALKING POINT:
# "One controller installation manages ALL your runner scale sets.
#  It handles registration, scaling, and lifecycle automatically."
# =============================================================================

set -e

# --- Prerequisites -----------------------------------------------------------
# • A Kubernetes cluster (AKS, EKS, GKE, or local like kind/minikube)
# • Helm 3.x installed
# • kubectl configured with cluster access
# • cert-manager (recommended for production)

echo "🚀 Installing Actions Runner Controller (ARC)"
echo "================================================"

# --- Step 1: Create the controller namespace ---------------------------------
# Best practice: Isolate controller from runner pods
CONTROLLER_NAMESPACE="arc-systems"

echo "📁 Creating controller namespace: ${CONTROLLER_NAMESPACE}"
kubectl create namespace "${CONTROLLER_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# --- Step 2: Install the ARC controller via Helm ----------------------------
# This is a ONE-TIME setup — manages all runner scale sets centrally
echo "📦 Installing ARC controller via Helm..."

helm install arc \
  --namespace "${CONTROLLER_NAMESPACE}" \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

# --- Step 3: Verify the installation ----------------------------------------
echo "✅ Verifying controller installation..."
kubectl get pods -n "${CONTROLLER_NAMESPACE}"

echo ""
echo "=============================================="
echo "✅ ARC Controller installed successfully!"
echo ""
echo "WHAT JUST HAPPENED:"
echo "  • Controller pod is running in '${CONTROLLER_NAMESPACE}'"
echo "  • It will manage all runner scale sets you deploy"
echo "  • It communicates with GitHub API to receive job assignments"
echo "  • It creates/destroys runner pods based on demand"
echo ""
echo "NEXT STEPS:"
echo "  • Run 02-deploy-scaleset-repo.sh for repo-level runners"
echo "  • Run 03-deploy-scaleset-org.sh for org-level runners"
echo "=============================================="
