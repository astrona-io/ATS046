# Question

Solve this question on: `terminal`

The platform team must audit the cluster against the CIS Kubernetes Benchmark that kube-bench uses for Kubernetes 1.35, and keep a record of the findings. The namespace `compliance` exists and is empty. Use the image `docker.io/aquasec/kube-bench:v0.16.0`.

1. Run kube-bench as a Job named `kube-bench` in `compliance`. It must check the targets `master`, `node`, `etcd` and `policies` against the benchmark `cis-2.0`, and print JSON. The pod needs the host process namespace and read-only access to the host directories that the checks read. It must run on the control-plane node. Wait until the Job completes.

2. Create a ConfigMap `kube-bench-summary` in `compliance` with one key, `summary.json`. Its value is a JSON array with one object per target (taken from the `node_type` field of the report). Each object has `node_type`, `total_pass`, `total_fail`, `total_warn`, `total_info` and `failed`. The `failed` field is the list of check identifiers with the status `FAIL`. Build it from the log of the Job, not by hand.

3. Some failed checks cannot be fixed by the owner of this assessment, because they need a change to the control plane static pod files. Create a ConfigMap `kube-bench-exceptions` in `compliance` with at least one entry. Each key is the identifier of a check that failed in your report. Each value is a sentence that says why the failure is accepted. Never list a check that did not fail.

`kubectl` already points at the cluster as the cluster administrator.
