#!/usr/bin/env bash
# Check: the scout service account has no cluster-admin binding and no rights
# to read Secrets or change the cluster, and the shuttle service account has
# none either. Rejects deleting the service account or the Secret.
set -uo pipefail

fail=0

for name in scout shuttle; do
  if ! kubectl -n starfleet get serviceaccount "$name" >/dev/null 2>&1; then
    echo "FAIL: the $name service account was deleted; remove its grant instead"
    fail=1
  fi
done
if ! kubectl -n starfleet get secret fleet-credentials >/dev/null 2>&1; then
  echo "FAIL: the Secret fleet-credentials was deleted"
  fail=1
fi

expect_no() {
  local account="$1" description="$2"
  shift 2
  local answer
  answer="$(kubectl auth can-i "$@" --as="system:serviceaccount:starfleet:$account" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: $account is allowed to $description"
    fail=1
  fi
}

for name in scout shuttle; do
  expect_no "$name" "get Secrets in starfleet" get secrets -n starfleet
  expect_no "$name" "list Secrets in every namespace" list secrets --all-namespaces
  expect_no "$name" "create pods in starfleet" create pods -n starfleet
  expect_no "$name" "delete nodes" delete nodes
  expect_no "$name" "create ClusterRoleBindings" create clusterrolebindings
done

bound="$(kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '.items[]
  | select(.roleRef.name=="cluster-admin" or .roleRef.name=="admin" or .roleRef.name=="edit")
  | select(any(.subjects[]?; .kind=="ServiceAccount" and (.name=="scout" or .name=="shuttle")))
  | .kind + "/" + .metadata.name')"
if [ -n "$bound" ]; then
  echo "FAIL: a broad role is still bound to scout or shuttle by: $bound"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout and shuttle have no broad rights"
fi
exit "$fail"
