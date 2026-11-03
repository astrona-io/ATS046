# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-02/labs/lab-01
```

## Step 1: Read the current state

```sh
kubectl get clusterpolicy disallow-privileged-containers
kubectl -n starfleet get policyreport -o wide
```

The policy shows `Ready` as true. The reports list one entry per resource. The report for the `probe` pod, and for the `probe` Deployment, shows a failed result for the policy. The policy is in `Audit` mode, so it records and does not reject.

## Step 2: Fix probe

```sh
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/securityContext/privileged","value":false}]'
kubectl -n starfleet rollout status deployment/probe
```

The Deployment controller replaces the pod. The new pod passes the policy. An old ReplicaSet may keep a failed result for a while. The grader ignores ReplicaSet entries.

## Step 3: Switch the policy to Enforce

```sh
kubectl patch clusterpolicy disallow-privileged-containers --type=json -p '[{"op":"replace","path":"/spec/rules/0/validate/failureAction","value":"Enforce"}]'
```

The `failureAction` field sits under `validate` in Kyverno 1.19. Wait a few seconds and test with a server-side dry run, which stores nothing:

```sh
kubectl -n starfleet run test-priv --image=curlimages/curl:8.22.0 --privileged=true --dry-run=server
```

The request is rejected, and the message names the policy. The same command with `-n outpost` is accepted, because the policy matches `starfleet` only.

## Step 4: Create the ValidatingAdmissionPolicy and the binding

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-owner-label
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "has(object.metadata.labels) && 'owner' in object.metadata.labels && object.metadata.labels['owner'] != ''"
      message: "Every Deployment must carry a non-empty owner label."
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-owner-label-starfleet
spec:
  policyName: require-owner-label
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: starfleet
```

Save both documents to a file and run `kubectl apply -f` on it. A policy with no binding does nothing, and a binding with `Warn` or `Audit` would not reject. The `namespaceSelector` limits the rule to `starfleet`.

## Step 5: Label the existing Deployments

```sh
for d in scout probe shuttle; do kubectl -n starfleet label deployment "$d" owner=starfleet-ops; done
```

The label goes on the Deployment metadata, which is the object the rule reads. The pods do not restart, because the pod template is unchanged.

## Step 6: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-02/labs/lab-01
```

If a check fails, read its hint. Typical causes: the new probe pod is not yet running, the report has not refreshed, or the binding action is `Warn`.

## Clean up

```sh
astrona destroy ats-046-lab-040-02
```
