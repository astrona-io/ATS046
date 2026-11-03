---
draft: true
exam_objectives:
  - Compliance Frameworks
---
# Compliance Scope And Control Evidence

This module explains how a security goal becomes a control, and how a control becomes evidence that another person can check. It then collects that evidence from a Kubernetes cluster with `kubectl`.

## Learning Goals

- Distinguish a framework, a benchmark, a policy and an evidence record.
- Explain assessment scope, versions, time and shared responsibility.
- Collect evidence for role bindings, service account tokens and privileged containers from the Kubernetes API.
- Record the evidence with its scope, cluster version and time, and explain why it does not prove the absence of risk.

## Before You Start

You should know what a pod, a namespace and a service account are. The hands-on part uses a playground with a kind cluster, `kubectl` and `jq`. Technical terms are defined where they first appear.

## Reading Order

1. Frameworks, Benchmarks, Policies And Evidence
2. Scope, Versions And Shared Responsibility
3. Collecting Control Evidence With kubectl
4. Summary

<!-- astrona:playground -->
