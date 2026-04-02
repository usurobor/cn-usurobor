# SELF-COHERENCE

Issue: #144
Version: 3.28.0
Mode: MCA
Active Skills: ocaml, performance-reliability, testing

## Terms

Fixed three interacting bugs in the orphan rejection mechanism that caused unbounded branch spam:

1. **Rejection deduplication** — replaced timestamped filenames (`make_thread_filename`) with deterministic filenames (`rejection_filename`) keyed on (peer, branch). Added `is_already_rejected` check before creating rejection messages.

2. **Authoritative sender identity** — removed `get_branch_author` (git log inference). Rejection messages now use `peer_name` (fetched peer identity) exclusively. Added `from:` field to rejection frontmatter envelope.

3. **Self-send guard** — added `to_name = name` check in `send_thread` before attempting outbox flush. Self-addressed messages emit `outbox.skip` trace event with `reason_code:"self_send"`.

## Pointer

The orphan rejection mechanism had no terminal state for rejected branches. Each sync cycle (~5 min) re-detected the same orphan, created a new timestamped rejection file, and attempted to send it. Over 2.5 hours, 30+ rejection branches accumulated from a single orphaned reply. The amplification path was: orphan detected → timestamped rejection file created → sent to peer → peer re-fetches → orphan still exists → repeat.

## Exit

- `rejection_filename` produces deterministic names: same (peer, branch) always maps to same file
- `is_already_rejected` checks outbox and sent dirs before creating a new rejection
- `reject_orphan_branch` short-circuits with dedup log when already rejected
- `send_thread` rejects self-send before peer lookup
- `get_branch_author` removed (dead code after fix)
- 8 ppx_expect tests prove the three invariants

## Acceptance Criteria Check

- [x] AC1: Rejection deduplication prevents re-processing of already-rejected orphan branches
- [x] AC2: Fetched peer identity is authoritative for transport sender (not git log author)
- [x] AC3: Self-send guard prevents outbox flush when to == my_name
- [x] AC4: Tests prove all three invariants (8 tests: 4 dedup, 2 identity, 2 negative space)
- [x] AC5: No amplification path remains — rejection is bounded (deterministic filename = at most 1 rejection per (peer, branch))

## Triadic Self-Check

- alpha: 4/4 — three fixes cleanly separated (dedup, identity, self-send); tests per invariant; no type ambiguity
- beta: 4/4 — rejection frontmatter now has `from:` field; trace events use existing `outbox.skip` pattern with new reason codes; FSM transitions unchanged (correct in protocol, now used correctly in mail)
- gamma: 4/4 — single-session fix; 3 files changed (cn_mail.ml, dune, cn_mail_test.ml); 1 file created (test); bootstrap + self-coherence present
- Weakest axis: none — straightforward MCA bugfix
- Action: none

## Known Debt

- Rejection messages remain in outbox/sent indefinitely — no TTL or cleanup. Low priority: deterministic filenames bound count to O(peers * orphan_branches).
- `get_branch_author` pattern still exists conceptually in the codebase mental model. If future code needs git-author data for display, it should be re-added as informational-only, never for routing.
