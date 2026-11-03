#!/usr/bin/env bash
# Starting state for the capstone. Environment only: it creates the `orbit`
# and `audit` namespaces, the workloads and the failing controls. It creates
# no Job, no evidence and no fix.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in beacon relay; do
  kubectl -n orbit rollout status "deployment/$name" --timeout=180s
done
echo "[lab] Ready."
