#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet delete rolebinding scout-edit
kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[solution] Applied."
