#!/bin/bash

set -e

LOGIN="akalimol"
CLUSTER_NAME="akalimol-cluster"

echo "======================================"
echo "Part 3: K3d Cluster Creation"
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
# ============================================================================
print_status "Checking dependencies..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Run install.sh first."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Run install.sh first."
    exit 1
fi

if ! command -v k3d &> /dev/null; then
    print_error "k3d is not installed. Run install.sh first."
    exit 1
fi

# Check if Docker daemon is running
if ! docker ps &> /dev/null; then
    print_error "Docker daemon is not running. Start it with: sudo systemctl start docker"
    print_warning "Or run: newgrp docker (if you just installed Docker)"
    exit 1
fi

print_status "All dependencies found!"

# ============================================================================
# Cluster Cleanup
# ============================================================================
print_status "Checking for existing cluster: $CLUSTER_NAME"

if k3d cluster list | grep -q "^$CLUSTER_NAME"; then
    print_warning "Cluster '$CLUSTER_NAME' already exists. Deleting..."
    k3d cluster delete $CLUSTER_NAME
    print_status "Cluster deleted."
    sleep 2
fi

# ============================================================================
# Create Cluster
# ============================================================================
print_status "Creating K3d cluster: $CLUSTER_NAME"

# Create cluster with:
# - 1 server node (control plane)
# - 2 agent nodes (workers)
# - Port 8080 on host -> port 80 in cluster (for ArgoCD UI via Ingress)
# - Port 8888 on host -> port 8888 in cluster (for your application)
# - Port 8443 on host -> port 443 in cluster (for HTTPS)

k3d cluster create $CLUSTER_NAME \
    --servers 1 \
    --agents 1 \
    --port 8080:80@loadbalancer \
    --port 8888:8888@loadbalancer \
    --port 8443:443@loadbalancer \
    --wait

print_status "Cluster created successfully!"

# ============================================================================
# Verify Cluster
# ============================================================================
print_status "Verifying cluster..."

# Wait for cluster to be ready
sleep 5

kubectl cluster-info
echo ""
kubectl get nodes

print_status "Cluster is ready!"
echo ""
echo "======================================"
echo "Cluster Information"
echo "======================================"
echo "Cluster name: $CLUSTER_NAME"
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "Exposed ports:"
echo "  - 8080 -> 80 (HTTP/ArgoCD)"
echo "  - 8888 -> 8888 (Application)"
echo "  - 8443 -> 443 (HTTPS)"
echo ""

exit 0
