# COHERENCE-SYSTEM
## How Coherence Unfolds into cnos

**Version:** 1.0
**Status:** Draft
**Date:** 2026-03-12
**Audience:** Designers, implementers, operators, coherent agents
**Scope:** Defines coherence as the primary principle and cnos as its recurrent articulation across doctrine, architecture, runtime, packages, repository, release, and operation.

---

## 0. Purpose

This document defines the highest-level model of cnos.

It does not begin from:
- the repository
- the runtime
- the agent
- the package system
- the development process

It begins from **coherence** itself.

The claim of this document is:

> **cnos is a recurrent coherence system.**

Everything else in the project is an articulation of that principle at some scale:
- doctrine
- architecture
- skills
- packages
- runtime
- repository
- release
- observability
- agents
- operator workflows

The repository is not the system's essence.
It is the current lowest durable articulation of the system in software form.

---

## 1. First Principle

There is always a possible gap between:

- **model** — what a system believes, expects, or encodes
- **reality** — what the world, runtime, operator, or environment actually is

That gap is the source of incoherence.

The foundational law is the agent-form of the Free Energy Principle:

> **A coherent system minimizes the gap between model and reality.**

In cnos, that law becomes operational through **CAP**:

- **MCA** — act on the world
- **MCI** — update the model
- **MCA first** when action is possible

This is the atomic dynamic of coherence:

> **Gap → MCA or MCI → MCA first**

Everything in cnos exists to make this dynamic:
- visible
- bounded
- reviewable
- recoverable
- evolvable

---

## 2. The Triad

Coherence has three irreducible dimensions.

### 2.1 α — Articulation / Pattern
This is the articulated substance of the system:
- doctrine
- docs
- skills
- code
- packages
- receipts
- traces
- release notes
- agents

α answers:
- what has been made explicit?
- is it internally consistent?
- do the parts hold together as a pattern?

### 2.2 β — Relation
This is the graph of relations among articulations:
- references
- constraints
- dependencies
- package overlays
- runtime composition
- operator understanding
- doc graph
- wake-up composition

β answers:
- do these articulations reveal one system or many fragments?
- does one layer agree with the others?
- does the system stay itself across contexts?

### 2.3 γ — Evolution / Exit
This is the process that moves the system:
- sensing
- review
- release
- migration
- repair
- observation
- iteration

γ answers:
- how does the system evolve?
- what is the next coherent move?
- can it change without losing itself?

---

## 3. MCP and CMP

If CAP is the atomic move, then before acting the system needs the best possible picture of where it stands.

### 3.1 MCP — Most Coherent Picture
The **Most Coherent Picture** is the current best picture the system can form of itself and its world.

It is not omniscience.
It is the best currently available picture across α, β, and γ.

An MCP includes:
- the relevant articulations
- the known relations among them
- the visible tensions and gaps
- the current path pressures / likely exits

### 3.2 CMP — Coherence Mapping Pass
The **Coherence Mapping Pass** is the operation that produces or refreshes the MCP.

CMP is the system-scale expression of the **Sense → Compare** phase defined in
FOUNDATIONS §3. Where Sense → Compare operates within a single agent cycle,
CMP operates across the full articulation graph — α, β, and γ simultaneously.

CMP asks:
- what are the relevant articulations right now?
- how do they relate?
- where are the strongest incoherences?
- what is the weakest axis?
- what can be acted on, and what must be re-modeled?

### 3.3 The core coherence algorithm
The recurrent algorithm of the system is:

> **CMP → CAP (MCA/MCI) → CLP → update articulations → CMP**

In words:

1. **CMP** — build the MCP (system-scale Sense → Compare)
2. **CAP** — choose the coherent move: MCA, MCI, or both (MCA first)
3. **CLP** — review the result: seed → reflect → triadic score → patch weakest axis → repeat until coherent enough to proceed
4. **Update** — record the result in the articulated system
5. **CMP** — build the next picture

This extends the agent-scale loop in FOUNDATIONS §4 (`Sense → Compare → MCA/MCI → Repeat`) to the whole system. CLP is the full review rhythm (COHERENCE.md), not merely a post-move checkpoint.

---

## 4. CLP: The Reflective Law

If CAP is the dynamic atom, **CLP** is the reflective law that governs movement.

CLP:
- seeds the gap
- reflects on it
- scores α / β / γ
- patches the weakest axis
- repeats until coherent enough to proceed

CLP exists because movement alone is not enough.
The system must also inspect:
- whether the move was coherent
- whether it reduced the right gap
- whether it improved the future path

So:

- **CAP** gives the move
- **CMP** builds the MCP
- **CLP** judges the move against the MCP

---

## 5. Articulation Types

Not everything in cnos is an agent.
But everything important is an articulation of coherence.

### 5.1 Doctrinal articulations
These define first principles and boundaries:
- FOUNDATIONS
- CAP
- COHERENCE
- CA-Conduct
- CBP
- AGENT-OPS

### 5.2 Architectural articulations
These define the structural form:
- CAA
- AGENT-RUNTIME
- CAR
- TRACEABILITY
- SECURITY-MODEL
- SCHEDULER
- OUTPUT PLANE

### 5.3 Skill articulations
These define executable local procedures:
- coding
- documenting
- release
- cdd
- domain skills

### 5.4 Runtime articulations
These are operative, stateful expressions:
- package resolver
- scheduler
- CN Shell
- trace stream
- readiness projections
- receipts/artifacts

### 5.5 Package articulations
These are distributable cognitive units:
- `cnos.core`
- `cnos.eng`
- `cnos.pm`
- future org packs

### 5.6 Repository articulations
These are durable software encodings:
- the git tree
- lockfiles
- plans
- tests
- release notes

### 5.7 Agent articulations
A coherent agent is a special articulation because it has:
- a bounded self-model
- the ability to sense
- the ability to choose MCA/MCI
- the ability to act or learn
- the ability to review its own movement

### 5.8 Process articulations
These are coherence processes:
- CDD
- release
- review
- migration
- observation

---

## 6. cnos as a Recurrent Coherence System

cnos is not just "a repo" or "an agent framework."

It is a recurrent system in which coherent articulations:
- generate one another
- constrain one another
- package one another
- execute one another
- observe one another
- repair one another

This recurrence appears at multiple scales.

### 6.1 Inside one agent cycle
- the agent performs CMP → forms the MCP
- CAP chooses MCA/MCI
- the runtime executes under policy
- receipts and traces are emitted
- the next cycle begins from the new articulated state

### 6.2 Inside one development cycle
- the project identifies a gap
- design and plans articulate the fix
- code changes the runtime or model
- release records the coherence delta
- observation feeds the next cycle

### 6.3 Across the whole ecosystem
- packages articulate doctrine and skills
- hubs articulate local identity and overrides
- agents articulate coherent action
- traces articulate runtime truth
- docs articulate system meaning
- releases articulate measured deltas

So cnos is not a static object.
It is a **network of recurrent coherent articulations**.

---

## 7. The Coherent Agent as a Special Case

A coherent agent is one articulation inside the larger coherence system.

Its distinctive property is **agency**.

### 7.1 What makes an articulation an agent
An articulation becomes an agent when it can:
- perform CMP to form an MCP
- detect a gap
- choose MCA or MCI
- execute a bounded move
- review the result (CLP)
- continue the loop

### 7.2 What a coherent agent is
A coherent agent is therefore:

> **an articulation of coherence that can sense, compare, choose, act or learn, and remain itself while evolving.**

This is what `CAA.md` specifies structurally.

---

## 8. Doctrine, Mindsets, Skills

The runtime architecture makes one crucial distinction.
(Full definitions: FOUNDATIONS §5. This section frames the distinction as a
consequence of the coherence hierarchy.)

### 8.1 Doctrine
Always-on, constitutive, non-competitive.
Doctrine defines:
- first principles
- conduct
- runtime grammar
- review law

### 8.2 Mindsets
Always-on, orienting, deterministic.
Mindsets shape craft and style.

### 8.3 Skills
Bounded, selected, instrumental.
Skills are situational amplifiers, not identity.

This is not merely implementation detail.
It is a consequence of the coherence hierarchy:

- doctrine defines the invariant
- mindsets shape the persistent orientation
- skills help with local tasks

If doctrine competes with task skills, the architecture is already confused.

---

## 9. Runtime as Coherent Body

The runtime is the body through which coherent articulation becomes governed
action. (Structural specification: `AGENT-RUNTIME.md`. This section frames the
runtime as the system's coherent body, not a separate concern.)

### 9.1 Direct I/O boundary
The agent's direct I/O is bounded:
- input
- output

This preserves the separation between reasoning and action.

### 9.2 CN Shell
The runtime interprets capability requests post-call.
It preserves:
- no in-call tool loop
- policy gating
- receipts
- recovery
- auditability

### 9.3 Observe before effect
The runtime encodes "sense before act":
- observe
- then effect
- bounded passes
- explicit evidence

That is CAP made operational.

### 9.4 Traceability
The runtime does not merely act.
It must explain itself:
- boot
- readiness
- transitions
- reasons
- projections
- receipts
- artifacts

The body must not be opaque.

---

## 10. Packages as Coherent Substrate

Packages are not just distribution mechanics. (Resolver specification:
`CAR.md`. This section frames packages as the substrate of coherence, not a
deployment detail.)

They are the way cognition becomes:
- local
- versioned
- reproducible
- installed
- persistent across wake-up

The package system means:
- doctrine is not rediscovered
- mindsets are not borrowed ad hoc
- skills are not a nearby checkout accident

This is coherence at the substrate level.

---

## 11. Repository as Lowest Durable Articulation

The repository is important, but it is not primary.

The repository is:

> **the lowest durable software articulation of the coherence system.**

It contains:
- doctrine encodings
- design encodings
- plans
- code
- tests
- package manifests
- release notes
- traces of coherent deltas

But the repository is not the source of coherence itself.
It is the current durable form through which coherence is encoded, evolved, and distributed.

That is why:
- docs matter
- plans matter
- tests matter
- release notes matter
- traces matter

They are not side materials.
They are articulations in the same system.

---

## 12. CDD as γ at the Development Scale

CDD is not the whole system.
CDD is one expression of γ.

Specifically:

> **CDD is γ for evolving cnos itself.**

CDD applies CAP to development:
- identify the gap
- CMP → build the MCP of the current project state
- choose MCA/MCI
- write the design
- plan the move
- test the invariants
- implement
- release
- observe the coherence delta
- repeat

So the same coherence algorithm that governs the agent also governs the project.

This is why a release is not just a feature bundle.
It is a **measured coherence delta**.

---

## 13. Failure Modes

A coherence system must recognize how it can deform.

### 13.1 Doctrinal failure
- first principles missing
- conflicting doctrine
- doctrine treated as optional

### 13.2 Architectural failure
- doctrine, runtime, and packages disagree
- wake-up lacks cognition
- capabilities outrun policy
- docs teach a different system than the code runs

### 13.3 Runtime failure
- no receipts
- no recovery
- hidden side effects
- state transitions without reasons

### 13.4 Package failure
- missing core cognition
- drift between sources and shipped packages
- non-local wake-up dependencies

### 13.5 Process failure
- code before design
- release before coherence
- green CI mistaken for convergence
- no explicit coherence debt

### 13.6 Agent failure
- action before sensing
- MCI when MCA is possible
- no review
- no persistent self-model

---

## 14. The Coherence Gradient

cnos evolves by moving uphill in coherence space.

That does not mean:
- perfect symmetry
- final equilibrium
- no tradeoffs
- no local regressions

It means:
- each cycle should produce a coherence delta
- each release should reduce a named incoherence
- each articulation should fit the graph more truthfully than before

This is not a metaphor only.
It is the operating logic of the system.

### 14.1 CMP at every scale
At every scale, the system should ask:
- what is the MCP right now?
- what is the weakest incoherence?
- what move reduces it?
- what changed after the move?

### 14.2 Release as milestone
A release is a milestone on the coherence gradient:
- not the end state
- not mere feature shipment
- but a bounded articulation of increased coherence

---

## 15. Relationship to Other Documents

### System thesis / Above
- `docs/explanation/THESIS.md` — the public-facing thesis: cnos as a recurrent coherence system

### Doctrine / Why
- `packages/cnos.core/doctrine/FOUNDATIONS.md`
- `CAP.md`
- `COHERENCE.md`
- `CA-CONDUCT.md`
- `CBP.md`
- `AGENT-OPS.md`

### Agent architecture / What the coherent agent is
- `docs/design/CAA.md`

### Runtime embodiment / How it runs
- `docs/design/AGENT-RUNTIME.md`

### Cognitive substrate / How cognition arrives locally
- `docs/design/CAR.md`

### Development method / How cnos evolves coherently
- `docs/design/CDD.md`

This document sits between the whitepaper and the individual design docs:
- the whitepaper defines the thesis for external audiences
- this document defines the meta-model for internal use
- the design docs below define the structural, runtime, and process specifics

### Terminology reconciliation

| This document | Existing term | Source |
|---------------|---------------|--------|
| MCP (Most Coherent Picture) | (implicit in Sense → Compare) | FOUNDATIONS §3 |
| CMP (Coherence Mapping Pass) | Sense → Compare (agent scale) | FOUNDATIONS §3 |
| Core algorithm (§3.3) | Sense → Compare → MCA/MCI → Repeat | FOUNDATIONS §4 |
| CLP (unchanged) | CLP — seed → reflect → triadic check → patch → repeat | COHERENCE.md |
| Coherence delta (unchanged) | Coherence delta | CDD.md, CAA.md |
| α / β / γ (unchanged) | TSC axes | COHERENCE.md |

MCP and CMP are new named concepts. They name what Sense → Compare does
implicitly at the agent scale, made explicit at the system scale.

---

## 16. Summary

Coherence is primary.

From coherence unfold:
- doctrine
- architecture
- runtime
- packages
- repository
- releases
- agents
- traces

CAP gives the atomic move.
CMP builds the MCP.
CLP judges the move.
CDD applies the same law to the project itself.
CAA describes the coherent agent as one special articulation within the larger system.

So cnos is:

> **a recurrent coherence system in which every durable element — doctrine, skill, package, runtime, repo, release, and agent — is an articulation of coherence at a particular scale.**

The repository is the current lowest durable articulation.

The system is the recurrence above it.
