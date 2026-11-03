#!/usr/bin/env bash
# Check: the running beacon and relay pods have no service account token
# volume. Pods that are terminating are ignored.
set -uo pipefail

fail=0

for name in beacon relay; do
  pods="$(kubectl -n orbit get pods -l "app=$name" -o json)"
  running="$(echo "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
  if [ "$running" -lt 1 ]; then
    echo "FAIL: no running pod found for $name"
    fail=1
    continue
  fi
  mounted="$(echo "$pods" | jq -r '
    .items[]
    | select(.metadata.deletionTimestamp == null)
    | select(any(.spec.volumes[]?; .name | startswith("kube-api-access")))
    | .metadata.name')"
  if [ -n "$mounted" ]; then
    echo "FAIL: pod $mounted still mounts a service account token"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no running beacon or relay pod mounts a service account token"
fi
exit "$fail"
