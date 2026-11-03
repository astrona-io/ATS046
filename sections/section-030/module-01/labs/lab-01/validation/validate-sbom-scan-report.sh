#!/usr/bin/env bash
# Check: the SBOM was scanned with Trivy and the report keeps only HIGH and CRITICAL findings.
set -uo pipefail

report=/work/reports/scout-sbom-scan.json
kubectl -n supply-chain exec toolbox -- test -s "$report" 2>/dev/null \
  || { echo "FAIL: $report does not exist or is empty in the toolbox pod"; exit 1; }

if ! kubectl -n supply-chain exec toolbox -- jq -e 'type == "object" and has("SchemaVersion")' "$report" >/dev/null 2>&1; then
  echo "FAIL: $report is not a Trivy JSON report. Use trivy sbom --format json"
  exit 1
fi
low="$(kubectl -n supply-chain exec toolbox -- jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW" or .Severity == "MEDIUM" or .Severity == "UNKNOWN")] | length' "$report" 2>/dev/null)"
if [ "${low:-1}" != "0" ]; then
  echo "FAIL: the report still contains $low LOW, MEDIUM or UNKNOWN findings. Scan with --severity HIGH,CRITICAL"
  exit 1
fi
echo "PASS: $report is a Trivy report limited to HIGH and CRITICAL findings"
