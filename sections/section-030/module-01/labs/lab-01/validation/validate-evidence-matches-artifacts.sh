#!/usr/bin/env bash
# Check: ConfigMap starfleet/scout-release-evidence holds values that match the
# deployed pod, the SBOM file and the scan report.
set -uo pipefail

fail=0
ev() { kubectl -n starfleet get configmap scout-release-evidence -o "jsonpath={.data.$1}" 2>/dev/null; }

if ! kubectl -n starfleet get configmap scout-release-evidence >/dev/null 2>&1; then
  echo "FAIL: ConfigMap scout-release-evidence does not exist in starfleet"
  exit 1
fi

image_id="$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' 2>/dev/null)"
deployed_digest="${image_id##*@}"
if [ -z "$deployed_digest" ] || [ "$deployed_digest" = "$image_id" ]; then
  echo "FAIL: cannot read the digest of the scout pod (imageID is '$image_id')"
  exit 1
fi
if [ "$(ev image-digest)" != "$deployed_digest" ]; then
  echo "FAIL: image-digest is '$(ev image-digest)', but the scout pod runs '$deployed_digest'"
  fail=1
fi

sbom_sha="$(kubectl -n supply-chain exec toolbox -- sha256sum /work/sbom/scout.spdx.json 2>/dev/null | cut -d' ' -f1)"
if [ -z "$sbom_sha" ] || [ "$(ev sbom-sha256)" != "$sbom_sha" ]; then
  echo "FAIL: sbom-sha256 is '$(ev sbom-sha256)', but the SBOM file hashes to '$sbom_sha'"
  fail=1
fi

packages="$(kubectl -n supply-chain exec toolbox -- jq '.packages | length' /work/sbom/scout.spdx.json 2>/dev/null)"
if [ -z "$packages" ] || [ "$(ev spdx-package-count)" != "$packages" ]; then
  echo "FAIL: spdx-package-count is '$(ev spdx-package-count)', but the SBOM lists '$packages' packages"
  fail=1
fi

findings="$(kubectl -n supply-chain exec toolbox -- jq '[.Results[]?.Vulnerabilities[]?] | length' /work/reports/scout-sbom-scan.json 2>/dev/null)"
if [ -z "$findings" ] || [ "$(ev high-critical-count)" != "$findings" ]; then
  echo "FAIL: high-critical-count is '$(ev high-critical-count)', but the scan report lists '$findings' findings"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the evidence record matches the deployed digest, the SBOM and the scan report"
fi
exit "$fail"
