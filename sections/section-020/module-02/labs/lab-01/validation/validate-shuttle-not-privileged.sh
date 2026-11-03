#!/usr/bin/env bash
# Check: the running shuttle pods are not privileged, mount no hostPath volume,
# do not share the host namespaces, run as non-root, drop ALL capabilities and
# block privilege escalation, and they are Ready.
set -uo pipefail

if ! kubectl -n starfleet rollout status deployment/shuttle --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the shuttle Deployment is not available"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=shuttle -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null)]')"
if [ "$(echo "$pods" | jq 'length')" -lt 1 ]; then
  echo "FAIL: no shuttle pod is running"
  exit 1
fi

fail=0

# check_pods <description> <jq condition that must be true for every pod>
check_pods() {
  local ok
  ok="$(echo "$pods" | jq -r "all(.[]; $2)")"
  if [ "$ok" != "true" ]; then
    echo "FAIL: $1"
    fail=1
  fi
}

# check_containers <description> <jq condition that must be true for every container>
check_containers() {
  local ok
  ok="$(echo "$pods" | jq -r "all(.[]; . as \$pod | all(\$pod.spec.containers[]; $2))")"
  if [ "$ok" != "true" ]; then
    echo "FAIL: $1"
    fail=1
  fi
}

check_pods "a shuttle pod mounts a hostPath volume" '(all(.spec.volumes[]?; .hostPath == null))'
check_pods "a shuttle pod uses the host network, PID or IPC namespace" '(((.spec.hostNetwork // false) or (.spec.hostPID // false) or (.spec.hostIPC // false)) | not)'
check_containers "a shuttle container is privileged" '((.securityContext.privileged // false) == false)'
check_containers "a shuttle container can gain more privileges (allowPrivilegeEscalation must be false)" '(.securityContext.allowPrivilegeEscalation == false)'
check_containers "a shuttle container does not drop ALL capabilities" '(((.securityContext.capabilities.drop // []) | index("ALL")) != null)'
check_containers "a shuttle container may run as root (runAsNonRoot must be true)" '(($pod.spec.securityContext.runAsNonRoot // false) or (.securityContext.runAsNonRoot // false))'
check_containers "a shuttle container runs as user 0" '(((.securityContext.runAsUser // $pod.spec.securityContext.runAsUser // 1) != 0))'
check_pods "a shuttle pod is not Ready" '(any(.status.conditions[]?; .type=="Ready" and .status=="True"))'

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle runs unprivileged, as non-root, without host access"
fi
exit "$fail"
