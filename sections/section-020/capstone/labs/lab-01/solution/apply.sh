#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
# The starting state was created with `kubectl apply`, so applying the new
# scout Deployment removes the hostPath volume and its mount.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl delete clusterrolebinding scout-admin
kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
echo "[solution] Applied."
