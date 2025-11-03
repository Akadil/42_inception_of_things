#!/bin/bash
set -e

MASTER_IP=$1

echo "Installing K3s in agent mode..."

# Wait for token from master
echo "Waiting for node token from master..."
while [ ! -f /vagrant/node-token ]; do
  sleep 2
done

# Read the token
TOKEN=$(cat /vagrant/node-token)
echo "Here is my token: " ${TOKEN}

# Install K3s as agent
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface enp0s8" K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=${TOKEN} sh -

# Remove the token for security reasons
rm /vagrant/node-token

echo "✓ K3s agent installed successfully"
echo "✓ Joined cluster at ${MASTER_IP}"
