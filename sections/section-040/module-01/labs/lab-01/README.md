---
estimated_duration: 25m
---

# Lab: Fix Findings And Record An Exception

Graded lab for the findings module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The `starfleet` namespace starts with `scout` without a `securityContext`, a privileged `probe`, and a `shuttle` that needs a writable root file system. A Trivy toolbox pod and an empty exception register run in `tools`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-046-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-probe-not-privileged.sh` | No `probe` template, init container or running pod sets `privileged: true`, and the Deployment is available |
| `validate-scout-hardened.sh` | Every running `scout` pod has a numeric non-zero user, `runAsNonRoot`, `RuntimeDefault` seccomp, no privilege escalation and `drop: ["ALL"]` (a template changed without a rollout fails) |
| `validate-services-answer.sh` | `shuttle` gets HTTP 200 from the `scout` and `probe` Services |
| `validate-shuttle-unchanged.sh` | `shuttle` does not set `readOnlyRootFilesystem: true`, is available and has written `/tmp/last-run` |
| `validate-exception-recorded.sh` | The register holds exactly one entry: `KSV-0014`, a `paths` list that names `shuttle`, a one-line `statement` and an `expired_at` in the future and within 90 days |

## Known risks

- The `paths` value in the reference solution (`live/shuttle.yaml`) assumes Trivy matches the path of the scanned file as the helper passes it. The grader only checks that the list names `shuttle`.
- The toolbox pod runs `trivy config --skip-check-update`, so Trivy uses the checks built into version 0.76.1.
