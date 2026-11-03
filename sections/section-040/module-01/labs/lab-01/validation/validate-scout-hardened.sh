#!/usr/bin/env bash
# Check: every running scout pod meets the hardened settings, and the
# Deployment is available. The check reads the pods, so a template that was
# changed but not rolled out fails.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null)"
live_pods="$(printf '%s' "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
if [ "$live_pods" -lt 1 ]; then
  echo "FAIL: no scout pod exists"
  exit 1
fi

# For each container, the container value wins over the pod value.
bad="$(printf '%s' "$pods" | jq -r '
  .items[] | select(.metadata.deletionTimestamp == null) | .metadata.name as $pod | .spec.securityContext as $ps
  | .spec.containers[]
  | . as $c
  | ((($c.securityContext.runAsNonRoot) // ($ps.runAsNonRoot)) == true) as $nonroot
  | ((($c.securityContext.runAsUser) // ($ps.runAsUser)) as $uid | ($uid | type) == "number" and $uid != 0) as $numeric
  | (((($c.securityContext.seccompProfile.type) // ($ps.seccompProfile.type)) == "RuntimeDefault")) as $seccomp
  | (($c.securityContext.allowPrivilegeEscalation) == false) as $noescalation
  | ((($c.securityContext.capabilities.drop // []) | index("ALL")) != null) as $dropall
  | select(($nonroot and $numeric and $seccomp and $noescalation and $dropall) | not)
  | "\($pod)/\($c.name): runAsNonRoot=\($nonroot) numericUser=\($numeric) seccomp=\($seccomp) noEscalation=\($noescalation) dropAll=\($dropall)"
' 2>/dev/null)"
if [ -n "$bad" ]; then
  echo "FAIL: a scout pod does not meet the hardened settings:"
  echo "$bad"
  exit 1
fi

desired="$(kubectl -n starfleet get deployment scout -o jsonpath='{.spec.replicas}' 2>/dev/null)"
available="$(kubectl -n starfleet get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "${available:-0}" != "$desired" ]; then
  echo "FAIL: scout has ${available:-0} of ${desired} replicas available"
  exit 1
fi

echo "PASS: scout pods run hardened and are available"
