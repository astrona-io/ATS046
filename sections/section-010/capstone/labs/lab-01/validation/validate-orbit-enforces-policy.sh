#!/usr/bin/env bash
# Check: orbit enforces the baseline or restricted Pod Security level, and the
# API server proves it: a privileged pod and a hostPID pod are both rejected,
# a plain pod is accepted. All are server-side dry runs.
set -uo pipefail

fail=0

level="$(kubectl get namespace orbit -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
case "$level" in
  baseline|restricted) ;;
  *) echo "FAIL: orbit has enforce level '$level', expected baseline or restricted"; fail=1 ;;
esac

try_pod() {
  # $1 = pod name, $2 = extra pod spec lines, $3 = extra container lines
  kubectl apply --dry-run=server -f - 2>&1 <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $1
  namespace: orbit
spec:
$2
  containers:
    - name: check
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
$3
YAML
}

output="$(try_pod grader-privileged "  automountServiceAccountToken: false" "      securityContext:
        privileged: true")"
status=$?
if [ "$status" -eq 0 ] || ! echo "$output" | grep -q 'violates PodSecurity'; then
  echo "FAIL: the API server did not reject a privileged pod in orbit with a PodSecurity error"
  fail=1
fi

output="$(try_pod grader-hostpid "  hostPID: true" "")"
status=$?
if [ "$status" -eq 0 ] || ! echo "$output" | grep -q 'violates PodSecurity'; then
  echo "FAIL: the API server did not reject a hostPID pod in orbit with a PodSecurity error"
  fail=1
fi

output="$(try_pod grader-plain "  automountServiceAccountToken: false" "")"
status=$?
if [ "$status" -ne 0 ] && [ "$level" = "baseline" ]; then
  echo "FAIL: the API server rejected a plain pod at the baseline level: $output"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: orbit enforces $level; privileged and hostPID pods are rejected"
fi
exit "$fail"
