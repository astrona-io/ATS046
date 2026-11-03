---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Summary

A cluster runs whatever image a pod names, and nothing in Kubernetes asks who made it. Signing and admission verification add that check.

## What you learned

A cosign signature covers a JSON payload that holds an image digest. It vouches for that digest and for no other, so a signature stays valid when a tag moves, while the new target has no signature. Cosign stores the signature in the registry as a separate entry under the same image name. A verifier needs the public key and the digest, and it accepts only the keys it is told to trust. A valid signature from an unknown key is not a trusted signature.

An attestation signs a claim about a digest. It has a subject digest, a predicate type and a predicate, such as an SPDX SBOM. The predicate type lets a verifier require the right kind of claim, and the subject digest stops an attestation from one image being reused on another. The signature shows who produced the document and that it did not change. It does not show that the document is complete or that the components are safe.

Kyverno enforces verification at admission. A `verifyImages` rule names the image patterns, the trusted public keys and, for attestations, the predicate types. One entry verifies signatures or attestations, not both, so a gate that needs both uses two rules. `Enforce` rejects the pod and `Audit` only records the failure. `mutateDigest` pins the verified digest into the pod. The gate checks at creation, covers only what its patterns match, and depends on its failure setting when Kyverno is unreachable.

The key facts to remember are these:

- Sign the digest, never the tag.
- A policy must name the keys it trusts; any valid signature is not enough.
- The predicate type and the attestors belong in every attestation rule.
- A gate that is not set to Enforce does not refuse anything.

<!-- astrona:playground:destroy -->
