---
estimated_duration: 20m
---

# Lab: Fix Failing Controls And Record Evidence

Graded lab for the compliance scope module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with a service account bound to `cluster-admin`, a privileged container and service account tokens in every pod. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-046-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-shuttle-cluster-admin-removed.sh` | No RoleBinding or ClusterRoleBinding gives `shuttle` the `cluster-admin` role; the service account still exists |
| `validate-shuttle-least-privilege.sh` | `can-i` answers `no` for wildcard, Secrets, pods, Deployments and cluster-wide Secrets (rejects `edit`, `admin`, `view`) |
| `validate-token-not-mounted.sh` | The running (not terminating) `scout` and `probe` pods have no `kube-api-access` volume |
| `validate-probe-not-privileged.sh` | No running pod in `starfleet` has a privileged container or init container |
| `validate-workloads-running.sh` | The three Deployments have an available replica and their original images |
| `validate-control-evidence-recorded.sh` | The `control-evidence` ConfigMap has the scope, the live server version, a UTC time and a `PASS` line per control |

`validate-workloads-running.sh` passes before any change. It fails if a learner deletes or scales down a workload while fixing a control.
