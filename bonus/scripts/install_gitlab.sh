#!/bin/bash
set -euo pipefail

NAMESPACE="gitlab"
DOMAIN="local"
GITLAB_HOST="gitlab.k3d.gitlab.com"
EXTERNAL_IP="127.0.0.1"
HOSTS_ENTRY="${EXTERNAL_IP} ${GITLAB_HOST}"

# ─── 1. Install Helm if missing ───────────────────────────────────────────────
if ! command -v helm &>/dev/null; then
  echo "[+] Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "[✓] Helm already installed: $(helm version --short)"
fi

# ─── 2. Add GitLab Helm repo ──────────────────────────────────────────────────
if ! helm repo list 2>/dev/null | grep -q "^gitlab"; then
  echo "[+] Adding GitLab Helm repo..."
  helm repo add gitlab https://charts.gitlab.io/
fi
helm repo update

# ─── 3. Create namespace ──────────────────────────────────────────────────────
kubectl get namespace "$NAMESPACE" &>/dev/null || kubectl create namespace "$NAMESPACE"

# ─── 4. Install/upgrade GitLab ────────────────────────────────────────────────
echo "[+] Installing GitLab (this takes 5-10 min)..."
helm upgrade --install gitlab gitlab/gitlab \
  -n "$NAMESPACE" \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.hosts.domain=k3d.gitlab.com \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.class=traefik \
  --set global.hosts.https=false \
  --timeout 600s

# ─── 5. Wait for all pods ─────────────────────────────────────────────────────
echo "[+] Waiting for GitLab pods to be ready (timeout: 10min)..."

kubectl wait --namespace "$NAMESPACE" \
  --for=condition=ready pod \
  --selector=app=webservice \
  --timeout=1200s

kubectl rollout status deployment/gitlab-webservice-default \
  --namespace "$NAMESPACE"

echo "[✓] GitLab is ready."

# ─── 6. Apply GitLab ingress ──────────────────────────────────────────────────
echo "[+] Applying GitLab ingress..."
kubectl apply -f "./confs/gitlab/ingress.yaml"

# ─── 7. Patch /etc/hosts (idempotent) ────────────────────────────────────────
if grep -qF "$HOSTS_ENTRY" /etc/hosts; then
  echo "[✓] /etc/hosts already contains ${GITLAB_HOST}, skipping."
else
  echo "[+] Adding ${GITLAB_HOST} to /etc/hosts..."
  echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts > /dev/null
fi

# ─── 8. Print credentials ─────────────────────────────────────────────────────
ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password \
  -n "$NAMESPACE" \
  -o jsonpath="{.data.password}" | base64 --decode)

echo ""
echo "════════════════════════════════════════"
echo "  GitLab is up!"
echo "  URL:      http://${GITLAB_HOST}"
echo "  User:     root"
echo "  Password: ${ROOT_PASSWORD}"
echo "════════════════════════════════════════"
echo ""
echo "  Next step: run configure_argocd.sh"
