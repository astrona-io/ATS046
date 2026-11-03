#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# policy is Ready and Kyverno enforces it on an unsigned image.
set -uo pipefail

for _ in $(seq 1 60); do
  ready="$(kubectl get clusterpolicy require-signed-images -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ "$ready" = "True" ] && break
  sleep 3
done
for _ in $(seq 1 60); do
  if ! kubectl -n outpost run wait-probe --image=registry.supply-chain.svc.cluster.local:5000/outpost/drifter:2.25.0 --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] Kyverno enforces the policy."
    sleep 5
    exit 0
  fi
  sleep 3
done
echo "[testing] Kyverno did not enforce the policy in time." >&2
exit 1
