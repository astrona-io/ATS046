#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"

# Controls 5.1.1 and 5.1.6: no cluster-admin for beacon-ci, no token mounts.
kubectl delete clusterrolebinding orbit-beacon-ci-admin
for name in beacon relay; do
  kubectl -n orbit patch deployment "$name" --type=merge \
    -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
done
# Controls 5.2.2 and 5.2.3: not privileged, no shared process namespace.
kubectl -n orbit patch deployment beacon --type=json -p '[
  {"op":"remove","path":"/spec/template/spec/hostPID"},
  {"op":"remove","path":"/spec/template/spec/containers/0/securityContext/privileged"}]'
for name in beacon relay; do
  kubectl -n orbit rollout status "deployment/$name" --timeout=180s
done

# Control 5.2.1: an active policy control mechanism.
kubectl label --overwrite namespace orbit pod-security.kubernetes.io/enforce=baseline

kubectl -n audit wait --for=condition=complete job/kube-bench --timeout=300s
master_fail="$(kubectl -n audit logs job/kube-bench | sed -n '/^{/,$p' | jq -r '[.Controls[] | select(.node_type == "master") | .total_fail] | add')"
version="$(kubectl version -o json | jq -r '.serverVersion.gitVersion')"
observed="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

kubectl -n orbit create configmap assessment-evidence \
  --from-literal=scope="namespace orbit; workloads beacon and relay; control plane by kube-bench" \
  --from-literal=kubernetes-version="$version" \
  --from-literal=observed-at="$observed" \
  --from-literal=benchmark="cis-2.0" \
  --from-literal=master-fail="$master_fail" \
  --from-literal=5.1.1="PASS: beacon-ci has no binding to cluster-admin" \
  --from-literal=5.1.6="PASS: beacon and relay pods have no token volume" \
  --from-literal=5.2.1="PASS: orbit enforces the baseline Pod Security level" \
  --from-literal=5.2.2="PASS: no pod in orbit has a privileged container" \
  --from-literal=5.2.3="PASS: no pod in orbit shares the host process namespace"
echo "[solution] Applied."
