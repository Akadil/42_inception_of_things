#!/bin/bash
set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────
GITLAB_NAMESPACE="gitlab"
GITLAB_HOST="gitlab.k3d.gitlab.com"
GITLAB_EXTERNAL_URL="http://${GITLAB_HOST}"
GITLAB_INTERNAL_URL="http://gitlab-webservice-default.gitlab.svc:8181"
PROJECT_NAME="my-gitlab"
ARGOCD_NAMESPACE="argocd"
CONFS_DIR="./confs"

# ─── 1. Get root password ─────────────────────────────────────────────────────
echo "[+] Fetching GitLab root password..."
ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password \
  -n "$GITLAB_NAMESPACE" \
  -o jsonpath="{.data.password}" | base64 --decode)

# ─── 2. Create PAT (revoke existing to stay idempotent) ──────────────────────
echo "[+] Setting up GitLab PAT..."
EXISTING_TOKEN_ID=$(curl -sf \
  "${GITLAB_EXTERNAL_URL}/api/v4/personal_access_tokens?user_id=1" \
  -u "root:${ROOT_PASSWORD}" \
  | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2 || true)

if [ -n "${EXISTING_TOKEN_ID:-}" ]; then
  echo "    Revoking existing PAT (id=${EXISTING_TOKEN_ID})..."
  curl -sf -X DELETE \
    "${GITLAB_EXTERNAL_URL}/api/v4/personal_access_tokens/${EXISTING_TOKEN_ID}" \
    -u "root:${ROOT_PASSWORD}" > /dev/null
fi

GITLAB_TOKEN=$(curl -sf \
  -X POST "${GITLAB_EXTERNAL_URL}/api/v4/users/1/personal_access_tokens" \
  --header "Content-Type: application/json" \
  -u "root:${ROOT_PASSWORD}" \
  --data '{
    "name": "argocd-token",
    "scopes": ["api", "read_repository", "write_repository"]
  }' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$GITLAB_TOKEN" ]; then
  echo "[✗] Failed to create PAT. Is GitLab reachable at ${GITLAB_EXTERNAL_URL}?"
  exit 1
fi
echo "[✓] PAT created."

# ─── 3. Create GitLab project (idempotent) ────────────────────────────────────
echo "[+] Creating GitLab project '${PROJECT_NAME}'..."
PROJECT_EXISTS=$(curl -sf \
  "${GITLAB_EXTERNAL_URL}/api/v4/projects?search=${PROJECT_NAME}" \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  | grep -c "\"name\":\"${PROJECT_NAME}\"" || true)

if [ "$PROJECT_EXISTS" -eq 0 ]; then
  curl -sf \
    -X POST "${GITLAB_EXTERNAL_URL}/api/v4/projects" \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{
      \"name\": \"${PROJECT_NAME}\",
      \"visibility\": \"public\",
      \"initialize_with_readme\": false
    }" > /dev/null
  echo "[✓] Project created."
else
  echo "[✓] Project already exists, skipping."
fi

# ─── 4. Push manifests to GitLab ─────────────────────────────────────────────
echo "[+] Pushing manifests to GitLab..."
REPO_URL="http://root:${GITLAB_TOKEN}@${GITLAB_HOST}/root/${PROJECT_NAME}.git"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

git clone "$REPO_URL" "$TMP_DIR" 2>/dev/null

pushd "$TMP_DIR" > /dev/null
  git config user.email "admin@gitlab.local"
  git config user.name "admin"

  # Handle empty repo (no HEAD yet)
  if ! git rev-parse HEAD &>/dev/null; then
    git checkout -b main
  fi

  cp "${CONFS_DIR}/devs/deployment.yaml" .
  cp "${CONFS_DIR}/devs/service.yaml" .

  git add .
  if git diff --cached --quiet; then
    echo "[✓] Manifests already up to date, nothing to commit."
  else
    git commit -m "Add application manifests"
    git push origin HEAD:main
    echo "[✓] Manifests pushed."
  fi
popd > /dev/null

# ─── 5. Register repo in ArgoCD (idempotent) ─────────────────────────────────
echo "[+] Registering GitLab repo in ArgoCD..."
if kubectl -n "$ARGOCD_NAMESPACE" get secret gitlab-repo-creds &>/dev/null; then
  kubectl -n "$ARGOCD_NAMESPACE" delete secret gitlab-repo-creds
fi

kubectl -n "$ARGOCD_NAMESPACE" create secret generic gitlab-repo-creds \
  --from-literal=type=git \
  --from-literal=url="${GITLAB_INTERNAL_URL}/root/${PROJECT_NAME}.git" \
  --from-literal=username=root \
  --from-literal=password="${GITLAB_TOKEN}"

kubectl -n "$ARGOCD_NAMESPACE" label secret gitlab-repo-creds \
  argocd.argoproj.io/secret-type=repository

echo "[✓] Repo registered in ArgoCD."

# ─── 6. Apply ArgoCD Application CR ──────────────────────────────────────────
echo "[+] Applying ArgoCD Application..."
kubectl apply -f "${CONFS_DIR}/devs/application.yaml"
echo "[✓] Application applied."

# ─── 7. Wait for ArgoCD sync ─────────────────────────────────────────────────
echo "[+] Waiting for ArgoCD to sync (timeout: 4min)..."
for i in $(seq 1 24); do
  SYNC=$(kubectl get app my-application -n "$ARGOCD_NAMESPACE" \
    -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Pending")
  HEALTH=$(kubectl get app my-application -n "$ARGOCD_NAMESPACE" \
    -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Pending")
  echo "  [${i}/24] Sync: ${SYNC} | Health: ${HEALTH}"
  [ "$SYNC" = "Synced" ] && [ "$HEALTH" = "Healthy" ] && break
  sleep 10
done

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo "  GitLab + ArgoCD ready!"
echo ""
echo "  GitLab URL  : ${GITLAB_EXTERNAL_URL}"
echo "  GitLab user : root"
echo "  GitLab pass : ${ROOT_PASSWORD}"
echo "  GitLab repo : ${GITLAB_EXTERNAL_URL}/root/${PROJECT_NAME}"
echo ""
echo "  To demo version update:"
echo "    1. Clone: git clone ${GITLAB_EXTERNAL_URL}/root/${PROJECT_NAME}.git"
echo "    2. Edit deployment.yaml: change v1 to v2"
echo "    3. git add . && git commit -m 'v2' && git push"
echo "    4. Watch ArgoCD sync automatically"
echo "════════════════════════════════════════════════════════"
