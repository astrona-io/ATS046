---
draft: true
exam_objectives:
  - Compliance Frameworks
---
# Summary

Compliance means meeting the obligations that apply to a defined scope and showing that you meet them. Security means reducing the real risk to assets. A framework sets goals, a certifiable standard sets requirements that an auditor can check, and a benchmark lists configuration recommendations for one technology and one version. A policy is the organization's own rule, and an evidence record is the proof that a control implements it.

Every result is bounded. The scope says which systems and namespaces were assessed, the versions say which benchmark, cluster and tool were used, and the time says when the check was true. Responsibility is split by layer: a provider can run the control plane while the customer owns role bindings, pod settings and images. A clean result for one namespace says nothing about another.

Evidence comes from the Kubernetes API. A list of bindings to `cluster-admin`, a count of service account token volumes and a list of privileged pods each show one control. The same check run after a change shows that the change reached the running pods. A record keeps the result together with its scope, version and time, and it becomes wrong as soon as the cluster changes.

Key facts:

- A benchmark informs a control but does not replace a policy.
- Automated recommendations can be decided by a program, and manual ones need a person.
- An exception names a reason, an owner, a scope and a review date, and the failed check stays visible.
- A passing check does not show that the application or the cluster is free of risk.

<!-- astrona:playground:destroy -->
