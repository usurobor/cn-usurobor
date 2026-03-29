# Selection — v3.26.0

## Observation Inputs

### CHANGELOG TSC (baseline)

v3.25.0: C_Sigma A, alpha A, beta A, gamma A-

### Encoding Lag (from v3.25.0 assessment)

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #74 | Rethink logs structure (P0) | process | issue spec + evidence comments | not started | **growing** |
| #59 | cn doctor — deep validation | feature | partial design | partially addressed | low |
| #68 | Agent self-diagnostics | feature | issue spec | not started | growing |
| #84 | CA mindset reflection requirements | feature | issue spec | not started | growing |
| #79 | Projection surfaces | feature | issue spec | not started | growing |
| #94 | cn cdd: mechanize CDD invariants | feature | issue spec | not started | growing |
| #100 | Memory as first-class capability | feature | issue spec | not started | growing |
| #96 | Docs taxonomy alignment | process | issue spec | not started | growing |
| #101 | Normalize skill corpus | process | issue spec | not started | growing |
| #20 | Eliminate silent failures in daemon | bug | issue spec | not started | growing |
| #43 | No interrupt mechanism | feature | issue spec | not started | growing |
| #124 | Agent asks permission despite autonomy defaults | bug | issue spec | not started | growing |

### Last Post-Release Assessment

v3.25.0 assessment committed #74 as next MCA:
> "Next MCA: #74 — Rethink logs structure (P0)"

## Selection Rules Applied

1. **P0 override (CDD section 3.1):** #74 is the only remaining P0 issue.
2. **Assessment commitment default (CDD section 3.3):** v3.25.0 assessment committed #74 as next MCA.

## Why #74

Operator observability requires understanding 6 log locations, 4 formats, and manual correlation. No single command answers "what happened?" The system's own events stream (logs/events/) has the right idea but wrong scale (22MB/day) and missing key data (no message content, no correlation across input/output files). The daemon summary is actively misleading ("0 ops" for invocations that did real work).

Three evidence comments on the issue document:
1. daemon.log reports "0 ops" for invocations with 3 passes, 28K tokens, 2 observe ops
2. N-pass bind intermediate steps are not persisted (passes 0-N between first input and final output are lost)
3. Root-owned event file caused crash-loop with no dedup, no rate limiting

## Engineering Level Target: L7

This changes the observability boundary. Today: 6 locations, 4 formats, manual correlation. After: one structured stream + one CLI command. The class of failure (operator can't find what happened) becomes impossible by construction. Enables #68 (self-diagnostics), #59 (doctor), #65 (conversation persistence).

## Phasing

Per issue comment scoping note:
- **Phase 1 (this release):** Unified log stream + `cn logs` (basic tail + time filter + json output + msg filter + errors)
- Phase 2 (follow-up): Step-level trace archival, conversation index
- Phase 3 (follow-up): Archive cleanup, retention/rotation, daemon.log replacement
