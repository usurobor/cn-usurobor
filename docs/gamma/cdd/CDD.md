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

### 3.2 Operational infrastructure override

If core operational paths are broken, fix them before feature work. Examples:

- self-update broken
- logging absent
- health checks missing
- deployment path incoherent
- system cannot observe or maintain itself

These are not "nice to have." They are preconditions for coherent development.

### 3.3 Assessment commitment default

If the last assessment named a next MCA and no stronger override fires, that MCA is selected by default. Observation may override it, but the override must be stated explicitly.

### 3.4 MCI freeze check

If the lag table contains stale issues, the next substantial MCA must come from the stale set. New design work is frozen until at least one stale item ships.

### 3.5 Weakest-axis rule

If no stronger rule decides selection, choose work that addresses the weakest current axis:

- α → structural / consistency work
- β → alignment / integration work
- γ → process / evolution work

### 3.6 Maximum leverage

Among candidates that address the weakest axis, choose the one that moves the most lag entries.

### 3.7 Dependency order

If A blocks B blocks C, choose A regardless of local excitement or presentation value.

### 3.8 Effort-adjusted tie-break

Between candidates with equal leverage and axis effect, choose the smaller one. Ship sooner, observe sooner, correct sooner.

### 3.9 No-gap case

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
| 5 | Mode | Choose MCA, MCI, or both | Mode stated with rationale |
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

### 5.3 Supporting rules

- one source of truth per fact
- derive, do not duplicate
- update docs before release
- write tests before or alongside the code they validate
- build-sync source asset changes before commit
- enumerate affected files before implementation begins
- every AC must map to evidence before review

### 5.4 Frozen snapshot rule

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
- process learning
- review quality metrics
- next move commitment

The CHANGELOG TSC entry at release time is provisional. Assessment governs the final judgment of the cycle.

---

## 10. Closure

A cycle is not closed merely because code merged.

### 10.1 Immediate outputs

These must be executed within the same cycle:

- changelog corrections
- missing documentation
- skill/process micro-patches
- issue filing required by the assessment
- lag-table updates
- metadata fixes

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

That is the handoff from step 13 back to step 0.

---

## 11. Related documents

### 11.1 Executable summary

`src/agent/skills/ops/cdd/SKILL.md` is the executable summary of this spec.

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
