#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet patch deployment probe --type=json -p '[
  {"op": "replace", "path": "/spec/template/spec/containers/0/securityContext/privileged", "value": false}
]'
kubectl -n starfleet rollout status deployment/probe --timeout=180s

kubectl patch clusterpolicy disallow-privileged-containers --type=json -p '[
  {"op": "replace", "path": "/spec/rules/0/validate/failureAction", "value": "Enforce"}
]'

for name in scout probe shuttle; do
  kubectl -n starfleet label deployment "$name" owner=starfleet-ops --overwrite
done

kubectl apply -f "$DIR/solution.yaml"
echo "[solution] Applied."
