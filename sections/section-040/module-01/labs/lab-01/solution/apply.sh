#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet patch deployment probe --type=json -p '[
  {"op": "replace", "path": "/spec/template/spec/containers/0/securityContext/privileged", "value": false}
]'

kubectl -n starfleet patch deployment scout -p '{
  "spec": {"template": {"spec": {
    "securityContext": {
      "runAsNonRoot": true,
      "runAsUser": 100,
      "seccompProfile": {"type": "RuntimeDefault"}
    },
    "containers": [{
      "name": "scout",
      "securityContext": {
        "allowPrivilegeEscalation": false,
        "capabilities": {"drop": ["ALL"]}
      }
    }]
  }}}
}'

for name in scout probe; do
  kubectl -n starfleet rollout status "deployment/${name}" --timeout=180s
done

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
        statement: "shuttle writes /tmp/last-run; owner starfleet-ops; compensating control: non-root, all capabilities dropped"
        expired_at: ${expiry}
YAML
echo "[solution] Applied."
