#!/bin/bash
set -e

APP_NAME="my_application"
NAMESPACE="dev"

echo "======================================"
echo "Redeploy Application (Hard Reset)"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[!]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[*]${NC} $1"; }

# ============================================================================
# Confirm redeploy
# ============================================================================
print_warning "This will DELETE the namespace '$NAMESPACE' and the ArgoCD Application '$APP_NAME', then re-run the deployment script."
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Redeploy cancelled."
    exit 0
fi

# ============================================================================
# Delete existing resources
# ============================================================================
print_status "Deleting ArgoCD Application (if exists)..."
kubectl delete application $APP_NAME -n argocd --ignore-not-found=true

print_status "Deleting namespace '$NAMESPACE' (if exists)..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

# Wait for namespace to be fully gone
while kubectl get namespace $NAMESPACE &> /dev/null; do
    print_status "Waiting for namespace to be deleted..."
    sleep 2
done

print_status "Cleanup complete."

