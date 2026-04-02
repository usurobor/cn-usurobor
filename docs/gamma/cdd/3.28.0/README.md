# v3.28.0 — Orphan Rejection Loop Fix

Issue: #144
Branch: claude/execute-issue-144-cdd-O6Rl3
Mode: MCA
Active skills: ocaml, performance-reliability, testing

## Snapshot Manifest

- README.md — this file
- SELF-COHERENCE.md — triadic self-check
- POST-RELEASE-ASSESSMENT.md — (post-release)

## Deliverables

- Fix orphan rejection deduplication (no terminal state)
- Fix weak sender inference (use fetched peer identity)
- Add self-send guard to outbox flush
- Tests for all three fixes
