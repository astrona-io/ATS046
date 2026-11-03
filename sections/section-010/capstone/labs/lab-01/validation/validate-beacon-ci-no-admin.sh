#!/usr/bin/env bash
# Check: beacon-ci has no cluster-admin binding, keeps its service account and
# has no effective permissions. Rejects replacing cluster-admin with edit/admin.
set -uo pipefail

SA="system:serviceaccount:orbit:beacon-ci"
fail=0

remaining="$(kubectl get clusterrolebindings,rolebindings -A -o json | jq -r '
  .items[]
  | select(.roleRef.name == "cluster-admin")
  | select(any(.subjects[]?; .kind == "ServiceAccount" and .name == "beacon-ci" and .namespace == "orbit"))
  | .kind + "/" + .metadata.name')"
if [ -n "$remaining" ]; then
  echo "FAIL: beacon-ci is still bound to cluster-admin by: $remaining"
  fail=1
fi

if ! kubectl -n orbit get serviceaccount beacon-ci >/dev/null 2>&1; then
  echo "FAIL: the beacon-ci service account was deleted; remove the binding and keep the account"
  fail=1
fi

for args in "* * -n orbit" "get secrets -n orbit" "create deployments.apps -n orbit" "get secrets --all-namespaces"; do
  # shellcheck disable=SC2086
  answer="$(kubectl auth can-i $args --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: beacon-ci is allowed to: $args"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: beacon-ci has no cluster-admin binding and no permissions"
fi
exit "$fail"
