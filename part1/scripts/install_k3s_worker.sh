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
curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${TOKEN} sh -

echo "✓ K3s agent installed successfully"
echo "✓ Joined cluster at ${MASTER_IP}"
