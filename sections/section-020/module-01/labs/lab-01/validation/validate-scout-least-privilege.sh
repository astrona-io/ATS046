#!/usr/bin/env bash
# Check: the scout service account can read its own ConfigMap and nothing
# else. Rejects the plausible wrong fixes: keeping edit, binding admin or
# cluster-admin, a wildcard Role, a ClusterRoleBinding, deleting the account.
set -uo pipefail

SA="system:serviceaccount:starfleet:scout"
fail=0

if ! kubectl -n starfleet get serviceaccount scout >/dev/null 2>&1; then
  echo "FAIL: the scout service account was deleted; remove its grant instead"
  fail=1
fi

expect_answer() {
  local expected="$1" description="$2"
  shift 2
  local answer
  answer="$(kubectl auth can-i "$@" --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "$expected" ]; then
    echo "FAIL: scout answer for '$description' is '${answer:-none}', expected '$expected'"
    fail=1
  fi
}

expect_answer yes "get the scout-config ConfigMap" get configmaps/scout-config -n starfleet
expect_answer no "get Secrets in starfleet" get secrets -n starfleet
expect_answer no "list Secrets in starfleet" list secrets -n starfleet
expect_answer no "patch Deployments in starfleet" patch deployments.apps -n starfleet
expect_answer no "create pods in starfleet" create pods -n starfleet
expect_answer no "delete pods in starfleet" delete pods -n starfleet
expect_answer no "do anything in starfleet" '*' '*' -n starfleet
expect_answer no "get ConfigMaps in outpost" get configmaps -n outpost
expect_answer no "delete nodes" delete nodes

bound="$(kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '.items[]
  | select(.roleRef.name=="edit" or .roleRef.name=="admin" or .roleRef.name=="cluster-admin")
  | select(any(.subjects[]?; .kind=="ServiceAccount" and .name=="scout"))
  | .kind + "/" + .metadata.name')"
if [ -n "$bound" ]; then
  echo "FAIL: scout is still bound to a broad role by: $bound"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout can read scout-config and nothing else"
fi
exit "$fail"
