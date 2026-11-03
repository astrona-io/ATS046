#!/usr/bin/env bash
# Check: the stored summary equals what the live Job log says, target by
# target: the four totals and the sorted list of failed check identifiers.
set -uo pipefail

report="$(kubectl -n compliance logs job/kube-bench 2>/dev/null | sed -n '/^{/,$p')"
if ! echo "$report" | jq -e '.Controls | length > 0' >/dev/null 2>&1; then
  echo "FAIL: no kube-bench report in the Job log"
  exit 1
fi

stored="$(kubectl -n compliance get configmap kube-bench-summary -o json 2>/dev/null | jq -r '.data["summary.json"] // empty')"
if [ -z "$stored" ]; then
  echo "FAIL: ConfigMap kube-bench-summary with the key summary.json not found in compliance"
  exit 1
fi

live_normalised="$(echo "$report" | jq -S -c '
  [.Controls[] | {node_type, total_pass, total_fail, total_warn, total_info,
    failed: ([.tests[]?.results[]? | select(.status == "FAIL") | .test_number] | sort)}]
  | sort_by(.node_type)')"
stored_normalised="$(echo "$stored" | jq -S -c '
  [.[] | {node_type, total_pass, total_fail, total_warn, total_info,
    failed: ((.failed // []) | sort)}]
  | sort_by(.node_type)' 2>/dev/null || true)"

if [ -z "$stored_normalised" ]; then
  echo "FAIL: summary.json is not a JSON array of objects"
  exit 1
fi

if [ "$live_normalised" != "$stored_normalised" ]; then
  echo "FAIL: summary.json differs from the Job log; rebuild it from the log with jq"
  exit 1
fi

echo "PASS: the stored summary matches the totals and failed checks of the Job log"
exit 0
