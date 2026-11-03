---
estimated_duration: 25m
---

# Lab: Enforce Admission Policy

Graded lab for the policy module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. Kyverno 1.19.1 is installed with an `Audit`-mode ClusterPolicy `disallow-privileged-containers`; `probe` runs a privileged container. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-046-lab-040-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-probe-not-privileged.sh` | No `probe` template or running pod sets `privileged: true`, and the Deployment is available |
| `validate-privileged-rejected.sh` | Server-side dry runs: privileged pod and Deployment rejected by the policy in `starfleet`, clean pod accepted, privileged pod in `outpost` accepted |
| `validate-policy-report-clean.sh` | Reports hold results for the policy and no Pod or Deployment result fails |
| `validate-owner-denied.sh` | `require-owner-label` exists; an unlabelled Deployment is rejected in `starfleet` and accepted in `outpost`; a labelled one is accepted |
| `validate-existing-labelled.sh` | `scout`, `probe` and `shuttle` carry a non-empty `owner` label and are available |

## Known risks

- Kyverno 1.19.1 prints a deprecation warning for `kyverno.io/v1` ClusterPolicy. The seed script filters that one line.
- The `failureAction` path `/spec/rules/0/validate/failureAction` is assumed for the installed version.
- The seeded policy uses a pattern with anchors; the grader relies on the policy name appearing in the rejection message.
