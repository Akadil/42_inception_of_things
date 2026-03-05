#!/bin/bash
set -e

APP_NAME="my_application"           # Application name
NAMESPACE="dev"                     # Namespace to deploy app
SERVICE_NAME="wil-service"

echo "======================================"
echo "Part 3: Deploy Application via ArgoCD"
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
# Check cluster and ArgoCD
# ============================================================================
print_status "Checking cluster connection..."

if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to cluster. Is it running?"
    print_error "Run: ./create-cluster.sh"
    exit 1
fi

if ! kubectl get namespace argocd &> /dev/null; then
    print_error "ArgoCD namespace not found."
    print_error "Run: ./install-argocd.sh"
    exit 1
fi

print_status "Cluster and ArgoCD are ready."

# ============================================================================
# Create dev namespace
# ============================================================================
print_status "Creating namespace: $NAMESPACE"

if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_warning "Namespace '$NAMESPACE' already exists."
else
    kubectl create namespace $NAMESPACE
    print_status "Namespace created."
fi

# ============================================================================
# Create Application CRD
# ============================================================================
print_status "Creating ArgoCD Application..."

kubectl apply -f "./confs/dev/application.yaml"

print_status "Application created!"

# ============================================================================
# Wait for sync
# ============================================================================
print_status "Waiting for ArgoCD to sync application..."
print_warning "This may take a minute while ArgoCD clones the repo and applies manifests..."

sleep 15

# ============================================================================
# Display status
# ============================================================================
print_status "Checking application status..."
echo ""

kubectl get application $APP_NAME -n argocd

echo ""
print_status "Checking pods in $NAMESPACE namespace..."
kubectl get pods -n $NAMESPACE


# ============================================================================
# Setup port forwarding
# ============================================================================
print_status "Setting up port forwarding to access application on localhost:8888..."

# Wait for the service to exist
TIMEOUT=60
while ! kubectl get service $SERVICE_NAME -n $NAMESPACE &> /dev/null; do
    sleep 2
    TIMEOUT=$((TIMEOUT-2))
    if [ $TIMEOUT -le 0 ]; then
        print_warning "Service $SERVICE_NAME not found after waiting. Port forwarding skipped."
        break
    fi
done

if kubectl get service $SERVICE_NAME -n $NAMESPACE &> /dev/null; then
    # Start port-forward in background
    kubectl port-forward -n $NAMESPACE service/$SERVICE_NAME 8888:8888 &
    PF_PID=$!
    print_status "Port forwarding started (PID: $PF_PID)."
    print_warning "To stop port forwarding, run: kill $PF_PID"
    # Give it a moment to establish
    sleep 3
else
    print_warning "Service $SERVICE_NAME not found. Please check your application manifests."
fi


# ============================================================================
# Final instructions
# ============================================================================
echo ""
print_status "Application deployment initiated!"
echo ""
echo "======================================"
echo "Next Steps"
echo "======================================"
echo ""
echo "1. Check ArgoCD UI:"
echo "   http://argocd.local:8080"
echo ""
echo "2. Monitor application sync:"
echo "   kubectl get application $APP_NAME -n argocd -w"
echo ""
echo "3. Check pods:"
echo "   kubectl get pods -n $NAMESPACE"
echo ""
echo "4. View logs:"
echo "   kubectl logs -n $NAMESPACE -l app=$APP_NAME"
echo ""
echo "5. Test your application:"
if [ -n "$PF_PID" ]; then
    echo "   curl http://localhost:8888   (port‑forward active)"
else
    echo "   curl http://localhost:8888   (if you started port‑forward manually)"
fi
echo ""
echo "6. To update the app (change image version):"
echo "   - Edit deployment.yaml in your Git repo"
echo "   - Commit and push"
echo "   - ArgoCD will auto-sync in ~3 minutes"
echo ""
echo "======================================"

exit 0
