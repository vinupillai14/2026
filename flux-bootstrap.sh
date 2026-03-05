#!/bin/bash
# FluxCD bootstrap script for AKS clusters
# Run this ONCE per cluster after AKS is created

set -e

echo "🔄 FluxCD Bootstrap Script"
echo ""

# Auto-load GitLab token from .env.flux if it exists
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.env.flux" ]; then
  source "$SCRIPT_DIR/.env.flux"
  echo "📌 Loaded GITLAB_TOKEN from .env.flux"
fi

# Default values
GITLAB_OWNER="${GITLAB_OWNER:-ubs-group6303709}"
GITLAB_REPO="${GITLAB_REPO:-ubs-project}"
GITLAB_BRANCH="${GITLAB_BRANCH:-main}"
CLUSTER_ENV="${1:-dev}"  # dev or preprod

# Validate cluster environment
if [[ "$CLUSTER_ENV" != "dev" && "$CLUSTER_ENV" != "preprod" ]]; then
  echo "❌ Error: Invalid environment. Use: ./flux-bootstrap.sh dev|preprod"
  exit 1
fi

# Set cluster-specific variables
if [[ "$CLUSTER_ENV" == "dev" ]]; then
  RESOURCE_GROUP="rg-dev-2026"
  CLUSTER_NAME="aks-dev-2026"
  FLUX_PATH="clusters/dev"
else
  RESOURCE_GROUP="rg-preprod-2026"
  CLUSTER_NAME="aks-preprod-2026"
  FLUX_PATH="clusters/preprod"
fi

echo "📋 Configuration:"
echo "   Environment:    $CLUSTER_ENV"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Cluster:        $CLUSTER_NAME"
echo "   Flux Path:      $FLUX_PATH"
echo "   GitLab Repo:    $GITLAB_OWNER/$GITLAB_REPO"
echo ""

# Check if GITLAB_TOKEN is set
if [ -z "$GITLAB_TOKEN" ]; then
  echo "❌ Error: GITLAB_TOKEN not set."
  echo ""
  echo "   Create a token at: https://gitlab.com/-/user_settings/personal_access_tokens"
  echo "   Required scopes: api, read_repository, write_repository"
  echo ""
  echo "   Then run:"
  echo "   export GITLAB_TOKEN=<your-token>"
  echo "   ./flux-bootstrap.sh $CLUSTER_ENV"
  exit 1
fi

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
  echo "📦 Installing Flux CLI..."
  curl -s https://fluxcd.io/install.sh | bash
  echo ""
fi

echo "🔍 Checking Flux CLI version..."
flux version --client
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  echo "❌ Error: kubectl not found. Please install kubectl first."
  exit 1
fi

# Check if az CLI is available
if ! command -v az &> /dev/null; then
  echo "❌ Error: Azure CLI not found. Please install az cli first."
  exit 1
fi

# Connect to AKS cluster
echo "🔗 Connecting to AKS cluster: $CLUSTER_NAME..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

# Verify connection
echo "🔍 Verifying cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
  echo "❌ Error: Cannot connect to cluster. Is AKS deployed?"
  exit 1
fi
echo "✅ Connected to cluster"
echo ""

# Check if Flux is already installed
echo "🔍 Checking if Flux is already installed..."
if kubectl get namespace flux-system &> /dev/null; then
  echo "✅ Flux is already installed on this cluster!"
  echo ""
  echo "📊 Flux Status:"
  flux check
  echo ""
  echo "📦 Flux Resources:"
  kubectl get gitrepositories -n flux-system
  kubectl get kustomizations -n flux-system
  echo ""
  echo "No action needed. Flux is already configured."
  exit 0
fi

# Pre-flight check
echo "🔍 Running Flux pre-flight checks..."
if ! flux check --pre; then
  echo "❌ Error: Pre-flight checks failed. Fix the issues above and retry."
  exit 1
fi
echo ""

# Bootstrap Flux
echo "🚀 Bootstrapping FluxCD..."
echo ""
read -p "Continue with Flux bootstrap? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  flux bootstrap gitlab \
    --owner="$GITLAB_OWNER" \
    --repository="$GITLAB_REPO" \
    --path="$FLUX_PATH" \
    --branch="$GITLAB_BRANCH"
  
  echo ""
  echo "✅ FluxCD bootstrap complete!"
  echo ""
  echo "📋 What was created:"
  echo "   - flux-system namespace in cluster"
  echo "   - Source controller, Kustomize controller, etc."
  echo "   - Git credentials stored as K8s secret"
  echo "   - $FLUX_PATH/flux-system/ folder in GitLab repo"
  echo ""
  echo "📝 Next steps:"
  echo "   1. Add Kubernetes manifests to: $FLUX_PATH/"
  echo "   2. Push to GitLab"
  echo "   3. Flux will auto-deploy within ~1 minute"
  echo ""
  echo "🔍 Check Flux status anytime with:"
  echo "   flux check"
  echo "   flux get all"
else
  echo "❌ Bootstrap cancelled"
  exit 1
fi
