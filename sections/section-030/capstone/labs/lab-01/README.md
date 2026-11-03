---
estimated_duration: 45m
---

# Capstone Lab: Supply Chain Release Gate

Graded capstone for the supply chain compliance section. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with Kyverno 1.19.1 (`--allowInsecureRegistry=true`), a plain-HTTP registry with three images and a `toolbox` pod with cosign 2.6.5 and Trivy 0.76.1. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-046-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The graders use `kubectl create --dry-run=server`, so every Kyverno webhook runs and nothing is stored. The grader copies extra images into the registry and signs them with a foreign key inside the toolbox.

| Script | What it proves |
| --- | --- |
| `validate-scout-signed-and-attested.sh` | Scout has a signature and an SPDX attestation that verify with `/work/keys/cosign.pub`; probe is signed and has no attestation |
| `validate-gate-admits-scout.sh` | Scout is admitted by digest and by tag |
| `validate-gate-rejects-incomplete-releases.sh` | Probe (no SBOM), drifter (unsigned) and an image signed and attested by a foreign key are rejected |
| `validate-attestation-key-enforced.sh` | An image signed by the learner but attested by a foreign key is rejected |
| `validate-gate-scope.sh` | `outpost` and images from other registries are not blocked |

## Open items (UNTESTED assumptions)

- The node reaches the registry through a `hosts.toml` written by the `node-registry-access` Job and the fixed cluster IP `10.96.0.50`.
- Kyverno reaches the registry over plain HTTP with `--allowInsecureRegistry=true`.
- The SPDX predicate type is matched as `https://spdx.dev/Document`.
- Rejection messages are only checked for the policy name.
