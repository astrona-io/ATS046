---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Summary

MITRE ATT&CK is a public catalogue of attacker behavior. A tactic is a goal, a technique is a way to reach the goal and a sub-technique is a more specific form. The containers matrix covers container runtimes and orchestrators, and the Kubernetes threat matrix names cluster features directly. Both describe behavior. Neither scores risk nor lists controls, so a defender uses them to ask which techniques have a path in the cluster, which controls stop them and which can be detected.

An attack path is an ordered chain of steps, and every step enables the next. In the example the foothold in a pod gives access to the service account token, the token authenticates to the API server, a Role lets it read Secrets, and a privileged container with a hostPath volume reaches the node. Each step uses an ordinary Kubernetes feature: a token that is mounted by default, a Role that grants too much, a privileged flag and a hostPath volume. A scanner that reports these as separate findings does not show how they connect.

Each step has a control that breaks it. RBAC limits what an identity may do at the API server. The setting `automountServiceAccountToken: false` removes the token from the pod. A securityContext with no privileged flag, no hostPath volume, all capabilities dropped and a numeric non-root user limits the process on the node. A NetworkPolicy limits which pods the process can connect to. The controls act in different components, so none of them replaces another.

Every cut is proved with the request that an attacker would send, and the check reads the running pod because a Deployment can show a new template while the old pod still runs. The foothold remains, and so does the access that the application needs. That remaining risk belongs in the threat model, and the model changes when a new interface, identity or workload adds a new path.

Key facts:

- A tactic is a goal and a technique is a method.
- A valid token with no rights still gets a Forbidden response.
- The pod value of `automountServiceAccountToken` wins over the service account value.
- A NetworkPolicy port is a pod port, and an egress policy needs a DNS rule for names to resolve.

<!-- astrona:playground:destroy -->
