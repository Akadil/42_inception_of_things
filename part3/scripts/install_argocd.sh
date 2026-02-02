#!/bin/bash

set -e

echo "======================================"
echo "Part 3: ArgoCD Installation"
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
# Dependency Check
#
# https://argo-cd.readthedocs.io/en/stable/getting_started/#requirements
# ============================================================================
print_status "Checking dependencies..."

if ! command -v kubectl &> /dev/null; then
    print_error "Kubectl is not installed."
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Is the cluster running?"
    exit 1
fi

# ============================================================================
# Install ArgoCD
# ============================================================================
print_status "Creating argocd namespace..."

if kubectl get namespace argocd &> /dev/null; then
    print_warning "Namespace 'argocd' already exists. Deleting and recreating..."
    kubectl delete namespace argocd
    # Wait for namespace to be fully deleted
    while kubectl get namespace argocd &> /dev/null; do
        sleep 1
    done
fi

kubectl create namespace argocd
print_status "Namespace created."

print_status "Installing ArgoCD..."

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_status "ArgoCD installed. Waiting for pods to be ready..."
print_warning "This may take a few minutes..."

# Wait for all ArgoCD pods to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

print_status "All ArgoCD pods are ready!"

# ============================================================================
# Allow HTTP connection
# ============================================================================
# print_status "Configuring ArgoCD server access..."

# Patch the service to allow insecure access (for local development)
# kubectl patch deployment argocd-server -n argocd --type='json' \
#  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--insecure"}]'

# Wait for the patched deployment to roll out
# kubectl rollout status deployment/argocd-server -n argocd

# print_status "ArgoCD server configured."

# ============================================================================
# Get ArgoCD Admin Password
# ============================================================================
print_status "Retrieving ArgoCD admin password..."

# Wait for the secret to be created
sleep 5

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# ============================================================================
# Display Access Information
# ============================================================================
print_status "ArgoCD is ready!"
echo ""
echo "======================================"
echo "ArgoCD Access Information"
echo "======================================"
echo "URL: http://localhost:8080"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo ""
echo "To access ArgoCD UI:"
echo "  1. Open browser: http://localhost:8080"
echo "  2. Login with credentials above"
echo "  3. Accept the self-signed certificate warning (if any)"
echo ""
echo "Check ArgoCD status:"
echo "  kubectl get pods -n argocd"
echo "  kubectl get svc -n argocd"
echo ""
echo "======================================"

exit 0
