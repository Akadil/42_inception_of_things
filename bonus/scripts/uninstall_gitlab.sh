#!/bin/bash
set -euo pipefail

echo "[+] Uninstalling GitLab helm release..."
helm uninstall gitlab -n gitlab 2>/dev/null || echo "[!] No helm release found, skipping."

echo "[+] Deleting gitlab namespace (this removes all PVCs and secrets)..."
kubectl delete namespace gitlab --timeout=120s 2>/dev/null || echo "[!] Namespace already gone."

echo "[+] Removing gitlab entry from /etc/hosts..."
sudo sed -i '/gitlab/d' /etc/hosts

echo "[✓] GitLab fully removed. Ready for fresh install."
