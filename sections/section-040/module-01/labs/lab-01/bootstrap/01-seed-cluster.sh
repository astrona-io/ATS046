#!/usr/bin/env bash
# Starting state for the findings lab. Environment only: the Starfleet workloads
# with their deliberate misconfigurations, the Trivy toolbox and an empty
# exception register. The learner fixes and records.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=240s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
kubectl -n tools rollout status deployment/trivy --timeout=300s
echo "[lab] Ready."
