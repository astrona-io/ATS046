#!/usr/bin/env bash
# Check: a ValidatingAdmissionPolicy rejects a Deployment that sets hostNetwork
# in starfleet, accepts a normal Deployment there, and does not cover outpost.
# The grader uses --dry-run=server. The rejection must come from a
# ValidatingAdmissionPolicy and not from Kyverno.
set -uo pipefail

fail=0

deployment_manifest() {
  # deployment_manifest <name> <hostNetwork true|false>
  cat <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $1
  labels:
    app: $1
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
      hostNetwork: $2
      containers:
        - name: test
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "sleep 3600"]
YAML
}

server_create() {
  kubectl create -n "$1" --dry-run=server -o name -f - 2>&1
}

rejected=0
out=""
for _ in $(seq 1 15); do
  if ! out="$(deployment_manifest grader-hostnet true | server_create starfleet)"; then
    rejected=1
    break
  fi
  sleep 3
done
if [ "$rejected" -ne 1 ]; then
  echo "FAIL: a Deployment with hostNetwork: true was accepted in starfleet (is the binding action Deny?)"
  fail=1
elif ! printf '%s' "$out" | grep -q 'ValidatingAdmissionPolicy'; then
  echo "FAIL: the rejection does not come from a ValidatingAdmissionPolicy: $(printf '%s' "$out" | tail -2)"
  fail=1
fi

if ! out="$(deployment_manifest grader-plain false | server_create starfleet)"; then
  echo "FAIL: a normal Deployment was rejected in starfleet: $(printf '%s' "$out" | tail -2)"
  fail=1
fi

if ! out="$(deployment_manifest grader-outpost true | server_create outpost)"; then
  echo "FAIL: a Deployment with hostNetwork was rejected in outpost, but the rule must cover starfleet only: $(printf '%s' "$out" | tail -2)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: a ValidatingAdmissionPolicy denies hostNetwork Deployments in starfleet only"
fi
exit "$fail"
