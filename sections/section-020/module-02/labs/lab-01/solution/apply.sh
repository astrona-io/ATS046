#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
# The starting state was created with `kubectl apply`, so applying the new
# Deployment removes the fields that the new file no longer has: the hostPath
# volume and its mount.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet delete rolebinding shuttle-secret-reader
kubectl -n starfleet delete role shuttle-secret-reader
kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
echo "[solution] Applied."
