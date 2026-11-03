---
draft: true
exam_objectives:
  - Compliance Frameworks
---
# Auditing A Cluster Against The CIS Kubernetes Benchmark

This module runs the CIS Kubernetes Benchmark against a cluster with kube-bench, reads the report and keeps a record of the findings with the exceptions that the team accepts.

## Learning Goals

- Explain what kube-bench reads and why its pod needs host process access and read-only host paths.
- Name the benchmark targets and the four result statuses, and explain why manual checks report `WARN`.
- Extract the failed checks from the JSON report with `jq`.
- Store a summary built from the report and record the failures that the team accepts.

## Before You Start

You should know what a Job, a pod, a taint and a ConfigMap are. The hands-on part uses a playground with a kind cluster, `kubectl` and `jq`. Technical terms are defined where they first appear.

## Reading Order

1. How kube-bench Reads A Cluster
2. Reading kube-bench Results
3. Recording And Excepting Findings
4. Summary

<!-- astrona:playground -->
