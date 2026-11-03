#!/usr/bin/env bash
# Check: an SPDX JSON SBOM of the scout image (podinfo) exists in the toolbox.
set -uo pipefail

file=/work/sbom/scout.spdx.json
kubectl -n supply-chain exec toolbox -- test -s "$file" 2>/dev/null \
  || { echo "FAIL: $file does not exist or is empty in the toolbox pod"; exit 1; }

result="$(kubectl -n supply-chain exec toolbox -- jq -r '[(.spdxVersion // ""), ((.packages // []) | length | tostring)] | join(" ")' "$file" 2>/dev/null)"
if [ -z "$result" ]; then
  echo "FAIL: $file is not valid JSON"
  exit 1
fi
version="${result%% *}"
count="${result##* }"
case "$version" in
  SPDX-2.*) ;;
  *) echo "FAIL: $file is not an SPDX document (spdxVersion is '$version'). Use --format spdx-json"; exit 1 ;;
esac
if [ "$count" -lt 1 ]; then
  echo "FAIL: the SBOM lists no packages"
  exit 1
fi
if ! kubectl -n supply-chain exec toolbox -- grep -q podinfo "$file"; then
  echo "FAIL: the SBOM does not describe the podinfo image that scout runs"
  exit 1
fi
echo "PASS: $file is an SPDX document with $count packages for the scout image"
