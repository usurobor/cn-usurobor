# Thread Event Model

## Canonical Thread Semantics Above Packet Transport

**Version:** 1.0.1
**Status:** Draft
**Issue:** #153
**Purpose:** Define the semantic model for threads, replies, discovery, routing, and projection in cnos.

**Related:**

- `docs/alpha/protocol/MESSAGE-PACKET-TRANSPORT.md`
- `docs/alpha/AGENT-RUNTIME.md`
- `docs/reference/GLOSSARY.md`

---

## 0. Coherence Contract

### Gap

cnos now has:

- validated packet transport
- Git-first message movement
- thread-like markdown files under `threads/`
- inbox triage that expects one actionable item in `state/input.md`

But it still lacks one explicit semantic model for:

- top-level thread creation
- replies/comments
- discovery of what a peer posted
- propagation of replies to thread owners, participants, and interested peers
- local persistence and projection
- parent-linked publication in web/feed views
- durable identity independent of any one remote URL

Without that model, the system remains too flat:

- packets are transport units
- thread files are human-readable artifacts
- inbox items are actionable projections
- but "what actually happened in the conversation?" is not yet a first-class semantic object

### Named incoherence

A thread is currently treated partly as:

- a packet payload
- a markdown file
- an inbox artifact
- a human concept

That is too many roles for one object.

### Failure modes

1. **Transport / semantic collapse** — packet = thread = markdown file
2. **Authority duplication** — packet envelope, markdown frontmatter, and projection all claim thread truth
3. **Routing leakage** — agent must reason about transport, recipients, or feed mechanics
4. **Reply propagation ambiguity** — unclear how authors, participants, and other peers learn about replies
5. **Thread discovery ambiguity** — no explicit model for "what threads did this peer post?"
6. **Identity / locator confusion** — remote URLs are mistaken for canonical identity
7. **Locator fragility** — a forge or remote URL may disappear over time
8. **Projection authority drift** — thread markdown files become accidental semantic authorities

### Mode

MCA — add a canonical thread-event layer above packet transport and below projections.

### α / β / γ target

- α PATTERN: one canonical semantic unit (`thread_event`) and one canonical identity model
- β RELATION: packet transport, event store, discovery, inbox routing, and thread projections all describe the same thread state
- γ EXIT: future web publishing, feeds, subscriptions, and alternate transports fit without changing thread semantics

### Smallest coherent intervention

Do not replace packet transport. Do not make URLs or markdown files authoritative. Add:

- canonical thread events
- canonical event/thread IDs
- a non-authoritative locator model
- cnos-owned routing/persistence/projection

---

## 1. Core Decision

Threads are modeled as event streams, not files.

### Canonical stack

1. **Packet** — transport truth
2. **Thread event** — semantic truth
3. **Projection** — human-readable / actionable views

### Key rule

- **Packet** answers: what transport-validated unit arrived?
- **Thread event** answers: what happened in the conversation?
- **Projection** answers: how should humans or the agent see it?

### Consequence

- A message is one thread event carried by one packet
- A thread is a sequence of thread events
- A thread markdown file is a projection, never the canonical semantic object

---

## 2. Canonical Identity Model

### 2.1 Event identity

Every thread event has a globally unique canonical ID:

```
{id}@{author}
```

This is the semantic identity of the event.

### 2.2 Thread identity

Every thread has a stable canonical thread ID:

```
thr-{id}
```

The `thread_id` is shared across all events in the thread.

### 2.3 Reply linkage

Every reply/comment links to its parent through canonical event identity:

- `root_event_id`
- `reply_to_event_id`

This gives parent-linked threads independent of URL or hosting location.

### 2.4 Canonical identity vs locator

A canonical ID is **not** a URL.

The following are **not** canonical identity:

- Git remote URL
- GitHub/GitLab forge URL
- web thread URL
- blockchain tx hash

Those are **locators** — they tell you where to find the event, not what the event is.

---

## 3. Canonical Thread Event Schema

```ocaml
type thread_event_kind =
  | Open
  | Reply
  | Note
  | Close
  | Supersede

type visibility =
  | Direct
  | Participants
  | Followers
  | Public

type audience = {
  direct_recipients     : string list;
  participant_recipients : string list;
  mention_recipients    : string list;
}

type thread_event = {
  event_id            : string;         (* globally unique: {id}@{author} *)
  thread_id           : string;         (* stable thread identity: thr-{id} *)
  root_event_id       : string;         (* event_id of the Open event *)
  reply_to_event_id   : string option;
  kind                : thread_event_kind;
  author              : string;         (* packet sender *)
  created_at          : string;
  topic               : string;
  visibility          : visibility;
  audience            : audience;
  body_md             : string;         (* validated packet payload *)
}
```

### Mapping from packet to event

A thread event is derived from a validated conversational packet:

- `event_id` ← `packet.envelope.msg_id`
- `thread_id` ← `packet.envelope.thread_id`
- `root_event_id` ← `packet.envelope.root_event_id`
- `reply_to_event_id` ← `packet.envelope.reply_to_event_id`
- `kind` ← `packet.envelope.event_kind`
- `author` ← `packet.envelope.sender`
- `created_at` ← `packet.envelope.created_at`
- `body_md` ← validated payload bytes

### Authority rule

The canonical semantic event is derived from:

- transport-authoritative envelope metadata
- payload body bytes

It is **not** derived from markdown frontmatter in the payload.

---

## 4. Locator Model

### 4.1 Locators are secondary, not canonical

An event may have one or more **locators** that tell a node where or how it was found. Locators are not semantic identity.

### 4.2 Locator kinds

Examples:

- Git packet ref
- local projection URL
- web projection URL
- archive URL
- optional chain commitment
- future relay/event locator

### 4.3 Local locator record

Nodes may maintain local locator metadata such as:

```json
{
  "event_id": "01JZ...@sigma",
  "locators": [
    {
      "kind": "git",
      "ref": "refs/cn/msg/{sender}/{msg_id}",
      "remote": "git+ssh://..."
    },
    {
      "kind": "web",
      "url": "https://example.net/events/01JZ...@sigma"
    }
  ]
}
```

### 4.4 Rule

If a locator disappears:

- the event identity remains valid
- thread parent/child relationships remain valid
- local event-store truth remains valid

This is why locators must not be canonical.

---

## 5. Packet Envelope Extensions

The packet envelope must carry authoritative thread metadata for conversational packets.

### Required fields

```json
{
  "thread_id": "thr-01JZ...",
  "root_event_id": "01JZ...@sigma",
  "reply_to_event_id": null,
  "event_kind": "open",
  "visibility": "participants",
  "audience": {
    "direct_recipients": ["pi"],
    "participant_recipients": [],
    "mention_recipients": []
  }
}
```

### Rules

- `event_id` = `msg_id`
- `root_event_id` = `event_id` for Open
- `reply_to_event_id` is required for Reply
- `thread_id` is stable for the whole thread
- thread metadata in the envelope is authoritative
- frontmatter inside `message.md` is not authoritative for routing or threading

---

## 6. Git-First Transport, Transport-Flexible Semantics

### 6.1 Git-first

Git remains the default transport substrate. Packets are fetched and validated through packet refs and transport proofs as defined in MESSAGE-PACKET-TRANSPORT.md.

### 6.2 Transport-agnostic semantics

Thread semantics are above transport. That means:

- the same `thread_event` model works whether the packet arrived from:
  - Git
  - a future mailbox adapter
  - a future relay adapter
  - a future chain commitment layer

### 6.3 Rule

cnos remains Git-first for transport, while thread semantics remain transport-agnostic.

---

## 7. Discovery Model

### 7.1 Actor feed projection

A peer learns what threads another peer posted through a feed projection.

For top-level Open events, cnos publishes feed refs such as:

```
refs/cn/feed/{author}/{event_id}
```

These refs point to the same canonical packet commit as the message packet.

### 7.2 Feed rules

- Open events always appear in the author feed
- Replies may appear depending on visibility policy
- Feed refs are discovery projections, not semantic authority

### 7.3 Local feed projection

A node that follows a peer:

1. fetches the peer's feed refs
2. validates the packet
3. derives the thread event
4. stores it locally
5. updates a local feed projection

This answers:

> "How does a peer know what threads their peer posted?"

By:

- following the peer,
- fetching feed projections,
- and letting cnos turn validated events into local feed state.

---

## 8. Reply / Comment Model

A reply is just another canonical thread event.

### 8.1 Reply creation

To reply/comment:

- create a packet with:
  - same `thread_id`
  - same `root_event_id`
  - `event_kind` = `"reply"`
  - `reply_to_event_id` = the parent event

### 8.2 Parent-linked threads

Because replies link by canonical event ID, any projection can render:

- parent pointers
- reply trees
- thread timelines
- web permalinks to parent/child events

### 8.3 Rule

Parent linkage is by canonical event ID, not by URL. URLs are derived projections from canonical IDs.

---

## 9. How the Thread Owner Learns About Replies

The thread owner should not have to follow every participant's whole feed.

### Mechanism

For every routed event, cnos publishes recipient-delivery refs such as:

```
refs/cn/inbox/{recipient}/{event_id}
```

These refs point to the same canonical packet commit.

### Rule

The thread owner is always included in the routed recipients for:

- replies
- closes
- supersedes
- direct notes on their thread

That answers:

> "How does their peer know someone replied / commented on their thread?"

By:

- cnos publishing an inbox delivery projection,
- not by the author manually broadcasting or the receiving agent guessing.

---

## 10. How Other Peers Learn About Replies

There are two coherent ways:

### 10.1 Actor-feed discovery

A peer follows the replier's feed. If visibility allows, the reply appears there.

### 10.2 Thread subscription

A peer is subscribed to the thread. Local subscription state may live in:

```
state/thread-subscriptions.json
```

A peer can be subscribed because they:

- own the thread
- authored an event in the thread
- were explicitly mentioned
- were manually subscribed by operator policy

That answers:

> "How do other peers know someone replied / commented on another peer's thread?"

By:

- feed discovery,
- or subscription/participation routing,
- with cnos handling it below the agent.

---

## 11. Persistence Model

### 11.1 Canonical local semantic store

After packet validation, cnos stores the derived event in a local event store, for example:

```
state/thread-events/{thread_id}/{event_id}.json
```

This is local semantic truth.

### 11.2 Thread projections

Human-readable thread files are projections derived from the event store.

Examples:

- `threads/mail/inbox/{thread_id}.md`
- `threads/mail/outbox/{thread_id}.md`
- `threads/adhoc/{thread_id}.md`

### 11.3 Web projections

Web publishing can generate stable URLs such as:

- `/events/{event_id}`
- `/threads/{thread_id}`

These are derived URLs, not semantic identity.

### 11.4 Rule

If the remote repo or website disappears:

- the canonical IDs still work
- the local event store still works
- parent-linked threads still work
- only some locators/projections disappear

---

## 12. Inbox / Actionability Model

### 12.1 cnos owns routing and persistence

The agent does not reason about:

- feed refs
- inbox refs
- participant routing
- storage layout
- projection updates

cnos performs:

- validation
- event derivation
- routing
- persistence
- actionability classification
- projection updates

### 12.2 Actionable vs non-actionable

Only actionable events become `state/input.md`.

**Actionable examples:**

- direct messages
- replies on local threads that require response
- explicit mentions
- review or coordination requests

**Non-actionable examples:**

- passive feed discoveries
- thread updates that do not require response
- follower-visible public replies

### 12.3 Rule

The agent still sees one triaged actionable item at a time. That preserves the current inbox abstraction.

---

## 13. Scenarios

### Scenario A — "How does a peer know what threads another peer posted?"

1. Sigma posts an Open event
2. cnos validates and stores it
3. Sigma's cnos publishes:
   - packet ref
   - feed ref
4. Pi follows Sigma and fetches feed refs
5. Pi's cnos validates packet, derives event, updates local feed projection
6. Agent is only woken if policy makes that event actionable

### Scenario B — "How do they reply/comment on a thread?"

1. Pi sees thread `thr-123`
2. Pi creates a Reply event with:
   - `thread_id` = `thr-123`
   - `root_event_id` = root
   - `reply_to_event_id` = parent
3. Pi's cnos emits a canonical packet and routes it

### Scenario C — "How does the thread owner know?"

1. Pi's reply routes to Sigma via inbox projection
2. Sigma fetches `refs/cn/inbox/sigma/*`
3. cnos validates packet, stores event, updates thread projection
4. If actionable, Sigma receives one `state/input.md`

### Scenario D — "How do other peers know?"

1. A third peer either follows Pi or subscribes to `thr-123`
2. They fetch feed/inbox refs as appropriate
3. cnos validates and stores the event
4. Local projections update without agent-level routing knowledge

---

## 14. Why This Matches the Desired Model

This replicates the useful parts of:

- store-and-forward threaded messaging
- actor feeds
- parent-linked web threads
- participant/subscriber reply propagation

while preserving cnos's stronger invariants:

- Git-first canonical substrate
- validated packet transport
- single authority surfaces
- cnos-owned routing and persistence
- agent isolation from low-level mechanics

---

## 15. Leverage

This design makes future work easier by:

- unifying direct messages and comments/replies under one semantic model
- making discovery, inbox delivery, and web projection all derived from the same event truth
- enabling parent-linked published threads without making URLs canonical
- allowing remote URLs to disappear without breaking semantic thread identity
- supporting future transport adapters without changing threading semantics
- keeping the agent focused on actionability, not mechanics

---

## 16. Negative Leverage

This design adds:

- one new semantic layer
- event-store infrastructure
- routing/projection logic
- subscription state
- more traceability
- migration work away from implicit thread-file semantics

It also requires explicit decisions for:

- visibility defaults
- actionability rules
- subscription policy
- event retention

---

## 17. Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Treat thread markdown files as canonical shared objects | Human-readable, simple to inspect | Weak authority model, difficult routing, poor concurrency/adversarial behavior | Rejected |
| Treat packets as threads directly | Fewer layers | Collapses transport and semantics, weak for projections and local state | Rejected |
| Let the agent manage reply routing and thread discovery | Flexible | Leaks mechanics into cognition, fragile, expensive, error-prone | Rejected |
| Use Git remote URL as canonical event identity | Easy to hyperlink | Remote can disappear or move; URL is locator, not identity | Rejected |
| Use blockchain tx hash as canonical identity | Durable public locator | Too heavy as default, wrong layer for most messages, ties semantics to transport | Rejected |
| Canonical thread-event model above packet transport, with IDs first and URLs as locators | Clean authority chain, parent-linked web publishing, Git-first compatibility, durable semantic identity | More infrastructure required | **Selected** |

---

## 18. Process Cost / Automation Boundary

### Human judgment remains for:

- visibility defaults
- actionability policy
- subscription policy
- UI/product decisions for feed/thread views
- legacy migration priorities

### Mechanical work should be automated:

- packet validation
- event derivation
- route computation
- event-store persistence
- feed/inbox projection creation
- web permalink derivation
- participant auto-subscription

---

## 19. Non-goals

This design does not:

- make Git URLs canonical
- require blockchain as a default ledger
- redesign reflection memory in v1
- unify every local thread type immediately
- define a full social product
- add non-Git transports in v1

Reflections remain separate in v1.

---

## 20. File Changes

### Create

- `docs/alpha/protocol/THREAD-EVENT-MODEL.md`
- `src/transport/cn_thread_event.ml`
- local event-store module
- feed projection module
- inbox routing module
- locator/projection metadata module

### Edit

- `docs/alpha/protocol/MESSAGE-PACKET-TRANSPORT.md`
  - clarify envelope thread metadata and locator semantics
- `src/transport/cn_packet.ml`
  - validate thread-event metadata
- `src/cmd/cn_mail.ml`
  - publish packet refs, feed refs, inbox refs
- `src/cmd/cn_maintenance.ml`
  - fetch/process feed/inbox refs
- `src/agent/skills/ops/inbox/SKILL.md`
  - actionable events are derived thread events
- `docs/reference/GLOSSARY.md`
  - distinguish packet / thread event / projection / locator

---

## 21. Acceptance Criteria

- [ ] Every conversational packet derives exactly one validated `thread_event`
- [ ] Thread opens are discoverable through actor feed projection
- [ ] Replies/comments are represented as explicit Reply events with `reply_to_event_id`
- [ ] Thread owners always receive replies/comments through inbox routing
- [ ] Participants/subscribers can receive thread updates without ad hoc routing logic
- [ ] `state/input.md` is produced only for actionable events
- [ ] Thread markdown files are derived projections, not semantic authority
- [ ] Packet validation still happens before any event-store write or projection update
- [ ] Parent-linked web publishing is supported through canonical event IDs and derived URLs
- [ ] Loss of a remote repo or web projection does not break canonical thread identity or parent linkage
- [ ] The agent never needs to reason about transport refs, URLs, or persistence mechanics

---

## 22. Known Debt

- Reflections remain outside the event model in v1
- Subscription UX/policy is deferred
- Feed pagination/index optimization is deferred
- Chain/nostr/mailbox locators are deferred
- Legacy thread-file migration needs its own plan
- Retention/GC for event store and locator metadata is not yet designed
