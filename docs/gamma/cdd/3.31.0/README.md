# v3.31.0 — Fail-Closed Inbox Materialization

Issue: #150
Branch: claude/execute-issue-150-cdd-O6Rl3
Mode: MCA
Active skills: ocaml, coding, testing
Engineering Level: L7

## Snapshot Manifest

- README.md — this file
- PLAN-message-packet-transport.md — 12-step implementation plan (pre-existing)
- SELF-COHERENCE.md — triadic self-check

## Deliverables

### Phase 0 — P0 Hotfix (fail-closed legacy path)
- Pull clone main before diffing to eliminate stale merge base
- Fail closed on 0 or >1 candidate message files (never "first match")
- Emit structured diagnostics for ambiguous materialization
- Trace events for rejection/ambiguity

### Phase 1 — Canonical Packet Protocol
- `cn_packet.ml` — packet schema types (envelope, payload, transport proof, validation result)
- Packet validation pipeline (9-step, all before materialization)
- `refs/cn/msg/{sender}/{msg_id}` namespace for inbound packets
- Send-side packet creation in `send_thread`
- Exact materialization from validated payload bytes only
- Dedup index (same msg_id + same hash = ignore; different hash = equivocation)
- Packet lifecycle trace events

### Phase 2 — Deferred
- Signature enforcement (receiver-local policy)
- Trusted peer registry with public keys

## Design

docs/alpha/protocol/MESSAGE-PACKET-TRANSPORT.md

## Acceptance Criteria (from issue)

- AC1: `materialize_branch` only materializes files introduced by the branch, not stale diff noise
- AC2: When a message file cannot be unambiguously identified, materialization fails with error
- AC3: Peer clone main is current before diff computation
- AC4: No silent content swap under any stale-clone condition
