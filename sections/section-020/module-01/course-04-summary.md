---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Summary

A threat model describes a system before it asks how the system can be harmed. It lists the assets, draws the data flows between the elements and marks the trust boundaries where identity, privilege or assumptions change. The description must match the running cluster, so the flows are tested with real requests and the identities are tested with permission checks. Kubernetes adds flows that no manifest draws, such as pod-to-pod traffic that crosses namespaces and the call from a pod to the API server with a service account token.

STRIDE gives six questions: spoofing, tampering, repudiation, information disclosure, denial of service and elevation of privilege. The questions apply to every flow and element, and one flow often produces threats in several categories. The categories are prompts. They are not a risk score, and they do not say which control to use. Priority comes from the asset, the access path and the consequence in the actual environment.

A mitigation answers a specific step of a specific path. RBAC is enforced by the API server and limits what an identity may do. A NetworkPolicy is enforced by the network plugin and limits which pods may connect. A securityContext is enforced by the container runtime and the kernel and limits what a process may do on the node. Each control needs proof from the cluster, and the network control needs a real request because a plugin can ignore a policy.

Residual risk is what remains after the controls. It is written down with an owner and a decision: accept, reduce, transfer or avoid. The model changes when the design changes: a new data store, flow or identity adds elements to review, and a changed assumption can disable a control without changing any YAML.

Key facts:

- A threat is a way to harm an asset, a vulnerability is the weakness that allows it, and a mitigation reduces it.
- A namespace separates names and RBAC rules, not network traffic.
- A NetworkPolicy port is a pod port, not a Service port.
- `runAsNonRoot` needs a numeric `runAsUser` when the image names its user.

<!-- astrona:playground:destroy -->
