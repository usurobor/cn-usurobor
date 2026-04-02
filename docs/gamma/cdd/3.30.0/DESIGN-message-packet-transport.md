# Message Packet Transport

**Issue:** #150
**Version:** 3.30.0
**Mode:** MCA
**Active Skills:** design, inbox, writing
**Engineering Level:** L7

## Problem

Inbox materialization can silently write the wrong message content. The receiver reads a different message than the sender sent, with no error or warning.

**Evidence:** Pi sent `sigma/axiom-says-hi` with body "Axiom says hi." Sigma materialized it with body from `where-does-a-surfaced-mca-for.md` — a completely different message from a different date. Triage proceeded on wrong content. The actual message was silently dropped.

**Mechanism:** `get_branch_files` runs `git diff main...origin/<branch>` on the local peer clone. When the clone's main is stale, the diff includes every file changed since the old merge base — not just the message file. `materialize_branch` iterates all diff results and writes the first unarchived `.md` match. Wrong file first in diff = wrong content in inbox.

**Failure modes:**

1. **Stale clone main** — diff against old merge base returns noise files
2. **Ambiguous file selection** — materializer picks first match, not the intended file
3. **No content verification** — receiver never checks that materialized content matches what the sender declared
4. **No dedup by identity** — duplicate detection is filename-based, not message-identity-based
5. **No equivocation detection** — same message ID with different content is not caught

## Constraints

### Existing contracts

- Pull-only transport: agents push to their own repo, peers fetch (inbox skill §2.1.3)
- Frontmatter envelope: `from`, `to`, `id`, `sent`, `thread` (issue #144 design)
- `cn_io.ml` `materialize_branch` is the materialization entry point
- `peers.md` defines peer clones and their local paths
- Inbox skill governs triage; this design governs transport

### What can't change

- Git as the transport substrate
- Pull-only fetch model
- Peer clone approach (each agent maintains local clones of peers)
- Hub structure (`threads/mail/inbox/`, `threads/mail/outbox/`, `threads/mail/sent/`)

### Abstraction level

This is a transport protocol change. It sits below the inbox skill (triage) and above Git operations (plumbing). The protocol defines the packet shape, validation pipeline, and materialization contract.

## Challenged Assumption

**The current code assumes that diffing a branch against main is a reliable way to discover which file is the message.** This assumption fails when the clone's main diverges from the peer's main, when branches contain unexpected files, or when multiple message-like files appear in the diff.

The replacement assumption: **a message is a self-contained packet with a fixed shape and an explicit manifest. The receiver validates the manifest against the actual content before any inbox write.**

## Impact Graph

### Downstream consumers

| Consumer | How it's affected |
|----------|------------------|
| `materialize_branch` in `cn_io.ml` | Replaced: no longer diffs against main; validates packet shape instead |
| `sync_inbox` in `cn_io.ml` | Updated: fetches packet refs, not arbitrary branches |
| `get_branch_files` in `cn_io.ml` | Removed or bypassed: packet tree is validated directly, not discovered via diff |
| `inbox_check_once` in `cn_maintenance.ml` | Updated: calls new packet validation pipeline |
| `reject_orphan_branch` in `cn_maintenance.ml` | Updated: orphan detection uses packet schema presence, not merge base |
| `outbox_flush` / `send_thread` in `cn_mail.ml` | Updated: sends must produce packet commits, not bare branch pushes |
| Inbox skill (`ops/inbox/SKILL.md`) | Updated: §2.1.2 input shape reflects packet envelope; §2.1.3 transport docs updated |
| Peer skill (`ops/peer/SKILL.md`) | Updated: send protocol produces packets |

### Upstream producers

| Producer | What it provides |
|----------|-----------------|
| `send_thread` in `cn_mail.ml` | Must produce packet commits with `envelope.json` + `message.md` |
| `cn sync` CLI | Must fetch `refs/cn/msg/` namespace, not arbitrary branch names |
| Peer clone (`cn-pi-clone`, etc.) | Must have packet refs fetched correctly |

### Copies and authority

| Artifact | Authority |
|----------|-----------|
| `envelope.json` in packet | Authoritative manifest for the message |
| Frontmatter in `message.md` | Message-level metadata (from, to, thread) — must agree with envelope |
| Inbox file frontmatter | Derived from validated envelope at materialization time |
| Branch name / ref path | Routing only — not authoritative for content |

## Proposal

### Data model

```
type packet = {
  envelope : envelope;
  payload  : payload;
  signature : signature option;
}

type envelope = {
  schema       : string;            (* "cn.packet.v1" *)
  msg_id       : string;            (* "<ulid>@<sender>" *)
  sender       : string;
  recipient    : string;
  created_at   : string;            (* ISO 8601 *)
  content_type : string;            (* "text/markdown" *)
  payload_path : string;            (* "packet/message.md" — fixed *)
  payload_blob_oid : string;        (* git blob SHA *)
  payload_sha256   : string;        (* SHA-256 of payload bytes *)
  payload_bytes    : int;
  topic        : string;
  thread       : string option;
  reply_to     : string option;
  protocol     : protocol_meta;
}

type protocol_meta = {
  transport : string;   (* "git-packet" *)
  version   : int;      (* 1 *)
}

type payload = {
  blob_oid : string;
  sha256   : string;
  bytes    : int;
  content  : string;
}

type validation_result =
  | Valid of packet
  | Rejected of { reason_code : string; reason : string }
```

### Packet ref namespace

```
refs/cn/msg/<sender>/<msg_id>
```

Only refs under `refs/cn/msg/` enter the inbox pipeline. All other peer refs are ignored by materialization.

### Packet commit shape

Each packet ref points to a **root commit** (no parents) whose tree contains exactly:

```
packet/
  envelope.json
  message.md
  signature.ed25519   (* optional in Phase 1, required in Phase 2 *)
```

No other files. Root commit eliminates dependency on merge base, main staleness, or branch history.

### Validation pipeline

Nine steps, all before any inbox write. If any step fails, no write occurs.

| Step | Check | Reject reason |
|------|-------|---------------|
| 1 | Fetch to quarantine ref | fetch_failed |
| 2 | Resolve commit + tree OIDs | invalid_commit |
| 3 | Tree contains exactly allowed files | invalid_tree_shape |
| 4 | Parse `envelope.json` — all required fields present, schema = `cn.packet.v1` | invalid_envelope |
| 5 | `envelope.sender` = ref sender, `envelope.msg_id` = ref msg_id, `envelope.recipient` = local name | namespace_mismatch |
| 6 | Load `packet/message.md` — blob OID, SHA-256, byte length all match envelope | payload_mismatch |
| 7 | Verify signature (Phase 2; skip in Phase 1) | signature_invalid |
| 8 | Check dedup index — same msg_id + different hash = equivocation | equivocation |
| 9 | Write inbox file from validated payload bytes + envelope metadata | — |

### Send-side changes

`send_thread` / `outbox_flush` must produce packet commits:

1. Write `packet/envelope.json` with all required fields
2. Write `packet/message.md` with message content
3. Compute `payload_blob_oid`, `payload_sha256`, `payload_bytes`
4. Create root commit (no parents) with only the packet tree
5. Push to `refs/cn/msg/<recipient>/<msg_id>` on own repo

### Dedup and equivocation

- `msg_id` format: `<ULID>@<sender>` — globally unique, monotonic
- Inbound index: `state/inbound-index.json` keyed by `(msg_id, sender)`
- Same msg_id + same payload_sha256 → duplicate, ignore
- Same msg_id + different payload_sha256 → equivocation, reject, log

### Materialization rule

The materializer writes exactly the validated payload blob. It does not search, diff, or guess. The inbox file's frontmatter is derived from the validated envelope — never from filenames, branch topics, or diff output.

## Leverage

- Future message types (attachments, multi-part) extend the packet schema without reintroducing ambiguity
- Signature verification (Phase 2) becomes a gate in the existing pipeline, not a redesign
- Dedup index enables reliable exactly-once delivery semantics
- Packet shape is testable in isolation — no integration setup required for validation tests
- Orphan detection becomes trivial: ref exists but fails validation = orphan

## Negative Leverage

- Send path becomes heavier: must compute hashes, create root commits, push to dedicated refs
- Two-phase migration: old-format branches coexist with new packets during rollout
- Dedup index is new state that must be persisted and garbage-collected
- Envelope schema becomes a versioned contract — changes require schema migration

## Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Better diffing (pull clone main before diff) | Minimal code change | Still diff-based discovery; fails if clone and peer diverge in other ways | Phase 0 hotfix only |
| Diff against branch parent instead of main | Correct diff semantics | Still discovers files from diff; doesn't prevent ambiguity if branch has multiple files | Phase 0 hotfix only |
| Filter diff to `threads/in/` only | Reduces noise | Doesn't verify content; still guesses which file is the message | Phase 0 hotfix only |
| **Packet-based with envelope validation** | Eliminates all discovery ambiguity; fail-closed | Heavier send path; migration needed | **Selected — Phase 1** |
| Full cryptographic signing | Prevents adversarial substitution | Requires key management infrastructure | Phase 2 |

## Process Cost / Automation Boundary

**New artifacts:**
- `envelope.json` per message — produced by sender, consumed by receiver validation
- `state/inbound-index.json` — produced by receiver, consumed by dedup check
- Packet validation pipeline — 9 mechanical steps, all automatable

**Who pays:** The send path adds ~50 lines of envelope generation + root commit creation. The receive path replaces diff-based discovery with structured validation — similar complexity, much higher reliability.

**Automation boundary:**
- Packet shape validation, envelope parsing, hash verification, dedup: all mechanical, all automated
- Triage (what to do with the message once validated): remains human/agent judgment per inbox skill

## Non-goals

- Encrypting message content (transport-layer concern, not materialization)
- Replacing Git as transport substrate
- Changing the pull-only fetch model
- Supporting non-Markdown payloads in Phase 1
- Key management infrastructure in Phase 1

## File Changes

### Create

| File | Contents |
|------|----------|
| `src/transport/cn_packet.ml` | Packet types, envelope parser, validation pipeline (9 steps) |
| `src/transport/cn_packet.mli` | Public interface for packet validation |
| `test/transport/cn_packet_test.ml` | Tests: valid packet, each rejection class, dedup, equivocation |

### Edit

| File | Change |
|------|--------|
| `src/transport/cn_io.ml` | `sync_inbox`: fetch `refs/cn/msg/` instead of arbitrary branches. `materialize_branch` → `materialize_packet`: validate before write. Remove `get_branch_files` diff-based discovery. |
| `src/cmd/cn_mail.ml` | `send_thread` / `outbox_flush`: produce packet commits (root commit, envelope.json, message.md). Push to `refs/cn/msg/<recipient>/<msg_id>`. |
| `src/cmd/cn_maintenance.ml` | `inbox_check_once`: call packet validation pipeline. `reject_orphan_branch`: use packet schema presence for orphan detection. |
| `src/transport/git.ml` | Add: `create_root_commit`, `ls_tree`, `show_blob`, `fetch_refspec`. |
| `src/agent/skills/ops/inbox/SKILL.md` | §2.1.2: input shape reflects packet envelope. §2.1.3: transport docs describe packet model. |
| `packages/cnos.core/skills/ops/inbox/SKILL.md` | Mirror of above. |

### Phase 0 Hotfix (immediate, before full packet protocol)

| File | Change |
|------|--------|
| `src/transport/cn_io.ml` | `get_branch_files`: fail closed if 0 or >1 candidate message files. Pull clone main before diff. Filter to `threads/in/` and `threads/out/` only. |

## Acceptance Criteria

### Phase 0

- [ ] `get_branch_files` returns error (not empty list or first match) when diff yields 0 or >1 message files
- [ ] Clone main is pulled before any diff computation
- [ ] `materialize_branch` never writes content from a file that wasn't the intended message

### Phase 1

- [ ] `send_thread` produces packet commits: root commit, `packet/envelope.json`, `packet/message.md`, pushed to `refs/cn/msg/<recipient>/<msg_id>`
- [ ] `envelope.json` contains all required fields per schema
- [ ] `sync_inbox` fetches only `refs/cn/msg/` namespace
- [ ] Validation pipeline rejects: invalid tree shape, missing envelope, wrong recipient, payload OID mismatch, payload SHA-256 mismatch, payload byte length mismatch
- [ ] Dedup index prevents duplicate materialization (same msg_id + same hash)
- [ ] Equivocation detected and rejected (same msg_id + different hash)
- [ ] Materialized inbox content is exactly the validated payload blob
- [ ] Stale clone main does not affect materialization correctness (no diff against main)
- [ ] `grep -rn "diff.*main\.\.\." src/transport/cn_io.ml` returns zero matches after Phase 1

### Phase 2

- [ ] Unsigned packets rejected in secure mode
- [ ] Invalid signatures rejected
- [ ] Sender public key verified against configured peer keys

## Known Debt

- Phase 0 hotfix coexists temporarily with the old diff-based path
- Old-format branches (non-packet) must be handled during migration (reject or legacy-materialize with warning)
- Dedup index garbage collection not designed (unbounded growth if not pruned)
- Attachments / multi-part payloads deferred to Phase 3
- No schema migration strategy yet (what happens when `cn.packet.v2` is needed)

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| 0 Observe | Daily reflection, Pi message triage failure | inbox | Silent content swap observed during heartbeat triage |
| 1 Select | #150 | — | P0: data integrity failure in messaging |
| 4 Gap | This design doc | design, inbox, writing | Diff-based discovery is structurally unsafe; packet-based validation is the minimum coherent fix |
| 5 Mode | This design doc | design, inbox, writing | MCA, L7 — protocol replacement, not patch |
| 6 Artifacts | DESIGN-message-packet-transport.md | — | Design complete; Phase 0 hotfix + Phase 1 packet protocol |
