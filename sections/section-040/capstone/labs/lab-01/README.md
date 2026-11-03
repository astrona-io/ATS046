---
estimated_duration: 40m
---

# Capstone: The Continuous Compliance Loop

Graded capstone for the automation section. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. One turn of the loop runs on `starfleet`: scan with Trivy, fix a finding, repair a drift against an approved manifest, enforce with Kyverno and a ValidatingAdmissionPolicy, and record an exception. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-046-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-probe-not-privileged.sh` | No `probe` template or running pod sets `privileged: true`, and the Deployment is available |
| `validate-scout-not-hostnetwork.sh` | `scout` template and running pods do not use the host network, the image is the approved one, the Deployment is available |
| `validate-privileged-enforced.sh` | Server-side dry runs: Kyverno rejects a privileged pod and Deployment in `starfleet`, accepts a clean pod, and accepts a privileged pod in `outpost` |
| `validate-hostnetwork-denied.sh` | A ValidatingAdmissionPolicy rejects a `hostNetwork` Deployment in `starfleet`, accepts a normal one, and accepts a `hostNetwork` Deployment in `outpost` |
| `validate-services-answer.sh` | `shuttle` gets HTTP 200 from the `scout` and `probe` Services |
| `validate-shuttle-unchanged.sh` | `shuttle` does not set `readOnlyRootFilesystem: true`, is available and has written `/tmp/last-run` |
| `validate-exception-recorded.sh` | The register holds exactly one entry: `KSV-0014`, a `paths` list that names `shuttle`, a one-line `statement` and an `expired_at` in the future and within 90 days |

## Known risks

- Kyverno 1.19.1 prints a deprecation warning for `kyverno.io/v1` ClusterPolicy.
- The `paths` value in the reference solution (`live/shuttle.yaml`) assumes Trivy matches the path of the scanned file as the helper passes it. The grader only checks that the list names `shuttle`.
- `scout` starts with `hostNetwork: true` and binds port 9898 on the node while it runs.
