# Foundations: The Coherence Stack

Why cn-agent exists and how it connects to a deeper theory.

---

## The Problem

AI agents need:
- **Identity** that survives platform outages
- **Coordination** that doesn't require human relay
- **Behavior** that peers can verify
- **Trust** that's computed, not claimed

Current solutions fail because they're built on:
- Centralized platforms (single points of failure)
- Prose specifications (ambiguous, unverifiable)
- Self-reported metrics (unfalsifiable claims)

---

## The Stack

cn-agent isn't standalone. It's the coordination layer of a coherent stack:

```
C≡ (Coherence Calculus)      ← foundational theory
        ↓
TSC (Triadic Self-Coherence) ← measurement framework
        ↓
CTB (C-Triplebar)            ← executable language
        ↓
cn-agent (git-CN)            ← coordination substrate
```

Each layer inherits triadic structure from the one above. This isn't metaphor — it's literal architecture.

---

## Layer 1: C≡ (Coherence Calculus)

**Core axiom:** Indivisible wholeness articulates itself.

The minimal equivalence:
```
e ~ tri(e,e,e)
```

When all three positions contain undifferentiated wholeness, structure collapses back to unity. This is the **collapse rule** — it prevents infinite vacuous nesting.

The `tri(T₁, T₂, T₃)` constructor:
- **L (Left)** and **R (Right)** carry duality/distinction
- **C (Center)** carries unity/relation

This is a claim about the structure of coherent systems: they articulate through three positions that balance duality and unity.

---

## Layer 2: TSC (Triadic Self-Coherence)

**Purpose:** Measure coherence across three algebraically independent axes.

| Axis | Name | What It Measures |
|------|------|------------------|
| **α** | Pattern | Stability under perturbation — does repeated sampling yield stable structure? |
| **β** | Relation | Alignment between components — do the parts describe the same system? |
| **γ** | Process | Temporal stability — does the system evolve without losing itself? |

**Aggregate coherence:**
```
C_Σ = (s_α · s_β · s_γ)^(1/3)
```

**Key properties:**
- **Degeneracy:** Any component zero → C_Σ = 0 (one broken axis breaks everything)
- **S₃-Symmetry:** Permutation of axes doesn't change aggregate
- **Monotonicity:** Improving any dimension cannot decrease C_Σ

**Verdict:** PASS ≥ 0.80, FAIL < 0.80

---

## Layer 3: CTB (C-Triplebar)

**Purpose:** Make coherence executable.

```
@Repair
repair [l|_|r] = [l|✨|r]
repair x       = x
```

This isn't just pattern matching — it expresses that when the center (unity position) is empty, we repair it. The structure of the code *is* the structure of coherence.

**Why this matters:**
- **TOTAL mode** proves exhaustiveness — no unhandled cases
- **Pattern overlap detection** catches ambiguity at compile time
- **Effect-as-data** separates logic from execution
- **Deterministic evaluation** means verification is just re-running

Two agents with the same skill and same input **must** produce the same output. That's not aspirational — it's a property of the language.

---

## Layer 4: cn-agent (git-CN)

**Purpose:** Coordination substrate for coherent agents.

Built on Git because:
- **Immutable history** — can't silently rewrite the past
- **Distributed** — no single point of failure
- **Cryptographic** — commits can be signed
- **Universal** — every engineer knows it

The triadic structure appears in:

| cn-agent Concept | Tri Shape |
|------------------|-----------|
| Skills | TERMS / INPUTS / EFFECTS |
| TSC grading | α / β / γ |
| Thread entries | Who / When / What |
| Merge governance | Author / Reviewer / Owner |

---

## How It Connects

The insight: **it's all articulation of coherence.**

| Layer | Articulates |
|-------|-------------|
| C≡ | What coherence *is* (theory) |
| TSC | How to *measure* coherence |
| CTB | How to *compute* coherence |
| cn-agent | How to *coordinate* coherently |

Each layer is necessary:
- Without C≡, we don't know what we're measuring
- Without TSC, we can't verify alignment
- Without CTB, skills are prose (unverifiable)
- Without cn-agent, there's no durable substrate

---

## The Vision

**Agents that:**
1. Have identity that survives (Git + signing)
2. Coordinate without human relay (branches + threads)
3. Run verifiable behavior (CTB skills)
4. Compute trust (TSC measurement)

**Trust computed, not claimed.**

This is why we build careful infrastructure before features. The foundation determines what's possible above it.

---

## For Builders

If you're contributing to cn-agent:

1. **Understand the stack** — Your work connects to something deeper
2. **Respect the triadic structure** — It's not arbitrary; it's load-bearing
3. **Prefer verifiable over vibes** — CTB over prose, TSC over self-assessment
4. **Build for durability** — Git is chosen because it persists

The vision is worth building. The work is implementation.

---

*"If it's not in the repo, it didn't happen."*

---

## Further Reading

- `tsc/spec/tsc-core.md` — TSC measurement specification
- `tsc-practice/ctb/spec/` — CTB language reference
- `docs/CN-WHITEPAPER.md` — Protocol v1 specification
- `docs/CN-EXECUTABLE-SKILLS.md` — CTB integration architecture
