#!/usr/bin/env bash
# Check: the recorded decision follows the findings, and an exception has an owner and a future expiry.
set -uo pipefail

ev() { kubectl -n starfleet get configmap scout-release-evidence -o "jsonpath={.data.$1}" 2>/dev/null; }

if ! kubectl -n starfleet get configmap scout-release-evidence >/dev/null 2>&1; then
  echo "FAIL: ConfigMap scout-release-evidence does not exist in starfleet"
  exit 1
fi

findings="$(kubectl -n supply-chain exec toolbox -- jq '[.Results[]?.Vulnerabilities[]?] | length' /work/reports/scout-sbom-scan.json 2>/dev/null)"
if [ -z "$findings" ]; then
  echo "FAIL: cannot read the scan report /work/reports/scout-sbom-scan.json"
  exit 1
fi
decision="$(ev decision)"
owner="$(ev exception-owner)"
expires="$(ev exception-expires)"
today="$(kubectl -n supply-chain exec toolbox -- date -u +%F)"

if [ "$findings" = "0" ]; then
  if [ "$decision" != "approved" ]; then
    echo "FAIL: the report has no HIGH or CRITICAL finding, so decision must be 'approved' (it is '$decision')"
    exit 1
  fi
  echo "PASS: no HIGH or CRITICAL finding and decision is approved"
  exit 0
fi

case "$decision" in
  rejected)
    if [ -n "$owner" ] || [ -n "$expires" ]; then
      echo "FAIL: a rejected release must not carry exception keys"
      exit 1
    fi
    echo "PASS: $findings HIGH or CRITICAL findings and the release is rejected"
    ;;
  approved-with-exception)
    if [ -z "$owner" ]; then
      echo "FAIL: an exception needs exception-owner"
      exit 1
    fi
    if ! printf '%s' "$expires" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
      echo "FAIL: exception-expires must be a date like 2026-12-31 (it is '$expires')"
      exit 1
    fi
    if [ ! "$expires" \> "$today" ]; then
      echo "FAIL: exception-expires '$expires' is not after today ($today)"
      exit 1
    fi
    echo "PASS: $findings findings, approved with an exception owned by $owner until $expires"
    ;;
  *)
    echo "FAIL: with $findings HIGH or CRITICAL findings, decision must be 'rejected' or 'approved-with-exception' (it is '$decision')"
    exit 1
    ;;
esac
