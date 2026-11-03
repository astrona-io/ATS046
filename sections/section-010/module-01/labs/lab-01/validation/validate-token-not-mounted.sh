#!/usr/bin/env bash
# Check: running pods. The pods that exist now (not the Deployment text) have
# no service account token volume for scout and probe. Pods that are still
# terminating are ignored, so the check needs the rollout to be finished.
set -uo pipefail

fail=0

for name in scout probe; do
  pods="$(kubectl -n starfleet get pods -l "app=$name" -o json)"
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
    echo "FAIL: pod $mounted still mounts a service account token; roll out the change"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no running scout or probe pod mounts a service account token"
fi
exit "$fail"
