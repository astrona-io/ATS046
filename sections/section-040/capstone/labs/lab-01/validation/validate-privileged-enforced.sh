#!/usr/bin/env bash
# Check: a Kyverno policy rejects a privileged pod and a privileged Deployment
# in starfleet, accepts a clean pod there, and does not cover outpost. The
# grader uses --dry-run=server, so nothing is stored. The rejection must come
# from Kyverno.
set -uo pipefail

fail=0

pod_manifest() {
  cat <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $1
  labels:
    app: grader
spec:
  containers:
    - name: test
      image: curlimages/curl:8.22.0
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        privileged: $2
YAML
}

deployment_manifest() {
  cat <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grader-privileged
  labels:
    app: grader-privileged
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grader-privileged
  template:
    metadata:
      labels:
        app: grader-privileged
    spec:
      containers:
        - name: test
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "sleep 3600"]
          securityContext:
            privileged: true
YAML
}

server_create() {
  kubectl create -n "$1" --dry-run=server -o name -f - 2>&1
}

# expect_rejected <description> <namespace> <manifest>
# Retries for about 45 seconds, because Kyverno needs a few seconds to use a
# new policy.
expect_rejected() {
  local description="$1" namespace="$2" manifest="$3" out=""
  for _ in $(seq 1 15); do
    if ! out="$(printf '%s' "$manifest" | server_create "$namespace")"; then
      if printf '%s' "$out" | grep -qi 'kyverno'; then
        return 0
      fi
      echo "FAIL: $description was rejected, but not by Kyverno: $(printf '%s' "$out" | tail -2)"
      fail=1
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was accepted, but it must be rejected (is the policy in Enforce mode?)"
  fail=1
}

expect_accepted() {
  local description="$1" namespace="$2" manifest="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(printf '%s' "$manifest" | server_create "$namespace")"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf '%s' "$out" | tail -2)"
  fail=1
}

expect_rejected "a privileged pod in starfleet" starfleet "$(pod_manifest grader-priv true)"
expect_rejected "a privileged Deployment in starfleet" starfleet "$(deployment_manifest)"
expect_accepted "a non-privileged pod in starfleet" starfleet "$(pod_manifest grader-clean false)"
expect_accepted "a privileged pod in outpost (the policy covers starfleet only)" outpost "$(pod_manifest grader-outpost true)"

if [ "$fail" -eq 0 ]; then
  echo "PASS: Kyverno rejects privileged pods and Deployments in starfleet only"
fi
exit "$fail"
