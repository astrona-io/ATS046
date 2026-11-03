#!/usr/bin/env bash
# Check: the running scout and shuttle pods have no service account token.
# Neither workload calls the Kubernetes API. Reads the live pods, so a change
# that did not roll out fails.
set -uo pipefail

fail=0

for name in scout shuttle; do
  if ! kubectl -n starfleet rollout status "deployment/$name" --timeout=120s >/dev/null 2>&1; then
    echo "FAIL: the $name Deployment is not available"
    fail=1
    continue
  fi
  pods="$(kubectl -n starfleet get pods -l "app=$name" -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null)]')"
  if [ "$(echo "$pods" | jq 'length')" -lt 1 ]; then
    echo "FAIL: no $name pod is running"
    fail=1
    continue
  fi
  has_volume="$(echo "$pods" | jq -r 'any(.[]; any(.spec.volumes[]?; (.projected.sources // []) | any(.serviceAccountToken != null)))')"
  has_mount="$(echo "$pods" | jq -r 'any(.[]; any(.spec.containers[]; any(.volumeMounts[]?; .mountPath == "/var/run/secrets/kubernetes.io/serviceaccount")))')"
  if [ "$has_volume" = "true" ] || [ "$has_mount" = "true" ]; then
    echo "FAIL: a $name pod still has a service account token"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout and shuttle have no service account token"
fi
exit "$fail"
