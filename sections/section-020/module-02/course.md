---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Kubernetes Attack Paths And MITRE ATT&CK

An attacker rarely needs one big flaw. A small foothold, a token that sits in a file, a pod with too many rights and a flat network are enough, and each step uses a feature that Kubernetes provides on purpose. A defender who knows the steps can break the path at the cheapest place.

This module teaches two things. First, the shared vocabulary that security teams use to describe attacks: the MITRE ATT&CK matrix for containers and the Kubernetes threat matrix. Second, how one attack path through a cluster works step by step, and which Kubernetes control stops each step.

The module has three parts. **Tactics, Techniques And The Kubernetes Matrices** explains what ATT&CK is, lists the tactics of the containers matrix and maps its techniques to Kubernetes objects. **Following An Attack Path** walks one path from an exposed interface to the node, step by step, with a pod that is already compromised. **Breaking The Path** removes each step with RBAC, a service account token setting, a securityContext and a NetworkPolicy, and proves each change with the same attack.

## Learning Goals

- Describe MITRE ATT&CK tactics and techniques and the role of the containers matrix.
- Map Kubernetes attack steps to ATT&CK tactics.
- Explain an attack path through an exposed interface, a stolen service account token, a privileged pod and a hostPath mount.
- Break an attack path with RBAC, `automountServiceAccountToken`, a securityContext and a NetworkPolicy.
- Choose the control that breaks a specific step instead of adding controls at random.

## Before You Start

You need Kubernetes basics: namespaces, pods, Deployments, service accounts and the commands `kubectl get`, `kubectl apply` and `kubectl exec`. A short HTTP request with `curl` is used in the commands.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The default network plugin of `kind` enforces NetworkPolicy. The cluster runs these objects, and the faults are left in place on purpose:

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `shuttle` | A `curl` pod. It is privileged, runs as root, mounts the node directory `/var/log` at `/host-logs` and keeps its service account token |
| `starfleet` | service account `shuttle` | A Role and RoleBinding named `shuttle-secret-reader` let it get and list Secrets |
| `starfleet` | `scout`, `probe` | Backends whose Services listen on port 80 |
| `starfleet` | Secret `fleet-credentials` | The data an attacker wants |
| `outpost` | `drifter` | A client pod that belongs to another team |

You run every command as the cluster administrator. When you act as the attacker, you run the command inside the `shuttle` pod with `kubectl exec`.

## Reading Order

1. Tactics, Techniques And The Kubernetes Matrices
2. Following An Attack Path
3. Breaking The Path
4. Summary

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
