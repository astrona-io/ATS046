---
estimated_duration: 20m
---

# Lab: Turn STRIDE Threats Into Mitigations

Graded lab for the structured threat modelling module. **UNTESTED: built untested.** It was validated statically only (`astrona validate`, `bash -n`, YAML parsing). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-046-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-least-privilege.sh` | `scout` reads `scout-config` and nothing else; no `edit`, `admin` or `cluster-admin` binding; the account still exists |
| `validate-probe-accepts-only-shuttle.sh` | `shuttle` reaches `probe`; `caller` (same namespace) and `drifter` (`outpost`) are refused, by real `curl` requests |
| `validate-probe-hardened.sh` | The live `probe` pods are unprivileged, non-root, drop ALL capabilities, block privilege escalation and are Ready |
| `validate-app-still-works.sh` | Workloads are available, the ConfigMap and Secret exist, `shuttle` reaches `scout` |

`app-still-works` passes before any change. It fails if a fix breaks the application.

## Notes

kind's default network plugin (kindnet) enforces NetworkPolicy since kind v0.24.0, so no extra plugin is installed. This is taken from the kind v0.24.0 release notes and was not run here.
