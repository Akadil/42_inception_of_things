#!/bin/bash

# 1. Install K3s in server mode
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# 2. Pass the server token to worker nodes by storing it shared folder
# 2.1 Wait for K3s to be ready
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  echo "Waiting for node-token..."
  sleep 2
done

# 2.2 Copy token to synced folder so worker can access it
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

# 3. Finished
echo "K3s server installed. Token saved to /vagrant/node-token"
