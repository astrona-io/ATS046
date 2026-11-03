---
draft: true
exam_objectives:
  - Automation and Tooling
---
# Summary

This module covered the two controls that act after a scan has listed the problems: admission policy before an object is stored, and runtime detection while a process runs.

- An admission policy decides about a request. It does not remove objects that exist, and a background scan only records them.
- Kyverno enforces through a webhook. A ClusterPolicy rule matches resources and validates a pattern. `Audit` records a failure and lets the request through. `Enforce` rejects it.
- A policy report lists one entry for each resource, with a scope, a result and the policy and rule names. A failed result on an old ReplicaSet describes an old template and is not the same as a live risk.
- A ValidatingAdmissionPolicy runs inside the API server in CEL. A policy without a binding does nothing. The binding sets the scope and the actions `Deny`, `Warn` and `Audit`, and only `Deny` rejects a request.
- A rule that reads a field that may be absent needs a test for its presence. The failure policy decides what a rule error does to a request.
- The effective behavior of a policy is proved with a test request inside and outside the scope, because the declared policy and the loaded policy can differ.
- Falco reads system call events and compares them with rules. A rule has a condition, an output and a priority, built from macros and lists.
- An alert shows that an event met a condition on a node with a running sensor. No alert does not prove that nothing happened, and a rule that matches a name can be bypassed.
- Admission and runtime detection answer different questions, and each leaves evidence that a compliance loop can keep.

<!-- astrona:playground:destroy -->
