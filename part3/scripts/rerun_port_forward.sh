# Kill the old one first
pkill -f "kubectl port-forward.*8888"

# Start a fresh one
kubectl port-forward -n dev service/wil-service 8888:8888
