#!/usr/bin/env bash
# Check: probe runs no privileged container, in the Deployment template and in
# every running pod, and the Deployment is available. Rejects the plausible
# wrong fix of editing the template without the pods being replaced.
set -uo pipefail

template="$(kubectl -n starfleet get deployment probe -o json 2>/dev/null)"
if [ -z "$template" ]; then
  echo "FAIL: the Deployment probe does not exist in starfleet. Fix it, do not delete it."
  exit 1
fi

privileged_in_template="$(printf '%s' "$template" | jq '[.spec.template.spec.containers[]? , .spec.template.spec.initContainers[]?] | map(select(.securityContext.privileged == true)) | length')"
if [ "$privileged_in_template" != "0" ]; then
  echo "FAIL: the probe Deployment template still sets privileged: true"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=probe -o json 2>/dev/null)"
live_pods="$(printf '%s' "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
if [ "$live_pods" -lt 1 ]; then
  echo "FAIL: no running probe pod exists"
  exit 1
fi
privileged_pods="$(printf '%s' "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp == null) | .spec.containers[] | select(.securityContext.privileged == true)] | length')"
if [ "$privileged_pods" != "0" ]; then
  echo "FAIL: a probe pod still runs a privileged container. Wait for the rollout to finish."
  exit 1
fi

desired="$(printf '%s' "$template" | jq '.spec.replicas')"
available="$(printf '%s' "$template" | jq '.status.availableReplicas // 0')"
if [ "$available" != "$desired" ]; then
  echo "FAIL: probe has ${available} of ${desired} replicas available"
  exit 1
fi

echo "PASS: probe has no privileged container and is available"
