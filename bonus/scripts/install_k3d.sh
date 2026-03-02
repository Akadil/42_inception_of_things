#!/bin/bash

# k3d installation script
# This script installes all dependencies and k3d itself
#
# The website:
# https://k3d.io/stable
set -e  # Exit on any error

echo "=================================="
echo "IoT Part 3 - K3d Setup Script"
echo "=================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[!]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[*]${NC} $1"; }

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    # Not the best practice and it messes up the further logic
    exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt-get update

# Install Docker if not present
# https://docs.docker.com/engine/install/debian/
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    
    # Install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_warning "Docker installed. You may need to log out and back in for group changes to take effect."
else
    print_status "Docker already installed"
fi

# Install kubectl if not present
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
if ! command -v kubectl &> /dev/null; then
    print_status "Installing kubectl..."
    
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    print_status "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    print_status "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# Install K3d if not present
# https://k3d.io/stable/#installation
if ! command -v k3d &> /dev/null; then
    print_status "Installing K3d..."
    
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    
    print_status "K3d installed: $(k3d version)"
else
    print_status "K3d already installed: $(k3d version)"
fi

# Verify installations
print_status "Verifying installations..."

if command -v docker &> /dev/null && \
   command -v kubectl &> /dev/null && \
   command -v k3d &> /dev/null; then
    print_status "All required tools installed successfully!"
    echo ""
    echo "Installed versions:"
    echo "  - Docker: $(docker --version)"
    echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    echo "  - K3d: $(k3d version)"
else
    print_error "Some tools failed to install. Please check the output above."
    exit 1
fi

print_status "Installation complete!"
print_warning "Note: If this is your first time installing Docker, you may need to:"
print_warning "  1. Log out and log back in (for docker group permissions)"
print_warning "  2. Or run: newgrp docker"

exit 0
