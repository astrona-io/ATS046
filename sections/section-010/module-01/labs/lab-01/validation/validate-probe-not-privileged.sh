#!/usr/bin/env bash
# Check: no pod in starfleet has a privileged container, in any container list.
set -uo pipefail

fail=0

privileged="$(kubectl -n starfleet get pods -o json | jq -r '
  .items[]
  | select(.metadata.deletionTimestamp == null)
  | select(any((.spec.containers[]?, .spec.initContainers[]?); .securityContext.privileged == true))
  | .metadata.name')"
if [ -n "$privileged" ]; then
  echo "FAIL: privileged pods remain in starfleet: $privileged"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: no pod in starfleet has a privileged container"
fi
exit "$fail"
