---
estimated_duration: 30m
---

# Capstone: Threat Model Driven Hardening Of A Small App

Capstone for the threat modelling frameworks section. **UNTESTED: built untested.** It was validated statically only (`astrona validate`, `bash -n`, YAML parsing). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-046-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-no-cluster-admin.sh` | `scout` and `shuttle` cannot read Secrets, create pods, delete nodes or create ClusterRoleBindings; no `cluster-admin`, `admin` or `edit` binding names them; accounts and Secret still exist |
| `validate-tokens-not-mounted.sh` | The live `scout` and `shuttle` pods have no token volume and no mount at the service account path |
| `validate-scout-hardened.sh` | The live `scout` pods are unprivileged, have no hostPath or host namespaces, run as non-root, drop ALL capabilities, block escalation and are Ready |
| `validate-probe-accepts-only-shuttle.sh` | `shuttle` reaches `probe`; `caller` and `drifter` are refused, by real `curl` requests |
| `validate-residual-risk-register.sh` | The ConfigMap `residual-risk` has three keys with sentences of at least 40 characters and no placeholder word |

## Notes

kind's default network plugin (kindnet) enforces NetworkPolicy since kind v0.24.0 (kind v0.24.0 release notes), so no extra plugin is installed. This was not run here.
