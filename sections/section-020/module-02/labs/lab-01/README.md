---
estimated_duration: 25m
---

# Lab: Break A Kubernetes Attack Path

Graded lab for the Kubernetes attack paths module. **UNTESTED: built untested.** It was validated statically only (`astrona validate`, `bash -n`, YAML parsing). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-046-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-shuttle-secrets-unreadable.sh` | `shuttle` cannot read or list Secrets, list or create pods, or act in `starfleet`; no binding names it; the account and the Secret still exist |
| `validate-shuttle-token-not-mounted.sh` | The live `shuttle` pods have no projected token volume and no mount at the service account path |
| `validate-shuttle-not-privileged.sh` | The live pods are unprivileged, have no hostPath or host namespaces, run as non-root, drop ALL capabilities, block escalation and are Ready |
| `validate-shuttle-egress-limited.sh` | `shuttle` reaches `probe` by name; the `scout` Service and the `scout` pod address are refused |

## Notes

kind's default network plugin (kindnet) enforces NetworkPolicy since kind v0.24.0 (kind v0.24.0 release notes), so no extra plugin is installed. The egress rule for DNS and the behavior of egress policies were not run here.
