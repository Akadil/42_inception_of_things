#!/bin/bash
set -e

echo "Installing K3s in server mode..."

# Install K3s as server
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface enp0s8"  sh -
echo "K3s installation completed."

# Verify K3s installation
kubectl get nodes
echo "K3s server is up and running."

# Deploy all applications
