#!/bin/bash
set -e

echo "Installing K3s in server mode..."

# Install K3s as server
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface enp0s8"  sh -
echo "K3s installation completed."

echo "Creating app one..."
kubectl create configmap app-one-html --from-file /vagrant/confs/app1/index.html
kubectl apply -f /vagrant/confs/app1/deployment.yaml
kubectl apply -f /vagrant/confs/app1/service.yaml
echo "App one created succesfully!"

echo "Creating app two..."
kubectl create configmap app-two-html --from-file /vagrant/confs/app2/index.html
kubectl apply -f /vagrant/confs/app2/deployment.yaml
kubectl apply -f /vagrant/confs/app2/service.yaml
echo "App two created succesfully!"

echo "Creating app three..."
kubectl create configmap app-three-html --from-file /vagrant/confs/app3/index.html
kubectl apply -f /vagrant/confs/app3/deployment.yaml
kubectl apply -f /vagrant/confs/app3/service.yaml
echo "App three created succesfully!"

# Verify K3s installation
kubectl get nodes
echo "K3s server is up and running."

# Deploy all applications
kubectl apply -f /vagrant/confs/ingress.yaml
