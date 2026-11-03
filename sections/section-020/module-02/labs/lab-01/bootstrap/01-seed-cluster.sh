#!/usr/bin/env bash
# Starting state for the attack path lab. Environment only: it creates the workloads
# and the faulty access setup. It does not create any Role, NetworkPolicy or
# securityContext that the learner must write.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/workloads.yaml"
kubectl apply -f "$DIR/manifests/access.yaml"

for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
