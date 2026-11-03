#!/usr/bin/env bash
# Check: the shuttle service account cannot use the API to read Secrets or
# anything else useful to an attacker who stole its token. Rejects the
# plausible wrong fixes: deleting only the Role, moving the grant to a
# ClusterRoleBinding, binding view or edit, or deleting the service account.
set -uo pipefail

SA="system:serviceaccount:starfleet:shuttle"
fail=0

if ! kubectl -n starfleet get serviceaccount shuttle >/dev/null 2>&1; then
  echo "FAIL: the shuttle service account was deleted; remove its grant instead"
  fail=1
fi
if ! kubectl -n starfleet get secret fleet-credentials >/dev/null 2>&1; then
  echo "FAIL: the Secret fleet-credentials was deleted; remove the access to it instead"
  fail=1
fi

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

expect_no "get Secrets in starfleet" get secrets -n starfleet
expect_no "list Secrets in starfleet" list secrets -n starfleet
expect_no "list Secrets in every namespace" list secrets --all-namespaces
expect_no "list pods in starfleet" list pods -n starfleet
expect_no "create pods in starfleet" create pods -n starfleet
expect_no "do anything in starfleet" '*' '*' -n starfleet

bound="$(kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '.items[]
  | select(any(.subjects[]?; .kind=="ServiceAccount" and .name=="shuttle" and (.namespace // "starfleet")=="starfleet"))
  | .kind + "/" + .metadata.name')"
if [ -n "$bound" ]; then
  echo "FAIL: shuttle still has bindings: $bound"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the shuttle service account cannot read Secrets or use the API"
fi
exit "$fail"
