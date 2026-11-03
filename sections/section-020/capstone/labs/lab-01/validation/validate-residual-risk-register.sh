#!/usr/bin/env bash
# Check: the ConfigMap residual-risk in starfleet records one residual risk
# for each of the three mitigated threats. Each value must be a real sentence
# (at least 40 characters, no placeholder), so an empty ConfigMap or a one-word
# value fails. The grader cannot judge the wording; it checks the register
# exists and is filled in.
set -uo pipefail

fail=0

if ! kubectl -n starfleet get configmap residual-risk >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap residual-risk does not exist in starfleet"
  exit 1
fi

for key in spoofing information-disclosure elevation-of-privilege; do
  value="$(kubectl -n starfleet get configmap residual-risk -o json | jq -r --arg key "$key" '.data[$key] // ""')"
  if [ "${#value}" -lt 40 ]; then
    echo "FAIL: residual-risk key '$key' is missing or shorter than 40 characters"
    fail=1
    continue
  fi
  if echo "$value" | grep -qiE 'todo|tbd|placeholder|fixme'; then
    echo "FAIL: residual-risk key '$key' contains a placeholder word"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the residual-risk register has an entry for each threat"
fi
exit "$fail"
