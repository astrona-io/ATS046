#!/usr/bin/env bash
# Check: the evidence record. Scope, version of THIS cluster, a UTC time, the
# benchmark, the control plane failure count from the live kube-bench log and a
# PASS line for each of five controls. The state checks prove the PASS lines.
set -uo pipefail

fail=0
NS=orbit
NAME=assessment-evidence

if ! kubectl -n "$NS" get configmap "$NAME" >/dev/null 2>&1; then
  echo "FAIL: ConfigMap $NAME not found in $NS"
  exit 1
fi

read_key() {
  kubectl -n "$NS" get configmap "$NAME" -o json | jq -r --arg key "$1" '.data[$key] // ""'
}

if ! read_key scope | grep -q 'orbit'; then
  echo "FAIL: key 'scope' must name the orbit namespace"
  fail=1
fi

recorded_version="$(read_key kubernetes-version)"
live_version="$(kubectl version -o json | jq -r '.serverVersion.gitVersion')"
if [ "$recorded_version" != "$live_version" ]; then
  echo "FAIL: key 'kubernetes-version' is '$recorded_version', the cluster reports '$live_version'"
  fail=1
fi

if ! read_key observed-at | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
  echo "FAIL: key 'observed-at' must be a UTC time like 2026-11-03T10:15:00Z"
  fail=1
fi

if [ "$(read_key benchmark)" != "cis-2.0" ]; then
  echo "FAIL: key 'benchmark' must be cis-2.0"
  fail=1
fi

live_fail="$(kubectl -n audit logs job/kube-bench 2>/dev/null | sed -n '/^{/,$p' | jq -r '[.Controls[] | select(.node_type == "master") | .total_fail] | add // empty' 2>/dev/null || true)"
recorded_fail="$(read_key master-fail)"
if [ -z "$live_fail" ] || [ "$recorded_fail" != "$live_fail" ]; then
  echo "FAIL: key 'master-fail' is '$recorded_fail', the kube-bench log reports '$live_fail' failed master checks"
  fail=1
fi

for control in 5.1.1 5.1.6 5.2.1 5.2.2 5.2.3; do
  value="$(read_key "$control")"
  if ! echo "$value" | grep -q '^PASS'; then
    echo "FAIL: key '$control' must start with PASS and say what you observed"
    fail=1
  elif [ "${#value}" -lt 15 ]; then
    echo "FAIL: key '$control' needs a short sentence of evidence after PASS"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the evidence record is complete and matches the cluster and the kube-bench log"
fi
exit "$fail"
