# SELF-COHERENCE

Issue: #150
Version: 3.31.0
Mode: MCA
Active Skills: ocaml, coding, testing

## Terms

- **Packet**: A self-contained message unit with envelope, payload, and transport proof. Replaces branch-diff discovery.
- **Envelope**: `packet/envelope.json` -- sole transport-authoritative manifest. Contains sender, recipient, payload hash, byte length, topic, msg_id.
- **Payload commitment**: SHA-256 hash of payload bytes. The canonical content identity (transport-agnostic).
- **Fail-closed**: If any validation step fails, no inbox write occurs. No "first match" guessing.
- **Dedup index**: `state/inbound-index.json` keyed by (msg_id, sender, payload_sha256). Same hash = duplicate (ignore), different hash = equivocation (reject loudly).
- **Packet ref namespace**: `refs/cn/msg/{sender}/{msg_id}` -- dedicated namespace for inbound packets, separate from arbitrary branches.

## Pointer

- `src/cmd/cn_mail.ml:46-142` -- `materialize_packet`: packet validation + dedup + exact materialization
- `src/cmd/cn_mail.ml:144-181` -- `inbox_process`: packet-only path (legacy diff-based path deleted)
- `src/cmd/cn_mail.ml:199-315` -- `send_thread`: packet creation via `Cn_packet.create_git_packet`
- `src/transport/cn_packet.ml` -- Packet schema types, envelope serialization, 9-step validation pipeline, dedup index, Git packet operations
- `test/transport/cn_packet_test.ml` -- 16 ppx_expect tests

## Exit

All four issue ACs verified:

- [x] AC1: Legacy `materialize_branch` deleted; `materialize_packet` materializes exact validated payload only
- [x] AC2: When candidate cannot be unambiguously identified, materialization fails with error -- 0 candidates -> reject, >1 candidates -> reject, trace events emitted
- [x] AC3: Obsolete -- peer clone main freshness no longer relevant (diff-based path removed entirely)
- [x] AC4: No silent content swap -- payload identified by SHA-256, validated before any inbox write

## Triadic Self-Check

- alpha: 4/4 -- Packet types are unambiguous: distinct field names (pkt_schema, pkt_sender, pkt_recipient, pkt_topic), validation_result is a clean sum type (Valid | Rejected), dedup_status is a closed enum. Envelope serialization round-trips through JSON. SHA-256 is the canonical content identity.
- beta: 4/4 -- Send side creates packets -> receive side validates them. Envelope fields match ref namespace bindings. Dedup index tracks all inbound packets. Legacy diff-based path fully deleted -- packet is the only materialization path. Packet lifecycle events cover fetched/validated/rejected/duplicate/equivocation/materialized.
- gamma: 4/4 -- 16 tests cover envelope round-trip, validation rejection (5 failure modes), dedup (3 cases), ref parsing (3 cases), payload commitment determinism (2 cases), msg_id format. Single-path inbox_process (packets only).
- Weakest axis: none -- all axes clean
- Action: none

## Known Debt

- Phase 2 (signatures) deferred -- design is in MESSAGE-PACKET-TRANSPORT.md but not implemented
- Dedup index pruning not yet designed (index grows unbounded)
- Legacy branch send/receive path fully removed in favor of packets; peers running old versions will not receive packets (migration doc needed)
- `cn_io.ml` still contains old `materialize_branch` / `sync_inbox` -- dead code, separate cleanup
- `create_git_packet` uses `printf '%s'` for payload blob creation which may have shell escaping issues with binary content; text/markdown is safe
