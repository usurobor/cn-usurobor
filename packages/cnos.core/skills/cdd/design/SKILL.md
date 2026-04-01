---
name: design
description: Design systems where the impact graph is fully traced and every acceptance criterion maps to a specific file. Use before implementing substantial changes. Triggers on architecture decisions, new subsystems, protocol changes, issue spec writing.
---

# Design

## Core Principle

**Coherent design: every decision traces to a named incoherence, and every artifact affected by the decision is enumerated before implementation begins.**

If you can't name the incoherence, you don't have a design problem. If you can't enumerate what your change affects, you don't have a design — you have a guess.

## Algorithm

1. **Define** — name the incoherence, the parts, and the failure mode.
2. **Unfold** — walk the design through problem, constraints, impact graph, proposal, acceptance criteria, and file changes.
3. **Rules** — make each subsection mechanically actionable with explicit ❌/✅ examples.

---

## 1. Define

1.1. **Identify the parts**
  - Problem (the named incoherence)
  - Constraints (what can't change, what contracts govern)
  - Proposal (what to build, with types and interfaces)
  - Impact graph (what consumes, produces, or copies the changed thing)
  - Acceptance criteria (specific file + specific check + pass/fail)
  - ❌ "We need better version handling" (unnamed incoherence)
  - ✅ "Version is duplicated in 5 files with no single source of truth — #22" (named, numbered)
  - ✅ "Actor FSM allows Idle→Processing but daemon never checks for re-entry — #12" (named, located)

1.2. **Articulate how they fit**
  - The problem names what's wrong; constraints bound what you can touch; the proposal changes the minimum to close the gap; the impact graph ensures nothing is missed; ACs verify the gap is closed
  - ❌ Jump from problem to proposal
  - ✅ Problem → constraints → impact graph → proposal → ACs

1.3. **Name the failure mode**
  - Design fails via **incomplete impact tracing** — changing the node without following the edges. The proposal fixes one artifact but breaks or neglects the artifacts that consume it.
  - ❌ "Updated the skill, canonical doc will catch up later"
  - ✅ "Skill declares canonical doc as authority → canonical doc must be updated in the same change, or authority claim must be explicitly narrowed"

---

## 2. Unfold

### 2.1. Problem

State the incoherence precisely before proposing anything.

2.1. **Name the incoherence, not the feature**
  - ❌ "Add a VERSION file" (solution, not problem)
  - ✅ "Version is duplicated across 5 files — bumping requires 5 manual edits, forgetting any breaks CI" (incoherence)

2.2. **Distinguish schema from population**
  - ❌ "Lockfile doesn't support package versions" (wrong — schema has version/source/rev/subdir)
  - ✅ "Lockfile schema has version field but first-party entries populate it with placeholder `1.0.0`" (population problem)

2.3. **Show evidence**
  - ❌ "This has caused problems"
  - ✅ "v3.8.0 shipped with v3.7.4 version string. Three patch releases to fix. Pi reported v3.7.3 when binary was v3.8.2."

2.4. **Enumerate all failure modes**
  - ❌ "`cn update` version comparison is broken" (one failure mode)
  - ✅ "Three independent failures: CI doesn't upload assets (404), binary naming mismatch (`x64` vs `x86_64`), version-only comparison (no same-version patches)" (all three)

---

### 2.2. Constraints

Identify what governs before proposing what changes.

3.1. **Name existing contracts**
  - What authority relationships exist? What documents govern on disagreement?
  - ❌ "We'll update the skill"
  - ✅ "Skill §Authority says canonical doc governs on disagreement — so canonical doc must be updated, or authority claim must be narrowed"

3.2. **Name the abstraction level**
  - ❌ "Use dune-project as version source" (OCaml package metadata — wrong level for system manifests, lockfiles, tests, status)
  - ✅ "VERSION file is language-agnostic, sits above all consumers: OCaml build, system manifest, package manifests, lockfiles, tests, CI"

3.3. **Name what can't change**
  - ❌ Proposal silently breaks an existing interface
  - ✅ "Lockfile format is consumed by `cn deps restore` — schema stays, population changes"

3.4. **Name the architecture assumption you are challenging**
  - State which existing boundary, ownership model, or system assumption is no longer serving the system.
  - ❌ "We need a cleaner design"
  - ✅ "This change challenges the assumption that every new capability family must be hardcoded in trusted core"
  - ✅ "This change challenges the assumption that communication is just a capability rather than a body/medium subsystem"

---

### 2.3. Impact Graph

**This section is not optional.** Trace everything the change touches.

4.1. **Enumerate downstream consumers**
  - What reads, renders, or acts on the artifact you're changing?
  - ❌ Update CDD skill, forget post-release template consumes the new metrics
  - ✅ "CDD §11.11 defines metrics → post-release template must render them → review skill must tag findings by type"
  - ✅ "Adding a new FSM state → check: protocol .mli, doctor checks, status output, packed context renderer, tests"

4.2. **Enumerate upstream producers**
  - What produces the inputs your design depends on?
  - ❌ "Tests will use the version" (which version? from where?)
  - ✅ "VERSION file → build generates cn_version.ml → cn_lib.ml reads it → tests derive from Cn_lib.version"

4.3. **Enumerate copies and embeddings**
  - Where does the same information appear in multiple places?
  - ❌ "Update src, packages will sync"
  - ✅ "src/agent/skills/ops/cdd/SKILL.md + packages/cnos.core/skills/ops/cdd/SKILL.md — must match (md5 verified)"

4.4. **Name authority relationships**
  - If two artifacts carry the same information, which governs?
  - ❌ Both skill and canonical doc have the rule, unclear which wins
  - ✅ "Skill is executable summary. Canonical doc governs on disagreement. New §1.5 exists only in skill — authority explicitly narrowed until canonical catches up."

4.5. **Trace rule changes through all embeddings**
  - When you add a rule, find every artifact that embeds, templates, or implements that rule
  - ❌ Add review quality metrics to CDD, forget post-release template still has old 4-section output
  - ✅ "New metric added to CDD §11.11 → check: post-release template (SKILL.md), post-release procedure (Step 5.5), review skill taxonomy (§5.1), self-coherence report format"

---

### 2.4. Proposal

The minimum change that closes the gap.

5.1. **Start with types**
  - Define the data model before the interface
  - ❌ "Add a `cn cdd status` command" (interface without model)
  - ✅ "CDD state is derived from: branch name, version dir presence, artifact paths, CI state, tag presence" (model first)
  - ✅ `type memory_backend = Git_threads | State_files | External of uri` — makes the design space explicit before choosing an interface

5.2. **One source of truth, N derived artifacts**
  - If information appears in multiple places, one is authoritative, the rest derive
  - ❌ "Keep version in cn_lib.ml and cn.json" (two sources)
  - ✅ "VERSION is source. cn_lib.ml generated at build time. cn.json stamped and validated by CI."

5.3. **Derive state from artifacts, not parallel bookkeeping**
  - ❌ "Store CDD pipeline state in `state/cdd/*.json`" (separate state store that drifts)
  - ✅ "Derive CDD step from branch name + artifact presence + test results" (state = evidence)

5.4. **Mechanize invariants, not judgment**
  - What can a tool check? (naming, presence, structure, consistency) → mechanize it
  - What requires reasoning? (is the gap real, is the mode right, is the design good) → leave it human
  - ❌ "Tool scores α/β/γ for the author"
  - ✅ "Tool checks branch naming, artifact presence, snapshot integrity. Scoring stays human."

5.5. **Name the leverage**
  - Name what future work becomes easier, safer, or unnecessary if this proposal lands.
  - ❌ "This helps later"
  - ✅ "Future capability families become package-installed extensions instead of repeated core runtime edits"
  - ✅ "Future wake-time self-model changes fit into body/medium without redesign"

5.6. **Name the negative leverage**
  - Name what this proposal makes harder, heavier, or more complex.
  - ❌ "No downsides"
  - ✅ "This removes core accretion, but adds manifest, registry, doctor, and traceability complexity"
  - ✅ "This strengthens runtime contract truth, but increases versioned frozen-artifact discipline"

5.7. **Price any new process overhead**
  - If the proposal adds artifacts, gates, or process, state:
    - who must produce them
    - who consumes them
    - why a lighter alternative is insufficient
  - ❌ "Require another artifact for rigor"
  - ✅ "Require SELF-COHERENCE.md for governance branches because reviewer and releaser need branch-local proof that the branch followed the process it defines"

5.8. **State the automation boundary**
  - Say what should remain human judgment and what should become script/CI/lint.
  - ❌ "Reviewers will keep checking stale paths manually"
  - ✅ "Artifact presence, placeholder rendering, and stale path refs should be automated; α/β/γ judgment remains human"

5.9. **Simplest thing that closes all failure modes**
  - KISS/YAGNI, but don't confuse "simple" with "incomplete"
  - ❌ "Fix version comparison" (1 of 3 failure modes — CI upload and naming still broken)
  - ✅ "Three failures, three fixes: CI uploads assets, naming made consistent, comparison includes commit hash"

5.10. **Name what you're not doing**
  - ❌ Non-goals absent
  - ✅ "V1 does not: score α/β/γ semantically, decide MCA vs MCI correctness, replace review dialogue"

---

### 2.5. Acceptance Criteria

ACs are the contract between design and implementation.

6.1. **Map each AC to a specific file and check**
  - ❌ "The system handles version coherence correctly" (unfalsifiable)
  - ✅ "`grep -rn` for version string returns exactly one source file (`VERSION`)" (file + check + pass/fail)

6.2. **No charitable interpretation**
  - Each AC must be mechanically verifiable — not "I believe this is met because..." but "file X, line Y, present: yes/no"
  - ❌ "AC4 is met because §11.11 covers review metrics" (belief, not evidence)
  - ✅ "AC4 requires post-release template update → file: `src/agent/skills/ops/post-release/SKILL.md` → §4 Review Quality section → present: yes"

6.3. **Cover the impact graph**
  - Every artifact in the impact graph should have at least one AC that touches it
  - ❌ 7 ACs for the proposal, 0 for downstream consumers
  - ✅ "AC for skill, AC for canonical doc, AC for post-release template, AC for review skill"

6.4. **Include the negative**
  - ❌ Only test the happy path
  - ✅ "CI fails if derived version files are stale" (negative gate)

---

### 2.6. Artifact Boundaries

The design doc is the origin artifact in the CDD pipeline. Plan, issue, and review reference it.

8.1. **Design owns gap, constraints, proposal, impact graph, ACs**
  - These live in the design doc and nowhere else
  - Plan references the gap, doesn't re-derive it
  - Issue summarizes in 3-5 lines, links to the design for depth
  - ❌ Plan §0 re-derives the gap analysis from scratch
  - ✅ Plan §0: "Implements [DESIGN.md]. See §0 there for gap and targets."

8.2. **Design does not own implementation order or step-level ACs**
  - That's the plan's job
  - ❌ Design specifies "do Step 1 first, then Step 2"
  - ✅ Design specifies what must be true; plan specifies in what order to make it true

8.3. **Design does not own the problem summary for external consumers**
  - Issue owns the concise entry point for engineers picking up the work
  - ❌ Design tries to be both architecture doc and issue
  - ✅ Design is the depth artifact; issue is the entry point

8.4. **When companion artifacts exist, link to them**
  - Design should link to issue, plan, and any prior art it references
  - ❌ Design is self-contained and mentions no related artifacts
  - ✅ "Issue: #113. Plan: PLAN-package-system.md. Prior art: EXTENSION-REGISTRY.md."

---

### 2.7. File Changes

List every file that needs to change, grouped by action.

9.1. **Create / Generate / Edit / Delete**
  - ❌ "Update the relevant files" (which ones?)
  - ✅ "Create: `VERSION`. Generate: `src/lib/cn_version.ml`. Edit: `cn_lib.ml`, `cn.json`, 3 package manifests, `cn_deps.ml`, `cn_system.ml`, `cn_runtime_contract.ml`, 3 test files."

9.2. **Name the specific change per file**
  - ❌ "Edit cn_deps.ml"
  - ✅ "Edit cn_deps.ml → `default_manifest_for_profile` uses current first-party version, not `^1.0.0`; `lockfile_for_manifest` uses exact version + `cnos_commit`"

---

## 3. Rules

### 3.1. Output Format

```markdown
# [Title]

**Issue:** #NN
**Version:** X.Y.Z
**Mode:** MCA / MCI
**Active Skills:** [2–3 governing skills for this change]
**Engineering Level:** L5 / L6 / L7 *(optional — if used, must be paired with active skills)*

## Problem
[Named incoherence with evidence]

## Constraints
[Existing contracts, abstraction levels, what can't change]

## Challenged Assumption
[Which boundary / ownership model / architecture assumption is being replaced]

## Impact Graph
[Downstream consumers, upstream producers, copies, authority relationships]

## Proposal
[Types → interface → workflow, with design principles governing trade-offs]

## Leverage
[What future work becomes easier / unnecessary / safer]

## Negative Leverage
[What gets heavier, riskier, or more complex]

## Alternatives Considered
| Option | Pros | Cons | Decision |

## Process Cost / Automation Boundary
[If this adds process/artifacts/gates: who pays, who consumes, what should be automated]

## Non-goals
[What V1 deliberately excludes]

## File Changes
[Create / Generate / Edit — specific file, specific change]

## Acceptance Criteria
- [ ] [file + check + pass/fail]

## Known Debt
[What remains after this change]

## CDD Trace
| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| §2.0 | — | — | [observation inputs and selected signal] |
| §2.1 | — | — | [selected gap] |
| §2.4 | this artifact | [active skills] | [work shape, level if used, mode] |
| §2.5 | [artifact name] | — | [design/plan/tests/docs progress] |
```

---

### 3.2. Keep the CDD Trace in the primary branch artifact

If this design artifact is the primary branch artifact for a substantial cycle, it must carry the CDD Trace.

- ❌ Mode and active skills stated, but no trace of when or why they were chosen
- ✅ The design artifact records observation, selected gap, mode, active skills, and artifact progress

If another artifact is the primary branch artifact, point to it explicitly.

### 3.3. Pre-Submission Checklist

Before requesting review:

- [ ] Problem stated as named incoherence with evidence
- [ ] Schema vs population distinguished (if data structures involved)
- [ ] All failure modes enumerated (not just the first one found)
- [ ] Constraints from existing contracts identified
- [ ] Abstraction level of the solution matches the scope of the problem
- [ ] Challenged architecture assumption named explicitly
- [ ] Impact graph complete: consumers, producers, copies, authority
- [ ] Proposal starts from types/model, not from interface
- [ ] One source of truth identified for any duplicated information
- [ ] State derived from artifacts, not parallel bookkeeping (where applicable)
- [ ] Mechanical vs judgment boundary drawn explicitly
- [ ] Leverage and negative leverage both stated
- [ ] Added process/artifact overhead priced and justified (if applicable)
- [ ] Automation boundary stated for any new mechanical checks
- [ ] ACs map to specific files with specific checks
- [ ] ACs cover the impact graph, not just the proposal
- [ ] Non-goals stated
- [ ] File changes listed with specific edits per file
- [ ] Known debt acknowledged
- [ ] Artifact boundaries respected: gap lives here, order lives in plan, summary lives in issue
- [ ] Companion artifacts linked (issue, plan, prior art)
- [ ] CDD Trace present and filled through the current lifecycle step (if substantial)
