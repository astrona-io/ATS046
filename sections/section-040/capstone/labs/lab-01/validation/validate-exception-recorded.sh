#!/usr/bin/env bash
# Check: the exception register holds exactly one entry, for KSV-0014, scoped to
# shuttle, with a one-line statement and an expiry date that is in the future
# and at most 90 days away. Rejects a blanket ignore, extra IDs, a missing
# statement, a missing expiry and an expiry that is too far away.
set -uo pipefail

content="$(kubectl -n tools get configmap trivy-exceptions -o jsonpath='{.data.trivyignore\.yaml}' 2>/dev/null)"
if [ -z "$content" ]; then
  echo "FAIL: the key trivyignore.yaml of the ConfigMap trivy-exceptions in tools is empty or missing"
  exit 1
fi

ids="$(printf '%s\n' "$content" | grep -E '^[[:space:]]*-?[[:space:]]*id:' | sed -E 's/^[[:space:]]*-?[[:space:]]*id:[[:space:]]*//; s/["'"'"']//g; s/[[:space:]]+$//')"
if [ "$(printf '%s\n' "$ids" | grep -c .)" != "1" ]; then
  echo "FAIL: the register must hold exactly one entry, found: [$(printf '%s' "$ids" | tr '\n' ' ')]"
  exit 1
fi
case "$ids" in
  KSV-0014|AVD-KSV-0014) ;;
  *) echo "FAIL: the entry id is '$ids', expected KSV-0014. Only the shuttle root file system finding is accepted; fix the others."; exit 1 ;;
esac

if ! printf '%s\n' "$content" | grep -qE '^[[:space:]]*paths:'; then
  echo "FAIL: the entry has no paths list, so it would hide KSV-0014 on every workload"
  exit 1
fi
if ! printf '%s\n' "$content" | grep -E '^[[:space:]]*-[[:space:]]+' | grep -v 'id:' | grep -q 'shuttle'; then
  echo "FAIL: the paths list does not name the shuttle manifest (for example live/shuttle.yaml)"
  exit 1
fi

if ! printf '%s\n' "$content" | grep -qE '^[[:space:]]*statement:[[:space:]]*["'"'"']?[^[:space:]"'"'"'].{14,}'; then
  echo "FAIL: the entry needs a one-line statement of at least 15 characters that gives the reason"
  exit 1
fi

expiry="$(printf '%s\n' "$content" | grep -E '^[[:space:]]*expired_at:' | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
if [ -z "$expiry" ]; then
  echo "FAIL: the entry has no expired_at date in the form yyyy-mm-dd"
  exit 1
fi
today="$(date -u +%Y-%m-%d)"
limit="$(date -u -d '+90 days' +%Y-%m-%d 2>/dev/null || date -u -v+90d +%Y-%m-%d)"
if [[ ! "$expiry" > "$today" ]]; then
  echo "FAIL: expired_at ${expiry} is not in the future (today is ${today})"
  exit 1
fi
if [[ "$expiry" > "$limit" ]]; then
  echo "FAIL: expired_at ${expiry} is more than 90 days away (the limit is ${limit})"
  exit 1
fi

echo "PASS: one scoped, explained exception for KSV-0014 expires on ${expiry}"
