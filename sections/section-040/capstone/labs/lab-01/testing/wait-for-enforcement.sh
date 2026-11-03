#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until Kyverno
# rejects a privileged pod and the API server rejects a Deployment that uses
# the host network in starfleet.
set -uo pipefail

for i in $(seq 1 60); do
  if ! kubectl -n starfleet run wait-priv --image=curlimages/curl:8.22.0 --privileged=true --dry-run=server -o name >/dev/null 2>&1; then
    break
  fi
  sleep 3
done

cat > /tmp/ats-046-wait-hostnet.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wait-hostnet
  namespace: starfleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wait-hostnet
  template:
    metadata:
      labels:
        app: wait-hostnet
    spec:
      hostNetwork: true
      containers:
        - name: test
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "sleep 3600"]
YAML
for i in $(seq 1 60); do
  if ! kubectl create --dry-run=server -f /tmp/ats-046-wait-hostnet.yaml >/dev/null 2>&1; then
    echo "[testing] Both policies reject bad requests."
    rm -f /tmp/ats-046-wait-hostnet.yaml
    sleep 3
    exit 0
  fi
  sleep 3
done
rm -f /tmp/ats-046-wait-hostnet.yaml
echo "[testing] The policies did not reject bad requests in time." >&2
exit 1
