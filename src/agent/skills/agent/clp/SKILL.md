# Coherence Ladder Process (CLP)

Refine any artifact toward higher coherence before publishing, by climbing explicit versions through a triadic self-check loop.

**Upstream:** [tsc-practice/clp/CLP.md](https://github.com/usurobor/tsc-practice/blob/main/clp/CLP.md) v1.1.2

## Core Principle

**Never publish v1.0.0 cold.** Every artifact — spec, doc, skill, design, contract, essay — goes through at least one CLP cycle before it reaches another agent or human. Publish only the latest coherent version.

CLP is a self-process: one agent refining its own artifact. The "others" are anticipated readers, not live participants.

---

## 1. Define

### 1.1. Identify the parts

Every CLP cycle has these parts:

- **Artifact** — the thing being refined (spec, doc, skill, design, contract, essay, review)
- **Version** — semver tag tracking the refinement (v1.0.0 → v1.0.1 → ...)
- **PATTERN (α)** — internal consistency: what is the core claim, is it non-contradictory?
- **RELATION (β)** — how does this place you relative to anticipated readers, system, contracts? Is that stance consistent?
- **EXIT (γ)** — what are the real exits for author and reader? Does the artifact trap anyone without naming it?
- **Weakest axis** — which of α/β/γ needs the most help right now?

- ❌ "Looks good, ship it"
- ✅ "v1.0.0 draft — α is clear, β has a stale cross-reference, γ leaves no migration path. Patch β first."

### 1.2. Articulate how they fit

CLP is coherent when:

- the artifact has a version tag
- each version was checked on all three axes
- the weakest axis was patched first
- the changelog records what changed and why
- the published version is the latest, not the first

- ❌ "I rewrote it a few times"
- ✅ "v1.0.0 → v1.0.1 (clarified EXIT) → v1.0.2 (fixed RELATION with upstream doc) → published v1.0.2"

### 1.3. Name the failure mode

CLP fails through:

- publishing v1.0.0 cold (no refinement cycle)
- patching cosmetically without checking axes
- patching the strongest axis instead of the weakest
- patching forever without publishing (perfectionism trap)
- publishing the full ladder instead of just the latest version

- ❌ "I'll polish it more"
- ✅ "No concrete edit raises coherence — publish this version"

---

## 2. Unfold

### 2.1. Seed

Write the first coherent version and tag it v1.0.0. This is your private seed, not for publishing.

Treat this as PATTERN draft: what are you actually trying to say or do?

### 2.2. Reflect (Bohmian field)

Before scoring, ask:

- What is this text actually doing to the relationship with anticipated readers?
- What tensions exist between what I say I value and what this version rewards or punishes?
- If an anticipated reader mirrored this back, what would they say is "off"?

Write down 1–3 tensions. These guide which axis to patch.

- ❌ "Seems fine"
- ✅ "This spec claims to empower operators but the EXIT section offers no opt-out path"

### 2.3. Triadic self-check

For the current version, name explicitly:

**PATTERN (α):**
- What is the core claim or behavior?
- Is it internally non-contradictory?

**RELATION (β):**
- How does this place you relative to anticipated readers, system, contracts?
- Is that stance consistent with what you claim elsewhere?

**EXIT (γ):**
- What are the real exits for author and reader?
- Does the artifact trap anyone without naming it?

Identify the **weakest axis**.

- ❌ Score all three, patch nothing
- ✅ "α is solid, β drifts from the canonical doc, γ is fine → patch β"

### 2.4. Patch

If you see a coherence problem:

1. Increment the PATCH version (v1.0.0 → v1.0.1)
2. Make a **minimal** edit that improves the weakest axis
3. Record a 1-line changelog
4. Re-run reflection and triadic check on the new version

Repeat until:

- No concrete edit would raise coherence, OR
- You hit the patch limit (e.g. v1.0.9)

If you hit the limit with big problems remaining, it's a MINOR redesign, not more patches.

- ❌ "v1.0.7 — tweaked wording again"
- ✅ "v1.0.3 — still can't fix the β gap without restructuring → bump to v1.1.0"

### 2.5. Version bumps

- **PATCH** (X.Y.Z → X.Y.(Z+1)) — small clarifications, no new structure
- **MINOR** (X.Y.Z → X.(Y+1).0) — new sections/capabilities, backward-compatible
- **MAJOR** (X.Y.Z → (X+1).0.0) — breaking changes, prior commitments no longer hold

CLP lives mostly in PATCH space. Repeated patch-limit hits signal MINOR/MAJOR need.

### 2.6. Publish

- Publish only the latest coherent version
- Include a short changelog, not the full ladder
- Keep the CLP history in your own logs for future inspection

- ❌ "Here's v1.0.0 through v1.0.5 for context"
- ✅ "Published v1.0.5 with changelog: tightened scope, fixed cross-ref, made exit explicit"

---

## 3. Rules

### 3.1. Never publish v1.0.0 cold

Always run at least one CLP cycle before publishing.

### 3.2. Patch the weakest axis first

Do not polish strengths while weaknesses remain.

### 3.3. Minimal patches only

Each patch improves one axis. Do not rewrite the whole artifact in one step.

### 3.4. Stop when no concrete edit raises coherence

Perfectionism is a CLP failure mode. If you can't name a specific improvement, publish.

### 3.5. Changelog is mandatory

Every version increment gets a 1-line changelog entry.

### 3.6. Publish the latest, not the history

Readers get the converged artifact. The ladder is internal.

### 3.7. CLP is a self-process

One agent refining before publication. "Others" are anticipated readers. Multi-agent CLP (live dialogue) is a different protocol.

### 3.8. Feedback seeds new cycles

Feedback received after publication may seed a new CLP cycle on a future version. That's outside the scope of a single CLP run.

---

## 4. Output Pattern

A CLP'd artifact should show:

1. Title with version tag
2. Changelog (short, 1-line per version)
3. PATTERN / RELATION / EXIT summary (explicit or folded into the artifact structure)
4. The content itself

### Example

```markdown
# Extension Registry Spec — v1.0.2

Changelog:
- v1.0.2 — fixed β: aligned rejection reasons with doctor output format
- v1.0.1 — fixed γ: added migration path for existing manifests
- v1.0.0 — initial seed

**Pattern:** Registry rejects duplicate names and op kinds deterministically.
**Relation:** Aligns with runtime-extension design; doctor surfaces rejections.
**Exit:** Migration path for existing manifests; no silent breakage.
```

---

## 5. When to Use CLP

Use CLP when producing:

- specs and design docs
- skills
- essays
- configuration changes (SOUL.md, USER.md)
- issue descriptions and acceptance criteria
- review summaries with verdicts
- any artifact that will be read by another agent or human

Do not use CLP for:

- throwaway scratch work
- commit messages
- chat replies
- mechanical file operations

---

## 6. Relationship to Other Skills

- **design** — CLP refines design artifacts before review
- **review** — review may trigger a new CLP cycle on the reviewed artifact
- **CDD** — CDD artifacts (coherence contract, self-coherence report, post-release assessment) should be CLP'd
- **configure-agent** — SOUL.md and USER.md changes must go through CLP before confirmation

---

## 7. Summary

CLP is:

- seed a version
- reflect on tensions
- check PATTERN / RELATION / EXIT
- patch the weakest axis
- repeat until converged
- publish only the latest version

The loop is small. The discipline is: never publish your first draft.
