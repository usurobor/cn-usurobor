# KATA-C1

## Capability Growth: Core Built-in vs Extension Architecture

**Kata ID:** C1-capability-growth-boundary
**Family:** Architecture & leverage
**Difficulty:** High
**Failure Family:** A repeated system pressure is being treated as a local feature request instead of a boundary decision.
**Expected Governing Skills (hidden):** design, architecture-evolution, process-economics

---

## Public Task Statement

A new issue asks for:

- network access (HTTP GET, DNS resolve)
- to be available to agents.

There are three serious proposals:

### Option A — Add them directly to core

- easiest short-term path
- new built-in op kinds in the trusted runtime

### Option B — Add a native plugin system only

- in-process OCaml plugin loading
- trusted first-party extension model

### Option C — Introduce a runtime extension architecture

- package-contained extensions
- manifest-driven discovery
- subprocess host by default
- open typed-op registry / dispatch
- Runtime Contract surfaces installed/active extensions

Your task:

1. choose the most coherent architecture direction
2. explain the challenged assumption
3. compare at least three boundary moves
4. state leverage, negative leverage, migration
5. price any added process/complexity

Do not just pick what is easiest today.

---

## Public Context

### Repeated pressure

Past runtime growth has already added:

- more typed ops
- more runtime-specific behavior
- more policy code in core

This issue looks like another "just one more built-in" request.

### Constraints

- wake-up must remain local
- runtime remains the policy decision point
- network access must be configurable and sandboxed
- future capability families may include:
  - browser access
  - device/sensor bridges
  - external APIs
- operator should eventually be able to install new functionality without changing core runtime code

### Additional concern

There is also interest in a future app/marketplace model where:

- cnos core stays minimal
- other capability families are installed later

You do not need to design the full marketplace in this answer.

---

## Public Deliverable

Return:

1. Challenged assumption
2. Boundary moves considered (at least 3)
3. Selected architecture direction
4. Leverage (what becomes easier)
5. Negative leverage (what gets harder)
6. Migration path (phased)
7. Process cost / complexity pricing
8. Non-goals
9. Known debt

---

## Hidden Evaluator Rubric

### α

Strong answer should:

- challenge the assumption that all capability growth belongs in trusted core
- compare real alternatives, not strawmen
- choose a clear boundary move
- keep marketplace concerns separate from runtime extension mechanics

Weak answer:

- picks Option A because "fastest"
- mixes runtime loading, registry, and marketplace into one thing
- introduces many abstractions without responsibility change

### β

Strong answer should align with:

- local wake-time truth
- Runtime Contract surfacing
- policy remaining in core
- extensions as package-contained providers
- bundles/apps and registry as a higher layer, not part of the runtime-extension mechanism

Weak answer:

- treats marketplace as part of runtime loading
- treats extensions as packages without distinguishing them
- collapses capability, package, and app into one concept

### γ

Strong answer should:

- give a migration path, for example:
  - phase 1: manifest + registry + subprocess host + first reference extension
  - phase 2: Runtime Contract / doctor / traceability
  - phase 3: optional ecosystem/marketplace layer
- name what is deliberately not in scope

Weak answer:

- chooses an architecture with no migration story
- or claims everything must be done now

### Hidden Checks

The best answer will likely choose Option C and include:

- subprocess isolation by default
- native plugin as trusted optional backend only
- package-contained extensions
- open op registry/dispatch
- network as first proving extension
- marketplace/registry explicitly separated into a companion layer

### Transfer Variant (hidden)

**Task B:** Replace network access with:

- browser automation
- and a parallel request for an app-store-like ecosystem

Good transfer means the answer:

- still chooses runtime extensions for the capability family
- still separates registry/app ecosystem into a higher layer
- does not collapse the two problems back into one doc or one mechanism
