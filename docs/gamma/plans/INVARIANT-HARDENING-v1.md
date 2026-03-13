# INVARIANT-HARDENING-v1
## Implementation Plan

**Status:** Active
**Implements:** `docs/gamma/INVARIANTS.md`
**Mode:** MCA
**Goal:** Make the current coherent repo structure self-enforcing.

---

## 0. Coherence Contract

### Gap
The repo/runtime/docs/agent surface are now coherent enough that the main risk is drift:
- package output drifting from source
- runtime drifting from documented contracts
- observability projections drifting from their spec
- agent behavior drifting from doctrine/runtime grammar

### Mode
**MCA** — change CI, tests, and runtime verification to make drift mechanically visible.

### α / β / γ target
- **α:** package/source and schema consistency
- **β:** docs/runtime/agent alignment
- **γ:** release-time drift prevention

---

## 1. Workstreams

| ID | Name | Invariant | Blocking |
|----|------|-----------|----------|
| W1 | Package/source drift check | I1 | Yes |
| W2 | Protocol contract consistency | I2 | Yes |
| W3 | Traceability smoke test | I3 | Yes |
| W4 | Agent behavioral eval | I4 | No (initially) |

---

## 2. Step Order

### Step 1 — CI package/source drift gate

Use existing `cn build --check`.

**Deliverables:**
- CI job: `coherence-build-check`
- Fail PR if `packages/` is stale relative to `src/agent/`

**Acceptance:**
- Editing generated package files directly fails CI
- Editing `src/agent/` without rebuilding packages fails CI

---

### Step 2 — Structured protocol contract

Create a machine-readable protocol contract.

**Path:** `docs/alpha/schemas/protocol-contract.json`

**Contents:**
- Legacy coordination op names
- Typed op kinds (observe + effect)
- Receipt statuses
- Pass labels
- Render reason codes
- Event layers / severities / statuses
- FSM state vocabularies (thread, actor, sender, receiver)
- Readiness projection required fields

**Deliverables:**
- Structured contract file
- Test in `test/cmd/cn_contract_test.ml` that compares code constants against the contract

**Acceptance:**
- Mismatch between code and contract fails CI
- No regex against prose docs

---

### Step 3 — Traceability smoke test

Create a deterministic test that validates readiness projection structure.

**Deliverables:**
- Test in `test/cmd/cn_traceability_test.ml`
- Validates `write_ready` output against required field schema
- CI coverage via existing `dune runtest`

**Acceptance:**
- Missing required readiness fields fails CI
- Shape drift in projections fails CI

---

### Step 4 — Agent behavioral eval (non-blocking first)

Create eval fixtures that check output class, not exact wording.

**Cases:**
1. Typed ops in frontmatter → parsed correctly, no XML wrapper
2. Control-plane syntax → blocked by `is_control_plane_like`
3. Human-facing render → no leak, no raw frontmatter

**Deliverables:**
- Eval fixtures in `test/cmd/cn_output_test.ml` (extend existing)
- CI coverage via existing `dune runtest`

**Acceptance:**
- Initially informational / release-gate only
- Artifacts saved for debugging

---

### Step 5 — Release/merge integration

Update CI workflow so deterministic checks are required.

**Blocking now:**
- Package/source drift (`coherence-build-check`)
- Protocol contract check (via `dune runtest`)
- Traceability smoke (via `dune runtest`)

**Non-blocking initially:**
- Agent behavior eval

**Acceptance:**
- Merge cannot proceed if deterministic invariants fail

---

## 3. File Layout

### New files
- `docs/gamma/INVARIANTS.md` — canonical invariant catalog
- `docs/gamma/plans/INVARIANT-HARDENING-v1.md` — this plan
- `docs/alpha/schemas/protocol-contract.json` — machine-readable protocol contract
- `test/cmd/cn_contract_test.ml` — protocol contract consistency test
- `test/cmd/cn_traceability_test.ml` — readiness projection smoke test
- `.github/workflows/coherence.yml` — coherence-specific CI jobs

### Existing files extended
- `test/cmd/dune` — add new test executables
- `.github/workflows/ci.yml` — reference coherence checks

### Existing reused (unchanged)
- `cn build --check` — package/source sync
- `cn_trace_state.ml` — projection writers
- `cn_output.ml` — render path
- `cn_shell.ml` — typed ops / receipts

---

## 4. CI Jobs

### `coherence-build-check` (blocking)
Runs `cn build --check`. Fails if packages/ stale.

### Protocol + traceability (blocking)
Covered by `dune runtest` — the new test files run as part of the standard test suite.

### `agent-behavioral-eval` (non-blocking initially)
Output-class checks against canonical prompts. Runs in CI but does not block merge.

---

## 5. Success Criteria

Done means:
- Package/source drift cannot merge unnoticed
- Protocol/runtime contract drift cannot merge unnoticed
- Readiness projection drift cannot merge unnoticed
- Agent output regressions are visible before release
