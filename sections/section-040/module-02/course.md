---
draft: true
exam_objectives:
  - Automation and Tooling
---
# Policy Enforcement And Runtime Detection

A scanner tells you that a risky object exists. It does not stop the next one. Two other kinds of control close that gap. An admission policy rejects or records a request before the object is stored. A runtime detector watches what processes do after they start. This module teaches the first kind by writing and running policies, and the second kind by reading a rule and reasoning about the events it sees.

Keep one sentence in mind for this module: **a policy only prevents what its scope matches and what its action rejects, so read three things on every policy: where it applies, what it checks, and whether a failure is blocked or only recorded.** You will write a Kyverno ClusterPolicy in `Audit` mode, read the policy report it produces, switch it to `Enforce`, write a ValidatingAdmissionPolicy with a binding, and read a Falco rule line by line.

The module has three parts. **Admission Policy With Kyverno** installs no extra tools, because Kyverno is already running: it writes a ClusterPolicy, compares `Audit` and `Enforce`, and reads PolicyReports. **Native Policy With ValidatingAdmissionPolicy** writes a CEL rule and binds it with `Warn`, `Audit` and `Deny`, and limits it to one namespace. **Reading Falco Rules** explains the parts of a Falco rule, the syscall events behind it and what an alert does and does not prove. The Falco part is reading only, because the runtime sensor does not run reliably in the playground cluster.

## Learning Goals

- Explain what Kyverno and ValidatingAdmissionPolicy enforce at admission, and what they do not change.
- Compare `Audit` and `Enforce`, and `Warn`, `Audit` and `Deny`, and predict the effect on a request.
- Read a PolicyReport and tell a failed result on a Pod from a failed result on an old ReplicaSet.
- Read a Falco rule: condition, output and priority, and the events it matches.

## Before You Start

You need Kubernetes basics: namespaces, Deployments, pods, labels and `kubectl apply`. You do not need to know Kyverno, CEL or Falco; each is explained where it is used.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with Kyverno 1.19.1 installed and no policy yet:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout`, `probe` and `shuttle`. `probe` runs a privileged container on purpose. No Deployment has an `owner` label |
| `outpost` | The `drifter` client |

`kubectl` already points at the playground cluster, as the cluster administrator. Falco is not installed.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
