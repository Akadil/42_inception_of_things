#!/bin/bash
set -e

echo "Installing K3s in server mode..."

# Install K3s as server
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Wait for node token to be generated
echo "Waiting for K3s to generate node token..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

# Copy token to shared folder
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

echo "✓ K3s server installed successfully"
echo "✓ Node token saved to /vagrant/node-token"
