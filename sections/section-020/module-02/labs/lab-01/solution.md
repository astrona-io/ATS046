# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without being run, so the text describes what you should see instead of showing recorded output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-02/labs/lab-01
```

## Step 1: Remove the Secret access

The `Role` and the `RoleBinding` are both named `shuttle-secret-reader`. Delete them and check the answers:

```sh
kubectl -n starfleet delete rolebinding shuttle-secret-reader
kubectl -n starfleet delete role shuttle-secret-reader
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:shuttle
```

The last command prints `no`. Run `astrona submit --keep`; `shuttle-secrets-unreadable` should pass. Moving the grant to a `ClusterRoleBinding` or binding `view` is the plausible wrong fix: the check still fails.

## Step 2: Remove the token and the node access

Both changes are in the pod template of the `shuttle` Deployment, so one new pod covers them. Save this as `deployment-shuttle.yaml`. It replaces the Deployment from the starting state: the `hostPath` volume, its mount and the `privileged` flag are gone, and the pod has no token.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shuttle
  namespace: starfleet
  labels:
    app: shuttle
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shuttle
  template:
    metadata:
      labels:
        app: shuttle
    spec:
      serviceAccountName: shuttle
      automountServiceAccountToken: false
      containers:
        - name: shuttle
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "while true; do sleep 30; done"]
          securityContext:
            runAsNonRoot: true
            runAsUser: 10001
            runAsGroup: 10001
            allowPrivilegeEscalation: false
            privileged: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: RuntimeDefault
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              memory: 32Mi
```

Apply it and wait for the rollout:

```sh
kubectl apply -f deployment-shuttle.yaml
kubectl -n starfleet rollout status deployment/shuttle
```

Check that the token directory is gone from the new pod. The command fails with a message that the directory does not exist, which is the expected result:

```sh
kubectl -n starfleet exec deploy/shuttle -- ls /var/run/secrets/kubernetes.io/serviceaccount
```

Run `astrona submit --keep`; `shuttle-token-not-mounted` and `shuttle-not-privileged` should pass. If `kubectl apply` warns that the last-applied annotation is missing, run `kubectl replace -f deployment-shuttle.yaml` instead.

## Step 3: Limit the egress of shuttle

An egress policy limits what the selected pods may send. Save this as `networkpolicy-shuttle-egress.yaml`. The first rule allows the `probe` pods on their container port 8080. The second rule allows the cluster DNS pods in `kube-system` on port 53, so the name `probe` still resolves.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shuttle-egress
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: shuttle
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: probe
      ports:
        - protocol: TCP
          port: 8080
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

Apply it:

```sh
kubectl apply -f networkpolicy-shuttle-egress.yaml
```

Then prove it with real requests. The first request must print `200`. The second must print `000` after four seconds:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://probe.starfleet.svc/get
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://scout.starfleet.svc/
```

Run `astrona submit`; all four checks should pass.

## Why this breaks the path

The attack path needs every step. Without the token and the grant, the attacker cannot call the API as `shuttle`. Without `privileged` and the `hostPath` volume, the attacker cannot reach the node from the container. With the egress policy, the attacker cannot use `shuttle` to reach `scout`. Each control stops a different technique, and a mistake in one of them leaves the others in place.
