---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Supply Chain Assurance Evidence

A release team wants to ship `scout`, a small web service, into the namespace `starfleet`. The platform team asks one question before it agrees: can you show that the bytes running in the cluster are the bytes you built, from the source you reviewed, and that you know what is inside them? Answering with "yes, we trust our pipeline" is not enough. The platform team needs records that a person or a program can check.

This module teaches what those records are, how they relate to each other, and how a team turns them into a decision to release, reject or accept with an exception. Keep one idea in mind: **evidence is only worth as much as its link to one exact artifact and the trust you place in whoever produced it.**

The module has three parts. **Demonstrating What Was Built And Deployed** follows the source, build and artifact records of one release and shows why an image digest is the anchor for all of them. **SBOM Formats And Provenance** compares the two common SBOM formats, then explains provenance, SLSA levels and in-toto attestations. **Verification Decisions And Retention** separates a signature from a verification decision, records an exception with an owner and an expiry, and decides how long to keep the evidence.

## Learning goals

After this module you can:

- Relate source, build and artifact records to an assurance requirement.
- Distinguish an SBOM, provenance, a signature and a verification decision.
- Create an SBOM in SPDX and CycloneDX format and scan it for known vulnerabilities.
- Explain the limits of framework levels and attestations.
- Describe retention and exception handling for release evidence.

## Before you start

You need to know what a container image is and what a pod is. Every term in the module is defined where it first appears.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. It has these parts:

| Where | What it is |
| --- | --- |
| namespace `starfleet` | `scout` runs the `podinfo` image 6.15.0, `probe` runs `go-httpbin` 2.25.0, `shuttle` runs a `curl` image |
| namespace `outpost` | `drifter` runs a `curl` image |
| pod `toolbox` in `supply-chain` | has cosign 2.6.5, Trivy 0.76.1 and `jq`, and an empty working directory `/work` |

There is no registry, no Kyverno and no policy. The toolbox needs internet access because Trivy downloads its vulnerability database on first use. `kubectl` already points at the cluster.

Launch your playground now and keep it running while you read:

<!-- astrona:playground -->
