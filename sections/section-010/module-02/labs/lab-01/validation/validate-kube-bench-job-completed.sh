#!/usr/bin/env bash
# Check: a kube-bench Job in compliance finished and its log is a JSON report
# of the cis-2.0 benchmark that covers all four targets. The report comes from
# the real log, so a hand-written file cannot pass.
set -uo pipefail

fail=0

succeeded="$(kubectl -n compliance get job kube-bench -o jsonpath='{.status.succeeded}' 2>/dev/null || true)"
if [ "$succeeded" != "1" ]; then
  echo "FAIL: Job kube-bench in compliance has not completed (status.succeeded='$succeeded')"
  exit 1
fi

image="$(kubectl -n compliance get job kube-bench -o jsonpath='{.spec.template.spec.containers[0].image}')"
case "$image" in
  *aquasec/kube-bench:*) ;;
  *) echo "FAIL: the Job does not use the kube-bench image (found '$image')"; fail=1 ;;
esac

report="$(kubectl -n compliance logs job/kube-bench 2>/dev/null | sed -n '/^{/,$p')"
if ! echo "$report" | jq -e '.Controls | length > 0' >/dev/null 2>&1; then
  echo "FAIL: the log of the Job is not a kube-bench JSON report (use the --json flag)"
  exit 1
fi

versions="$(echo "$report" | jq -r '[.Controls[].version] | unique | join(",")')"
if [ "$versions" != "cis-2.0" ]; then
  echo "FAIL: the report covers benchmark '$versions', expected cis-2.0"
  fail=1
fi

for target in master node etcd policies; do
  if ! echo "$report" | jq -e --arg target "$target" 'any(.Controls[]; .node_type == $target)' >/dev/null; then
    echo "FAIL: the report has no results for the target '$target'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the Job completed and its report covers master, node, etcd and policies for cis-2.0"
fi
exit "$fail"
