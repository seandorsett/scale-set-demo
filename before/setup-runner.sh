#!/bin/bash
# =============================================================================
# Traditional Self-Hosted Runner Setup Script
# =============================================================================
# This script demonstrates the MANUAL process of registering a self-hosted
# runner with GitHub Actions. This is the "before" approach — notice the
# operational overhead involved.
#
# PRESENTATION TALKING POINT:
# "Every runner must be individually provisioned, registered with a token,
#  and maintained. Scaling requires repeating this process for each machine."
# =============================================================================

set -e

# --- Configuration -----------------------------------------------------------
RUNNER_VERSION="2.319.1"
GITHUB_ORG="your-org"
GITHUB_REPO="your-repo"
RUNNER_NAME="self-hosted-runner-$(hostname)"
RUNNER_LABELS="self-hosted,linux,x64"
RUNNER_WORK_DIR="_work"

# --- Step 1: Download the runner package -------------------------------------
# PAIN POINT: Manual version management — you must track and update versions
echo "📦 Downloading Actions Runner v${RUNNER_VERSION}..."
mkdir -p actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# --- Step 2: Generate a registration token -----------------------------------
# PAIN POINT: Tokens expire after 1 hour — automation is fragile
# PAIN POINT: Requires a PAT with admin:org or repo scope
echo "🔑 Generating registration token..."
echo "    NOTE: You must provide a PAT with appropriate permissions"
echo "    For repo-level:  admin:repo scope"
echo "    For org-level:   admin:org scope"

# Repo-level registration token
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token" \
  | jq -r '.token')

# Org-level registration token (alternative)
# REG_TOKEN=$(curl -s -X POST \
#   -H "Authorization: token ${GITHUB_PAT}" \
#   -H "Accept: application/vnd.github+json" \
#   "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token" \
#   | jq -r '.token')

# --- Step 3: Configure the runner --------------------------------------------
# PAIN POINT: Interactive prompts or complex flag combinations
# PAIN POINT: No declarative configuration — imperative setup only
echo "⚙️  Configuring runner..."
./config.sh \
  --url "https://github.com/${GITHUB_ORG}/${GITHUB_REPO}" \
  --token "${REG_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --work "${RUNNER_WORK_DIR}" \
  --unattended \
  --replace

# --- Step 4: Install and start the runner service ----------------------------
# PAIN POINT: Must manage the service lifecycle manually (systemd, etc.)
# PAIN POINT: No auto-healing — if the runner crashes, manual intervention needed
echo "🚀 Installing runner as a service..."
sudo ./svc.sh install
sudo ./svc.sh start

echo "✅ Runner '${RUNNER_NAME}' is registered and running."
echo ""
echo "⚠️  OPERATIONAL CONCERNS WITH THIS APPROACH:"
echo "   • Runner state persists between jobs (security risk)"
echo "   • No automatic scaling — must manually add/remove runners"
echo "   • Token rotation requires re-registration"
echo "   • OS patching requires taking runners offline"
echo "   • No central management — each runner is independent"
echo "   • Runner groups must be managed via API or UI"
