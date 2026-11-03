---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Tactics, Techniques And The Kubernetes Matrices

Teams that defend clusters need a shared vocabulary for attacks. Without it, one report says "the attacker got in through the dashboard" and another says "initial access by an exposed interface", and nobody can compare them. MITRE ATT&CK is the most widely used vocabulary, and this part shows how it is organised and how its container techniques map to Kubernetes objects.

## What ATT&CK is

MITRE ATT&CK (Adversarial Tactics, Techniques and Common Knowledge) is a public knowledge base of how real attackers behave, collected from incident reports. It describes behavior. It does not score risk and it does not prescribe controls. A team uses it to name what an attacker did, to check which behaviors its monitoring can see, and to check which behaviors its controls stop.

ATT&CK has three levels of detail. A **tactic** is the goal of an attacker at one point of an attack, for example getting in or reading credentials. A **technique** is a way to reach that goal, for example using a stolen token. A **sub-technique** is a more specific form of a technique. Each technique has an identifier such as T1190, and each tactic has an identifier that starts with TA.

The knowledge base is split into **matrices** by platform. A matrix is a table: each column is a tactic, and the cells in the column are the techniques that reach that goal. The Enterprise ATT&CK matrices include one for containers. It covers container runtimes and orchestrators, so it applies to Kubernetes, but it is not written only for Kubernetes.

## The tactics of the containers matrix

A tactic is a goal. Read the list as the order in which a typical attack moves, although a real attacker jumps between tactics and repeats some of them.

- **Initial Access** gets the first foothold, for example by exploiting a public-facing application or using valid accounts.
- **Execution** runs the attacker's code, for example with a container administration command or by deploying a container.
- **Persistence** keeps access after a restart, for example with a new account or a scheduled job.
- **Privilege Escalation** gains higher rights, for example by escaping from a container to the host.
- **Stealth** and **Defense Impairment** hide the attack and weaken the defenders' tools. Older descriptions group these under one name, Defense Evasion.
- **Credential Access** steals secrets, for example a service account token or a credential in a file.
- **Discovery** learns the environment, for example which containers and services exist.
- **Lateral Movement** moves to other systems with the stolen material.
- **Impact** causes the final harm, for example resource hijacking for cryptocurrency mining.

The tactic names change between versions of the knowledge base, so check the current matrix when you write a report. The goals stay the same.

## Techniques that map to Kubernetes objects

Each technique corresponds to something that exists in a cluster. The mapping shows where a defender can look and which control can stop it.

| Technique (ID) | Kubernetes object or feature | What the attacker does |
| --- | --- | --- |
| Exploit Public-Facing Application (T1190) | A Service of type `LoadBalancer` or an Ingress | Sends a malicious request to a reachable application |
| External Remote Services (T1133) | An exposed API server, dashboard or kubelet | Uses a remote management interface that has no strong authentication |
| Valid Accounts (T1078) | Service accounts, kubeconfig files | Uses an identity that the API server already trusts |
| Container Administration Command (T1609) | `kubectl exec` | Runs a command inside a running container |
| Deploy Container (T1610) | Creating a pod | Starts a new container with the rights the attacker chooses |
| Unsecured Credentials: Container API (T1552.007) | The service account token and the API | Reads credentials through the container API |
| Steal Application Access Token (T1528) | The token file in the pod | Copies a token that grants API access |
| Escape to Host (T1611) | A privileged container, a hostPath mount | Reaches the node from inside a container |
| Container and Resource Discovery (T1613) | `kubectl get pods`, API list calls | Lists containers and resources |
| Network Service Discovery (T1046) | Flat pod network | Scans for reachable services |
| Resource Hijacking (T1496) | CPU and memory of the pods | Uses the cluster compute for the attacker's work |

You do not need to memorise identifiers. You do need to read a technique name and know which Kubernetes feature it uses.

## The Kubernetes threat matrix

Microsoft published a separate matrix for Kubernetes, in the same table form. It is an older community document that is not part of the MITRE knowledge base, so it uses different tactic and technique names. Its tactics are Initial Access, Execution, Persistence, Privilege Escalation, Defense Evasion, Credential Access, Discovery, Lateral Movement, Collection and Impact.

The Kubernetes matrix names Kubernetes features directly. Its techniques include exposed sensitive interfaces, exec into a container, a new container, a writable hostPath mount, a privileged container, a cluster-admin binding, listing Kubernetes secrets, the container service account, access to the Kubernetes API server, and cluster internal networking. Those names fit the attack in this module almost one to one.

Use both. The ATT&CK matrix is kept up to date by MITRE and is understood by security teams in every field. The Kubernetes matrix is quicker to read for an administrator because it speaks in cluster objects.

## Look at the techniques in the playground

You can see several of these techniques with commands that any identity with enough rights could run. Start with discovery. List the pods in every namespace as the cluster administrator. The command shows what an attacker with the same list rights would also learn:

<!-- astrona:playground:renew -->

```sh
kubectl get pods -A -o wide
```

The output should list the system pods in `kube-system`, the pods in `starfleet` and the pod in `outpost`, with their addresses. This is Container and Resource Discovery. Anyone with the `list` verb on pods gets this view, which is why the verb matters.

Next, check what the service account of `shuttle` is allowed to do. This is the question an attacker asks right after landing:

```sh
kubectl auth can-i --list -n starfleet --as=system:serviceaccount:starfleet:shuttle
```

The list should include `get` and `list` on `secrets`. That right is the technique Unsecured Credentials through the container API. Finally, check the privileges of the `shuttle` container:

```sh
kubectl -n starfleet get deployment shuttle -o jsonpath='{.spec.template.spec.containers[0].securityContext}{"\n"}'
```

The output should show `"privileged":true`. This is the precondition for Escape to Host. Three techniques are available to an attacker who has only one command in `shuttle`, and none of them needs an exploit.

## From a matrix to a model

A matrix is a catalogue, not an attack. Use it to ask a defender's questions. Which techniques can reach my assets from the places where an attacker can start? Which of them do my controls stop? Which of them can I detect? The answers feed the threat model: each technique that works becomes a threat, and each control that stops it becomes a mitigation.

Two limits apply. First, the matrix lists techniques that were seen, so a new technique is missing until someone reports it. Second, a technique can be listed and still not apply to your cluster, for example if no dashboard is installed. The model keeps only the techniques that have a path in your own environment.

You now have the vocabulary: tactics are goals, techniques are methods, and the matrices tie techniques to Kubernetes features. The next question is how techniques chain into one path from the outside to the node.

## Common pitfalls

> [!WARNING]
> ATT&CK describes attacker behavior. It is not a compliance checklist and not a risk score, so covering every technique name does not mean the cluster is safe. Also, do not copy techniques into a model without checking that a path exists in your cluster: a technique that needs a dashboard does not apply to a cluster without one.
