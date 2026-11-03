#!/usr/bin/env bash
# Check: a kube-bench Job in the audit namespace finished and its log is a
# JSON report of the cis-2.0 control plane checks. Read from the real log.
set -uo pipefail

fail=0

succeeded="$(kubectl -n audit get job kube-bench -o jsonpath='{.status.succeeded}' 2>/dev/null || true)"
if [ "$succeeded" != "1" ]; then
  echo "FAIL: Job kube-bench in audit has not completed (status.succeeded='$succeeded')"
  exit 1
fi

report="$(kubectl -n audit logs job/kube-bench 2>/dev/null | sed -n '/^{/,$p')"
if ! echo "$report" | jq -e '.Controls | length > 0' >/dev/null 2>&1; then
  echo "FAIL: the log of the Job is not a kube-bench JSON report (use the --json flag)"
  exit 1
fi

if ! echo "$report" | jq -e 'any(.Controls[]; .node_type == "master" and .version == "cis-2.0")' >/dev/null; then
  echo "FAIL: the report has no master results for the cis-2.0 benchmark"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the Job completed and its report holds the cis-2.0 control plane results"
fi
exit "$fail"
