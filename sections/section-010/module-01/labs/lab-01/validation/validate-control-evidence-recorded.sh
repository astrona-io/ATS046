#!/usr/bin/env bash
# Check: the evidence record. The ConfigMap must name the scope, carry the
# Kubernetes version of THIS cluster, a timestamp and a PASS line for each
# control. The cluster state checks prove that the PASS lines are true.
set -uo pipefail

fail=0
NS=starfleet
NAME=control-evidence

if ! kubectl -n "$NS" get configmap "$NAME" >/dev/null 2>&1; then
  echo "FAIL: ConfigMap $NAME not found in $NS"
  exit 1
fi

read_key() {
  kubectl -n "$NS" get configmap "$NAME" -o json | jq -r --arg key "$1" '.data[$key] // ""'
}

scope="$(read_key scope)"
if ! echo "$scope" | grep -q 'starfleet'; then
  echo "FAIL: key 'scope' must name the starfleet namespace"
  fail=1
fi

recorded_version="$(read_key kubernetes-version)"
live_version="$(kubectl version -o json | jq -r '.serverVersion.gitVersion')"
if [ "$recorded_version" != "$live_version" ]; then
  echo "FAIL: key 'kubernetes-version' is '$recorded_version', the cluster reports '$live_version'"
  fail=1
fi

observed="$(read_key observed-at)"
if ! echo "$observed" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
  echo "FAIL: key 'observed-at' must be a UTC time like 2026-11-03T10:15:00Z"
  fail=1
fi

for control in 5.1.1 5.1.6 5.2.2; do
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
  echo "PASS: the evidence record names the scope, the cluster version, the time and the three controls"
fi
exit "$fail"
