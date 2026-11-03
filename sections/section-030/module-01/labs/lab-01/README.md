---
estimated_duration: 25m
---

# Lab: Supply Chain Assurance Evidence

Graded lab for the supply chain evidence module. **UNTESTED**: it was built with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run on a cluster. The cluster starts with the Starfleet workloads and a `toolbox` pod in `supply-chain` that has cosign 2.6.5 and Trivy 0.76.1. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-046-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-sbom-for-scout.sh` | `/work/sbom/scout.spdx.json` is a valid SPDX 2.x document with packages and describes podinfo |
| `validate-sbom-scan-report.sh` | `/work/reports/scout-sbom-scan.json` is a Trivy report with HIGH and CRITICAL findings only |
| `validate-evidence-matches-artifacts.sh` | The ConfigMap values equal the digest in the pod status, the SBOM hash, the package count and the findings count |
| `validate-release-decision.sh` | The decision follows the findings; an exception has an owner and a future expiry date |

## Open items

- The grader does not check that the SBOM contains the digest string, because the exact fields Trivy writes were not confirmed by a run.
- The result depends on the Trivy vulnerability database of the day, so the solution handles both the no-finding and the finding case.
