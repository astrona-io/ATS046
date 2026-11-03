---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Section 030: Supply Chain Compliance

Makes the reader able to show that the software running in a cluster is the software that was built and approved. It links source, build and artifact records through the image digest, creates and scans SBOMs, signs images and attests an SBOM with cosign, and enforces the result with a Kyverno admission gate.

**Curriculum item covered:** Supply Chain Compliance

---

## What You Will Master

- Relate source, build and artifact records to an assurance requirement through the image digest
- Read the digest a pod runs and explain why an approval written against a tag does not cover a rebuilt image
- Create an SPDX and a CycloneDX SBOM of one digest and scan the SBOM for known vulnerabilities
- Explain provenance, SLSA build levels and the limit of a level
- Describe an in-toto attestation: subject digest, predicate type, predicate, signed envelope
- Distinguish a signature from a verification decision, and record an exception with an owner and an expiry
- Generate a cosign key pair, sign an image by digest and verify the signature
- Attach an SBOM as a signed attestation and verify it by predicate type
- Write a Kyverno ClusterPolicy with verifyImages that refuses unsigned images and images signed by an unknown key
- Build a release gate that admits only signed images carrying an SBOM attestation

---

## The Learning Path

### 1. Supply Chain Assurance Evidence
*   **Module Reader:** **[Module 1: Supply Chain Assurance Evidence](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-01/playground` — kind cluster. The Starfleet workloads (`scout` runs `podinfo`, `probe` runs `go-httpbin`, `shuttle` and `drifter` run `curl`) and a `toolbox` pod in `supply-chain` with cosign 2.6.5, Trivy 0.76.1 and `jq`. No registry, no Kyverno, no policy.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-01/playground
    ```
*   **Graded Lab:** `sections/section-030/module-01/labs/lab-01` — record the release evidence for `scout`: the digest, an SPDX SBOM, a scan and a decision.

### 2. Signing And Verifying Images
*   **Module Reader:** **[Module 2: Signing And Verifying Images](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-02/playground` — kind cluster. Kyverno 1.19.1 with no policy, a plain-HTTP registry in `supply-chain` with three unsigned images, and the `toolbox` pod with cosign 2.6.5 and Trivy 0.76.1. For testing only: Kyverno runs with `--allowInsecureRegistry=true`.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-02/playground
    ```
*   **Graded Lab:** `sections/section-030/module-02/labs/lab-01` — sign the scout image and write a policy that refuses unsigned and foreign-signed images.

### Section Capstone Challenge
*   **Comprehensive Challenge:** Supply Chain Compliance Capstone — `sections/section-030/capstone/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Build a release gate for the namespace `starfleet`. The reader signs `scout` and `probe`, attaches an SPDX SBOM attestation to `scout` only, and writes a two-rule Kyverno policy. The grader rejects `probe` (no SBOM), an unsigned image, an image signed and attested by another key, and an image signed by the reader but attested by another key. It admits `scout` and leaves other namespaces and registries alone.

---

## Ready for Assessment?

*   **Take the Section 030 Knowledge Check:** `sections/section-030/quiz.yaml`
