#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

image_id="$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}')"
digest="${image_id##*@}"

kubectl -n supply-chain exec toolbox -- sh -c "
  set -eu
  mkdir -p /work/sbom /work/reports
  trivy image --format spdx-json --output /work/sbom/scout.spdx.json ghcr.io/stefanprodan/podinfo@${digest}
  trivy sbom --severity HIGH,CRITICAL --format json --output /work/reports/scout-sbom-scan.json /work/sbom/scout.spdx.json
"

tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
sbom_sha="$(tb sha256sum /work/sbom/scout.spdx.json | cut -d' ' -f1)"
packages="$(tb jq '.packages | length' /work/sbom/scout.spdx.json)"
findings="$(tb jq '[.Results[]?.Vulnerabilities[]?] | length' /work/reports/scout-sbom-scan.json)"

args=(--from-literal=image-digest="$digest" --from-literal=sbom-sha256="$sbom_sha" \
  --from-literal=spdx-package-count="$packages" --from-literal=high-critical-count="$findings")
if [ "$findings" = "0" ]; then
  args+=(--from-literal=decision=approved)
else
  expires="$(tb sh -c 'date -u -d "@$(( $(date +%s) + 2592000 ))" +%F')"
  args+=(--from-literal=decision=approved-with-exception --from-literal=exception-owner=platform-team --from-literal=exception-expires="$expires")
fi
kubectl -n starfleet delete configmap scout-release-evidence --ignore-not-found
kubectl -n starfleet create configmap scout-release-evidence "${args[@]}"
echo "[solution] Applied."
