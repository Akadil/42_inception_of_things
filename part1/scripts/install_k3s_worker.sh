#!/bin/bash

MASTER_IP=$1

# 1. Get Master token to register as worker node
# 1.1. Wait for token file from server
while [ ! -f /vagrant/node-token ]; do
  echo "Waiting for node-token from server..."
  sleep 2
done

# 1.2. Read the token
TOKEN=$(cat /vagrant/node-token)

# 2. Install K3s in agent mode, connecting to server
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN sh -

# 3. Success!
echo "K3s agent installed and joined to cluster"
