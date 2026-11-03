#!/usr/bin/env bash
# Check: the running probe pods are not privileged, do not run as root, drop
# all capabilities and block privilege escalation, and the workload is still
# available. Reads the live pods, not the Deployment, so a change that did not
# roll out fails.
set -uo pipefail

fail=0

if ! kubectl -n starfleet rollout status deployment/probe --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the probe Deployment is not available"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=probe -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null)]')"
count="$(echo "$pods" | jq 'length')"
if [ "$count" -lt 1 ]; then
  echo "FAIL: no probe pod is running"
  exit 1
fi

# check_all <description> <jq condition that must be true for every container>
check_all() {
  local ok
  ok="$(echo "$pods" | jq -r "all(.[]; . as \$pod | all(\$pod.spec.containers[]; $2))")"
  if [ "$ok" != "true" ]; then
    echo "FAIL: $1"
    fail=1
  fi
}

check_all "a probe container is privileged" '((.securityContext.privileged // false) == false)'
check_all "a probe container can gain more privileges (allowPrivilegeEscalation must be false)" '(.securityContext.allowPrivilegeEscalation == false)'
check_all "a probe container does not drop ALL capabilities" '(((.securityContext.capabilities.drop // []) | index("ALL")) != null)'
check_all "a probe container may run as root (runAsNonRoot must be true)" '(($pod.spec.securityContext.runAsNonRoot // false) or (.securityContext.runAsNonRoot // false))'
check_all "a probe container runs as user 0" '(((.securityContext.runAsUser // $pod.spec.securityContext.runAsUser // 1) != 0))'

ready="$(echo "$pods" | jq -r 'all(.[]; any(.status.conditions[]?; .type=="Ready" and .status=="True"))')"
if [ "$ready" != "true" ]; then
  echo "FAIL: a probe pod is not Ready"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: probe runs unprivileged, as non-root, and is Ready"
fi
exit "$fail"
