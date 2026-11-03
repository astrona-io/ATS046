#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fix the finding on probe.
kubectl -n starfleet patch deployment probe --type=json -p '[
  {"op": "replace", "path": "/spec/template/spec/containers/0/securityContext/privileged", "value": false}
]'

# Repair the drift on scout: remove the hand-made hostNetwork setting.
kubectl -n starfleet patch deployment scout --type=json -p '[
  {"op": "remove", "path": "/spec/template/spec/hostNetwork"}
]'

for name in scout probe; do
  kubectl -n starfleet rollout status "deployment/${name}" --timeout=180s
done

# Prevent the findings from returning: Kyverno for privileged containers, a
# ValidatingAdmissionPolicy for the host network.
kubectl apply -f "$DIR/policies.yaml"

# Accept the shuttle finding with a dated, scoped exception.
expiry="$(date -u -d '+60 days' +%Y-%m-%d 2>/dev/null || date -u -v+60d +%Y-%m-%d)"
kubectl -n tools apply -f - <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: trivy-exceptions
  namespace: tools
data:
  trivyignore.yaml: |
    misconfigurations:
      - id: KSV-0014
        paths:
          - "live/shuttle.yaml"
        statement: "shuttle writes /tmp/last-run; owner starfleet-ops; compensating control: policy blocks privileged and host network"
        expired_at: ${expiry}
YAML
echo "[solution] Applied."
