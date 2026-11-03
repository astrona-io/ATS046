---
draft: true
exam_objectives:
  - Automation and Tooling
---
# Automation, Findings And Control Drift

A security tool is only useful when the reader knows what it can and cannot prove. A configuration scanner reads files and live objects. An admission policy answers requests at the moment an object is created or changed. A runtime detector watches what processes do after they start. Each one answers a different question, and each one can be wrong in its own way.

Keep one sentence in mind for this module: **a finding is evidence that a rule matched one object at one time, and it is only worth acting on when you know which object, which version of the rule and which behavior it describes.** You will scan the example workloads with Trivy, read the findings, fix them in the cluster, check that the fix is real, record an exception that expires, and see how a change outside the approved source becomes control drift.

The module has three parts. **What Security Automation Can Establish** compares configuration scanning, policy enforcement and runtime detection and explains how to read a finding. **Scan A Cluster With Trivy** runs a misconfiguration scan on live Deployments and reads the check IDs, severities and the lines that caused them. **Fix Drift And Record Exceptions** repairs findings, proves the repair against effective behavior, writes an ignore file entry with a reason and an expiry date, and keeps scan evidence.

## Learning Goals

- Compare configuration scanning, policy enforcement and runtime detection.
- Interpret findings through scope, version and effective behavior.
- Explain control drift and reproducible corrective changes.
- Relate exception review and evidence retention to continuous assurance.

## Before You Start

You need Kubernetes basics: namespaces, Deployments, pods, `kubectl get`, `kubectl patch` and `kubectl apply`. You do not need to know Trivy; it is explained where it is used.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no policy engine:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout` with no `securityContext`, `probe` with a privileged container, and `shuttle`, which is hardened but writes a file on its root file system |
| `outpost` | The `drifter` client |
| `tools` | A toolbox pod that runs Trivy 0.76.1, and a ConfigMap that holds the Trivy ignore file and starts empty |

`kubectl` already points at the playground cluster, as the cluster administrator. Trivy runs inside the toolbox pod, so you install nothing on your own machine.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
