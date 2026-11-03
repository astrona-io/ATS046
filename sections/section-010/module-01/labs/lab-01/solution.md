# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you fix the controls.

## Step 1: Remove cluster-admin from shuttle

Control 5.1.1 asks where `cluster-admin` is used. List every binding to it with its subjects:

```sh
kubectl get clusterrolebindings,rolebindings -A -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .kind + " " + .metadata.name + " -> " + ([.subjects[]? | .kind + ":" + (.namespace // "") + "/" + .name] | join(", "))'
```

The list has the bindings that every kind cluster has for the groups `system:masters` and `kubeadm:cluster-admins`, and one more for the service account `starfleet/shuttle`. Its name is `shuttle-admin`. Delete only that one and keep the service account:

```sh
kubectl delete clusterrolebinding shuttle-admin
kubectl auth can-i '*' '*' -n starfleet --as=system:serviceaccount:starfleet:shuttle
```

The answer is `no`. Do not replace the binding with `edit` or `view`: the `shuttle` never calls the API, so it needs no role.

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-01/labs/lab-01 --keep
```

The checks `shuttle-cluster-admin-removed` and `shuttle-least-privilege` now pass.

## Step 2: Stop mounting the token in scout and probe

Check which pods mount a token:

```sh
kubectl -n starfleet get pods -o json | jq -r '.items[] | .metadata.name + " token-volumes=" + ([.spec.volumes[]? | select(.name | startswith("kube-api-access"))] | length | tostring)'
```

Every pod has one token volume. Turn the mount off in the pod template of both Deployments and wait for the new pods:

```sh
kubectl -n starfleet patch deployment scout --type=merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
kubectl -n starfleet patch deployment probe --type=merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
kubectl -n starfleet rollout status deployment/scout --timeout=120s
kubectl -n starfleet rollout status deployment/probe --timeout=120s
```

Run the first command of this step again. The pods `scout` and `probe` now show `token-volumes=0`, while `shuttle` still shows 1, which this task does not ask you to change. The check reads running pods, so it fails until the old pods are gone.

## Step 3: Remove the privileged setting from probe

Find the privileged containers in the namespace:

```sh
kubectl -n starfleet get pods -o json | jq -r '.items[] | select(any(.spec.containers[]; .securityContext.privileged == true)) | .metadata.name'
```

Only the `probe` pod is listed. Remove the setting from the Deployment and wait for the rollout:

```sh
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"remove","path":"/spec/template/spec/containers/0/securityContext/privileged"}]'
kubectl -n starfleet rollout status deployment/probe --timeout=120s
```

Run the search again. It prints nothing. Grade it: the checks `token-not-mounted`, `probe-not-privileged` and `workloads-running` pass.

## Step 4: Record the evidence

Read the server version and the time, then use them in the record:

```sh
kubectl version -o json | jq -r '.serverVersion.gitVersion'
date -u +%Y-%m-%dT%H:%M:%SZ
```

Save this as `control-evidence.yaml`, with your own version and time:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: control-evidence
  namespace: starfleet
data:
  scope: "namespace starfleet; workloads scout, probe and shuttle"
  kubernetes-version: "v1.35.8"
  observed-at: "2026-11-03T10:15:00Z"
  "5.1.1": "PASS: no service account in starfleet is bound to cluster-admin"
  "5.1.6": "PASS: scout and probe pods have no service account token volume"
  "5.2.2": "PASS: no pod in starfleet has a privileged container"
```

Apply it:

```sh
kubectl apply -f control-evidence.yaml
```

The value of `kubernetes-version` must be exactly what the first command printed. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-01/labs/lab-01
```

All six checks pass. Clean up with `astrona destroy ats-046-lab-010-01`.
