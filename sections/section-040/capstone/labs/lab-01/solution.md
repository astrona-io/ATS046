# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/capstone/labs/lab-01
```

Paste the `trivy_scan` helper from the question into your terminal.

## Step 1: Scan

```sh
trivy_scan --severity HIGH,CRITICAL
```

Trivy prints one block for each file (`live/probe.yaml`, `live/scout.yaml`, `live/shuttle.yaml`) with the failed checks. Look for `KSV-0017` in `live/probe.yaml` and `KSV-0014` in `live/shuttle.yaml`. The Deployment `scout` is also listed for the host network setting.

## Step 2: Fix probe

```sh
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/securityContext/privileged","value":false}]'
kubectl -n starfleet rollout status deployment/probe
```

The Deployment controller replaces the pod, and the new pod has no privileged setting.

## Step 3: Find and repair the drift on scout

Write the approved manifest to a file and compare it with the live object:

```sh
kubectl -n tools get configmap approved-manifests -o jsonpath='{.data.scout\.yaml}' > scout-approved.yaml
kubectl diff -f scout-approved.yaml
```

The diff shows a line for `hostNetwork: true` in the live object that the approved file does not have. Other lines may differ because the cluster adds defaults and status fields. Remove the field:

```sh
kubectl -n starfleet patch deployment scout --type=json -p '[{"op":"remove","path":"/spec/template/spec/hostNetwork"}]'
kubectl -n starfleet rollout status deployment/scout
```

The pod is replaced and no longer uses the host network.

## Step 4: Enforce privileged containers with Kyverno

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged-containers
spec:
  background: true
  rules:
    - name: no-privileged
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["starfleet"]
      validate:
        failureAction: Enforce
        message: "Privileged containers are not allowed in starfleet."
        pattern:
          spec:
            =(initContainers):
              - =(securityContext):
                  =(privileged): "false"
            containers:
              - =(securityContext):
                  =(privileged): "false"
```

Save it to a file and run `kubectl apply -f` on it. Kyverno 1.19 can print a deprecation warning for this API version, and the policy is still created. Wait a few seconds, then test with a server-side dry run that stores nothing:

```sh
kubectl -n starfleet run test-priv --image=curlimages/curl:8.22.0 --privileged=true --dry-run=server
```

The request is rejected and the message names the policy. The same command with `-n outpost` is accepted.

## Step 5: Deny the host network with a ValidatingAdmissionPolicy

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: deny-host-network
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "!has(object.spec.template.spec.hostNetwork) || object.spec.template.spec.hostNetwork == false"
      message: "Deployments must not use the host network."
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: deny-host-network-starfleet
spec:
  policyName: deny-host-network
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: starfleet
```

Save both documents to a file and run `kubectl apply -f` on it. The `has()` test protects the lookup when the field is absent. Without the binding the policy does nothing, and with `Warn` it would not reject.

## Step 6: Record the exception for shuttle

Compute a date about 60 days ahead. On GNU systems use `date -d '+60 days' +%Y-%m-%d`, on macOS `date -v+60d +%Y-%m-%d`. Replace `<EXPIRY>` with that date:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: trivy-exceptions
  namespace: tools
data:
  trivyignore.yaml: |
    misconfigurations:
      - id: KSV-0014
        paths:
          - "live/shuttle.yaml"
        statement: "shuttle writes /tmp/last-run; owner starfleet-ops; compensating control: policy blocks privileged and host network"
        expired_at: <EXPIRY>
```

Save it to a file and run `kubectl apply -f` on it. Scan again with `trivy_scan --severity HIGH,CRITICAL`: the finding for `shuttle` no longer appears, and the register holds the reason and the expiry.

## Step 7: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/capstone/labs/lab-01
```

If a check fails, read its hint. Typical causes: the new pod is not yet running, a policy is in `Audit` or `Warn` mode, the binding is missing, or the exception date is too far away.

## Clean up

```sh
astrona destroy ats-046-capstone-040
```
