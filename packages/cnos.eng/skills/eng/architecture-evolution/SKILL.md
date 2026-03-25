# Architecture Evolution

Change the shape of the system so repeated future work becomes simpler, safer, and cheaper.

## Core Principle

**Coherent architecture evolution reduces repeated future incoherence by changing the system's boundaries, responsibilities, or primitives — not just by polishing one local implementation.**

A good architecture move does at least one of these:

- deletes a recurring class of workaround
- turns repeated core edits into configuration, package, or extension
- strengthens invariants so bad states are harder to express
- makes future changes cheaper across multiple paths, not just today's task

---

## 1. Define

### 1.1. Identify the parts

Every architecture-evolution decision has these parts:

- Pressure — what keeps recurring or resisting local fixes
- Current boundary — where responsibilities live now
- Candidate move — delete / split / invert / isolate / platformize / externalize
- Invariant — what must remain true after the move
- Leverage — what future work becomes easier
- Migration — how the system gets there without incoherent breakage

  - ❌ "We should refactor this"
  - ✅ "This subsystem keeps requiring core edits for every new capability; the candidate move is to externalize capability families into extensions"

### 1.2. Articulate how they fit

Architecture evolution is coherent when:

- the pressure is real and evidenced
- the move changes the right boundary
- the invariants remain or get stronger
- the leverage is broader than the immediate feature
- the migration path is explicit

  - ❌ "This is cleaner"
  - ✅ "This removes repeated core accretion, preserves policy authority in runtime, and turns future capability growth into package installation"

### 1.3. Name the failure mode

Architecture evolution fails through:

- treating repeated structural pressure as isolated bugs
- patching symptoms instead of changing the boundary that generates them
- introducing a new abstraction that adds words but not leverage

  - ❌ "We'll just add one more built-in"
  - ✅ "We've now added the same class of built-in three times; the boundary is wrong"

---

## 2. Unfold

### 2.1. Start from repeated pressure, not novelty

Name the repeated pressure first. Look for:

- the same fix appearing in multiple places
- the same class of issue recurring
- the same policy decision being re-implemented
- the same operator confusion happening across features

  - ❌ Start with the desired feature
  - ✅ Start with the repeating pressure that the feature exposes

### 2.2. Name the architecture assumption you are challenging

State what assumption is no longer serving the system.

Examples:
- "All capabilities belong in core"
- "This module should own both transport and policy"
- "A package is only cognitive substrate, never runtime affordance"
- "This information can be discovered ad hoc at wake"

  - ❌ "We need a cleaner design"
  - ✅ "We are challenging the assumption that all new capability kinds must be hardcoded in the trusted runtime"

### 2.3. Generate boundary moves before picking one

Generate at least three candidate shape moves:

- **delete** — remove the feature/class entirely
- **split** — separate concerns now coupled
- **invert** — move authority/policy up or down a layer
- **isolate** — put risky work behind a stricter boundary
- **platformize** — make the repeated thing a primitive
- **externalize** — move growth into package/extension/config space

  - ❌ Consider only one "obvious" architecture
  - ✅ Compare at least three structurally different moves

### 2.4. Compare local fix vs architecture move

Ask whether the current change is:

- a one-off patch
- a local simplification
- or a platform move that changes future work

A local fix may still be right. But make that explicit.

  - ❌ Present a local patch as architecture
  - ✅ "This is a bugfix, not an architecture move" / "This is an architecture move because it changes the capability growth boundary"

### 2.5. State leverage explicitly

For every candidate move, state:

- what future work becomes easier
- what future work becomes unnecessary
- what future work becomes safer
- what future work becomes harder

Use two sections:
- Positive leverage
- Negative leverage

  - ❌ "This will help later"
  - ✅ "Future network/browser/device capability families no longer require core runtime edits"

### 2.6. Strengthen or preserve invariants

List the invariants that matter after the move.

Examples:
- wake-up stays local
- runtime remains the policy decision point
- output-plane separation remains intact
- operator truth remains reconstructable
- package/source remains single-source-of-truth

  - ❌ "We'll keep things safe"
  - ✅ "The extension host may execute, but it never decides its own authority envelope"

### 2.7. Distinguish layers cleanly

Name what layer the move belongs to:

- doctrine
- architecture
- runtime
- package/distribution
- ecosystem/registry
- operator surface

Refuse category collapse.

  - ❌ "Communication is a capability"
  - ✅ "Communication is a runtime-declared surface/transport subsystem"
  - ❌ "Marketplace belongs in the runtime extension spec"
  - ✅ "Marketplace is the ecosystem layer above runtime extensions"

### 2.8. Choose the smallest coherent move

Pick the move that:

- resolves the pressure
- preserves or strengthens invariants
- creates real leverage
- and does not over-expand scope

  - ❌ Maximal redesign because it feels elegant
  - ✅ The smallest boundary change that removes the repeated future problem

### 2.9. Make migration part of the design

Architecture is incomplete without migration. State:

- what stays compatible
- what is transitional
- what is deprecated
- what is immediate
- what is explicitly later

  - ❌ "Future work"
  - ✅ "Phase 1: manifest + registry + subprocess host. Phase 2: Runtime Contract surfacing. Phase 3: optional registry ecosystem"

### 2.10. Decide whether this should become a primitive

Ask explicitly:

- Should this repeated pattern become a core primitive?
- Or should it become a package, extension, bundle, or config policy?

  - ❌ Add every useful thing to core
  - ✅ Keep core minimal; promote only the load-bearing primitive

---

## 3. Rules

### 3.1. Start from pressure, not preference

Architecture work starts from repeated structural pressure.

  - ❌ "I prefer plugin systems"
  - ✅ "The same capability family has required repeated core edits"

### 3.2. Name the challenged assumption

Every architecture proposal names what assumption it is replacing.

  - ❌ "New design"
  - ✅ "This replaces the assumption that capability growth belongs in trusted core"

### 3.3. Generate multiple boundary moves

Compare at least three structurally distinct moves before selecting one.

  - ❌ Only "add subsystem X"
  - ✅ "Delete / hardcode / extension architecture"

### 3.4. Prefer leverage over local elegance

Choose the move that changes future work, not just today's code.

  - ❌ "This is cleaner in this file"
  - ✅ "This removes future repeated core edits across capability families"

### 3.5. Make invariants explicit

List what must remain true after the architecture move.

  - ❌ "It should still work"
  - ✅ "Wake-up remains local; runtime stays the policy authority"

### 3.6. Separate layers

Do not collapse runtime, package, ecosystem, and operator layers into one concept.

  - ❌ "Registry belongs in the runtime extension mechanism"
  - ✅ "Runtime extension mechanism and registry are separate layers"

### 3.7. State leverage and negative leverage

Every architecture move names both what it improves and what it makes harder.

  - ❌ "This fixes the problem"
  - ✅ "This reduces core accretion, but adds manifest, registry, and doctor complexity"

### 3.8. Treat deletion as a first-class alternative

Sometimes the best architecture move is to remove the thing.

  - ❌ Never consider deletion
  - ✅ "Could we drop this class entirely and simplify the system?"

### 3.9. Make migration concrete

Architecture work must specify how the system gets from here to there.

  - ❌ "We'll migrate later"
  - ✅ "Phase 1 keeps built-ins; Phase 2 proves the extension path; Phase 3 optionally migrates non-core features"

### 3.10. Distinguish platform from product

A product-facing idea is not automatically a runtime primitive.

  - ❌ "Marketplace support belongs inside runtime extension loading"
  - ✅ "Runtime extension loading defines the platform; marketplace sits above it"

### 3.11. Demand evidence for "this keeps happening"

Repeated pressure must be evidenced. Acceptable evidence:

- repeated issues
- repeated edits
- repeated review findings
- repeated operator confusion
- repeated one-off workarounds

  - ❌ "This will probably recur"
  - ✅ "The same class of built-in capability has been added multiple times"

### 3.12. Refuse abstraction without responsibility change

If a proposal adds names but does not move responsibility, it is not architecture evolution.

  - ❌ New wrapper with same ownership model
  - ✅ Responsibility moved from core runtime to package-installed provider with runtime policy retained in core

---

## 4. Output Pattern

A strong architecture-evolution artifact should contain at least:

1. Repeated pressure
2. Challenged assumption
3. Candidate boundary moves
4. Selected move
5. Invariants
6. Leverage
7. Negative leverage
8. Migration
9. Acceptance criteria

### Example shape

```markdown
## Pressure
Repeated core accretion for each new capability family.

## Challenged Assumption
All capability growth belongs in trusted core runtime.

## Candidate Moves
1. Keep hardcoding in core
2. Native plugin loading only
3. Manifest-driven runtime extensions (selected)

## Invariants
- wake-up remains local
- runtime keeps policy authority
- capability authority remains typed

## Leverage
Future capability families become additive.

## Negative Leverage
Introduces registry/manifest/doctor complexity.

## Migration
Phase 1...
```

---

## 5. Relationship to Other Skills

- **design** — this skill goes beyond local subsystem design and asks whether the system boundary itself should move
- **testing** — architecture evolution should increase invariant-proof, not reduce it
- **review** — reviewers should ask whether a higher-leverage architecture move is being missed
- **CDD** — this skill is used when the next coherent move is structural, not merely local

---

## 6. Summary

Architecture evolution is not:

- cleanup
- taste
- bigger refactors
- more abstractions

It is: changing the system boundary so repeated future incoherence becomes less likely, less expensive, or impossible.

Start from repeated pressure. Challenge one architecture assumption. Compare real boundary moves. Choose the smallest coherent move with the highest leverage.
