# INVARIANTS
## Coherence Invariants for cnos

**Version:** 1.0
**Status:** Active
**Purpose:** Define the minimum invariants that must hold for the repo, runtime, docs, and agent surface to remain coherent as cnos evolves.

---

## 0. Purpose

cnos is now structurally coherent enough that the primary risk is **drift**.

This document defines the invariants that must be mechanically enforced so that:
- source remains the source of truth
- runtime behavior stays aligned with docs
- observability remains truthful
- the agent surface remains behaviorally coherent

These invariants are not advisory.
They are test and CI gates.

---

## 1. Invariant Classes

### 1.1 α — Pattern integrity
Internal consistency of articulated artifacts.

Examples:
- `src/agent/` is the only source of truth for doctrine, mindsets, skills
- generated `packages/` matches source
- protocol/runtime types match the structured protocol contract

### 1.2 β — Relation integrity
Alignment across artifacts and layers.

Examples:
- docs describe the same protocol/runtime that code executes
- readiness projections match the observability spec
- coordination ops / typed ops / receipt statuses are consistent across layers

### 1.3 γ — Evolution integrity
The system stays coherent as it changes.

Examples:
- CI blocks stale package output
- release gates block observability drift
- behavioral regressions are caught before release

---

## 2. Core Invariants

### I1. Source → Package Integrity

`src/agent/` is the single source of truth for doctrine, mindsets, and skills.

**Requirement:**
Running:
```bash
cn build --check
```
must succeed in CI.
If `packages/` does not match what `src/agent/` would generate, the build fails.

**Why:** Prevents manual edits to generated package output and preserves α consistency.

**Enforcement:** Blocking PR CI (`coherence-build-check` job).

---

### I2. Protocol Contract Consistency

The runtime and the documented protocol surface must match.

**Requirement:**
A structured protocol contract (`docs/alpha/schemas/protocol-contract.json`) must exist in machine-readable form and be checked against code.

Things that must match:
- Legacy coordination op vocabulary: `ack`, `done`, `fail`, `reply`, `send`, `delegate`, `defer`, `delete`, `surface`, `mca`
- Typed op kinds (observe): `fs_read`, `fs_list`, `fs_glob`, `git_status`, `git_diff`, `git_log`, `git_grep`
- Typed op kinds (effect): `fs_write`, `fs_patch`, `git_branch`, `git_commit`, `exec`
- Receipt statuses: `ok`, `denied`, `error`, `skipped`
- Pass labels: `A` (observe), `B` (effect)
- Render reasons: `control_plane_leak`, `raw_frontmatter`, `xml_tool_syntax`, `no_presentation_payload`
- Event layers: `sensor`, `body`, `mind`, `governance`, `world`
- Event severities: `debug`, `info`, `warn`, `error`
- Event statuses: `ok`, `degraded`, `blocked`, `error`, `skipped`
- FSM states (thread): `received`, `queued`, `active`, `doing`, `deferred`, `delegated`, `archived`, `deleted`
- FSM states (actor): `idle`, `updating`, `input_ready`, `processing`, `output_ready`, `timed_out`
- FSM states (sender): `pending`, `branch_created`, `pushing`, `pushed`, `failed`, `delivered`
- FSM states (receiver): `fetched`, `materializing`, `materialized`, `skipped`, `rejected`, `cleaned`
- Readiness statuses: `ready`, `degraded`, `blocked`, `starting`

**Why:** Prevents docs/runtime drift and preserves β relation.

**Enforcement:** Blocking PR CI (`protocol-contract-check` job).

**Note:** Checks compare code against a structured JSON contract, not freeform markdown prose.

---

### I3. Traceability Contract Integrity

Operational truth must remain reconstructable.

**Requirement:**
`state/ready.json` and related projections must match the schema and minimum field set described in TRACEABILITY.md.

At minimum, `ready.json` must contain:
- `schema` — `cn.ready.v1`
- `status` — readiness status
- `boot_id` — session identifier
- `updated_at` — ISO timestamp
- `mind.profile` — active profile name
- `mind.packages` — loaded package list
- `mind.doctrine.required` / `mind.doctrine.loaded` — doctrine counts
- `mind.mindsets.required` / `mind.mindsets.loaded` — mindset counts
- `mind.capabilities.n_pass` / `mind.capabilities.apply_mode` / `mind.capabilities.exec_enabled` — capabilities posture
- `body.fsm_state` — current actor FSM state
- `body.queue_depth` — items waiting

**Why:** An operator must be able to answer "is it fully operational?" from files alone.

**Enforcement:** Blocking PR CI (`traceability-smoke` job).

---

### I4. Agent Output Contract Integrity

The agent must continue to use the runtime's output grammar coherently.

**Requirement:**
Given a canonical packed context with doctrine + capabilities + skills, the agent/runtime path must preserve:
- Legacy coordination ops when appropriate
- Typed ops when observation/effect is needed
- No XML/pseudo-tool hallucination
- No control-plane leakage to human surfaces

**Why:** Preserves the live agent surface and prevents regression of the CN Shell contract.

**Enforcement:** Non-blocking at first; nightly / release-gate eval. May become partially blocking after stabilization.

---

## 3. Required Check Types

### 3.1 Deterministic structural checks (blocking)
- Package/source drift (`cn build --check`)
- Protocol contract consistency (code vs `protocol-contract.json`)
- Traceability readiness schema (required fields present)

### 3.2 Behavioral checks (initially non-blocking)
- Agent output grammar
- Sink-safe rendering
- Capability-use behavior

Behavioral checks become blocking only after they are stable and trusted.

---

## 4. CI Policy

**Blocking checks:**
1. `coherence-build-check` — package/source sync
2. `protocol-contract-check` — code ↔ contract alignment
3. `traceability-smoke` — readiness projection schema

**Non-blocking initially:**
4. `agent-behavioral-eval` — output grammar / surface integrity

---

## 5. Relationship to Other Docs

- **CDD.md** — explains why releases are coherence deltas
- **TRACEABILITY.md** — defines operational truth
- **AGENT-RUNTIME.md** — defines runtime contracts
- **CAR.md** / package docs — define source/package model
- **INVARIANT-HARDENING-v1.md** — implementation plan for this document

This document defines what must remain invariant across those layers.

---

## 6. Success Criteria

The invariant system is in place when:
- Package drift is impossible to merge unnoticed
- Protocol/runtime/doc mismatch is caught automatically
- Readiness projection drift is caught automatically
- Agent contract regressions are visible before release
