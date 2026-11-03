---
draft: true
exam_objectives:
  - Automation and Tooling
---
# Summary

Security automation comes in three kinds that act at different points. A configuration scanner reads declarations and live objects and reports. An admission policy decides when an object is created or changed, and rejects only when it is set to reject. A runtime detector watches behavior while processes run. A result from one kind does not prove what another kind covers.

A finding is evidence that one rule matched one object at one time. To use it, the reader needs the target, the tool version, the rule set and the effective behavior. A Deployment scan describes a template, and only the running pod shows what the container runtime applied. Severity labels describe a typical case, so the ranking of findings uses consequence, exposure and feasible misuse.

Trivy reads Kubernetes objects and reports checks with IDs such as `KSV-0017` and `KSV-0014`, a severity and the lines that caused each one. The flag `--skip-check-update` pins the rules to the tool version, and `--format json` produces a report that a pipeline can store.

A repair is complete when it lives in the approved source and when a second check confirms the running pod and the application. Control drift is the difference between approved intent and actual configuration, and it appears after manual edits, upgrades and copied exceptions.

An exception needs a reason, an owner, a scope, compensating measures and an expiry date. The Trivy ignore file records `id`, `paths`, `statement` and `expired_at`. Scan results kept as evidence need their time, target, version and rules, and they need protection from change.

- A scan reports; only an admission policy in an enforcing mode rejects.
- Admission does not act on objects that existed before the policy.
- A fix is proved by effective behavior, not by the scan that found the problem.
- An exception without a scope and a date hides a risk instead of recording it.

<!-- astrona:playground:destroy -->
