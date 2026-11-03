#!/usr/bin/env bash
# Check: the ValidatingAdmissionPolicy require-owner-label rejects a Deployment
# without an owner label in starfleet (Deny, not Warn), accepts one with the
# label, and does not apply in outpost. The grader uses --dry-run=server.
set -uo pipefail

fail=0

deployment_manifest() {
  # deployment_manifest <name> <labels block, indented 4 spaces>
  cat <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $1
  labels:
    app: $1
$2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $1
  template:
    metadata:
      labels:
        app: $1
    spec:
      containers:
        - name: test
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "sleep 3600"]
YAML
}

server_create() {
  kubectl create -n "$1" --dry-run=server -o name -f - 2>&1
}

if ! kubectl get validatingadmissionpolicy require-owner-label >/dev/null 2>&1; then
  echo "FAIL: the ValidatingAdmissionPolicy require-owner-label does not exist"
  exit 1
fi

rejected=0
out=""
for _ in $(seq 1 15); do
  if ! out="$(deployment_manifest grader-nolabel "" | server_create starfleet)"; then
    rejected=1
    break
  fi
  sleep 3
done
if [ "$rejected" -ne 1 ]; then
  echo "FAIL: a Deployment without an owner label was accepted in starfleet (is validationActions Deny?)"
  fail=1
elif ! printf '%s' "$out" | grep -q 'require-owner-label'; then
  echo "FAIL: the rejection does not come from require-owner-label: $(printf '%s' "$out" | tail -2)"
  fail=1
fi

if ! out="$(deployment_manifest grader-label "    owner: grader" | server_create starfleet)"; then
  echo "FAIL: a Deployment with an owner label was rejected in starfleet: $(printf '%s' "$out" | tail -2)"
  fail=1
fi

if ! out="$(deployment_manifest grader-outpost "" | server_create outpost)"; then
  echo "FAIL: a Deployment without an owner label was rejected in outpost, but the binding must cover starfleet only: $(printf '%s' "$out" | tail -2)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: require-owner-label denies unlabelled Deployments in starfleet only"
fi
exit "$fail"
