# Coherence-Driven Development (CDD)

**Version:** 3.15.0
**Status:** Draft
**Date:** 2026-03-25
**Placement:** γ document (`docs/gamma/cdd/`)
**Audience:** Contributors, reviewers, maintainers, release operators
**Scope:** Canonical algorithm spec for how cnos selects, executes, measures, and closes substantial development cycles

---

## 0. Purpose

CDD is the development method used to evolve cnos coherently. Its purpose is not merely to ship features. Its purpose is to reduce incoherence across the system as a whole:

- doctrine
- architecture
- implementation
- runtime behavior
- operator understanding
- release state
- development process itself

A release is therefore not just a bundle of outputs. It is a measured coherence delta.

> A change is good not merely when it is implemented, but when it reduces incoherence across the system as a whole.

CDD is γ at development scale.

---

## 1. Scope

CDD applies to substantial changes: work that spans design, code, tests, docs, process, packaging, runtime behavior, or release state. CDD also defines a small-change path for changes too small to warrant a full version-directory cycle.

### 1.1 Substantial change

A change is substantial when one or more of the following are true:

- it introduces or changes a subsystem, contract, or protocol
- it changes runtime behavior or ABI
- it changes package, security, or release surfaces
- it requires design, test, docs, and release alignment
- it will likely take more than one day
- it creates future coherence risk if handled informally

### 1.2 Small change

A change may take the small-change path when it is narrowly local, low-risk, and does not need a frozen snapshot. In the small-change path:

- bootstrap does not apply
- the coherence contract may live in the commit message or PR body
- self-coherence is optional
- the author still owes a named incoherence and an explicit scope

### 1.3 First principle

CDD begins from the same first principle as the coherent agent:

> There is a gap between model and reality.

In development terms:

- model = doctrine, architecture, design, operator understanding, intended behavior
- reality = code, runtime behavior, logs, failures, release outcomes, actual operator experience

CDD exists to close that gap through coherent action.

---

## 2. Inputs

CDD selection begins from observation, not preference. Every substantial cycle reads these inputs before selecting work:

### 2.1 CHANGELOG TSC table

Read the current α / β / γ release state.

Question:
- which axis is weakest?

### 2.2 Encoding lag table

Read the lag state of open feature and process issues.

Questions:
- what is stale?
- what is growing?
- what is blocked by something else?

### 2.3 Doctor / status

Read the health of the running system.

Questions:
- is there a P0?
- is operational infrastructure broken?
- is the system able to observe, update, and maintain itself?

### 2.4 Last post-release assessment

Read the prior cycle's output.

Questions:
- what MCA was committed as next?
- what MCIs remain unresolved?
- what process debt was identified?

If no prior assessment exists, skip this input and select from §2.1–§2.3 alone.

---

## 3. Selection Function

CDD selection is coherence-driven. The next substantial gap is selected by the following function, in order.

### 3.1 P0 override

If doctor/status shows a P0 bug such as crash, data loss, or silent failure, that is the gap. No further selection logic applies until it is addressed.

**New-vs-known rule:** If the P0 was already visible when the last assessment was written and the assessment committed a different next MCA, the assessment decision governs unless the P0 has escalated (e.g. now causing active data loss or blocking all development). A known P0 that was weighed and deferred is not an override — it is a prioritized backlog item.

### 3.2 Operational infrastructure override

If core operational paths are broken, fix them before feature work. Examples:

- self-update broken
- logging absent
- health checks missing
- deployment path incoherent
- system cannot observe or maintain itself

These are not "nice to have." They are preconditions for coherent development.

**Sizing rule:** Before selecting infrastructure debt as a full cycle, ask whether the fix is cycle-sized or immediate-output-sized. If the fix is executable in minutes (a script, a hook, a one-line config change), execute it as an immediate output (§10.1) and continue to §3.3. Only select infrastructure debt as the cycle gap when the fix requires design, multiple files, tests, or review.

### 3.3 Assessment commitment default

If the last assessment named a next MCA and no stronger override fires, that MCA is selected by default. Observation may override it, but the override must be stated explicitly.

### 3.4 No clear winner — stale backlog re-evaluation

If §3.1–§3.3 produce no actionable candidate (e.g. P0s exist but have no clear fix path, assessment doesn't commit a next MCA, no operational debt), re-evaluate stale issues before selecting new work:

- For each stale issue: is it still a real gap, or has the system moved past it?
- **Descope** issues that are no longer coherence gaps (close with rationale).
- **Consolidate** issues that overlap or could be addressed by one MCA.
- **Commit** the stale issue with the clearest fix path as the next MCA.
- If no stale issue has a clear fix path either, enter observation mode (§3.9).

Stale backlog accumulating across multiple cycles without re-evaluation is itself an incoherence.

### 3.5 MCI freeze check

If the lag table contains stale issues, the next substantial MCA must come from the stale set. New design work is frozen until at least one stale item ships.

### 3.6 Weakest-axis rule

If no stronger rule decides selection, choose work that addresses the weakest current axis:

- α → structural / consistency work
- β → alignment / integration work
- γ → process / evolution work

### 3.7 Maximum leverage

Among candidates that address the weakest axis, choose the one that moves the most lag entries.

### 3.8 Dependency order

If A blocks B blocks C, choose A regardless of local excitement or presentation value.

### 3.9 Effort-adjusted tie-break

Between candidates with equal leverage and axis effect, choose the smaller one. Ship sooner, observe sooner, correct sooner.

### 3.10 No-gap case

If:

- no P0 exists
- no operational-debt override exists
- no stale lag item exists
- no prior assessment commitment forces a next MCA
- axes are healthy or tied

then do not start a new substantial cycle. Remain in observation or choose a small-change path.

---

## 4. Development Lifecycle

CDD owns the full arc from observation back to observation.

### 4.1 Lifecycle steps

| # | Step | Purpose | Required output |
|---|------|---------|-----------------|
| 0 | Observe | Read current coherence state | Selection inputs read |
| 1 | Select | Choose the next gap | Named selected gap |
| 2 | Branch | Create a dedicated branch | Valid branch name |
| 3 | Bootstrap | Create snapshot skeleton | Version dir + stubs |
| 4 | Gap | Name the incoherence precisely | Coherence contract draft |
| 5 | Mode | Choose MCA/MCI and governing skills | Mode + active skill set |
| 6 | Artifacts | Design → contract → plan → tests → code → docs | Aligned implementation artifacts |
| 7 | Self-coherence | Author checks own work against ACs and triad | Self-coherence report |
| 8 | Review | CLP with another CA or human reviewer | Converged review outcome |
| 9 | Gate | Verify release readiness | Gate checklist passes |
| 10 | Release | Tag, publish, announce | Release artifacts exist |
| 11 | Observe | Confirm runtime matches design | Observation result |
| 12 | Assess | Post-release assessment | Assessment artifact |
| 13 | Close | Execute immediate outputs and commit deferred outputs | Cycle closed |

Step 13 feeds back to step 0.

### 4.2 Branch rule

Every substantial change must be developed on its own dedicated branch. No substantial CDD work is performed directly on main.

Canonical branch format:

```text
{agent}/{version}-{issue}-{scope}
```

Version may be omitted when not yet known:

```text
{agent}/{issue}-{scope}
```

### 4.3 Branch pre-flight

Before creating the branch, verify:

- version segment, if present, is greater than the latest released/tagged version
- no remote branch already claims the same issue
- no open PR already covers the same issue
- branch name matches the canonical format
- current CI / main state is known
- the intended scope is declared before implementation begins

### 4.4 Skill selection

At step 5 (Mode), the implementer must name the 2–3 skills that govern this change and **read each SKILL.md file** before beginning any work step. Naming a skill without reading it is not loading it. The loaded skills are **hard generation constraints** — not post-hoc review checklists. All other skills remain available as reference but do not bind generation.

Rationale: breadth without depth produces checklist engineering. Ten skills loaded at surface level means none are deeply internalized. Fewer constraints, deeply applied, prevent more defects than many constraints lightly checked.

The selected skill set must be stated alongside mode. Example:

```text
Mode: MCA
Active skills: ocaml, performance-reliability
```

When in doubt about mode, apply CAP: if the answer is already in the system, cite it (MCA) — don't reinvent it (MCI). If two paths close the same gap, take the lighter one unless the heavier one buys durability the lighter one cannot.

Review (step 8) checks whether the implementation is consistent with the declared active skills. Findings that a loaded active skill would have prevented are process debt (§6.1).

---

## 5. Artifact Contract

CDD is artifact-driven. Every substantial cycle must produce inspectable artifacts.

### 5.1 Bootstrap

The first diff on the branch must create a version directory for every bundle that will receive a frozen snapshot.

Path convention:

```text
docs/{tier}/{bundle}/{X.Y.Z}/
```

Each version directory must contain:

- README.md — snapshot manifest
- one stub per declared deliverable

Artifacts outside version directories, such as PR body files or navigation updates, are not required as bootstrap stubs.

### 5.2 Ordered artifact flow

The canonical artifact order is:

1. design
2. coherence contract
3. plan
4. tests
5. code
6. docs
7. self-coherence
8. review
9. gate
10. release
11. observe
12. assess
13. close

### 5.3 Artifact manifest

CDD is artifact-driven. For substantial changes, each lifecycle step must leave one inspectable evidence surface.

| Step | Name | Required evidence | Owner |
|------|------|-------------------|-------|
| 0 | Observe | CDD Trace row recording inputs read and selected signal | primary branch artifact |
| 1 | Select | CDD Trace row naming selected gap | primary branch artifact |
| 2 | Branch | valid branch name | branch + CDD Trace row |
| 3 | Bootstrap | version directory + manifest README + declared stubs | branch diff |
| 4 | Gap | named incoherence / coherence contract | primary branch artifact |
| 5 | Mode | mode + active skills (+ bundle/level if used) | primary branch artifact |
| 6a | Design | design artifact or explicit "not required" note by change class | primary branch artifact |
| 6b | Plan | plan artifact when cycle-sized, otherwise explicit "not required" note | primary branch artifact or linked plan |
| 6c | Tests | test files or explicit reason no tests apply | diff / primary branch artifact |
| 6d | Code | implementation diff or explicit "docs/process only" note | diff / primary branch artifact |
| 6e | Docs | changed canonical docs / specs / READMEs as required | diff |
| 7 | Self-coherence | SELF-COHERENCE.md | version directory |
| 8 | Review | review artifact / PR review / review comment link | review surface |
| 9 | Gate | gate result / release-readiness evidence | release surface or review surface |
| 10 | Release | CHANGELOG row, tag, release note / release artifact | release surface |
| 11 | Observe | post-release observation result | post-release assessment |
| 12 | Assess | POST-RELEASE-ASSESSMENT.md | version directory |
| 13 | Close | immediate outputs executed + deferred outputs committed | post-release assessment |

Rules:
- "Not required" is valid only when stated explicitly.
- An omitted step with no explicit note is incomplete, not implicit.
- Small-change mode may collapse steps 4–7 into commit/PR-body evidence, but the same distinctions still apply.

### 5.4 CDD Trace

Every substantial cycle must carry a lightweight execution trace. For steps 0–10, the trace lives in the primary branch artifact. For steps 11–13, closure lives in the post-release assessment.

The primary branch artifact is the artifact that owns the named incoherence, mode, active skills, and acceptance criteria. In most cycles this is the design artifact. For governance/process work it may be the governing doc being changed. For smaller substantial changes it may be the PR body when no separate design doc is required.

Required format:

```markdown
## CDD Trace
| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| §2.0 | — | — | Observation inputs read; selected signal |
| §2.1 | — | — | Selected gap |
| §2.4 | primary artifact | skill1, skill2 | Work shape, level (if used), mode, active skills |
| §2.5 | design / plan / tests / docs | — | Artifact progress or explicit "not required" |
| §2.6 | review surface | review (+ others if loaded) | CLP review result |
| §2.8 | release surface | release, writing (if used) | Tag / changelog / release decision |
```

Rules:
- One row per completed lifecycle step.
- "Skills loaded" is required when skills shaped generation or lifecycle execution.
- If a lifecycle skill is used later (review, release, writing, post-release), record it when it becomes active.
- Missing rows mean the step is not yet evidenced.
- Contradictory rows are findings.

### 5.5 Supporting rules

- one source of truth per fact
- derive, do not duplicate
- update docs before release
- write tests before or alongside the code they validate
- build-sync source asset changes before commit
- enumerate affected files before implementation begins
- every AC must map to evidence before review

### 5.6 Frozen snapshot rule

After release, version directories are frozen by repository policy. Only path-reference repairs are allowed after freeze:

- markdown links
- backtick paths

No semantic content may change.

---

## 6. Mechanical vs Judgment Boundary

CDD is rigorous, but not fully mechanical.

### 6.1 Mechanical

These may be enforced by tools or checklists:

- branch naming
- branch uniqueness
- version-directory presence
- required artifact presence
- stale cross-reference detection
- AC accounting
- frozen snapshot integrity
- gate checks
- release artifact presence
- review-quality metrics
- process-debt filing when thresholds trigger

### 6.2 Judgment

These remain judgment-bearing:

- what the real incoherence is
- whether MCA or MCI is the right intervention
- whether α / β / γ scoring is substantively sound
- whether a review has truly converged
- whether a design is coherent enough to implement
- whether iteration should stop

Tools may validate the existence of judgment artifacts. They do not replace the judgment itself.

---

## 7. Review

CDD review uses CLP. Every substantial review should answer:

- TERMS — what are we talking about?
- POINTER — where is the incoherence?
- EXIT — what changed, or what still blocks closure?

Every reviewer should be asked for:

- α / β / γ scores
- weakest-axis diagnosis
- concrete patch suggestions
- iterate or converge verdict

The review skill owns the detailed protocol. CDD owns when review is required and what it must decide.

---

## 8. Gate

Release may proceed only when:

- the selected gap was actually addressed
- required artifacts exist
- self-coherence exists for substantial change
- review converged
- CI/build/test requirements pass
- docs, code, and release artifacts agree
- the previous release has an assessment
- known debt is explicit, not implicit

A passing gate means:

- structurally ready to release

It does not mean:

- intellectually perfect

---

## 9. Assessment

Post-release assessment is mandatory for substantial releases. It must record:

- measured coherence delta
- encoding lag table
- MCA/MCI balance
- process learning (including active skill re-evaluation against review findings)
- review quality metrics
- CDD self-coherence (α artifact integrity, β surface agreement, γ cycle economics)
- cycle iteration (see §9.1)
- next move commitment

The CHANGELOG TSC entry at release time is provisional. Assessment governs the final judgment of the cycle.

### 9.1 Cycle iteration

When a cycle exceeded expected effort — extra review rounds, avoidable mechanical errors, tooling failures, or environmental surprises — the assessment must include a cycle iteration section.

**Trigger:** Any of:
- review rounds exceeded target (default: 2)
- mechanical finding ratio exceeded 20%
- avoidable tooling or environmental failure delayed the cycle
- a skill that was loaded failed to prevent a finding it covers

**Required artifact:** A `## Cycle Iteration` section in the post-release assessment (located in `docs/{tier}/{bundle}/{X.Y.Z}/POST-RELEASE-ASSESSMENT.md`). Must contain these fields:

```markdown
## Cycle Iteration

### Triggers fired
- [ ] review rounds > 2 (actual: N)
- [ ] mechanical ratio > 20% (actual: N%)
- [ ] avoidable tooling/environmental failure
- [ ] loaded skill failed to prevent a finding

### Friction log
What went wrong in the cycle itself (process, not code).

### Root cause
One of: design flaw | skill gap | tooling gap | environmental | one-off

### Skill impact
Which active skill should have prevented the friction?
If a loaded skill failed: name it and patch it as immediate output (§10.1).

### MCA
System change shipped or proposed. "Won't repeat" without a mechanism is not an MCA.

### Cycle level
L5 | L6 | L7 (per ENGINEERING-LEVELS.md §6 — level = lowest miss)
Justification: [one line explaining the level]
```

The cycle level is also recorded in the CHANGELOG TSC table as a suffix: e.g. `(cycle: L6)`.

**Cycle level assessment:** After the friction log and MCA, assess the executed engineering level of the cycle. This applies the level framework from `docs/gamma/ENGINEERING-LEVELS.md` to cycles (change sets), not just individual diffs. Use the §6 diagnostic questions adapted for cycle scope:

- **L5: local correctness** — Was the code locally correct before review? Did it compile, pass tests, follow current patterns? If mechanical errors (compilation failures, type errors, broken assertions, missing tests) reached review, L5 was not met. Cycle caps at L5.
- **L6: system-safe execution** — Did the change stay coherent across docs, runtime, artifacts, tests, and operator truth? Were failure modes bounded and visible? If cross-surface drift (package sync, authority-sync, doc/code mismatch, test coverage gaps) reached review, L6 was not met. Cycle caps at L6.
- **L7: system-shaping leverage** — Did the cycle change the system boundary so the friction class gets easier or disappears? If friction was fixed locally but no system change prevents recurrence (no MCA shipped, no skill patched, no gate added), L7 was not met. Cycle caps at L6. Not every cycle needs L7 — only assess when friction occurred and a system-shaping response was available.
- **L7 achieved** — The cycle shipped an MCA that eliminates or reduces a friction class for future cycles.

The cycle level is the lowest miss. A cycle with L5 misses caps at L5 regardless of whether it also shipped an L7 MCA. Each level must be earned cleanly.

Record the cycle level in the assessment. Over time, cycle levels track whether the development process itself is improving.

**Gate:** If the trigger fires and the cycle iteration section is absent, the cycle cannot close (§10.3).

If the cycle went cleanly (no trigger fires), cycle iteration may be omitted.

---

## 10. Closure

A cycle is not closed merely because code merged.

### 10.1 Immediate outputs

These must be executed within the same cycle:

- changelog corrections
- missing documentation
- skill/process micro-patches
- skill patches identified by cycle iteration (§9.1) — if a loaded skill failed to prevent a finding it covers, patch the skill now, not later
- issue filing required by the assessment
- lag-table updates
- metadata fixes

Skill/spec patches produced as immediate outputs must pass CLP β: does this change create a mismatch with any canonical or derived surface? If the edited artifact has a paired authority surface (executable skill ↔ canonical spec), both must be updated in the same commit.

### 10.2 Deferred outputs

These may become the next cycle's work, but must be committed concretely:

- next MCA issue number
- owner, if known
- target branch name, if known
- first AC
- freeze/resume state for MCI backlog

### 10.3 Closure rule

A cycle closes only when:

- all immediate outputs are executed
- all deferred outputs are captured as explicit next-cycle commitments
- cycle iteration (§9.1) is present if any trigger fired

That is the handoff from step 13 back to step 0.

---

## 11. Related documents

### 11.1 Executable summary

`src/agent/skills/cdd/SKILL.md` is the executable summary of this spec.

### 11.2 Companion rationale

RATIONALE.md explains why CDD takes this shape.

---

## 12. Retro-packaging rule

If a substantial change lands direct-to-main as an exception to the branch/bootstrap discipline, it must be followed immediately by:

- a retro-snapshot in the appropriate version directory (frozen copies of the changed canonical artifacts)
- a self-coherence artifact covering the change
- a version-history entry in the bundle README

This closes the loophole where substantial method rewrites bypass their own packaging discipline. The method must eat its own cooking.

---

## 13. Non-goals

CDD does not:

- optimize primarily for speed
- treat issue queues as self-justifying
- reduce review to local diff reading
- treat release as "tag and hope"
- confuse a shipped feature with a closed coherence cycle
