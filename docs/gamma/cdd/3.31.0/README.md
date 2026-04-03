# v3.31.0 -- Fail-Closed Inbox Materialization

Issue: #150
Branch: claude/execute-issue-150-cdd-O6Rl3
Mode: MCA
Active skills: ocaml, coding, testing
Engineering Level: L7

## Snapshot Manifest

- README.md -- this file
- PLAN-message-packet-transport.md -- 12-step implementation plan (pre-existing)
- SELF-COHERENCE.md -- triadic self-check

## Deliverables

### Phase 1 -- Canonical Packet Protocol (replaces legacy diff-based path)
- `cn_packet.ml` -- packet schema types (envelope, payload, transport proof, validation result)
- Packet validation pipeline (9-step, all before materialization)
- `refs/cn/msg/{sender}/{msg_id}` namespace for inbound packets
- Send-side packet creation in `send_thread`
- Exact materialization from validated payload bytes only
- Dedup index (same msg_id + same hash = ignore; different hash = equivocation)
- Packet lifecycle trace events
- Legacy diff-based materialize_branch and all orphan/rejection helpers deleted

### Phase 2 -- Deferred
- Signature enforcement (receiver-local policy)
- Trusted peer registry with public keys

## Design

docs/alpha/protocol/MESSAGE-PACKET-TRANSPORT.md

## Acceptance Criteria (from issue, updated for packet-only path)

- AC1: Inbox materialization only writes exact validated payload content, not stale diff noise (legacy path deleted)
- AC2: When a message file cannot be unambiguously identified, materialization fails with error
- AC3: Obsolete -- peer clone main freshness no longer relevant (diff-based path removed)
- AC4: No silent content swap under any stale-clone condition (structural: payload identified by SHA-256)
