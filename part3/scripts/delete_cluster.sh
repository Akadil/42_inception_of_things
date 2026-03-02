#!/bin/bash
set -e

LOGIN="akalimol"
CLUSTER_NAME="akalimol-cluster"

echo "======================================"
echo "Delete K3d Cluster"
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
    print_error "Docker is not installed."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. Will skip kubectl context cleanup."
fi

if ! command -v k3d &> /dev/null; then
    print_error "k3d is not installed."
    exit 1
fi

# Check if Docker daemon is running
if ! docker ps &> /dev/null; then
    print_error "Docker daemon is not running. Start it first."
    exit 1
fi

print_status "All dependencies found!\n"

# ============================================================================
# Show current clusters
# ============================================================================
print_status "Current k3d clusters:"
k3d cluster list 2>/dev/null || echo "No clusters found"
echo ""

# ============================================================================
# Confirm deletion
# ============================================================================
if k3d cluster list 2>/dev/null | grep -q "^$CLUSTER_NAME"; then
    print_warning "About to delete cluster: $CLUSTER_NAME"
    read -p "Are you sure you want to delete this cluster? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deletion cancelled."
        exit 0
    fi
else
    print_warning "Cluster '$CLUSTER_NAME' not found. Nothing to delete."
    exit 0
fi

# ============================================================================
# Delete Cluster
# ============================================================================
echo ""
print_status "Deleting cluster: $CLUSTER_NAME"

# Delete the cluster
k3d cluster delete $CLUSTER_NAME

# Verify deletion
if ! k3d cluster list 2>/dev/null | grep -q "^$CLUSTER_NAME"; then
    print_status "Cluster deleted successfully!"
else
    print_error "Failed to delete cluster."
    exit 1
fi

# ============================================================================
# Clean up kubectl context
# ============================================================================
echo ""
print_status "Cleaning up kubectl context..."

# Check if current kubectl context points to the deleted cluster
if command -v kubectl &> /dev/null; then
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
    if [[ "$CURRENT_CONTEXT" == "k3d-$CLUSTER_NAME" ]]; then
        print_warning "Current kubectl context is set to deleted cluster. Switching context..."
        kubectl config unset current-context
        print_status "kubectl context reset"
    fi
    
    # Remove cluster from kubeconfig if it exists
    if kubectl config get-clusters 2>/dev/null | grep -q "k3d-$CLUSTER_NAME"; then
        print_warning "Removing cluster from kubeconfig..."
        kubectl config delete-cluster "k3d-$CLUSTER_NAME" 2>/dev/null || true
        kubectl config delete-context "k3d-$CLUSTER_NAME" 2>/dev/null || true
        kubectl config unset "users.k3d-$CLUSTER_NAME" 2>/dev/null || true
    fi
    print_status "kubectl context cleaned"
fi

# ============================================================================
# Optional: Clean up Docker resources
# ============================================================================
echo ""
print_warning "Would you like to clean up unused Docker resources? (optional)"
read -p "Remove unused Docker volumes and networks? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up Docker resources..."
    
    # Remove any leftover k3d volumes
    docker volume ls -q | grep "k3d.*$CLUSTER_NAME" | xargs -r docker volume rm
    
    # Remove unused Docker networks (but be careful!)
    docker network ls -q --filter "label=k3d" | xargs -r docker network rm 2>/dev/null || true
    
    print_status "Docker resources cleaned"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "======================================"
echo "Deletion Complete"
echo "======================================"
print_status "Cluster '$CLUSTER_NAME' has been deleted."
echo ""
print_status "Current clusters:"
k3d cluster list 2>/dev/null || echo "No clusters found"
echo ""
print_status "Current kubectl context:"
if command -v kubectl &> /dev/null; then
    kubectl config current-context 2>/dev/null || echo "No context set"
else
    echo "kubectl not installed"
fi
echo ""

exit 0
