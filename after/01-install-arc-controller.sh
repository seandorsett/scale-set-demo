#!/bin/bash
# =============================================================================
# AFTER: Install Actions Runner Controller (ARC)
# =============================================================================
# This script installs the modern GitHub-supported ARC controller into your
# Kubernetes cluster. It replaces the legacy summerwind controller approach.
#
# PRESENTATION TALKING POINT:
# "Compared to legacy ARC, this install is simpler:
#  no cert-manager dependency, no summerwind chart, and no CRD YAML wrangling."
# =============================================================================

set -e

# --- Prerequisites -----------------------------------------------------------
# • A Kubernetes cluster (AKS, EKS, GKE, or local like kind/minikube)
# • Helm 3.x installed
# • kubectl configured with cluster access
# • No cert-manager required for Runner Scale Sets

echo "🚀 Installing Actions Runner Controller (ARC)"
echo "================================================"

# --- Step 1: Create the controller namespace ---------------------------------
# Best practice: Isolate controller from runner pods
CONTROLLER_NAMESPACE="arc-systems"

echo "📁 Creating controller namespace: ${CONTROLLER_NAMESPACE}"
kubectl create namespace "${CONTROLLER_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# --- Step 2: Install the ARC controller via Helm ----------------------------
# Unlike legacy ARC, this uses GitHub's official Helm chart directly.
# No summerwind controller chart and no extra CRD manifests to manage.
# This is a ONE-TIME setup — manages all runner scale sets centrally.
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
echo "  • This is the GitHub-managed controller, not legacy summerwind ARC"
echo "  • No cert-manager was required for this installation"
echo "  • It will manage all runner scale sets you deploy"
echo "  • It communicates with GitHub through the listener-based scale set model"
echo "  • It creates/destroys runner pods based on demand"
echo ""
echo "NEXT STEPS:"
echo "  • Run 02-deploy-scaleset-repo.sh for repo-level runners"
echo "  • Run 03-deploy-scaleset-org.sh for org-level runners"
echo "=============================================="
