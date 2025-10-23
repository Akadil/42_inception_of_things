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

# Install K3s as agent
curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${TOKEN} sh -s - agent \
  --node-ip=192.168.56.111 \
  --flannel-iface=eth1

# Remove the token for security reasons
rm /vagrant/node-token

echo "✓ K3s agent installed successfully"
echo "✓ Joined cluster at ${MASTER_IP}"
