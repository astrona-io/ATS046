---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Summary

Supply chain assurance links source, build, artifact and deployment evidence. Each record covers a different property, and each one needs a trustworthy producer and a link to one exact artifact.

## What you learned

An image digest identifies exact content, while a tag is a label that can move. Records written against a tag can silently stop applying, so every record should name the digest, and a check should compare the digest of what runs with the digest that was approved.

An SBOM lists the components of an artifact in a machine-readable form. SPDX and CycloneDX are the two common formats, and they can describe the same image with different structure and counts. A scan of an SBOM matches its components against a vulnerability database, so the result depends on the SBOM's completeness and on the day of the scan.

Provenance records how an artifact was built. SLSA build levels describe how reliable that record is, from existence at the lowest level to protection against forgery at the highest. A level says nothing about defects in the code. An in-toto attestation wraps a claim in a statement with a subject digest, a predicate type and a predicate, and a signed envelope lets a verifier check who made it.

A signature identifies who vouched for bytes. A verification decision compares the evidence with a policy and produces an outcome: approved, rejected for missing evidence, rejected for invalid evidence, rejected for findings, or approved with an exception. An exception needs a scope, an owner, an expiry and a reason. The behavior of a control when verification cannot run is part of the evidence.

Retention keeps the records that relate a deployed version to its approval, protects them from change and from unwanted reading, and allows a later rescan to find the deployments affected by a new vulnerability.

The key facts to remember are these:

- Name the digest in every record, not the tag.
- An SBOM is an inventory; provenance is a statement about the build; a signature is a statement about identity.
- A framework level describes a process, not the quality of the code.
- A decision needs a policy; an exception needs an owner and an expiry.

<!-- astrona:playground:destroy -->
