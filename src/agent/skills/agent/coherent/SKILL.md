# Coherent

Produce outputs where internal consistency and external alignment are verifiable.

## Core Principle

**Coherent output: every part aligns with every other part, and the whole aligns with its sources.**

---

## 1. Define

1.1. **Identify the parts**
  - Claims (what output asserts)
  - Sources (what output derives from)
  - Dependencies (what parts rely on other parts)
  - ❌ Output exists in isolation
  - ✅ Output traces to inputs, parts trace to each other

1.2. **Articulate how they fit**
  - Parts reinforce each other; contradictions are bugs
  - Output reflects sources; drift is failure
  - ❌ "Section A says X, section B says not-X, both seem fine"
  - ✅ "A and B contradict — resolve before shipping"

1.3. **Name the failure mode**
  - Internal incoherence: parts contradict each other
  - External incoherence: output contradicts source
  - Orphan: part exists without connection to whole
  - ❌ Function documented but not implemented
  - ✅ Every documented function has implementation, every implementation has docs

---

## 2. Unfold

2.1. **Coherence levels**
  - L0: Output internally consistent (no contradictions)
  - L1: Output consistent with direct sources (code ↔ spec)
  - L2: Output consistent with transitive sources (spec ↔ upstream spec)
  - ❌ "Code matches spec" but spec contradicts architecture
  - ✅ Check full chain: code → spec → architecture → principles

2.2. **Verification direction**
  - Top-down: Does output satisfy its sources?
  - Bottom-up: Are all parts accounted for in the whole?
  - Cross-check: Do related parts agree?
  - ❌ Only check that code compiles
  - ✅ Check code ↔ tests ↔ docs ↔ spec all align

2.3. **Coherence vs correctness**
  - Coherence: parts align with each other
  - Correctness: parts do the right thing
  - Coherence is necessary but not sufficient
  - ❌ "Code is coherent with spec" (spec is wrong)
  - ✅ "Code is coherent with spec; spec is coherent with requirements"

---

## 3. Rules

3.1. **State TERMS before producing**
  - What sources constrain this output?
  - What must align with what?
  - ❌ Start writing without knowing what success looks like
  - ✅ "This implements PLAN.md §3; must match fn signature in spec"

3.2. **Trace every claim**
  - If you can't point to source, don't include it
  - ❌ "The agent supports 5 commands" (from memory)
  - ✅ "5 commands per PROTOCOL.md §2.1" (verified)

3.3. **Resolve contradictions immediately**
  - Don't ship incoherence; fix or escalate
  - ❌ "Spec says X, code does Y — I'll note it for later"
  - ✅ "Contradiction found — blocking until resolved"

3.4. **Update all related parts**
  - Change propagates; coherence requires completeness
  - ❌ Change function signature, leave callers broken
  - ✅ Change signature → update callers → update tests → update docs

3.5. **Make alignment verifiable**
  - Reader should be able to check coherence
  - ❌ "This matches the spec" (which spec? where?)
  - ✅ "Implements AGENT-RUNTIME-v3.md §4.2 — see fn signature line 42"

3.6. **Orphans are bugs**
  - Every part connects to the whole
  - ❌ Dead code, unused imports, orphan docs
  - ✅ Remove or connect; no dangling parts

---

## 4. Checklist

Before shipping:

- [ ] TERMS stated — sources and constraints named
- [ ] Internal consistency — no contradictions between parts
- [ ] External alignment — output traces to sources
- [ ] Propagation complete — all related parts updated
- [ ] Verification path clear — reader can check alignment

---

## 5. Coherence Modes

| Mode | Focus | When |
|------|-------|------|
| **CLP** (Lab Protocol) | Explore alignment between concepts | Ambiguity, disagreement, design |
| **CAP** (Action Protocol) | Execute with verified alignment | Implementation, clear requirements |

CLP: Find coherence through dialogue.
CAP: Maintain coherence through execution.

When unclear which mode: CLP first, then CAP.

---

## 6. Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| Cargo coherence | "Matches template" without understanding | State why alignment matters |
| Deferred incoherence | "Known issue, will fix later" | Fix now or escalate |
| Surface coherence | Top-level matches, details diverge | Verify at all levels |
| Solo coherence | Internally consistent, externally wrong | Check against sources |
| Implicit alignment | "Obviously matches" | Make explicit, cite source |
