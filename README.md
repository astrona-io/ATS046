# Compliance and Security Frameworks (ATS046)

Kubernetes and Cloud Native Security Associate (KCSA) — Compliance and Security Frameworks, 10% of the published curriculum. This course is part of ATP009.

Concept lessons explain each official objective through concrete examples, diagrams and scenario reasoning. Every module has a playground (a clean kind cluster to explore), a graded lab, and a summary. Every section ends with a capstone lab and a knowledge check. A final knowledge check closes the course.

## Course Outline

| Section | Objective | Modules | Tools used in the labs |
| --- | --- | --- | --- |
| 010 | Compliance Frameworks | 2 + capstone | kubectl evidence, kube-bench |
| 020 | Threat Modelling Frameworks | 2 + capstone | RBAC, securityContext, NetworkPolicy |
| 030 | Supply Chain Compliance | 2 + capstone | Trivy SBOM, cosign, Kyverno verifyImages |
| 040 | Automation and Tooling | 2 + capstone | Trivy configuration scan, Kyverno, ValidatingAdmissionPolicy, Falco rules (reading) |

See [the curriculum map](CURRICULUM.md) for module outcomes. The manifest `astrona.yaml` registers readings, labs and quizzes in teaching order.

## Authoring Status

Readings are drafts for review. The playgrounds and labs are built untested: only static checks were run (`astrona validate -c`, `bash -n`, YAML parsing). Every lab README says UNTESTED. Technical sections and the ATP009 registration remain draft until the maintainer approves publication.

## Run A Lab

```sh
astrona run -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-046-lab-010-01
```

Playgrounds are started the same way with `astrona run -c <playground dir>`.

## Sources And Contributions

Author references are recorded in [SOURCES.md](SOURCES.md). Report corrections through this repository’s issues. The material uses the repository license.
