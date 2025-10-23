#!/bin/bash
set -e

echo "Installing K3s in server mode..."

# Install K3s as server
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode=644 \
  --node-ip=192.168.56.110 \
  --advertise-address=192.168.56.110 \
  --flannel-iface=eth1

# Wait for node token to be generated
echo "Waiting for K3s to generate node token..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

# Copy token to shared folder
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

# Show how to configure master node
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc

echo "✓ K3s server installed successfully"
echo "✓ Node token saved to /vagrant/node-token"
