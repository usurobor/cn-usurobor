# Coherence-Driven Development (CDD)

**Version:** 3.13.0
**Status:** Draft
**Date:** 2026-03-23
**Placement:** γ document (`docs/gamma/`)
**Audience:** Contributors, reviewers, maintainers, release operators
**Scope:** Defines the development method used to evolve cnos coherently

---

## 0. Purpose

This document defines **Coherence-Driven Development (CDD)**:
a development method in which the primary objective is to reduce incoherence across:

- doctrine
- architecture
- implementation
- runtime behavior
- operator understanding
- release state

CDD applies CAP to development itself.

> **A change is good not merely when it is implemented, but when it reduces incoherence across the system as a whole.**

CDD therefore treats each substantial release as a **measured coherence delta**:
not merely a bundle of features, but a specific movement toward greater coherence.
Features are the operator-facing articulation of that movement.

Formalization — writing explicit contracts (specs, schemas, invariants, acceptance criteria) — is how coherence becomes inspectable. The cnos system already practices formalization through doctrine, design documents, and schemas. CDD names the wider method that gives formalization its purpose.

CDD should be read beneath `COHERENCE-SYSTEM.md`, where:
- **MCP** = Most Coherent Picture
- **CMP** = Coherence Mapping Pass
- **CAP** = the atomic move
- **CLP** = the reflective law

CDD is γ at the development scale.

---

## 1. Definition

CDD is a development method in which every meaningful change is treated as an intervention on incoherence.

A change is proposed, reviewed, implemented, tested, and released in terms of:

- what gap exists,
- whether the intervention is MCA or MCI (applied to development — see §2.1),
- how it affects:
  - **α PATTERN** — internal consistency
  - **β RELATION** — alignment with surrounding artifacts and contexts
  - **γ EXIT** — future evolution path

### 1.1 Formalization as core practice

Formalization is the practice of writing coherence down so it can be inspected:

- architecture docs
- schemas
- invariants
- migration rules
- examples
- acceptance criteria

Without formalization, coherence cannot be tested. Contradictions stay implicit, tests become local-only, reviews become taste-based, and runtime drift hides until late.

But formalization alone does not guarantee relational coherence across docs, operator readiness, doctrine/runtime alignment, release integrity, or evolution clarity. That is why CDD is broader than any single formal practice.

---

## 2. First Principle

CDD begins from the same first principle that governs the coherent agent (FOUNDATIONS.md):

> **There is a gap between model and reality.**

In development terms:

- the **model** is doctrine, architecture, design, operator understanding, and intended behavior
- **reality** is code, runtime behavior, logs, failures, and actual operator experience

That gap is development incoherence.

### 2.1 CAP applied to development

CDD applies CAP to the development process. The mechanism is the same — MCA or MCI, MCA first — but the scope shifts:

| CAP (agent runtime) | CDD (development process) |
|---------------------|--------------------------|
| MCA: act on the world | MCA: change the system (code, config, runtime) |
| MCI: update the model | MCI: change the design (docs, assumptions, specs) |
| Reality: external world | Reality: code, runtime behavior, operator experience |
| Model: agent beliefs | Model: doctrine, architecture, design docs |

The priority rule holds:

> **Prefer MCA when coherent action is possible.
> Use MCI when the model is wrong or action is blocked.**

Examples:
- Runtime behavior wrong, docs correct → MCA (fix the code)
- Docs wrong, runtime correct → MCI (fix the docs)
- Both wrong → MCA + MCI, smallest coherent intervention

Before choosing MCA or MCI, development must perform a **CMP**:
construct the **MCP** of the current project state by mapping:
- the relevant artifacts (α)
- their relations (β)
- the pressures on future movement (γ)

### 2.2 Boundary with CAP

CDD governs how humans and agents develop the system.
CAP governs how the agent operates at runtime.

CDD uses CAP's vocabulary because the underlying dynamic is the same: detect a gap, close it through action or learning. But CDD is not CAP. CAP is doctrine. CDD is a design-level method that applies doctrine to the development process.

---

## 3. What CDD Optimizes For

CDD does not optimize primarily for speed, novelty, local elegance, or green CI alone.

CDD optimizes for:

### 3.1 α PATTERN — internal consistency

The change should not introduce contradiction, duplication, or conceptual drift.

- Are terms used consistently?
- Do examples match norms?
- Does the code reflect the spec?
- Does the spec reflect the actual system?

### 3.2 β RELATION — alignment across the system

The change should make surrounding artifacts reveal the same system.

- Do README, design docs, code, runtime behavior, and operator experience agree?
- Do setup, runtime, and security form one story?
- Does the agent-facing instruction surface match the runtime ABI?

### 3.3 γ EXIT — coherent evolution path

The change should improve the future, not just the present.

- Is migration clear?
- Are versioning and lockfiles stable?
- Can the system evolve without special-case accretion?
- Did we reduce future incoherence?

### 3.4 Coherence delta as the release unit

A release is not judged only by the features it contains.
Under CDD, a release is judged by the **coherence delta** it produces.

This means every substantial change should answer:

- What incoherence was reduced?
- Along which axis or axes (α / β / γ)?
- What concrete feature, fix, or refactor articulated that reduction?
- What coherence debt remains?

Features still matter. They are how users and operators experience the change.
But in CDD they are understood as the **concrete articulation of a movement through coherence space**, not the sole unit of value.

---

## 4. The CDD Review Loop

CDD uses CLP as its review structure. Two aspects of CLP apply:

### 4.1 CLP as dialogue structure (TERMS → POINTER → EXIT)

Every significant review, whether in a thread, a PR, or a design discussion, uses:

- **TERMS** — what is being discussed; shared vocabulary
- **POINTER** — where the tension is; what's incoherent
- **EXIT** — what changed; what's next

This is the dialogue form from COHERENCE doctrine.

### 4.2 CLP as refinement loop (CMP → Seed → Reflect → Check → Patch → Repeat)

Every substantial artifact undergoes iterative refinement:

1. **CMP** — build the current MCP. What are the relevant articulations? How do they relate? Where is the real incoherence? Which axis is weakest?

2. **Seed** — state the gap clearly. What is incoherent? At which layer? What is the smallest coherent intervention?

3. **Bohmian reflection** — dialog that seeks the real structure of the problem. Not brainstorming. Questions: What is the system trying to become? What are we implicitly assuming? Where are two truths coexisting? What would make this simpler and truer?

4. **Triadic check** — score the change across α PATTERN, β RELATION, γ EXIT.

5. **Choose MCA / MCI** — given the MCP and triadic assessment: choose MCA if the system should change, MCI if the model should change, both when required (MCA first when action is coherent and possible).

6. **Patch weakest axis** — do not polish the strongest axis. Fix the weakest one.

7. **Repeat until threshold** — stop when the design is coherent enough to implement. Do not implement into unresolved conceptual fog.

These two aspects are compatible: the TERMS/POINTER/EXIT structure gives form to each step in the refinement loop.

---

## 5. The Development Pipeline

### 5.0 Branch rule

Every substantial feature or change MUST be developed on its own dedicated branch (per AGILE-PROCESS.md §Lifecycle). No work is performed directly on `main`.

#### Branch naming

The canonical branch name format is:

```
{agent}/{version}-{issue}-{scope}
```

| Segment | Required | Description | Example |
|---------|----------|-------------|---------|
| `{agent}` | Yes | The actor performing the work | `claude`, `sigma`, `pi` |
| `{version}` | When known | Target cnos release version | `3.14.0` |
| `{issue}` | Yes | Issue number from the tracker | `62` |
| `{scope}` | Yes | Short kebab-case topic | `agent-runtime` |

Examples:
- `claude/3.13.0-75-docs-governance`
- `sigma/3.14.0-42-actor-model`
- `pi/58-packages-sync`

**Tooling suffixes.** Some CI or automation systems append session identifiers to branch names (e.g., `-PfdYZ`). These are transport artifacts, not part of the logical branch name. Reviews, commit messages, and documentation SHOULD reference the branch by its logical name without the suffix.

### 5.1 Pipeline steps and deliverable artifacts

Each step in the pipeline produces concrete artifacts. The table below defines what MUST exist at the end of each step before moving to the next.

| # | Step | Deliverable artifacts | Location |
|---|------|-----------------------|----------|
| 0 | **Bootstrap** | Version directory with stub files for every artifact the **target bundle** will produce for this version. Includes `README.md` (snapshot manifest) and one stub per deliverable. If a branch touches multiple bundles, each bundle that will receive a frozen snapshot gets its own version directory. Artifacts that live outside version directories (PR body files, navigation docs, bundle READMEs) are not enumerated in the bootstrap stubs. | `docs/{tier}/{bundle}/vX.Y.Z/` |
| 1 | **Design** | Design doc or design section in the spec stub. States the structural decision and its triadic justification. | Version dir or `docs/alpha/` |
| 2 | **Coherence contract** | Gap, mode, scope, expected triadic effect, failure-if-skipped (§6). May live in the PR body, a dedicated file, or a header block in the spec. | PR body file or spec header |
| 3 | **Plan** | Implementation plan: ordered steps, dependencies, risk boundaries, compile-safe increments. | `docs/gamma/plans/PLAN-vX.Y.Z-{scope}.md` or version dir |
| 4 | **Tests** | Test files that pin invariants, schemas, edge cases, and regressions. Tests SHOULD be written before the code they validate. | `tests/` or co-located `__tests__/` |
| 5 | **Code** | Source code that realizes the design. Code does not invent architecture — it implements the plan. | `src/`, `packages/`, or relevant source dirs |
| 6 | **Docs** | All affected documentation updated to match the implementation. Bundle README, spec, directory maps, and navigation surfaces reflect the new state. | `docs/`, bundle READMEs, `docs/README.md` |
| 7 | **Release** | CI green, version bumped, CHANGELOG entry, release notes stating the coherence delta and known debt. Frozen snapshot in the version directory (stubs replaced with final content). **Self-coherence report** (see §7.8) in the version directory. | Version dir (frozen), `CHANGELOG.md`, release notes, `SELF-COHERENCE.md` |
| 8 | **Observe** | Runtime telemetry or manual verification confirming design/implementation alignment. Observation results recorded. | Telemetry logs, post-release assessment |

**The first diff on the branch MUST be step 0 (Bootstrap).** This forces the author to name the version and enumerate deliverables before writing content.

**Frozen snapshot semantics.** After step 7, version directories are governed by the freeze policy in DOCUMENTATION-SYSTEM.md §2.9/§4. Contents MUST NOT be modified — with one exception: path references (backtick paths, markdown links) MAY be updated when the target file has moved, so that references remain resolvable. No semantic content may change.

Steps 1–3 may be collapsed into a single commit for small changes. Steps 4–6 typically span multiple commits. Step 7 is the final commit before merge. Step 8 happens after merge.

**Before requesting review:** the branch MUST be rebased on `main`. Reviewer time is more valuable than author time (per RULES.md). A branch that is not rebased MUST NOT be submitted for review.

### 5.2 Rationale

The bootstrap-first rule and per-step artifact expectations serve three CDD purposes:

- **α** — naming the version and enumerating deliverables up front prevents scope drift and forces internal consistency from the first commit
- **β** — the version directory and its stubs are immediately visible to reviewers and CI, establishing the branch's relation to the rest of the repo before any content is written
- **γ** — the stub structure is the skeleton of the frozen snapshot; filling it in is the development path, freezing it is the release

### 5.3 Small-change exception

If a change is too small to warrant a version directory (e.g., a one-line fix, a typo correction), the bootstrap step does not apply. The coherence contract can be carried in the commit message alone (see §12).

### 5.4 Relationship to AGILE-PROCESS.md

The workflow states (Backlog → Claimed → In Progress → Review → Done) defined in `docs/gamma/cdd/AGILE-PROCESS.md` govern how work moves through the team. CDD governs what coherence means at each stage:

| Agile state | CDD concern | Pipeline steps |
|-------------|-------------|----------------|
| Backlog | Gap identified, prioritized by coherence impact | — |
| Claimed | Branch created, version dir bootstrapped | 0 |
| In Progress | Design → contract → plan → test → code → docs | 1–6 |
| Review | Triadic check (α/β/γ), CLP dialogue | — |
| Done | Release criteria met (§9), snapshot frozen | 7–8 |

CDD does not replace the agile workflow. It defines the quality function the workflow optimizes for.

---

## 6. The Coherence Contract

Every substantial change SHOULD carry a coherence contract.

A coherence contract answers:

### 6.1 Gap
What incoherence is being reduced?

### 6.2 Mode
Is this MCA or MCI? (In the development sense — see §2.1)

### 6.3 Scope
Which layer is affected?
- doctrine
- architecture
- runtime
- packaging
- operator surface
- release process

### 6.4 Expected triadic effect
- α: what internal contradiction is reduced?
- β: what relation is aligned?
- γ: what future path is clarified?

### 6.5 Failure if skipped
What incoherence persists if we do nothing?

### 6.6 Expected coherence delta
What measured movement do we expect this change to produce?

At minimum:
- starting α / β / γ assessment
- intended weakest-axis improvement
- expected end state after release

This does not require false precision.
It does require that the release be understood as a movement, not just an output.

---

## 7. Artifacts Used by CDD

CDD uses the standard cnos artifact set.

### 7.1 Doctrine artifacts
- `packages/cnos.core/doctrine/FOUNDATIONS.md`
- `packages/cnos.core/doctrine/CAP.md`
- `packages/cnos.core/doctrine/COHERENCE.md`
- `packages/cnos.core/doctrine/CBP.md`
- `packages/cnos.core/doctrine/CA-CONDUCT.md`
- `packages/cnos.core/doctrine/AGENT-OPS.md`

Role: define first principles and normative boundaries.

### 7.2 Design artifacts
- `docs/alpha/agent-runtime/CAA.md`
- `docs/alpha/agent-runtime/AGENT-RUNTIME.md`
- `docs/alpha/cognitive-substrate/CAR.md`

Role: define the structural system.

### 7.3 Process artifacts
- `docs/gamma/cdd/AGILE-PROCESS.md`
- `docs/gamma/rules/RULES.md`
- `CHANGELOG.md`

Role: define workflow, governance, and release procedure.

### 7.4 Implementation plans
- Feature-specific plans in `docs/gamma/plans/` (e.g., `PLAN-vX.Y.Z-{scope}.md`)

Role: define build order and scope.

### 7.5 Tests
Role: pin invariants and executable truth.

### 7.6 Release notes
Role: explain the coherence delta to operators and contributors.

### 7.7 Runtime telemetry
Role: expose whether the actual running system matches the design.

### 7.8 Self-coherence report

Every substantial release SHOULD include a `SELF-COHERENCE.md` in its version directory. This artifact records the branch author's own CDD-compliance assessment before requesting review.

**Required format:**

```markdown
# Self-Coherence Report — {branch logical name}

**Version:** {cnos version}
**Date:** {date}
**Author:** {agent or contributor}

## Pipeline compliance

| # | Step | Status | Evidence / artifact |
|---|------|--------|---------------------|
| 0 | Bootstrap | {done/partial/skipped/n-a} | {path or note} |
| 1 | Design | ... | ... |
| ... | ... | ... | ... |

## Triadic assessment

| Axis | Score | Rationale |
|------|-------|-----------|
| α Pattern | {A-D} | {one sentence} |
| β Relation | {A-D} | {one sentence} |
| γ Exit | {A-D} | {one sentence} |

## Checklist pass

Which checklists were applied and what was the outcome:
- [ ] engineering
- [ ] documenting
- [ ] functional (if code changes)
- [ ] testing (if code changes)

## Known coherence debt

| Item | Severity | Note |
|------|----------|------|
| ... | ... | ... |

## Reviewer notes

Anything the reviewer should pay attention to; unresolved tensions; open questions.
```

**Placement:** `docs/{tier}/{bundle}/vX.Y.Z/SELF-COHERENCE.md`

**When to omit:** Small changes covered by the §5.3 exception do not require a self-coherence report. The coherence contract in the commit message or PR body is sufficient.

Role: make the branch author's coherence assessment inspectable before review. Prevents the reviewer from having to reconstruct compliance from commit history alone.

---

## 8. Runtime and Operations Are Part of CDD

CDD does not stop at merge.

A system can be well-designed and still be incoherent in operation.

### 8.1 Structural coherence telemetry
The system should expose:
- doctrine loaded?
- packages installed?
- mindsets loaded?
- capabilities rendered?
- transport ready?
- state = ready / degraded / blocked?

### 8.2 Transition traceability
Operators must be able to answer:
- why did it go here?
- why did it not go there?
- what evidence was used?
- what was denied and why?

### 8.3 Release gates
A release is not coherent if:
- docs disagree with code
- runtime cannot explain itself
- setup story differs from security story
- an operator cannot determine readiness

---

## 9. Release Criteria Under CDD

A change is releasable when:

### 9.1 α is acceptable
- no major internal contradictions remain
- examples and norms align
- naming is stable

### 9.2 β is acceptable
- docs, runtime, code, and operator story agree
- no stale worldview remains in agent-facing instructions

### 9.3 γ is acceptable
- migration path is clear
- versioning is explicit
- future evolution is not cornered by the current fix

### 9.4 Operational visibility exists
- boot/readiness can be determined
- failure modes are visible
- major transitions have reason codes

### 9.5 The release's coherence delta is explicit
The release should state:
- which incoherence it primarily reduced
- what changed as its concrete articulation
- what coherence debt remains

This can be carried in release notes, a changelog TSC table, or equivalent release metadata.

---

## 10. Failure Modes of Development

CDD defends against these failures:

### 10.1 Spec-free implementation
Coding before the design has stabilized.

### 10.2 Design drift
Docs and runtime telling different stories.

### 10.3 Local optimization
Fixing α while worsening β or γ.

### 10.4 Green-build illusion
Treating CI success as sufficient release justification.

### 10.5 Hidden incoherence
Accepting silent fallback or degraded behavior without explicit visibility.

### 10.6 Runtime/documentation split
The system works one way, but teaches another.

---

## 11. Post-Release Assessment

CDD does not end at merge. Every release triggers a post-release assessment.

The assessment has four mandatory parts:

1. **Coherence measurement** — score α/β/γ, compare to baseline, update CHANGELOG TSC table
2. **Encoding lag report** — all converged-but-unimplemented design commitments in a lag table (none/low/growing/stale)
3. **Process learning** — what went wrong, what went right, skill patches executed immediately
4. **Next move commitment** — concrete next MCA (issue, owner, branch, first AC, freeze state)

### Rules

- After every release, all outstanding MCI must be captured in the Encoding Lag table.
- The MCI/MCA balance decision is mandatory (balanced / freeze MCI / resume MCI).
- The next MCA must be named concretely: issue number, owner, first AC, freeze/resume state.
- Small process/skill corrections discovered in the assessment should be executed immediately.
- Larger MCA becomes the next delivery cycle's work.
- "Freeze MCI" means operationally: no new substantial design docs or plans until the committed MCA backlog is reduced below threshold.

### Delegation

The full procedure is defined in `ops/post-release/SKILL.md`. CDD §11 defines the requirement; the skill defines the execution.

### Human judgment

CDD is rigorous, but not mechanical. It requires judgment:

- when to stop iterating
- what counts as the real gap
- whether a contradiction is superficial or structural
- whether a release is coherent enough

CLP exists because coherence cannot always be inferred from checklists alone. But checklists still matter. CDD must not become a gate that blocks shipping. CA-CONDUCT says: "Done beats perfect. Bias for action." CDD's role is to ensure that action is coherent, not to replace action with ceremony.

---

## 12. Practical Workflow Summary

### For a substantial change:

1. State the gap (coherence contract)
2. Run Bohmian reflection if needed
3. Score α / β / γ
4. Patch the weakest axis
5. Write or update the design
6. Write the plan
7. Write tests
8. Implement
9. Update docs
10. Release with notes
11. Observe the running system
12. Post-release assessment (measurement, lag, learning, next move)

For a small change, the coherence contract can be a single sentence in the commit message or PR description. The method scales down.

---

## 13. Governance

### 13.1 Merge governance
Per RULES.md: no self-merge. Engineer writes → PM merges. PM writes → Engineer/Owner merges.

### 13.2 Review discipline
Reviews use CLP dialogue structure (TERMS → POINTER → EXIT) and check triadic coherence. This is not additional ceremony — it is what review already means in cnos.

---

## 14. Relationship to Other Documents

| Document | Scope | Relationship to CDD |
|----------|-------|---------------------|
| THESIS.md | System thesis / above | CDD is one articulation of the recurrent coherence system |
| COHERENCE-SYSTEM.md | Meta-model / above | CDD is γ at the development scale |
| FOUNDATIONS.md | Doctrine / why | CDD derives its first principle from here |
| CAP.md | Doctrine / dynamic | CDD applies CAP to development |
| COHERENCE.md | Doctrine / review | CDD uses TSC axes and CLP structure |
| CA-CONDUCT.md | Doctrine / behavior | CDD inherits "ship" and "own" |
| RULES.md | Process / governance | CDD operates within these rules |
| AGILE-PROCESS.md | Process / workflow | CDD defines the quality function |
| CAA.md | Architecture / what | CDD ensures architecture stays coherent |
| AGENT-RUNTIME.md | Runtime / how | CDD ensures runtime matches design |
| CAR.md | Distribution / how | CDD ensures packages stay coherent |

CDD is a design document. It is not doctrine — it does not define first principles. It defines how the development process applies doctrine to produce coherent systems.

---

## 15. Summary

Coherence-Driven Development means:

- starting from the real gap
- applying CAP to the development process (not just to agent runtime)
- using CLP as the review loop and dialogue structure
- formalizing coherence so it can be inspected and tested
- implementing only after coherence is good enough
- testing the invariants
- releasing only when runtime, docs, and operator story align
- observing the live system as part of the same method
- scaling down for small changes, scaling up for substantial ones

> **Development organized around reducing incoherence across thought, design, implementation, operation, and evolution.**

More precisely:

> **CMP constructs the MCP.
> CAP chooses the move.
> CLP judges the delta.
> CDD is that logic applied to the evolution of cnos itself.**

Each substantial release is therefore a **measured coherence delta**.
The feature is not discarded or treated as accidental;
it is the concrete, operator-visible articulation of that delta.

---

## Coherence Contract for This Document

**Gap:** cnos has doctrine (CAP, COHERENCE, CBP, CA-CONDUCT) and process (AGILE-PROCESS, RULES) but no explicit development-method document connecting them. Development coherence was implicit.

**Mode:** MCA — create the document that makes the method explicit.

**Scope:** Design layer.

**Expected effect:**
- α: development vocabulary stabilized (gap, mode, scope, triadic effect)
- β: doctrine, process, and design docs now relate through a named method
- γ: future changes can reference CDD for development coherence criteria

**Failure if skipped:** Development coherence remains implicit and taste-based. Reviews lack shared criteria. The gap between doctrine and practice widens.
