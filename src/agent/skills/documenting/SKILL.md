# Documenting

Write documentation that describes reality, not intentions.

## Core Principle

**Coherent documentation: every claim is verified against source of truth.**

---

## 1. Define

1.1. **Identify the parts**
  - Claim (what the doc asserts)
  - Source (code, spec, or upstream doc)
  - Verification (checking claim against source)
  - ❌ Write from memory or copy from other docs
  - ✅ Check code/spec, then write what you verified

1.2. **Articulate how they fit**
  - Claims describe sources; verification ensures alignment
  - Docs are a view of reality, not a separate truth
  - ❌ "The README says X, so X is true"
  - ✅ "Code does X, so the README should say X"

1.3. **Name the failure mode**
  - Drift: docs say one thing, code does another
  - Propagation: copying stale claims between docs
  - ❌ "Agents push to each other's hubs" (copied from intro, never verified)
  - ✅ "Code shows push-to-self; fixed all docs that said otherwise"

---

## 2. Unfold

2.1. **Source of truth hierarchy**
  - Code > Spec > Docs
  - When they conflict, trust the higher source
  - ❌ Spec says X, code does Y → "spec is authoritative"
  - ✅ Spec says X, code does Y → either fix code or update spec, then align docs

2.2. **Verify before writing**
  - Every claim requires a source check
  - README claims about behavior → check code
  - Architecture claims about protocol → check spec
  - ❌ "The transport works by..." (from memory)
  - ✅ `grep -n "git push" cn_mail.ml` → write what code actually does

2.3. **Verify after editing**
  - Cross-check related docs for consistency
  - Search for same claim in other files
  - ❌ Fix README, leave ARCHITECTURE with old wording
  - ✅ `grep -r "push.*branch" docs/` → fix all occurrences

---

## 3. Rules

3.1. **Trace every claim to source**
  - If you can't point to code or spec, don't write it
  - ❌ "Agents are pure functions that read input.md"
  - ✅ "Agent receives input, produces output — `cn` handles file I/O" (verified against cn_agent.ml)

3.2. **Don't copy between docs without verifying**
  - Other docs may be stale; copying propagates drift
  - ❌ README says X → copy X to ARCHITECTURE
  - ✅ README says X → check code → write verified claim to both

3.3. **Update all occurrences**
  - A claim appears in multiple places; fix all or fix none
  - ❌ Fix one file, leave others inconsistent
  - ✅ `grep -rn "old claim" --include="*.md"` → fix every hit

3.4. **Version and date normative docs**
  - Specs need versions; readers need to know what's current
  - ❌ WHITEPAPER.md with no version header
  - ✅ `**Version:** 2.0.4` at top, updated on every normative change

3.5. **Examples must run**
  - Code blocks are claims; verify them
  - ❌ `cn sync` example that errors on current version
  - ✅ Run the example, paste actual output

3.6. **Remove, don't comment**
  - Dead docs mislead; delete or archive
  - ❌ `<!-- old section, might need later -->`
  - ✅ `git rm` or move to `_archive/`

---

## 4. Checklist

Before committing doc changes:

- [ ] Each new claim traced to code or spec
- [ ] `grep` for same claim in other docs — all consistent
- [ ] Examples tested — they run and output matches
- [ ] No stale references to removed features
- [ ] Version bumped if normative doc

---

## 5. Structure

| Doc | Purpose | Source of truth |
|-----|---------|-----------------|
| README.md | Entry point, quick start | Code (commands, behavior) |
| ARCHITECTURE.md | System overview | Code (modules, flow) |
| WHITEPAPER.md | Protocol spec | Itself (normative) |
| CHANGELOG.md | Version history | Git commits |
| skills/*.md | How-to guides | Code (procedures) |
| mindsets/*.md | Principles | Themselves (normative) |

---

## 6. Style

From `mindsets/WRITING.md`:

6.1. **Short, direct sentences**
  - ❌ "It should be noted that the agent is responsible for..."
  - ✅ "The agent produces output."

6.2. **Concrete facts, no vibes**
  - ❌ "The system is designed to be flexible"
  - ✅ "Supports three transport levels: L0 (PR), L1 (push-to-self), L2 (bundle)"

6.3. **Only claim what you can prove**
  - ❌ "This is the fastest approach"
  - ✅ "Benchmarks show 12ms p99 latency (see perf/results.md)"
