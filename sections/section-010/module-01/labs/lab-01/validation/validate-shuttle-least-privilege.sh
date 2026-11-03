#!/usr/bin/env bash
# Check: effective permissions. The shuttle needs no Kubernetes API access, so
# every plausible wrong fix is rejected: admin, edit, view, a wildcard Role.
set -uo pipefail

SA="system:serviceaccount:starfleet:shuttle"
fail=0

expect_no() {
  local description="$1"
  shift
  local answer
  answer="$(kubectl auth can-i "$@" --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: shuttle is allowed to $description"
    fail=1
  fi
}

expect_no "do anything in starfleet" '*' '*' -n starfleet
expect_no "read secrets in starfleet" get secrets -n starfleet
expect_no "list pods in starfleet" list pods -n starfleet
expect_no "create deployments in starfleet" create deployments.apps -n starfleet
expect_no "read secrets in every namespace" get secrets --all-namespaces
expect_no "delete nodes" delete nodes

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle has no Kubernetes API permissions"
fi
exit "$fail"
