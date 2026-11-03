#!/usr/bin/env bash
# Check: the Starfleet application still works. scout and probe Deployments
# are available with at least one replica, scout answers shuttle, and the
# ConfigMap and the Secret were not deleted to "fix" a threat.
set -uo pipefail

fail=0

for name in scout probe shuttle; do
  replicas="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 0)"
  ready="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"
  if [ "${replicas:-0}" -lt 1 ] || [ "${ready:-0}" -lt 1 ]; then
    echo "FAIL: deployment $name has replicas=${replicas:-0} ready=${ready:-0}"
    fail=1
  fi
done

for resource in configmap/scout-config secret/fleet-credentials; do
  if ! kubectl -n starfleet get "$resource" >/dev/null 2>&1; then
    echo "FAIL: $resource was deleted"
    fail=1
  fi
done

got=""
for _ in $(seq 1 10); do
  got="$(kubectl -n starfleet exec deploy/shuttle -c shuttle -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 4 http://scout.starfleet.svc/ 2>/dev/null || true)"
  [ "$got" = "200" ] && break
  sleep 3
done
if [ "$got" != "200" ]; then
  echo "FAIL: shuttle cannot reach scout, got ${got:-no answer}"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout, probe and shuttle are available and shuttle reaches scout"
fi
exit "$fail"
