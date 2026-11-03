---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Structured Threat Modelling

A threat model is a written description of a system, of what could go wrong with it, and of what the team does about it. A team that writes one before an incident has already decided which requests, identities and data paths it must protect. A team that skips it finds the same facts out during an incident, when the answers cost more.

This module teaches a repeatable process with four steps. You list the assets and draw the data flows, you mark the trust boundaries, you ask the STRIDE questions at each flow, and you pick mitigations and record what risk remains. You run the process on a small application with real faults, and you turn each threat into a Kubernetes control that the cluster enforces.

The module has three parts. **Assets, Data Flows And Trust Boundaries** builds the system description from a running namespace. **Asking The STRIDE Questions** applies the six STRIDE categories to each flow and finds three real threats. **Mitigations And Residual Risk** turns each threat into a RoleBinding change, a NetworkPolicy and a securityContext, then records what remains possible.

## Learning Goals

- Explain a repeatable asset, data-flow and threat analysis process.
- Draw a data-flow diagram of a Kubernetes application with its trust boundaries.
- Use STRIDE categories without treating them as an automatic risk score.
- Relate proposed mitigations to specific trust-boundary failures.
- Describe residual risk and model updates after a design change.

## Before You Start

You need Kubernetes basics: namespaces, Deployments, Services, pods, and the commands `kubectl get`, `kubectl apply` and `kubectl exec`.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The default network plugin of `kind` enforces NetworkPolicy. The cluster runs a small application with faults that are left in place on purpose:

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout` | A backend (podinfo) with a service account that is bound to the `edit` ClusterRole |
| `starfleet` | `probe` | A backend (go-httpbin) whose container is privileged and runs as root |
| `starfleet` | `shuttle`, `caller` | Client pods that run `curl` |
| `outpost` | `drifter` | A client pod that belongs to another team |
| `starfleet` | ConfigMap `scout-config`, Secret `fleet-credentials` | Data in the namespace |

You run every command as the cluster administrator. `kubectl` already points at the playground cluster.

## Reading Order

1. Assets, Data Flows And Trust Boundaries
2. Asking The STRIDE Questions
3. Mitigations And Residual Risk
4. Summary

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
