#!/usr/bin/env bash
# Check: the three starfleet Deployments carry a non-empty owner label on the
# Deployment itself, and every replica is available.
set -uo pipefail

fail=0
for name in scout probe shuttle; do
  owner="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.metadata.labels.owner}' 2>/dev/null || true)"
  if [ -z "$owner" ]; then
    echo "FAIL: the Deployment $name has no owner label"
    fail=1
    continue
  fi
  desired="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  available="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [ "${available:-0}" != "$desired" ]; then
    echo "FAIL: $name has ${available:-0} of ${desired} replicas available"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout, probe and shuttle carry an owner label and are available"
fi
exit "$fail"
