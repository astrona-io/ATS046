#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n compliance wait --for=condition=complete job/kube-bench --timeout=300s

kubectl -n compliance logs job/kube-bench | sed -n '/^{/,$p' > /tmp/ats046-kube-bench-report.json

jq '[.Controls[] | {
      id, version, node_type, total_pass, total_fail, total_warn, total_info,
      failed: ([.tests[]?.results[]? | select(.status == "FAIL") | .test_number] | sort)
    }]' /tmp/ats046-kube-bench-report.json > /tmp/ats046-kube-bench-summary.json
kubectl -n compliance create configmap kube-bench-summary --from-file=summary.json=/tmp/ats046-kube-bench-summary.json

first_failed="$(jq -r '[.Controls[].tests[]?.results[]? | select(.status == "FAIL") | .test_number][0]' /tmp/ats046-kube-bench-report.json)"
kubectl -n compliance create configmap kube-bench-exceptions \
  --from-literal="${first_failed}=Accepted for this assessment: needs a change to the control plane static pod, which is outside the namespace owner scope."
echo "[solution] Applied."
