#!/usr/bin/env bash
# Check: the Kyverno policy reports in starfleet hold results for the policy and
# none fail for a Pod or a Deployment. Old ReplicaSets keep their old
# template and can still report a failure, so only pods and Deployments count.
set -uo pipefail

for _ in $(seq 1 20); do
  reports="$(kubectl -n starfleet get policyreport -o json 2>/dev/null)"
  total="$(printf '%s' "$reports" | jq '[.items[] | .results[]? | select(.policy == "disallow-privileged-containers")] | length' 2>/dev/null)"
  failing="$(printf '%s' "$reports" | jq '[.items[] | select(.scope.kind == "Pod" or .scope.kind == "Deployment") | .results[]? | select(.policy == "disallow-privileged-containers" and .result == "fail")] | length' 2>/dev/null)"
  if [ "${total:-0}" -gt 0 ] && [ "${failing:-1}" = "0" ]; then
    echo "PASS: the policy report shows no failed pod or Deployment for disallow-privileged-containers"
    exit 0
  fi
  sleep 3
done

if [ "${total:-0}" -eq 0 ]; then
  echo "FAIL: the policy reports in starfleet hold no result for disallow-privileged-containers. Keep the policy; do not delete it."
else
  echo "FAIL: ${failing} pod or Deployment results still fail for disallow-privileged-containers"
fi
exit 1
