# PLAN-v3.31.0-message-packet-transport

## Implementation Plan for Fail-Closed Message Packet Transport

Status: Draft
Implements: docs/alpha/protocol/MESSAGE-PACKET-TRANSPORT.md
Issue: #150
Depends on: current Git transport, inbox pipeline, trusted peer config, traceability

Purpose: Replace ambiguous diff-based inbox materialization with packet-based, fail-closed validation so stale local state, unexpected files, and adversarial packet contents cannot silently swap message content.

---

## 0. Coherence Contract

### Gap

The current inbox pipeline can materialize the wrong message body because it:

- discovers candidate files by diffing a branch against local main
- depends on local clone freshness
- accepts branch noise as candidate input
- chooses the first matching .md file
- validates nothing about sender intent before writing inbox content

Issue #150 demonstrates that this can silently swap the message body without error. That is a transport-integrity failure at the lowest level.

### Mode

MCA — replace the transport/materialization mechanism.

### α / β / γ target

- α PATTERN: one canonical packet shape and one validation pipeline
- β RELATION: sender intent, Git objects, inbox content, and operator-visible diagnostics all describe the same message
- γ EXIT: future transports can reuse the same packet validator without redesigning materialization

### Smallest coherent intervention

Do not "improve diffing." Land a fail-closed hotfix immediately, then replace diff-based discovery with packet refs + packet validation.

---

## 1. Scope

### In scope

- fail-closed inbound materialization
- canonical packet schema
- Git packet transport adapter
- envelope validation
- payload hash validation
- signature verification (secure mode driven by local policy)
- dedup / equivocation detection
- exact materialization from validated payload
- operator-visible packet lifecycle traces

### Out of scope

- attachments / multipart payloads
- mailbox / chain / nostr adapters
- advanced key distribution / trust federation
- packet schema v2
- UI/product changes beyond diagnostics and traceability

---

## 2. Delivery Strategy

Deliver in three implementation slices plus an immediate hotfix.

### Phase 0 — Legacy path made fail-closed

Goal:
- stop silent wrong-file materialization immediately

### Phase 1 — Canonical packet transport over Git

Goal:
- make Git-based inbound transport packet-based and exact

### Phase 2 — Secure mode and trust hardening

Goal:
- make authenticity receiver-policy-driven and fail closed

### Phase 3 — Deferred extensibility

Goal:
- preserve clean extension points for attachments and alternate transports without landing them now

---

## 3. Phase 0 — Immediate P0 Fail-Closed Hotfix

### Goal

Stop silent corruption before the full packet protocol lands.

### Work

In the legacy diff-based path:

1. fetch/update the peer clone state used by the current path
2. if candidate message files are:
   - 0 → reject
   - >1 → reject
3. never materialize "first match"
4. emit structured diagnostics for:
   - zero_candidates
   - multiple_candidates
   - ambiguous_materialization_blocked

### Acceptance

- the current path cannot silently write a wrong message file
- ambiguity causes rejection, not best-effort guessing
- operators can see why the packet/branch was rejected

### Files likely touched

- src/transport/cn_io.ml
- src/cmd/cn_maintenance.ml
- traceability emission points
- tests for legacy ambiguity

### Risk boundary

This is a hotfix only. It does not make the transport correct; it only makes the current failure class loud and safe.

---

## 4. Phase 1 — Canonical Packet Protocol over Git

## Step 1 — Add packet schema module

### Goal

Introduce a canonical packet representation independent of Git diff semantics.

### Work

Add a packet module, e.g.:

- src/transport/cn_packet.ml

It should define:

- envelope
- payload commitment
- signature record
- Git proof record
- validation result types

### Acceptance

- packet parsing/validation can be tested independently from transport fetching
- sender/recipient/hash/path invariants are modeled explicitly

### Tests

- valid packet parses
- malformed envelope rejects
- missing required fields reject
- unsupported schema/version rejects

---

## Step 2 — Add Git packet ref namespace

### Goal

Stop using arbitrary peer branches as inbox message discovery inputs.

### Work

Use a dedicated namespace:

```
refs/cn/msg/{sender}/{msg_id}
```

Sender-side packet publication should push there. Receiver-side inbox sync should fetch only that namespace into quarantine refs.

### Acceptance

- inbox materialization only considers refs/cn/msg/...
- ordinary branches can no longer enter the inbox path accidentally

### Files likely touched

- src/transport/cn_io.ml
- src/cmd/cn_mail.ml
- Git helper code
- tests for fetch/ref filtering

---

## Step 3 — Define packet tree layout

### Goal

Make the message tree mechanically enumerable.

### Work

Require the fetched packet tree to contain exactly:

```
packet/
  envelope.json
  message.md
  signature.ed25519   (optional only in insecure/dev mode)
```

Prefer a root commit with no parents whose tree contains only the packet.

### Acceptance

- packet trees with extra files reject
- packet trees missing required files reject
- packet materialization no longer depends on merge base or local main

### Tests

- exact tree shape passes
- extra file rejects
- missing envelope rejects
- missing payload rejects

---

## Step 4 — Validate route and payload bindings

### Goal

Make sender intent and payload identity mechanically checkable before any inbox write.

### Work

Implement validator steps:

1. ref sender matches envelope.sender
2. ref msg_id matches envelope.msg_id
3. envelope.recipient matches local node
4. payload_path == "packet/message.md"
5. payload bytes exist at that path
6. payload bytes hash to payload_sha256
7. payload length matches payload_bytes

### Acceptance

- any mismatch rejects before materialization
- payload is identified by content hash, not by diff position or filename guesswork

### Tests

- wrong recipient rejects
- path mismatch rejects
- hash mismatch rejects
- byte-length mismatch rejects
- sender/ref mismatch rejects

---

## Step 5 — Materialize exact payload only

### Goal

Make inbox writes derive from validated payload bytes, not from any search heuristic.

### Work

After validation passes:

- write inbox file from the exact payload bytes
- derive inbox metadata from the validated envelope
- treat markdown frontmatter inside message.md as non-authoritative for transport

### Acceptance

- inbox content equals validated payload bytes exactly
- no "first matching file" logic remains in the packet path

### Tests

- materialized inbox file bytes equal payload bytes
- frontmatter disagreements do not override envelope truth

---

## 5. Phase 2 — Secure Mode and Trust Hardening

## Step 6 — Add receiver-local trust policy

### Goal

Make signature requirement local policy, not sender-controlled metadata.

### Work

Define a local trust source, e.g.:

- trusted peer registry / sender→key mapping

This should govern:

- whether a given peer requires signatures
- what public key(s) are trusted
- unknown peer handling
- key rotation policy

### Acceptance

- packet acceptance policy does not depend on sender-declared secure_mode
- unknown or untrusted senders reject appropriately in secure mode

### Files likely touched

- peer config/trust code
- packet validator
- docs
- tests

---

## Step 7 — Add canonical serialization for signing

### Goal

Make signatures implementable and interoperable.

### Work

Define one canonical envelope serialization for signing and verification:

- deterministic JSON or
- explicit binary canonical form

The validator and sender must both use the same serialization.

### Acceptance

- same logical envelope always yields same signable bytes
- signature verification is deterministic across runs/implementations

### Tests

- canonicalization is stable
- signature verifies for canonical bytes
- altered field order / whitespace does not create ambiguity

---

## Step 8 — Verify signatures before materialization

### Goal

Prevent adversarial substitution, not just accidental corruption.

### Work

In secure mode:

- require signature file
- verify against trusted sender key
- reject on missing/invalid signature before inbox write

### Acceptance

- unsigned packet rejects in secure mode
- invalid signature rejects
- valid signature passes

### Tests

- valid signature accepted
- invalid signature rejected
- missing signature rejected in secure mode
- insecure/dev mode behavior explicit and tested

---

## 6. Phase 2.5 — Dedup and Equivocation

## Step 9 — Add inbound packet index

### Goal

Detect duplicates and equivocation before materialization.

### Work

Maintain an index, e.g.:

```
state/inbound-index.json
```

Keyed by:

- msg_id
- sender
- payload_sha256
- status

Rules:

- same msg_id + same hash → duplicate, ignore safely
- same msg_id + different hash → equivocation, reject loudly

### Acceptance

- duplicates do not rematerialize
- equivocation is detected and surfaced to operator

### Tests

- duplicate same content ignored
- duplicate different content rejected as equivocation

---

## 7. Operator and Traceability Surface

## Step 10 — Emit packet lifecycle events

### Goal

Make transport correctness auditable.

### Work

Emit:

- packet.fetched
- packet.validated
- packet.rejected
- packet.duplicate
- packet.equivocation
- packet.materialized

Include:

- msg_id
- sender
- recipient
- Git proof identifiers
- payload_sha256
- reason_code

### Acceptance

Operators can reconstruct why a packet was or was not materialized.

### Tests

- successful packet path emits fetched → validated → materialized
- failure path emits reject reason
- duplicate/equivocation paths are distinguishable

---

## 8. Send-Side Changes

## Step 11 — Make send-side produce canonical packets

### Goal

Ensure sender and receiver speak the same protocol.

### Work

Update send-side path (`send_thread` / `outbox_flush`) to:

1. create packet/envelope.json
2. create packet/message.md
3. compute payload hash/length
4. sign envelope in secure mode
5. create packet commit/tree
6. push to refs/cn/msg/{sender}/{msg_id}

### Acceptance

- sender produces valid packets accepted by the receiver
- packet publication is deterministic and testable

### Tests

- packet generated on send is accepted by local validator
- malformed sender packet generation is impossible or rejected

---

## 9. Docs and Skill Updates

## Step 12 — Align docs and operational skills

### Goal

Make the design executable across the docs graph.

### Update

- docs/alpha/protocol/MESSAGE-PACKET-TRANSPORT.md
- packages/.../ops/inbox/SKILL.md
- packages/.../ops/peer/SKILL.md
- any operator runbooks for sync/inbox materialization

### Acceptance

Inbox and peer docs no longer describe diff-based message discovery as authoritative.

---

## 10. Tests

### Unit / schema tests

- envelope parsing
- canonical serialization
- trust policy evaluation
- signature verification
- dedup/equivocation logic

### Transport tests

- Git packet ref discovery
- exact tree shape validation
- payload hash/path mismatch rejection

### Integration tests

- send-side packet generation + receiver validation
- no inbox write on invalid packet
- inbox write on valid packet
- duplicate safe ignore
- equivocation loud reject

### Legacy hotfix tests

- zero candidates reject
- multiple candidates reject
- no more first-match materialization

---

## 11. CI / Release Gating

Before release:

- packet schema tests green
- signature / trust tests green
- Git packet transport tests green
- integration materialization tests green
- traceability tests green
- legacy ambiguity hotfix tests green

---

## 12. Non-goals

This plan does not include:

- attachments / multipart payloads
- mailbox / chain / nostr transport adapters
- federation of trust keys
- packet schema v2
- inbox triage semantics
- UI/product changes beyond diagnostics

---

## 13. Acceptance Criteria

This implementation line is complete when:

### Phase 0

1. Legacy ambiguity no longer materializes a "first match."
2. Zero or multiple candidate files reject loudly.

### Phase 1

3. Inbox materialization no longer depends on diffing against local main.
4. Every inbound packet is validated before any inbox write.
5. A packet with invalid shape, wrong recipient, or mismatched payload is rejected.
6. Materialized inbox content is exactly the validated payload bytes.

### Phase 2

7. In secure mode, unsigned or invalidly signed packets are rejected.
8. Signature requirement is driven by local trust policy, not sender-controlled fields.
9. Trusted-key source is explicit and enforced.

### Dedup

10. Duplicate same-content packets are ignored safely.
11. Duplicate same-ID different-content packets are rejected as equivocation.

### Operator truth

12. Packet lifecycle is visible in traceability.
13. No silent wrong-content materialization remains possible.

---

## 14. Known Debt

- Attachments deferred
- Multi-transport adapters deferred
- Key rotation tooling may start minimal
- Legacy compatibility path may need temporary support during migration
- Dedup index pruning not yet designed

---

## 15. Summary

This plan replaces:

- diff-based discovery
- merge-base dependence
- guessed payload selection

with:

- canonical packets
- transport-proof validation
- local trust policy
- exact payload materialization
- dedup/equivocation checks
- fail-closed operator-visible rejection

That is the smallest coherent path from the current P0 bug to a bulletproof transport substrate.
