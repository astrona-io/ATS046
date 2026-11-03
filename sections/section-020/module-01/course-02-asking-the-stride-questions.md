---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Asking The STRIDE Questions

With a tested data-flow diagram in hand, the next problem is what to ask. A team that asks "is this secure?" gets a yes or a shrug. STRIDE replaces that question with six smaller ones, and each of them can be answered with a request, a command or a configuration check.

## The six categories

STRIDE is a mnemonic from the six threat categories. Each category is the opposite of a security property that the system should keep. The category names a way the property can fail.

| Category | Property it breaks | The question to ask |
| --- | --- | --- |
| Spoofing | Authenticity | Can someone act as an identity that is not theirs? |
| Tampering | Integrity | Can someone change data, code or configuration without permission? |
| Repudiation | Non-repudiation | Can someone deny an action because no trustworthy record exists? |
| Information disclosure | Confidentiality | Can someone read data they must not read? |
| Denial of service | Availability | Can someone stop legitimate users from using the system? |
| Elevation of privilege | Authorization | Can someone do more than their identity allows? |

The six words are prompts. They are not a score and they are not a list of threats. A prompt that finds nothing for one flow is a valid result. A prompt that finds a threat starts a conversation about impact and likelihood, which the category cannot answer.

## Which categories apply to which element

Not every category applies to every kind of element, and checking that saves time. A process can be spoofed, tampered with, repudiate an action, disclose information, be denied service and be a way to elevate privilege, so all six apply. A data store can be tampered with, can disclose information and can be denied service, and a store that holds logs can raise repudiation. A data flow can be tampered with, can disclose information and can be denied service. An external entity can be spoofed and can repudiate.

Use the table as a checklist for the diagram, not as a rule that forbids a question. If you are unsure whether a category fits, ask the question anyway and write down the answer.

## What STRIDE does not tell you

STRIDE finds kinds of threats. It does not say how likely a threat is, how much it costs, or which control fits. Those answers come from facts outside the framework: who can reach the flow, what the asset is worth and what the cluster already enforces.

For example, the information-disclosure threat on `probe` is minor if `probe` only returns public test data. It is serious if the same Service later returns customer records. The category is the same in both cases, and only the data changes the priority. This is why the model records the asset next to every threat.

A second limit is completeness. A finished STRIDE pass means every flow got the six questions. It does not mean every threat was found, because a threat that the team cannot imagine is not found by a checklist. Review the model again when a new person joins the review or when the design changes.

## STRIDE on the flow from drifter to probe

Take one flow and ask all six questions. The flow is the HTTP request from the `drifter` pod in `outpost` to the Service `probe`.

Spoofing asks whether `probe` can tell who sent the request. Plain HTTP carries no identity. The only evidence is the source address of the pod, so any pod can pretend to be a trusted client simply by being allowed through. Information disclosure asks what `probe` returns. The go-httpbin service reflects request data, so a caller can read it. Denial of service asks whether one client can flood `probe` and starve `shuttle`. With no limits on connections or requests, it can.

Tampering asks whether the response can be altered in transit. Between two pods on the same node the traffic does not leave the machine, but nothing in this design encrypts it. Repudiation asks whether the request leaves a record that names the caller. The application log of `probe` records addresses, and a pod address changes when the pod restarts. Elevation of privilege asks whether the request lets the sender do more than a client should. A process that handles the request runs with the rights of the `probe` container, which is privileged, so a flaw in request handling gives the attacker much more than the application.

Notice that the same flow produced threats in four categories. The categories also overlap: the privileged container is an elevation-of-privilege threat on the process, and it makes the disclosure and tampering threats more costly. That overlap is normal. The goal is not a perfect label for each threat. The goal is that every flow gets all six questions.

## STRIDE on the service account

Now take the flow that is invisible in the diagram of manifests: the call from a pod to the API server. Each pod receives a token for its service account. The API server accepts the token as the identity `system:serviceaccount:starfleet:scout`, then decides what that identity may do.

Spoofing: a process in `scout` can use the token, so a flaw in `scout` becomes an identity that the API server trusts. Elevation of privilege: the token's rights decide how far the attacker gets. Check what the `scout` identity can do with Secrets and Deployments:

<!-- astrona:playground:renew -->

```sh
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:scout
kubectl auth can-i patch deployments.apps -n starfleet --as=system:serviceaccount:starfleet:scout
```

Both commands should print `yes`. The `scout` application only serves HTTP, so no requirement explains these rights. An attacker with code execution in `scout` can read `fleet-credentials` and change any Deployment in `starfleet`, which also changes which code runs. This is an elevation-of-privilege threat that crosses the service account boundary.

Find which grant causes it. The binding is a RoleBinding, because it applies in one namespace:

```sh
kubectl -n starfleet get rolebindings -o wide
```

The output should show a RoleBinding named `scout-edit` that points at the ClusterRole `edit` and names the service account `scout`. A RoleBinding that points at a ClusterRole gives the rules of that role only in the binding's namespace. The rights are limited to `starfleet`, and still far larger than `scout` needs.

## STRIDE on the container

Finally, ask the questions about the process boundary. A container is a process on the node that the kernel isolates with namespaces and control groups. The `securityContext` of the container sets how much isolation remains. Read it for `probe`:

```sh
kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.containers[0].securityContext}{"\n"}'
```

The output should be a short JSON object with `"privileged":true` and `"runAsUser":0`. A **privileged container** has nearly all the Linux capabilities and can access the devices of the node. Running as user 0 means the process is root inside the container. Together they make a flaw in the `probe` application much more serious: the attacker can leave the container more easily.

This is elevation of privilege again, on a different boundary. The `scout` finding crosses the service account boundary and the `probe` finding crosses the container boundary. Two threats can share a category and still need two different mitigations, so the category never chooses the control. The data flow and the boundary choose it.

## Turn the findings into a threat list

Write each finding in one fixed form: the element or flow, the category, the way it happens, and the asset at risk. The review of this namespace gives three entries:

- Flow `drifter` to `probe`: information disclosure. A pod of another team reads responses of `probe` because no NetworkPolicy restricts the flow.
- Service account `scout`: elevation of privilege. A process in `scout` reads Secrets and changes Deployments through the `edit` ClusterRole.
- Container `probe`: elevation of privilege. A flaw in `probe` runs as root in a privileged container.

The list is not a ranking. Whether the Secret or the node is the more valuable target depends on what the cluster runs, and the model only becomes useful when someone with that knowledge orders the entries by impact and by how easy each path is. You now have three threats. The remaining question is what to change in the cluster for each of them, and what risk is left after the change.

## Common pitfalls

> [!WARNING]
> Do not treat STRIDE as a score. Counting the categories that apply to a flow does not give its risk, and a category that finds no threat is not a failure of the method. Also do not stop at the first threat per flow: one flow often produces threats in several categories, and each category can need a different control.
