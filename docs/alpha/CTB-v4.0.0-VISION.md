# CTB v4.0.0 — Vision, Design, and Definition

**Project:** Coherent Agents (CA) / git-CN / CTB
**Document type:** Vision + Design Definition (non-normative)
**Version:** 4.0.0
**Date:** 2026-03-22
**Status:** Draft for alignment (intended to guide the next 2–4 major iterations)

---

## 0. Why this document exists

CTB v1.0.x defines a small, deterministic, expression-only language that can *articulate* (not "execute") agent behavior as pure transformations over triadic terms.

This document explains the next step: how CTB evolves from a correct minimal kernel into a **full-blown, adoption-ready language for LLM-driven Coherent Agents**.

"Full-blown" here does **not** mean "general-purpose." It means:

- **Implementable** (reference interpreter/compiler exists)
- **Usable** (tooling + debugging + docs)
- **Verifiable** (determinism, totality profiles, witness diagnostics)
- **Integrable** (effects bridge to real systems: git, filesystem, issues, PRs)
- **Adoptable** (teams can onboard without buying the whole philosophical stack)

---

## 1. Problem statement

LLM agents can already write code, but agent coordination has three persistent failure modes:

1. **Non-determinism and ambiguity**
   - "Same prompt, same repo state" does not guarantee the same action plan.
   - Natural language specs are underdetermined; general-purpose languages are overpowered.

2. **Non-auditable intent vs. action**
   - An agent can claim it followed a policy, but peers cannot cheaply verify it.
   - Git history proves *something* happened, not *why* it was the right move.

3. **Coordination without shared runtime**
   - Different agents run different stacks (Node, Python, local tools).
   - A shared "skills layer" written in Markdown or prose cannot be executed consistently.

**We need a skills substrate where:**

- Skills are **programs**, not prose.
- Programs are **small enough** for LLMs to reliably produce, review, and repair.
- Outputs are **effect plans** (data) rather than immediate side effects.
- Peers can **re-run** the same program and get the same plan.
- Plans can be **verified** and then executed by a separate runtime with explicit capabilities.

---

## 2. Audience and framing

This document is written for:

- **Implementers** building the runtime/toolchain (compiler, interpreter, linter, formatter)
- **Agent architects** designing git-based coordination protocols (git-CN)
- **Early adopters** who want practical value *before* the full stack is finished
- **Skeptical reviewers** evaluating whether CTB adds real leverage vs. "just use Python"

It assumes:

- The **theory stack** exists (Coherence Calculus → TSC → CTB → cn-agent/git-CN)
- The *direction* is "coherence as a computable property," not a vibe

---

## 3. Design goals

### 3.1 Primary goals (must-win)

1. **Determinism**
   - Same inputs → same outputs.
   - No hidden time, randomness, I/O, or ambient state.

2. **Totality as an operational option**
   - A strict profile (TOTAL) where evaluation cannot crash due to match failure.
   - A relaxed profile (PARTIAL) where missing cases are allowed but warned.

3. **Misuse resistance**
   - Ban ambiguous clause overlap (cross-overlap)
   - Prevent semantics changing from line reordering
   - Provide synthesized witnesses when something is incomplete

4. **Separation of logic and effects**
   - CTB program returns an **Effect Plan** (a term).
   - A separate runtime interprets the plan with explicit capabilities.

5. **LLM friendliness**
   - Small surface area, predictable syntax.
   - Canonical formatting.
   - Errors that include counterexamples (witnesses) and suggested repairs.

### 3.2 Non-goals (explicitly not trying to do)

- Replace Python/JS/OCaml for general compute.
- Become a full dependent type theory.
- Make "emoji programming" mandatory; emoji is an allowed atom set, not the language.
- Implicitly grant authority; effects remain capability-gated.

---

## 4. The core model

### 4.1 CTB programs are *equations* over triadic terms

CTB's kernel remains intentionally small:

- **Wholeness**: `_` (value)
- **Atoms**: emoji and symbol tokens (domain-defined)
- **Tri constructor**: `[L|C|R]`

A CTB "skill" is a pure function:

```
skill : State -> EffectPlan
```

Where:

- `State` is data (usually derived from git-CN hub + thread + repo context)
- `EffectPlan` is data (a term that describes intended actions)

### 4.2 Why "plan-as-data" is the unlock

If a skill returns data, then:

- Peers can reproduce and verify the output.
- Tooling can statically lint for dangerous patterns.
- Runtimes can sandbox execution and enforce capabilities.

The runtime becomes a "driver," not the source of truth.

---

## 5. The adoption constraint: why not just use an existing language?

### 5.1 Baseline alternatives

**A) Use general-purpose languages for skills (Python/JS/OCaml)**

- Pros: immediate; libraries; familiar
- Cons:
  - enormous surface area for LLM errors
  - ambient effects and non-determinism
  - difficult cross-agent verification
  - security: arbitrary code execution

**B) Use declarative formats (YAML/JSON) for skills**

- Pros: easy to parse; deterministic
- Cons:
  - weak composability
  - limited abstraction and reuse
  - quickly turns into "YAML programming" with ad-hoc conventions

**C) Use existing total/config languages (Dhall, Nix, Cue)**

- Pros: purity; some totality guarantees; good tooling
- Cons:
  - not designed around triadic articulation
  - ergonomics for LLM authoring are mixed
  - may force a different conceptual stack

**D) Use WASM modules as the skill unit**

- Pros: sandboxing; portable runtime
- Cons:
  - authoring friction (toolchain)
  - LLMs still need to produce source in another language
  - debugging and explainability are worse

### 5.2 CTB's differentiator

CTB aims at a narrow but high-leverage niche:

- A *small*, deterministic, equation-only language
- With built-in conformance constraints that prevent ambiguous meaning
- And with first-class support for "errors as counterexamples" (witness synthesis)

This is specifically tuned for **LLMs writing skills** and **peers verifying skills**.

---

## 6. Proposed solution: CTB as the Skill Language for Coherent Agents

### 6.1 Architectural layers

**Layer 1 — CTB (pure)**

- Parses `.coh` source.
- Evaluates pure equations.
- Produces an output term: `EffectPlan`.

**Layer 2 — Effect Algebra (still pure)**

- A standardized vocabulary of effects encoded as terms.
- Example (illustrative):

```
[WriteFile | [path|content|_] | _]
[GitCommit | [message|files|_] | _]
[Seq | effect1 | effect2]
```

**Layer 3 — Runtime Bridge (impure, capability-gated)**

- Interprets effect terms.
- Executes with explicit capability grants (read-only git, write-files, create PRs, etc.).
- Produces an execution log that can be committed to git-CN.

### 6.2 Determinism boundary

Determinism is guaranteed **above** the runtime boundary:

- CTB evaluation and effect plan synthesis are deterministic.
- Runtime execution is audited and reproducible *in intent*, even if the environment changes.

---

## 7. Implementation strategy (OCaml-first, adoption-aware)

### 7.1 Language design influence vs. implementation language

CTB's surface syntax can feel "Haskell-like" (infix declarations, off-side rule, equational style) without being "based on Haskell."

The reference implementation **should be written in OCaml** if the host project/tooling is already OCaml-based.

Why OCaml works well:

- Pattern matching maps directly onto CTB clause semantics.
- OCaml makes it easier to keep the interpreter small and correct.
- A single static binary can be distributed for CI and local usage.

### 7.2 Multi-runtime posture

To optimize adoption, aim for a two-target posture:

- **Reference:** OCaml interpreter/compiler (correctness + maintainability)
- **Distribution:** one of
  - compiled binary invoked by Node-based tools, or
  - WASM build embedded in Node tools, or
  - a small JS port once semantics stabilize

The decision is tactical; the language semantics stay the same.

---

## 8. Roadmap: CTB v1 → v4

This roadmap is intentionally outcome-driven.

### 8.1 v1.x — "Spec is frozen; prove it runs"

Deliverables:

- Reference interpreter that can run the v1.0.5 conformance suite.
- Canonical formatter (so LLM output can be normalized).
- Effect Algebra v0 (minimal set: read, write, git operations, sequencing).
- One migrated skill from Markdown → `.coh`, with golden tests.

Exit criteria:

- A peer can clone a hub, run `ctb check`, and deterministically reproduce a skill's plan.

### 8.2 v2.0 — "Toolchain and packaging"

Deliverables:

- Module/import system (small and explicit; no dynamic loading).
- Package format (lockfile) with content-addressed references.
- Linter: overlap/totality/witness diagnostics as a first-class CLI.
- Standard library (tiny, curated).

Exit criteria:

- Teams can share and upgrade skills without copy/paste.

### 8.3 v3.0 — "Safety envelope"

Deliverables:

- Capability annotations on effect plans (declare required capabilities).
- Policy checking: deny dangerous capabilities by default.
- Sandboxed runtime bridge with explicit permissions.
- Reproducible "plan hash" (content-addressed plan IDs) for verification.

Exit criteria:

- "Trustless execution": peers can verify the plan hash equals the committed plan before running.

### 8.4 v4.0 — "Language for real agent networks"

Deliverables:

- Stable interoperability with git-CN protocol artifacts (threads/manifests/peers).
- Conformance test suite as a public standard.
- LSP/IDE support focused on LLM workflows (explain errors, synthesize witnesses, propose fixes).
- Signed artifacts (skill packages and/or plan outputs) bound to agent identity.
- Operational telemetry hooks (not for surveillance—only for reproducible diagnosis).

Exit criteria:

- Independent implementers can write a new CTB runtime and still interoperate.

---

## 9. Tradeoffs and explicit choices

### 9.1 Small language vs. expressive language

- **Choice:** keep CTB small.
- **Tradeoff:** some problems require "host language escapes."
- **Mitigation:** host escapes happen only in runtimes, not in CTB.

### 9.2 Totality without a type system

- **Choice:** TOTAL/PARTIAL profiles with syntactic exhaustiveness.
- **Tradeoff:** less precise than typed exhaustiveness.
- **Mitigation:** witness synthesis and runtime logs make failures visible and repairable.

### 9.3 Emoji atoms

- **Choice:** atoms are domain-defined; emoji allowed.
- **Tradeoff:** tooling and fonts vary.
- **Mitigation:** define canonical "ASCII aliases" in tooling and allow dual rendering.

---

## 10. How this lands in git-CN (practical adoption path)

The "minimum credible product" for adoption is:

1. A hub contains a `skills/` directory with `.coh` skills.
2. A thread entry references a skill + input snapshot.
3. Any peer can run:
   - `ctb plan <skill> <input>` → deterministic plan
   - `ctb verify <plan> <commit>` → checks plan matches committed output
4. The runtime bridge executes the plan only if capabilities are granted.

This turns coordination from "I think I did the right thing" to "here's the plan; you can reproduce it."

---

## 11. Success metrics (adoption + coherence)

**Technical:**

- % of skills expressed as `.coh` vs Markdown.
- Deterministic plan reproduction rate across machines/agents.
- Reduction in merge conflicts for thread logs.
- Witness synthesis coverage: % of non-total groups that produce a witness.

**Operational:**

- Mean time for a peer agent to verify another agent's plan.
- Incidents of "semantic drift" (meaning changed without diff) → should trend to ~0.

**Community:**

- Third-party hubs adopting the toolchain.
- Independent runtime implementations passing the conformance suite.

---

## 12. Open questions (intentionally deferred)

- Do we need a lightweight shape/type system for effect plans?
- What is the minimal effect vocabulary that still feels useful?
- How do we represent strings, paths, and blobs canonically while staying minimal?
- What is the cryptographic binding model: signed plans, signed skills, or signed commits only?

---

## Appendix: terminology

- **C≡ (Coherence Calculus):** foundational term algebra and equivalences.
- **TSC:** measurement framework producing coherence scores.
- **CTB:** the programming language used to express executable coherence/skills.
- **Coherent Agent (CA):** an agent identity operating via git-CN substrates.
- **Effect Plan:** pure data describing intended side effects.
