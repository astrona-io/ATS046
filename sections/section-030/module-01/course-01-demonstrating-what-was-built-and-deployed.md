---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Demonstrating What Was Built And Deployed

A platform approves `scout` only when its artifact meets defined origin and maintenance requirements. Supply chain compliance concerns demonstrating those requirements through a reliable process and evidence. The evidence needs a trustworthy link to the actual deployed content, not only a spreadsheet row naming the application.

## Evidence Across The Release Path

Source review can document an approved revision. Build records can identify tools and dependency inputs. Provenance can describe relevant origin and build facts. A signature can attest to particular content under an accepted identity. A software bill of materials (SBOM) can inventory included components. Vulnerability findings can describe known issues at a particular time.

A digest provides precise artifact identity through the chain. If an approval applies to digest A while deployment uses digest B, the original evidence does not automatically cover the replacement. A mutable tag should not erase that distinction.

Each record also needs a trusted producer. A compromised build service can generate plausible but misleading output. Protect source and build identities, evidence storage and the verification process. An attestation format alone does not make its claims reliable.

## Frameworks And Specific Guarantees

Supply-chain Levels for Software Artifacts (SLSA) organizes supply chain assurance into defined tracks and levels. The National Institute of Standards and Technology's Secure Software Development Framework (NIST Secure Software Development Framework (SSDF)) describes practices for secure development. Their scope concerns processes and assurance, not a promise that resulting software contains no defect.

Evaluate the requirement actually claimed, its version and the evidence demonstrating it. A framework name in a release note is weaker than a traceable record of the relevant build environment and controls. Do not infer unclaimed properties from a passed level or a familiar issuer.

## Verification And Acceptance

A policy decision can require approved publisher identity, valid provenance and an acceptable vulnerability result. The verifier must check the relationship to the selected artifact and the accepted trust roots or issuers. It should distinguish missing evidence, invalid evidence and a supported exception.

An exception needs scope, ownership and review. A temporary emergency bypass can become a long-term gap if its expiry or follow-up is never checked. Record why the release proceeded and what risk remains rather than making it appear identical to an ordinary approved artifact.

Failure behavior is also evidence. If a verification service outage allows every deployment, the effective control during that interval differs from a strict policy's written intent. The assessment should capture the actual decision path and outage behavior.

## Retention And Later Findings

Keep enough evidence to relate a deployed version to its origin and approval at the relevant time. Registry cleanup, overwritten records or missing build history can make a later investigation impossible. Protect access to retained records, especially when they reveal internal dependencies or sensitive configuration.

A new vulnerability can change the risk of previously approved content. Continued inventory and response allow the team to identify affected deployments and promote corrected artifacts. A scan that passed last month is historical evidence, not permanent approval of all future knowledge.

## A Reviewable Release Record

A useful record identifies the source revision, build identity, artifact digest, trusted attestations, verification outcome and deployment target. It states exceptions and later maintenance actions where relevant. This gives reviewers a concrete chain rather than several unrelated green status indicators.

Supply chain assurance is therefore about trustworthy evidence of defined properties and a process that acts on it. Application authorization, runtime privilege and data recovery remain necessary controls beyond that assurance scope.

## Common pitfalls

> [!WARNING]
> An SBOM inventories components; it does not prove safe origin or behavior. Attestations and framework claims need trusted production, exact artifact identity and a defined verification decision.
