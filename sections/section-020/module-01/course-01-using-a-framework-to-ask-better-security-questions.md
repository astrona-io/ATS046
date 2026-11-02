---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Using A Framework To Ask Better Security Questions

Threat modelling makes assumptions and possible harm explicit before or during system design. A framework supplies a repeatable set of questions, while the actual architecture provides their subject. A template filled with generic threats is less useful than a model that traces real identities, data and interfaces.

## Begin With A System Description

Identify the important assets: report confidentiality, deployment integrity, credentials and service availability. Describe actors, entry points, processes and data stores. Draw how a request and its authority move through the system, including build, administrative and backup paths where relevant.

Trust boundaries mark changes in identity, privilege or assumptions. A public client reaching an application crosses one boundary; the application's service credential reaching a database crosses another. A node administrator controlling container execution occupies a different trust position from an ordinary application user.

Record assumptions such as trusted hosts, protected signing identities and actual network-policy enforcement. These are conditions of the model, not conclusions that follow from a product name. Ask what changes if each assumption fails.

## STRIDE As A Question Set

STRIDE groups threats into Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service and Elevation of Privilege. Spoofing concerns acting as another identity. Tampering concerns unwanted change. Repudiation concerns denying an action when sufficient evidence is lacking. Information disclosure concerns unwanted access to data. Denial of service concerns preventing legitimate use. Elevation of privilege concerns obtaining broader authority.

Apply categories to relevant elements and flows. At an application programming interface (API) boundary, ask whether a stolen identity can act as a legitimate deployer. At a repository, ask whether artifact content or tags can be changed. At an audit store, ask whether evidence can be removed. At a data service, ask which readers can obtain plaintext.

The categories are not a numerical risk score or a guarantee that every threat was found. They help avoid overlooking classes of questions. Impact and likelihood still need the actual environment, authority and consequence.

## Linking A Threat To A Mitigation

Suppose an exposed build credential can publish a harmful image under a trusted tag. Narrow publication rights reduce scope, artifact identity makes selection precise and a trusted verification policy can reject unsuitable content. Pipeline identity separation limits access to deployment authority. These mitigations address different steps of the described path.

For each proposed control, state what it prevents or observes and what remains possible. A signature verifies an accepted publisher's attestation, not absence of application defects. A read-only data role prevents selected writes but still permits disclosure within its read scope. Residual risk is the remaining risk after the chosen controls.

## Reviewing And Maintaining The Model

Prioritize threats using meaningful consequence and feasibility evidence. Assign owners to controls and review decisions. A design change introducing a new external database, helper mount or administrative identity can alter the model even when the main application's source is unchanged.

Retest the assumptions and update the data-flow description when responsibilities or dependencies change. An old diagram can preserve a trust boundary that no longer exists. A useful review identifies changed authority rather than merely updating tool names.

The result should explain a concrete failure path, supported protections and known limits. A framework is valuable because it organizes that reasoning; it does not replace accurate architecture knowledge or control verification.

## Common pitfalls

> [!WARNING]
> STRIDE categories are prompts, not automatic risk rankings. A useful model needs real data flows, authority and assumptions, with mitigations tied to specific failure paths.
