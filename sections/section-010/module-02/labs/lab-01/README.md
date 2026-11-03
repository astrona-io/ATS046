---
estimated_duration: 25m
---

# Lab: Audit A Cluster With kube-bench And Record The Findings

Graded lab for the kube-bench module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. Open risks: how the kube-bench pod behaves on a kind node (host paths and process detection) and whether the log holds only the JSON report.

The cluster starts with an empty `compliance` namespace. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-046-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-kube-bench-job-completed.sh` | The Job `kube-bench` succeeded, uses the kube-bench image, and its log is a JSON report of `cis-2.0` with results for `master`, `node`, `etcd` and `policies` |
| `validate-kube-bench-summary-matches.sh` | `summary.json` equals the live log per target: the four totals and the sorted failed identifiers |
| `validate-exceptions-recorded.sh` | Every key of `kube-bench-exceptions` is a check with status `FAIL` in the live report and every reason has at least 30 characters |

All checks read the live log of the Job, so a hand-written report or an exception for a passing check fails. Every check fails before any change.
