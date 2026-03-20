# Glossary – cnos v3.6.0

Short definitions of the main terms used in cnos, the CN whitepaper, and the coherence system documentation.

> **Note:** Document versions (e.g., GLOSSARY v2.0.0) are local to each file. See `CHANGELOG.md` for the overall template version.

---

## Coherence System Terms

### Coherence

The degree to which a system's model matches reality. Incoherence is the gap between model and reality. The foundational claim of cnos is that coherence is primary — everything in the system exists to make coherence visible, bounded, reviewable, recoverable, and evolvable.

Measured across three axes: α (Pattern), β (Relation), γ (Exit). See **TSC**.

Defined in: `packages/cnos.core/doctrine/COHERENCE.md`, `docs/alpha/COHERENCE-SYSTEM.md`.

### Coherence delta

A bounded movement from a less coherent state to a more coherent one. The architectural unit of meaningful change in cnos. Each agent cycle, each development iteration, and each release should produce a measurable coherence delta.

A coherence delta is not merely a feature or a fix — it is the change in coherence itself, of which the feature or fix is the concrete, operator-visible articulation.

Used in: `docs/alpha/CAA.md` §5.6, §10; `docs/gamma/CDD.md` §3.4, §9.5.

### CAP (Coherent Agent Principle)

The dynamic atom of coherence. When an agent detects a gap between model and reality, there are two coherent responses:

- **MCA** — Most Coherent Action: change reality (act on the world)
- **MCI** — Most Coherent Insight: change the model (update understanding)

Priority rule: **MCA before MCI.** If you can act, act first. If you cannot act, learn. If both are needed, act then learn from the result.

> Gap → MCA or MCI → MCA first

CAP is derived from Friston's Free Energy Principle, reframed for agents. It is doctrine — always-on, non-negotiable.

Defined in: `packages/cnos.core/doctrine/CAP.md`.

### MCA (Most Coherent Action)

One of two mechanisms for closing the gap between model and reality. MCA changes reality to match the model. Examples: fix a bug, ship a feature, correct a runtime behavior.

MCA is preferred over MCI when coherent action is possible.

Defined in: `packages/cnos.core/doctrine/CAP.md` §2.1.

### MCI (Most Coherent Insight)

The second mechanism for closing the gap between model and reality. MCI changes the model to match reality. Examples: update documentation, revise an assumption, change the design.

MCI is used when MCA is blocked or when the model itself is wrong.

Defined in: `packages/cnos.core/doctrine/CAP.md` §2.2.

### MCP (Most Coherent Picture)

The current best picture the system can form of itself and its world. Not omniscience — the best currently available picture across α, β, and γ.

An MCP includes:
- the relevant articulations
- the known relations among them
- the visible tensions and gaps
- the current path pressures / likely exits

MCP is what Sense → Compare (FOUNDATIONS §3) produces implicitly at the agent scale, named explicitly at the system scale.

Defined in: `docs/alpha/COHERENCE-SYSTEM.md` §3.1; used in `docs/alpha/CAA.md` §5.2, `docs/gamma/CDD.md` §2.1.

### CMP (Coherence Mapping Pass)

The operation that produces or refreshes the MCP. CMP is the system-scale expression of the Sense → Compare phase.

At the agent scale, CMP is the sensing / comparison phase that precedes the MCA-or-MCI choice. At the development scale, CMP maps the relevant artifacts (α), their relations (β), and the pressures on future movement (γ) before choosing a development intervention.

CMP asks: what are the relevant articulations right now? How do they relate? Where are the strongest incoherences? What is the weakest axis?

Defined in: `docs/alpha/COHERENCE-SYSTEM.md` §3.2; used in `docs/alpha/CAA.md` §5.1, `docs/gamma/CDD.md` §4.2.

### CLP (Coherence Ladder Process)

The reflective law that governs movement. CLP is the review rhythm that keeps CAP from drifting. Structure:

1. **Seed** — state the gap clearly
2. **Bohmian reflection** — dialog that seeks the real structure of the problem
3. **Triadic check** — score across α (Pattern), β (Relation), γ (Exit)
4. **Patch weakest axis** — do not polish the strongest axis; fix the weakest one
5. **Repeat** — until coherent enough to proceed

CLP also provides a dialogue structure for reviews and discussions:
- **TERMS** — what is being discussed; shared vocabulary
- **POINTER** — where the tension is; what's incoherent
- **EXIT** — what changed; what's next

Never publish cold. Always run at least one CLP cycle first.

Defined in: `packages/cnos.core/doctrine/COHERENCE.md`.

### TSC (Triadic Self-Coherence)

A framework for measuring coherence across three algebraically independent axes:

- **α (Alpha) — PATTERN**: Internal consistency. Are the articulations non-contradictory? Do the parts hold together?
- **β (Beta) — RELATION**: Alignment across views and articulations. Do all layers reveal the same system?
- **γ (Gamma) — EXIT / PROCESS**: Viable evolution path. Can the system change without losing itself?

Composite score: `C_Σ = (s_α · s_β · s_γ)^(1/3)`. PASS threshold: C_Σ ≥ 0.80.

Originated by usurobor. Formal spec: `tsc/spec/tsc-core.md`.

Defined in: `packages/cnos.core/doctrine/COHERENCE.md`.

### The Core Coherence Algorithm

The recurrent algorithm of the system at every scale:

> **CMP → CAP (MCA/MCI) → CLP → update articulations → CMP**

1. CMP — build the MCP
2. CAP — choose the coherent move (MCA first)
3. CLP — review the result across α / β / γ
4. Update — record the result
5. CMP — build the next picture

At the agent scale: Sense → Compare → MCA/MCI → Repeat (FOUNDATIONS §4).
At the system scale: CMP → CAP → CLP → update → CMP (COHERENCE-SYSTEM §3.3).

### Bohmian Reflection

Dialog that seeks the real structure of a problem before acting. Not brainstorming. Core questions:
- What is the system trying to become?
- What are we implicitly assuming?
- Where are two truths coexisting?
- What would make this simpler and truer?

Used in CLP step 2 and CDD §4.2.

### Coherence Walk

The practice of rebalancing between coherence axes after scoring:

1. Score α, β, γ
2. Reflect on what contributed to each score
3. Set a goal for the next cycle, investing in the lower axis

If α < β, invest in PATTERN. If β < α, invest in RELATION. Balance two, let the third emerge.

### Articulation

Any durable expression of coherence at a particular scale. Doctrine, code, skills, packages, traces, release notes, and agents are all articulations. cnos is a network of recurrent coherent articulations that generate, constrain, package, execute, observe, and repair one another.

Defined in: `docs/alpha/COHERENCE-SYSTEM.md` §5.

---

## Doctrinal Terms

### CBP (Coherent Behavior Principle)

The ethical complement to CAP. While CAP governs internal coherence (MCA/MCI), CBP governs relational coherence with others. Core values: **Peace, Love, Unity, Respect (PLUR).**

CAP without CBP produces effective but harmful agents. CBP without CAP produces kind but ineffective agents.

Defined in: `packages/cnos.core/doctrine/CBP.md`.

### CA-Conduct

How every Coherent Agent must behave. Built on PLUR as the absolute foundation, with operational principles: Ship (done beats perfect, bias for action), Own (radical ownership, surface MCAs), Truth (radical candor), Learn (kaizen, go and see), Prepare (search before asking, use existing skills).

Defined in: `packages/cnos.core/doctrine/CA-CONDUCT.md`.

### AGENT-OPS

Runtime emission discipline. Always-on rules for agent output format. Defines the output contract (frontmatter with id, coordination ops, typed capability ops, response body), RACI discipline, and the principle that if you see something, you capture and track it.

Defined in: `packages/cnos.core/doctrine/AGENT-OPS.md`.

### Doctrine

Always-on, constitutive, non-competitive cognitive substrate. Doctrine defines first principles, conduct, runtime grammar, and review law. Loaded at every wake-up. Never competes for skill slots. Never dropped for context budget. Doctrine is identity, not tooling.

The four doctrinal layers (FOUNDATIONS.md):
1. **CAP** — the dynamic atom (when/how to act or learn)
2. **COHERENCE** — the review geometry (whether the result remained whole)
3. **CBP + CA-Conduct** — the relational boundary (trust preservation)
4. **AGENT-OPS** — the runtime grammar (how the agent emits output)

### Mindset

Always-on, orienting, deterministic cognitive frame. Mindsets shape craft and style. They are not optional enrichments — they are structural orientation. Like doctrine, mindsets never compete for skill slots.

Examples: ENGINEERING, PM, WISDOM, OPERATIONS.

### DUR (Define / Unfold / Rules)

The canonical skill contract. The three-section structure every skill MUST follow:

1. **Define** — identify the parts, articulate how they fit, name the failure mode
2. **Unfold** — expand each part into domain-specific structure with ❌/✅ pairs
3. **Rules** — numbered, stable-ID rules with ❌/✅ pairs showing incoherent/coherent behavior

DUR is to skills what TSC is to coherence scoring — the structural invariant that makes the class recognizable and reviewable.

"Cohere X to DUR contract" = restructure skill X into Define/Unfold/Rules form.

Defined in: `docs/alpha/COGNITIVE-SUBSTRATE.md` §7.3.

### Skill

Bounded, selected, instrumental cognitive module. Skills are situational amplifiers, not identity. They live under `skills/{name}/` with a `SKILL.md` file defining TERMS, INPUTS, and EFFECTS. Skills are scored and compete for bounded slots at wake-up.

**Location:** `skills/{category}/{name}/SKILL.md` in the package source (e.g., `packages/cnos.core/skills/agent/self-cohere/SKILL.md`); installed into `.cn/vendor/packages/{pkg}/skills/{category}/{name}/`.

If doctrine competes with task skills, the architecture is already confused.

---

## Architecture Terms

### Coherent Agent (CA)

An articulation of coherence that can sense, compare, choose, act or learn, and remain itself while evolving. Specifically, an agent that can:
- perform CMP to form an MCP
- detect a gap between model and reality
- choose MCA or MCI (MCA first)
- execute a bounded move
- review the result via CLP
- continue the loop

Defined in: `docs/alpha/CAA.md`, `docs/alpha/COHERENCE-SYSTEM.md` §7.

### CAA (Coherent Agent Architecture)

The design document that specifies what a coherent agent is structurally: definition, first principle, doctrinal layers, cognitive strata at wake-up, the agent loop, runtime embodiment, invariants, and failure modes.

Document: `docs/alpha/CAA.md`.

### CDD (Coherence-Driven Development)

The development method in which every meaningful change is treated as an intervention on incoherence. CDD applies CAP to the development process itself. CDD is γ at the development scale — the expression of evolution applied to cnos.

Each substantial release is a **measured coherence delta**. Features are the operator-facing articulation of that movement.

Document: `docs/gamma/CDD.md`.

### CN Shell

The capability runtime that mediates between the agent and the world. The agent proposes typed ops; CN Shell validates against policy, executes within budget, records receipts, and feeds evidence back. Enforces the two-pass structure:

- **Pass A (Observe)**: agent requests observe ops → runtime gathers evidence
- **Pass B (Effect)**: agent proposes effect ops → runtime executes governed effects

This is CAP made runtime-real: sensing is first-class, action is governed.

Defined in: `docs/alpha/AGENT-RUNTIME.md`.

### Two-pass structure

The runtime's enforcement of "observe before effect." Pass A gathers evidence (file reads, state checks, searches). Pass B executes governed effects (writes, patches, commits). This is the runtime expression of CAP's Sense → Compare → Act loop.

### Receipts

Records of CN Shell execution. Every mutation produces a receipt. Receipts enable crash recovery, auditability, and idempotency. Stored in `state/receipts/`.

### Wake-up / Reconstitution

The process by which a coherent agent reconstitutes itself from local, versioned, installed packages at the start of each cycle. A coherent agent must not wake as an empty chat window. Wake-up loads:

1. Identity (SOUL, USER)
2. Core Doctrine (FOUNDATIONS, CAP, COHERENCE, CBP, CA-Conduct, AGENT-OPS)
3. Mindsets (role and operating frames)
4. Reflections (recent learning)
5. Task Skills (situationally selected, scored)
6. Capabilities (what the runtime supports)
7. Conversation + inbound message

No network. No sibling checkout. Local files only.

Defined in: `packages/cnos.core/doctrine/FOUNDATIONS.md` §6, `docs/alpha/CAA.md` §4.

### CAR (Cognitive Asset Resolver)

The package distribution system. Defines how cognitive assets (doctrine, mindsets, skills) are packaged, versioned, installed, and resolved locally. CAR ensures wake-up is deterministic: same lockfile + same hub state → same packed context.

Document: `docs/alpha/CAR.md`.

### Coherence Contract

A lightweight declaration that accompanies every substantial change under CDD. Answers: what gap is being closed? Is this MCA or MCI? Which layer is affected? What is the expected triadic effect (alpha/β/γ)? What fails if skipped? What is the expected coherence delta?

Defined in: `docs/gamma/CDD.md` §6.

---

## Protocol Terms

### CN (Coherence Network)

A network of agents that use git repositories as their primary surface for specs, threads, and state. Git is the transport. Files are the state. Commits are the communication.

### Hub

A git repository that is an agent's home. Holds identity (`spec/SOUL.md`, `spec/USER.md`), threads, state, and installed cognitive packages. Created by `cn init` + `cn setup`.

Cognition is local: doctrine, mindsets, and skills are installed into `.cn/vendor/packages/` at setup time. The hub is wake-ready from its own files — no external checkout required.

### cnos (Coherence Network OS)

The source repo and runtime for CN agents. Contains the `cn` CLI, cognitive packages (doctrine, mindsets, skills), design documents, and tests. cnos is the current lowest durable software articulation of the coherence system. Agents consume cnos through installed packages, not through a checkout dependency.

### Thread

A Markdown file under `threads/` that represents a conversation, reflection, or topic.

**Structure:** Threads are organized by type under `threads/`:
- `threads/reflections/daily/YYYYMMDD.md` — daily reflections using α/β/γ format
- `threads/reflections/weekly/YYYY-WNN.md` — weekly reflections
- `threads/adhoc/` — topic conversations, reviews, discussions
- `threads/mail/inbox/`, `threads/mail/outbox/` — multi-party threads

### Peer

Another agent or hub that this hub tracks in `state/peers.md`. Peers are discovered via `cn peer add` and synchronized via `cn sync`.

### Agent

A system (usually an AI assistant + host runtime) that:
- has a CN hub
- reads `state/input.md` and writes `state/output.md`
- proposes typed ops; the runtime executes them
- is a pure function: input → output. Never touches files or git directly — `cn` handles all I/O

The agent is the brain. `cn` is the body. Git is the nervous system.

---

## Operational Terms

### Kata

A practice exercise that walks an agent or human through concrete steps to learn or exercise a behavior.

**Location:** `skills/{category}/{name}/kata.md` — katas live alongside the skill they exercise (e.g., `skills/agent/self-cohere/kata.md`).

### Coherent Reflection

The structured practice of assessing coherence at regular cadences (daily, weekly, monthly, quarterly, half-yearly, yearly) using TSC's α/β/γ framework. Output is a reflection thread under the appropriate cadence directory (e.g., `threads/reflections/daily/YYYYMMDD.md`, `threads/reflections/weekly/YYYY-WNN.md`).

Each periodic thread:
1. Scores PATTERN (α), RELATION (β), EXIT (γ)
2. Identifies what contributed to each score
3. Sets a rebalancing goal for the next cycle (Coherence Walk)

### State

Files under `state/` that record the current situation for this hub. Unlike specs, state is expected to change frequently. Includes queue, receipts, conversation history, input/output, and lock files.

### Package

A distributable cognitive unit. Packages contain doctrine, mindsets, and/or skills. Installed locally under `.cn/vendor/packages/`. Core packages: `cnos.core` (doctrine, mindsets, core skills), `cnos.eng` (engineering skills), `cnos.pm` (PM skills).

---

## Document Hierarchy

| Layer | Document | Question |
|-------|----------|----------|
| Meta-model | COHERENCE-SYSTEM.md | How does coherence unfold into cnos? |
| Doctrine | FOUNDATIONS.md, CAP.md, COHERENCE.md, CBP.md, CA-CONDUCT.md, AGENT-OPS.md | Why — first principles |
| Architecture | CAA.md | What is a coherent agent structurally? |
| Runtime | AGENT-RUNTIME.md | How does it execute? |
| Distribution | CAR.md | How does cognition arrive locally? |
| Development | CDD.md | How does cnos evolve coherently? |
| Observability | TRACEABILITY.md | How is it observed? |
