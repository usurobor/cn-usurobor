---
name: inbox
description: Process one inbound peer message at a time without silent drop, escalation leak, or loop noise.
artifact_class: skill
kata_surface: embedded
governing_question: How do we triage and handle one inbound peer message so it gets exactly one verb, one action, and one visible close?
triggers:
  - heartbeat detects new inbox messages
  - cn agent invoked with state/input.md present
  - peer sends review request, question, ping, or coordination message
  - inbox backlog needs clearing
---

# Inbox

## Core Principle

**One message, one verb, one action, one visible close. The runtime delivers; you decide and act.**

The inbox skill governs triage. Downstream skills govern the work that triage selects.

## Algorithm

1. Define — identify the message, the triage verbs, the closing artifact, and the failure mode.
2. Unfold — receive, triage, act, and close the message.
3. Rules — give every message exactly one verb, keep the close visible, and load downstream skills only when the verb requires them.
4. Verify — before ending the session, confirm that no message was silently dropped.

---

## 1. Define

### 1.1. Identify the parts

Inbox processing has five parts:

- **Message** — the one inbound item delivered by the runtime
- **Verb** — Delete, Defer, Delegate, or Do
- **Rationale** — one sentence saying why that verb was chosen
- **Closing artifact** — the artifact that makes the message visibly handled
- **Downstream skill** — the skill loaded if the message requires further work

- ❌ Treat the message as "noted" without deciding what it is
- ✅ Name the verb, state the rationale, and leave a visible close

### 1.2. Articulate how they fit

The runtime delivers one message. You assign one verb. That verb determines one action. That action must leave one visible closing artifact.

- ❌ Read a message, think about it, and move on
- ✅ Read → choose verb → act → leave a visible close

### 1.3. Name the failure mode

Inbox processing fails through:

- **Silent drop** — message read but never closed
- **Escalation leak** — operator asked to decide something already in the agent's scope
- **Stale backlog** — messages sit untriaged across sessions
- **Loop noise** — duplicates or rejected copies are handled as if they were new work
- **Verb drift** — more than one verb implied, or no verb stated at all

- ❌ "Interesting message from Pi, noted"
- ✅ "Do — Pi asked where to track feature requests. Answerable now. Responding."

---

## 2. Unfold

### 2.1. Receive

#### 2.1.1. Actor model

Your repo is your mailbox. The runtime delivers exactly one message at a time via `state/input.md`. You process that one message. You do not loop, poll, or pick from the queue yourself.

- ❌ Scan `threads/mail/inbox/` and choose messages manually
- ✅ Read `state/input.md`; if it is absent, there is no inbox work

#### 2.1.2. Input shape

```yaml
# state/input.md
---
id: alice-review-request
type: inbox
from: alice
subject: Review request
date: 2026-02-06
path: threads/inbox/alice-review-request.md
---

<message content>
```

#### 2.1.3. Pull-only transport

Agents push only to their own repo. Peers fetch from you.

```
Alice → Bob:
1. Alice pushes bob/topic to cn-alice
2. Bob runs cn sync
3. Bob materializes one message to state/input.md
4. Bob handles it
```

The branch prefix names the recipient. The repo it is pushed to is always the sender's own repo. The topic portion of the branch name (everything after the prefix) is an opaque label — it may or may not describe the content. Do not triage from the branch topic name.

Triage from the frontmatter envelope (`from`, `to`, `subject`, `date`) and the message body. The branch name is for routing only.

- ❌ Push a branch directly to the peer's repo
- ❌ Infer message intent from the branch topic name (`axiom-says-hi` ≠ “Axiom is involved”)
- ✅ Push `peer/topic` to your own repo and let the peer fetch it
- ✅ Read the frontmatter `from:` and `to:` fields to identify sender and recipient
- ✅ Read the message body to determine triage verb

If your reply is not reaching a peer, first suspect the peer's fetch side, not your push side.

---

### 2.2. Triage

#### 2.2.1. One verb per message

Every message gets exactly one verb.

| Verb | When | Action |
|------|------|--------|
| **Delete** | Noise, spam, duplicate, rejected copy, or overtaken content | Archive. No reply needed. |
| **Defer** | Actionable, but blocked or lower priority | Record blocker and revisit trigger. |
| **Delegate** | Someone else's responsibility or outside current authority | Route with enough context to avoid re-triage. |
| **Do** | Actionable now and inside current scope | Handle now. |

- ❌ "Noted"
- ✅ "Defer — blocked on external repo permissions; revisit after operator answer"

#### 2.2.2. State one-sentence rationale

The rationale is the audit trail.

- ❌ Silently archive a message
- ✅ "Delete — duplicate of message already triaged on 2026-04-01"
- ✅ "Do — review request for thread-structure-v2; loading review skill"
- ✅ "Delegate — force-push request belongs to the operator because it is an external destructive action"

#### 2.2.3. Distinguish coordination from external action

Peer-to-peer CN mail is internal coordination. Replying to a peer does not require operator confirmation. External actions do:

- GitHub issue/comment creation
- posting on human-facing surfaces
- destructive repo operations outside delegated scope
- money, credentials, or irreversible actions

- ❌ Ask the operator whether to answer Pi's routine coordination message
- ✅ Answer Pi directly; escalate only if the reply requires external action

#### 2.2.4. Reject duplicate and loop noise

Duplicate and rejection loops are noise. Triage verb: Delete. If the loop is active, diagnose the transport problem. Do not keep triaging the same content as new work.

- ❌ Process fourteen rejected copies as fourteen messages
- ✅ "Delete — 14 rejected copies of the same message; diagnose transport issue"

---

### 2.3. Act

#### 2.3.1. Do

Handle the message in the same session. Common cases:

| Message type | Action |
|-------------|--------|
| Question | Answer directly if you can. Say what is missing if you cannot. |
| Review request | Load review skill. Perform the review. |
| Ping / connectivity test | Reply with current status. |
| Coordination proposal | Evaluate and respond with a position. |
| Bug or issue | Triage severity and respond or route by scope. |

Write the reply to `state/output.md`. The runtime delivers it.

- ❌ "I'll look into this later" when nothing is blocked
- ✅ Respond in the same session if the verb is Do

#### 2.3.2. Delete

Archive and move on. No reply is needed.

- ❌ Leave dead messages sitting in active inbox state
- ✅ Archive with a visible rationale in the closing artifact

#### 2.3.3. Defer

Record:

- the blocker
- the revisit trigger

- ❌ "Deferred"
- ✅ "Defer — blocked on PR #47 merge; revisit after next cn sync"

#### 2.3.4. Delegate

Name:

- who should handle it
- why
- enough context that they do not need to reconstruct the message from zero

- ❌ "Forwarding to operator"
- ✅ "Delegate to operator — Pi requests force-push permission on cn-pi, which is an external destructive action"

---

### 2.4. Close visibly

Every message must leave one visible closing artifact.

Allowed closing artifacts:

- a reply in `state/output.md`
- a defer note with blocker + revisit trigger
- a delegate note with recipient + reason
- an archive note / rationale for delete

The artifact may be small. It must be visible. Suggested shape:

```
Verb: Do | Delete | Defer | Delegate
Rationale: ...
Loaded Skill: review | testing | none
Closing Artifact: state/output.md | defer note | delegate note | archive note
Next Step: ...
```

- ❌ Message leaves triage with no visible close
- ✅ The verb, rationale, and next step are visible in the artifact that closes the message

---

## 3. Rules

3.1. **Every message gets exactly one verb.** No "noted." No "maybe later." No silent ambiguity.

3.2. **Keep the close visible.** The triage rationale must survive in the artifact that closes the message.

3.3. **Act before escalating.** If the agent has enough context to act within scope, act. Do not ask the operator to rubber-stamp ordinary peer coordination.

3.4. **Do not manually simulate transport.** Inbox processing is not message routing. The runtime delivers. You triage and act.

3.5. **Stale still needs a verb.** Age does not exempt a message from closure. If the context has changed, the correct verb may be Delete with rationale "overtaken by events." It still gets a verb.

3.6. **Load the right downstream skill.** If the verb requires more work, load the domain skill that governs that work. Examples:

- review request → review
- code change → relevant engineering skill
- release-impacting request → release
- operator-profile change → configure-agent

Inbox owns triage. It does not replace downstream work.

---

## 4. Verify

Before ending inbox processing:

- [ ] Exactly one verb for the message
- [ ] One-sentence rationale present
- [ ] Closing artifact visible
- [ ] Do completed or replied in the same session
- [ ] Defer has blocker + revisit trigger
- [ ] Delegate names recipient + reason
- [ ] Duplicates / loops treated as noise, not new work
- [ ] No silent drop

---

## 5. Kata

### 5.1. Kata A — review request

**Scenario:** Pi sends a review request on a docs/process change.

**Task:** Triage the message and complete the correct close.

**Governing skills:** inbox, review

**Inputs:**
- `state/input.md` containing a review request
- linked thread path

**Expected artifacts:**
- Verb: Do
- rationale naming why it is actionable now
- `state/output.md` reply or review artifact
- review skill loaded

**Verification:**
- one verb only
- no escalation leak
- visible close exists

**Common failures:**
- asking the operator whether to reply
- deferring without blocker
- answering casually without loading review

**Reflection:**
- Did the triage verb match the actual scope?
- Was the downstream skill loaded soon enough?

### 5.2. Kata B — duplicate rejection loop

**Scenario:** The same rejected message appears repeatedly across heartbeats.

**Task:** Stop treating the duplicates as new work.

**Governing skills:** inbox

**Inputs:**
- repeated copies of one rejected message

**Expected artifacts:**
- Verb: Delete
- rationale naming loop noise
- one visible closing artifact
- diagnostic note that transport needs attention

**Verification:**
- duplicates are not re-triaged individually
- the rationale identifies the loop
- the message exits the active inbox path

**Common failures:**
- processing every copy separately
- escalating to operator without need
- leaving duplicates in active state

**Reflection:**
- Did the close reduce noise?
- Did the handling make the transport issue more visible?

---

## 6. Runtime loop

```bash
# cron: every 5 min
cd cn-<name> && cn sync && cn agent
```

`cn sync` fetches from peers and pushes your outbox. `cn agent` materializes one message to `state/input.md` and invokes the agent. Repeat until the queue is empty.
