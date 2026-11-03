#!/usr/bin/env bash
# Check: the running shuttle pods have no service account token. Reads the
# live pods, so a change that did not roll out fails. Setting the field on the
# service account instead of the pod also passes, because the pod inherits it.
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

has_token_volume="$(echo "$pods" | jq -r 'any(.[]; any(.spec.volumes[]?; (.projected.sources // []) | any(.serviceAccountToken != null)))')"
if [ "$has_token_volume" = "true" ]; then
  echo "FAIL: a shuttle pod still has a projected service account token volume"
  fail=1
fi

has_mount="$(echo "$pods" | jq -r 'any(.[]; any(.spec.containers[]; any(.volumeMounts[]?; .mountPath == "/var/run/secrets/kubernetes.io/serviceaccount")))')"
if [ "$has_mount" = "true" ]; then
  echo "FAIL: a shuttle container still mounts /var/run/secrets/kubernetes.io/serviceaccount"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the shuttle pods have no service account token"
fi
exit "$fail"
