# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout`, `probe` and `shuttle`. Kyverno is installed, and a ClusterPolicy named `disallow-privileged-containers` already exists, but it only audits. The security team wants admission control in `starfleet` that rejects bad requests. `kubectl` points at the cluster as the cluster administrator.

1. The `probe` Deployment runs a privileged container, and the policy reports it. Remove the privileged setting from `probe`. Do not delete or scale down the Deployment. Its pod must run again without the setting.

2. Change the existing ClusterPolicy `disallow-privileged-containers` so that it rejects a privileged pod or a privileged Deployment in `starfleet`. Keep the policy name and the namespace match. The namespace `outpost` must not be affected: a privileged pod there must still be accepted.

3. After the fix, the Kyverno policy report for `starfleet` must show no failed result for this policy on a pod or a Deployment. Old ReplicaSets are not counted.

4. Create a ValidatingAdmissionPolicy named `require-owner-label` and a binding for it. A Deployment without a non-empty `owner` label in its own metadata must be rejected (action `Deny`) in `starfleet`, and must still be accepted in `outpost`. A Deployment with an `owner` label must be accepted.

5. The three existing Deployments would fail the new rule on their next update. Add the label `owner=starfleet-ops` to `scout`, `probe` and `shuttle` (on the Deployment, not only on the pod template). All three must stay available.

Do not change the `outpost` namespace. Do not delete the Kyverno policy.
