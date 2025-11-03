#!/bin/bash
set -e

echo "Installing K3s in server mode..."

# Install K3s as server
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface enp0s8"  sh -

# Wait for node token to be generated
echo "Waiting for K3s to generate node token..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

# Copy token to shared folder
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

# Show how to configure master node
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
# sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/

echo "✓ K3s server installed successfully"
echo "✓ Node token saved to /vagrant/node-token"
