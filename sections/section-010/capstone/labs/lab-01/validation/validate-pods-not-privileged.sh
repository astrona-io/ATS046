#!/usr/bin/env bash
# Check: no running pod in orbit is privileged or shares a host namespace.
# Reads the pods, not the Deployments, so an unfinished rollout fails.
set -uo pipefail

fail=0

offenders="$(kubectl -n orbit get pods -o json | jq -r '
  .items[]
  | select(.metadata.deletionTimestamp == null)
  | select(
      .spec.hostPID == true or .spec.hostIPC == true or .spec.hostNetwork == true
      or any((.spec.containers[]?, .spec.initContainers[]?); .securityContext.privileged == true))
  | .metadata.name')"
if [ -n "$offenders" ]; then
  echo "FAIL: pods in orbit still privileged or sharing a host namespace: $offenders"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: no pod in orbit is privileged or shares the host process, IPC or network namespace"
fi
exit "$fail"
