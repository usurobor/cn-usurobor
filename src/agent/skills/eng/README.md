# Engineering Skills

## Software engineering practices for cnos development

Purpose: Define the engineering skill suite, recommended loading bundles, and the shared meaning of engineering levels used in cnos.

Related:
- docs/gamma/ENGINEERING-LEVELS.md
- docs/gamma/essays/ENGINEERING-LEVEL-ASSESSMENT.md

---

## Core Principle

Engineering in cnos is not just "write code that works." It means:

- make the invariant explicit
- pick the right proof depth
- choose the right system boundary
- price the operational and process cost
- leave behind a more coherent substrate than the one you found

---

## What this directory is for

eng/ contains the skills used when doing engineering work on cnos. These skills are grouped here because they share the same primary activation context:

> load them when building, changing, proving, reviewing, or hardening the system itself

This directory is not an org chart. It is a load-context group.

---

## Skill Index

### Local implementation

Use when writing or changing code directly.

- coding/ - make invalid states harder to express - keep side effects bounded and recoverable
- functional/ - functional design and dataflow discipline
- ocaml/ - OCaml-specific patterns, pitfalls, and conventions
- testing/ - prove invariants, not just examples
- performance-reliability/ - model budgets, saturation, degradation, and recovery

### Design and system-shaping

Use when deciding what the system should look like.

- design/ - name incoherence, constraints, impact graph, and file-level ACs
- architecture-evolution/ - challenge architecture assumptions and choose higher-leverage boundary moves
- process-economics/ - make every new process step earn its cost
- rca/ - explain why the failure happened and what boundary should change

### Review and closeout

Use when validating and finishing work.

- review/ - issue-first evidence-based review
- ship/ - safe closure and landing discipline
- follow-up/ - capture what remains open and what must happen next

### Tooling and operator surfaces

Use when building interfaces or tooling for humans/operators.

- tool-writing/ - build internal tools as stable, reusable system components
- ux-cli/ - CLI/operator experience as an engineering surface

### Authoring engineering knowledge

Use when writing durable engineering artifacts.

- documenting/ - write docs that are authoritative and maintainable

Note: the meta-skill (how to write, classify, and verify skills) lives at the corpus level: `src/agent/skills/skill/SKILL.md`.

---

## Recommended Load Bundles

These are not separate directories. They are the recommended co-load sets for common engineering work.

### 1. Coding bundle

Load when implementing local code changes.

- coding
- functional
- ocaml
- testing
- performance-reliability

### 2. Review bundle

Load when reviewing correctness and coherence of a branch.

- review
- documenting
- testing

### 3. Design bundle

Load when deciding what shape a change should take.

- design
- architecture-evolution
- process-economics

### 4. Runtime / platform bundle

Load when changing runtime, substrate, package, extension, registry, transport, or operator-contract surfaces.

- design
- architecture-evolution
- performance-reliability
- testing
- review

### 5. Tooling bundle

Load when building tools or CLI/operator surfaces.

- tool-writing
- ux-cli
- testing

### 6. Writing bundle

Load when writing docs or skills that will become durable system artifacts.

- documenting
- review
- (meta-skill at top-level skill/SKILL.md when authoring skills)

---

## Which bundle to choose

Use this rule:

### Small local bugfix
Start with:
- coding bundle

### Runtime or substrate change
Start with:
- runtime / platform bundle

### Design-only or architecture decision
Start with:
- design bundle

### Review-only task
Start with:
- review bundle

### Tool / CLI work
Start with:
- tooling bundle

### Docs / skills work
Start with:
- writing bundle

If the work crosses boundaries, say so explicitly and name the active bundle mix.

---

## What "L5 / L6 / L7" means in cnos

The repo should use these labels consistently.

### L5 — local correctness

An L5 engineer can:
- implement a coherent local fix
- follow established patterns
- produce working code with reasonable tests
- improve a system inside the chosen architecture

Typical signal:
- "This works and is reasonably safe."

### L6 — system-safe execution

An L6 engineer can:
- harden behavior across modules and artifacts
- make failure modes explicit and bounded
- keep docs/tests/runtime surfaces aligned
- complete work at a consistent quality bar
- improve the system within the chosen architecture

Typical signal:
- "This system change is coherent, testable, and safe to operate."

### L7 — system-shaping leverage

An L7 engineer can:
- challenge the architecture itself
- choose higher-leverage boundaries
- introduce stronger proof disciplines where they are needed
- price process and operational cost explicitly
- leave behind a platform that makes future work cheaper

Typical signal:
- "This changes the system boundary so a whole class of future work gets easier or disappears."

### The shortest version

- L5 = local correctness
- L6 = system-safe execution
- L7 = system-shaping leverage

See docs/gamma/ENGINEERING-LEVELS.md for the full shared definition.

---

## Default active skills by work shape and level

Levels describe the **scale of impact**. Bundles describe the **work context**. Active skills are the 2–3 hard generation constraints chosen for this specific change (CDD §2.4).

Selection rule:
1. Pick the work-shape bundle first
2. Identify the level of impact (L5 / L6 / L7)
3. Choose 2–3 active skills from the bundle that would most likely prevent the class of mistake this change risks

Review, ship, and post-release are **lifecycle skills** — they govern later CDD phases, not generation. Do not overload CDD §2.4 with lifecycle skills unless the change is specifically about review/release process.

| Work shape | Typical level | Default active skills | Notes |
|------------|---------------|----------------------|-------|
| Local bugfix | L5 | domain skill + testing | e.g. ocaml + testing |
| Cross-module feature | L6 | domain skill + design + testing | Add review as lifecycle, not generation constraint |
| Runtime / platform change | L6–L7 | design + architecture-evolution + testing | Add performance-reliability if load/failure matters |
| Architecture move | L7 | architecture-evolution + process-economics + testing | The L7 lane |
| Tool / CLI | L5–L6 | tool-writing + ux-cli + testing | |
| Docs / skills | L5–L6 | documenting + writing | Add skill/ meta-skill when authoring skills |

These are defaults, not mandates. Override when the specific change warrants it.

---

## How to aim for L7 in cnos

The path from strong L6 to L7 is not "write more code." It is:

- challenge an architecture assumption
- choose a better primitive or boundary
- prove stronger invariants
- model reliability and cost explicitly
- remove or automate process that no longer earns its cost

In practice, that means using these skills more deliberately:

- architecture-evolution
- testing
- performance-reliability
- process-economics

For substantial changes, those are no longer optional background skills. They are the L7 lane.

---

## Relationship to the level assessment essay

ENGINEERING-LEVEL-ASSESSMENT.md is a descriptive assessment of actual work in a period.

This README and ENGINEERING-LEVELS.md are normative:
- they define what the labels mean in cnos
- they define how the engineering skill suite supports those levels

The essay may evolve. The level definitions should remain stable unless deliberately changed.

---

## Summary

Use eng/ when doing engineering work on cnos. Choose a bundle based on the work context. Use L5/L6/L7 consistently:

- L5 — local correctness
- L6 — system-safe execution
- L7 — system-shaping leverage

And for substantial work, do not stop at "make it work." Load the skills that help decide whether the system boundary itself should change.
