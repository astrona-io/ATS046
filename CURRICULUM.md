# Curriculum Coverage

Exam: Kubernetes and Cloud Native Associate (KCSA). Domain: Compliance and Security Frameworks (10%).

Verified against the [official objectives](https://training.linuxfoundation.org/certification/kubernetes-and-cloud-native-security-associate-kcsa/) on 2026-10-11. Module titles and questions are original teaching material, not official exam questions.

| Section | Official objective | Modules | Status |
| --- | --- | --- | --- |
| 010 | Compliance Frameworks | 2 + capstone | Built; labs untested |
| 020 | Threat Modelling Frameworks | 2 + capstone | Built; labs untested |
| 030 | Supply Chain Compliance | 2 + capstone | Built; labs untested |
| 040 | Automation and Tooling | 2 + capstone | Built; labs untested |

| Section / module | Module | Teaching lessons | Measurable outcomes |
| --- | --- | --- | --- |
| 010 / 01 | Compliance Scope And Control Evidence | 3 | Distinguish a framework, benchmark, policy and evidence record.; Explain assessment scope and shared operating responsibilities.; Relate technical checks to organizational control goals.; Identify why compliance evidence does not prove absence of risk. |
| 020 / 01 | Structured Threat Modelling | 3 | Explain a repeatable asset, data-flow and threat analysis process.; Use STRIDE categories without treating them as an automatic risk score.; Relate proposed mitigations to specific trust-boundary failures.; Describe residual risk and model updates after a design change. |
| 030 / 01 | Supply Chain Assurance Evidence | 3 | Relate source, build and artifact records to an assurance requirement.; Distinguish SBOM, provenance, signature and verification decision.; Explain the limits of framework levels and attestations.; Describe retention and exception handling for release evidence. |
| 040 / 01 | Automation, Findings And Control Drift | 3 | Compare configuration scanning, policy enforcement and runtime detection.; Interpret findings through scope, version and effective behavior.; Explain control drift and reproducible corrective changes.; Relate exception review and evidence retention to continuous assurance. |

Every section begins with an introduction. Every module has a playground, a graded lab and a summary. Each section ends with a capstone lab and `quiz.yaml`; `sections/final-domain-quiz.yaml` closes the course.

The labs and playgrounds are built untested: static checks only, no runtime execution is claimed. Technical content remains draft until review.

## Added Modules

| Section / module | Module | Measurable outcomes |
| --- | --- | --- |
| 010 / 02 | Auditing A Cluster Against The CIS Kubernetes Benchmark | Run kube-bench and read PASS, FAIL, WARN and INFO results.; Separate findings that need a fix from findings that need a recorded exception.; Record benchmark, version, target and time with each result. |
| 020 / 02 | Kubernetes Attack Paths And MITRE ATT&CK | Name tactics and techniques of the ATT&CK for Containers and Kubernetes matrices.; Follow an attack path step by step.; Break a path with RBAC, service account token, securityContext and NetworkPolicy changes. |
| 030 / 02 | Signing And Verifying Images | Explain digests and key-based signing with cosign.; Attach and read SBOM attestations.; Enforce signatures with a Kyverno verifyImages policy. |
| 040 / 02 | Policy Enforcement And Runtime Detection | Compare Audit and Enforce modes in Kyverno and ValidatingAdmissionPolicy.; Read PolicyReports.; Read a Falco rule: condition, output and priority. |
