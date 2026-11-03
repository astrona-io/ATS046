---
draft: true
exam_objectives:
  - Compliance Frameworks
---
# Summary

kube-bench automates the audit procedures of the CIS Kubernetes Benchmark. It reads the files and processes of the node it runs on, so its pod needs the host process namespace, read-only host paths and a place on the control plane node. The benchmark splits into the targets master, etcd, controlplane, node and policies, and kube-bench picks the benchmark that matches the Kubernetes version. A managed control plane hides the master and etcd targets from the customer.

Each check ends as `PASS`, `FAIL`, `WARN` or `INFO`. A `FAIL` is a finding about a real setting. A `WARN` means that a person must decide, and every check of the policies section is manual, so none of them is a pass. A skipped check shows as `INFO`. The JSON report holds one entry per target with totals and one object per check, and `jq` pulls out the failed identifiers.

A useful record is small, built from the real report by a program, and checkable against the log. It holds the totals and the failed identifiers for each target. Failures that the team cannot fix or chooses to accept become exceptions with a reason, an owner and a review date, and only checks that failed can appear in them. The record is true for the time of the run, and a repeat run shows whether a fix worked.

Key facts:

- kube-bench reads the node and not only the Kubernetes API.
- `WARN` is not a pass, and a skipped check is not an exception.
- A benchmark result covers configuration and does not prove that the cluster is secure.

<!-- astrona:playground:destroy -->
