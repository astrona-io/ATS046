#!/usr/bin/env bash
# Check: the exception record. Every key must be the identifier of a check
# that FAILED in the live report (a passing, warning or unknown check cannot
# be excepted) and every reason must be a real sentence.
set -uo pipefail

fail=0

report="$(kubectl -n compliance logs job/kube-bench 2>/dev/null | sed -n '/^{/,$p')"
if ! echo "$report" | jq -e '.Controls | length > 0' >/dev/null 2>&1; then
  echo "FAIL: no kube-bench report in the Job log"
  exit 1
fi

if ! kubectl -n compliance get configmap kube-bench-exceptions >/dev/null 2>&1; then
  echo "FAIL: ConfigMap kube-bench-exceptions not found in compliance"
  exit 1
fi

failed_ids="$(echo "$report" | jq -r '.Controls[].tests[]?.results[]? | select(.status == "FAIL") | .test_number')"
entries="$(kubectl -n compliance get configmap kube-bench-exceptions -o json | jq -r '.data // {} | to_entries[] | .key + "\t" + .value')"

if [ -z "$entries" ]; then
  echo "FAIL: kube-bench-exceptions has no entries; record at least one accepted failure"
  exit 1
fi

while IFS=$'\t' read -r key reason; do
  if ! echo "$failed_ids" | grep -Fxq "$key"; then
    echo "FAIL: '$key' is not a check with status FAIL in the report"
    fail=1
  fi
  if [ "${#reason}" -lt 30 ]; then
    echo "FAIL: the reason for '$key' must be a sentence of at least 30 characters"
    fail=1
  fi
done <<< "$entries"

if [ "$fail" -eq 0 ]; then
  echo "PASS: every recorded exception is a failed check with a written reason"
fi
exit "$fail"
