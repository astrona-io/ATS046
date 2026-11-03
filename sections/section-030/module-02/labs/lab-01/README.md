---
estimated_duration: 35m
---

# Lab: Signing And Verifying Images

Graded lab for the image signing module. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with Kyverno 1.19.1 (`--allowInsecureRegistry=true`), a plain-HTTP registry in `supply-chain`, three images in it and a `toolbox` pod with cosign 2.6.5 and Trivy 0.76.1. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-046-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The graders use `kubectl create --dry-run=server`, so every Kyverno webhook runs and nothing is stored. Test images are copied into the registry and signed by the grader inside the toolbox.

| Script | What it proves |
| --- | --- |
| `validate-scout-signature-verifies.sh` | `cosign verify` with `/work/keys/cosign.pub` succeeds on the scout digest |
| `validate-unsigned-image-rejected.sh` | A pod with the unsigned `outpost/drifter` image is rejected and the message names `require-signed-images` |
| `validate-foreign-key-rejected.sh` | An image signed with a different key is rejected |
| `validate-signed-image-admitted.sh` | The signed scout image is admitted by digest and by tag |
| `validate-other-registries-unaffected.sh` | Images from `ghcr.io` and Docker Hub are admitted |

## Open items (UNTESTED assumptions)

- The node reaches the registry through a `hosts.toml` written by the `node-registry-access` Job and the fixed cluster IP `10.96.0.50` (kind default service range `10.96.0.0/16`).
- Kyverno reaches the registry over plain HTTP with `--allowInsecureRegistry=true`.
- The text of Kyverno rejection messages is only checked for the policy name.
