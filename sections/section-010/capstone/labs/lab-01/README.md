---
estimated_duration: 40m
---

# Capstone: Compliance Frameworks

Graded integration lab for the whole section. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. Open risks: how the kube-bench pod behaves on a kind node, and whether the Job log holds only the JSON report.

A namespace `orbit` starts with a privileged workload that shares the node process namespace, tokens in every pod, a service account bound to `cluster-admin` and no Pod Security labels. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-046-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-kube-bench-master-report.sh` | The Job `kube-bench` in `audit` succeeded and its log is a `cis-2.0` JSON report with `master` results |
| `validate-beacon-ci-no-admin.sh` | No binding of `beacon-ci` to `cluster-admin`; the account exists; `can-i` is `no` for wildcard, Secrets and Deployments (rejects `edit`, `admin`) |
| `validate-pods-not-privileged.sh` | No running pod in `orbit` is privileged or uses `hostPID`, `hostIPC` or `hostNetwork` |
| `validate-tokens-not-mounted.sh` | The running `beacon` and `relay` pods have no `kube-api-access` volume |
| `validate-orbit-enforces-policy.sh` | The enforce label is `baseline` or `restricted`; server-side dry runs reject a privileged pod and a `hostPID` pod |
| `validate-workloads-available.sh` | Both Deployments have an available replica and their original images |
| `validate-assessment-evidence.sh` | The record has the live server version, a UTC time, `cis-2.0`, the live `master` failure count and five `PASS` lines |

`validate-workloads-available.sh` passes before any change. Running the Job in `orbit` after enforcing a level fails because the pod uses host paths, which is why the task puts it in `audit`.
