# Question

Solve this question on: `terminal`

This is the Section 010 capstone: one scoped compliance assessment, no step-by-step guidance.

The scope of the assessment is the namespace `orbit` (the Deployments `beacon` and `relay`) and the control plane of this cluster, checked against the CIS Kubernetes Benchmark `cis-2.0`. Run the assessment, fix what you can fix inside the scope, and record the evidence.

1. Run kube-bench as a Job named `kube-bench` in the namespace `audit` (not in `orbit`) with the image `docker.io/aquasec/kube-bench:v0.16.0`. It checks the target `master` for the benchmark `cis-2.0` and prints JSON. It needs the host process namespace and read-only access to the host directories the checks read, and it must run on the control-plane node. Wait until it completes.

2. Control 5.1.1, cluster-admin is only used where required. The service account `beacon-ci` in `orbit` is bound to `cluster-admin`. Remove the grant and keep the service account. It needs no permissions.

3. Control 5.1.6, service account tokens are mounted only where necessary. No running `beacon` or `relay` pod may have a service account token volume.

4. Controls 5.2.2 and 5.2.3, privileged containers and the host process namespace. No pod in `orbit` may have a privileged container or share the host process, IPC or network namespace.

5. Control 5.2.1, at least one active policy control mechanism. `orbit` must enforce the Pod Security level `baseline` (or stricter) so that new privileged and host-sharing pods are rejected. Fix the pods before you enforce.

6. Do not delete or scale down `beacon` or `relay`. Both must stay available with their images.

7. Record the evidence in a ConfigMap `assessment-evidence` in `orbit` with these keys:
   - `scope`: what you assessed, naming `orbit`.
   - `kubernetes-version`: the server version as `kubectl version` reports it.
   - `observed-at`: your last check in UTC, in the form `2026-11-03T10:15:00Z`.
   - `benchmark`: the benchmark name.
   - `master-fail`: the number of failed `master` checks in the report of your Job.
   - `5.1.1`, `5.1.6`, `5.2.1`, `5.2.2` and `5.2.3`: one line each, starting with `PASS` and saying what you observed.

`kubectl` already points at the cluster as the cluster administrator.
