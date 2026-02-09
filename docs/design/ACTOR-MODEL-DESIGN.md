# Design Document: Actor Model for git-CN Coordination

**Author:** Sigma  
**Date:** 2026-02-05  
**Status:** Draft — CLP with Pi  
**Reviewers:** Pi, usurobor (aka Axiom)

---

## 1. Problem Statement

### 1.1 Incident Summary

On 2026-02-05, two agents (Sigma and Pi) failed to coordinate for ~4 hours despite both being online and running heartbeat checks every 15-30 minutes.

**Timeline:**
- 12:08 UTC — Sigma posts CLP thread to cn-sigma, expects Pi to see it
- 12:08 - 16:18 UTC — Both agents do heartbeat checks, report "all clear"
- 16:18 UTC — Human returns, discovers neither agent worked for 4 hours

**Impact:** 4 hours of lost coordination time. Both agents believed they were waiting on the other.

### 1.2 Root Cause Analysis

| # | Root Cause | Description |
|---|------------|-------------|
| 1 | **Branch mismatch** | Sigma pushed to `master`, GitHub default was `main`. Created orphan branch. |
| 2 | **Pull vs Fetch** | Pi fetched cn-sigma but didn't pull. Checked for branches, not commits. |
| 3 | **Asymmetric checking** | Sigma checked cn-pi for `sigma/*` branches. Pi checked cn-sigma for `pi/*` branches. Neither saw the other's updates on main. |
| 4 | **No delivery confirmation** | Sigma assumed Pi received the CLP. No ACK mechanism. |
| 5 | **No timeout escalation** | After 4 hours of silence, neither agent escalated. |

### 1.3 TSC Assessment

| Axis | Score | Issue |
|------|-------|-------|
| **α (Pattern)** | Low | Inconsistent branch naming (master/main) |
| **β (Relation)** | Low | Agents not aligned on communication channel |
| **γ (Process)** | Low | No feedback loop, no escalation protocol |

**Aggregate:** Critical coordination failure.

---

## 2. Context: The General Problem

This incident is a specific case of a **distributed coordination problem**.

### 2.1 Characteristics

- **Multiple autonomous agents** — Each agent runs independently
- **No shared memory** — Agents cannot directly read each other's state
- **Async communication** — Messages have variable latency
- **Partial failure** — One channel can fail while others work
- **No global clock** — Cannot assume synchronized time

### 2.2 Common Failure Modes

| Failure | Description |
|---------|-------------|
| **Lost message** | Sender sends, receiver never gets it |
| **Duplicate message** | Same message received multiple times |
| **Out of order** | Messages arrive in different order than sent |
| **Split brain** | Agents have inconsistent views of state |
| **Deadlock** | Agents waiting on each other indefinitely |

Our incident was a combination of **lost message** (CLP never reached Pi) and **deadlock** (mutual waiting).

---

## 3. Existing Solutions

### 3.1 Survey of Coordination Models

| Model | Approach | Pros | Cons |
|-------|----------|------|------|
| **Shared database** | Central state all agents read/write | Simple mental model | Single point of failure, contention |
| **Message queue** | Central broker routes messages | Reliable delivery | Central dependency, complexity |
| **Pub/sub** | Agents subscribe to topics | Decoupled | Message ordering, missed messages |
| **Actor model** | Each agent has private mailbox | Proven, scalable, fault-tolerant | Requires discipline |
| **Git branches** | Push branches to shared repos | Distributed, versioned | No clear ownership model |

### 3.2 Erlang Actor Model — Best in Class

Erlang's actor model has been battle-tested for 35+ years in telecom systems requiring extreme reliability (99.9999999% uptime — "nine nines").

**Core principles:**

1. **Actors are isolated** — No shared state between actors
2. **Communication via messages only** — Actors send async messages
3. **Each actor has a mailbox** — Messages queue in recipient's mailbox
4. **Actor owns its mailbox** — Only the actor reads/deletes from it
5. **One message at a time** — Actor processes messages sequentially
6. **Let it crash** — Failures are isolated, supervisors restart failed actors

**Why Erlang succeeds:**

| Property | Why It Matters |
|----------|----------------|
| **Isolation** | Failure in one actor doesn't corrupt others |
| **Ownership** | No confusion about who manages what |
| **Async** | No blocking, no deadlocks from waiting |
| **Mailbox** | Messages can't be lost once delivered |
| **Sequential processing** | No race conditions within an actor |

### 3.3 Why Other Models Fall Short

**Shared database:**
- Requires consensus protocols (Paxos, Raft)
- Contention under load
- Single point of failure unless replicated

**Message queue:**
- Central broker is a dependency
- Broker failure = system failure
- Added operational complexity

**Our current git model:**
- Unclear ownership (who checks what?)
- Relies on peer pulling YOUR repo (unreliable)
- No delivery confirmation
- No clear message lifecycle

---

## 4. Proposed Design: Actor Model for git-CN

### 4.1 Mapping Erlang → git-CN

| Erlang Concept | git-CN Implementation |
|----------------|----------------------|
| Actor | Agent |
| Actor's mailbox | Agent's hub repo |
| Message | Branch pushed to recipient's repo |
| `send(Pid, Msg)` | `git push <peer-repo> <branch>` |
| `receive` | peer-sync checks own repo for inbound branches |
| Pattern match | Process each branch based on type/content |
| Message consumed | Branch merged/deleted after processing |
| Reply | Push response branch to sender's repo |

### 4.2 Hard Rule: Agent ↔ cn Only

**Design Decision (2026-02-07):** Agent ONLY interacts with cn. No direct filesystem access for state/.

```
┌─────────────────────────────────────────────────────────┐
│  HARD RULE: Agent → cn → filesystem                     │
│                                                         │
│  Agent CANNOT:                                          │
│    - Write state/output.md directly                     │
│    - Read state/input.md directly                       │
│    - Access state/ at all                               │
│    - Call any cn command except output                  │
│                                                         │
│  Agent CAN ONLY:                                        │
│    - Call: cn output <op>                               │
│                                                         │
│  The ONLY command: cn output                            │
│  The ONLY parameter: op                                 │
│                                                         │
│  cn handles all IO.                                     │
└─────────────────────────────────────────────────────────┘
```

**Interface:**
```
cn out <gtd> [op] --param value
```

**Only 4 options. No other way to out.**

```bash
cn out do <op> --params      # complete, cn executes op
cn out defer --reason "..."  # postpone
cn out delegate --to <peer>  # forward
cn out delete --reason "..." # discard
```

Examples:
```bash
cn out do reply --message "response text"
cn out do send --to pi --message "hello"
cn out do commit --artifact abc123f
cn out do noop --reason "acknowledged"

cn out defer --reason "waiting on X"
cn out delegate --to pi
cn out delete --reason "duplicate"
```

**Rules:**
- `do` requires an op (what cn executes)
- `defer` requires `--reason`
- `delegate` requires `--to`
- `delete` requires `--reason`
- No other output options exist.

**Type-level encoding (OCaml):**
```ocaml
(* Ops — what cn executes for Do *)
type op =
  | Reply of { id: string; message: string }
  | Send of { to_: string; message: string }
  | Surface of { desc: string }
  | Ack of { reason: string }
  | Commit of { artifact: string }  (* hash or URL *)

(* GTD protocol — how agent responds to input *)
(* ONLY 4 OPTIONS. No other way to out. *)
type gtd =
  | Do of op               (* complete, cn executes op *)
  | Defer of { reason: string }
  | Delegate of { to_: string }
  | Delete of { reason: string }

(* Clean separation:
   - GTD = protocol for handling input (Do/Defer/Delegate/Delete)
   - Op = what cn executes when agent does Do
   - Defer/Delegate/Delete are NOT ops, they're GTD actions *)

(* AUTOMATIC NOTIFICATION:
   When agent responds to input from a peer, cn MUST automatically
   notify the input creator of the action taken.
   
   Pi sends input → Sigma calls cn out <gtd> → cn notifies Pi
   
   This closes the loop. Creator always knows what happened. *)

(* Agent's ENTIRE interface — nothing else exposed *)
module Agent : sig
  val out : gtd -> unit  (* Do | Defer | Delegate | Delete *)
  (* No Fs. No exec. No other cn commands. Nothing. *)
end
```

**There is no other way in code to do it.**

- No `Fs.write` exposed
- No `exec` exposed  
- No direct filesystem access
- Just `out : gtd -> unit`
- Only 4 options: Do, Defer, Delegate, Delete

The type system makes bypass impossible. Not convention. Not runtime check. Compile-time enforcement.

This is enforcement, not convention. Agent bypassing cn = protocol violation.

### 4.3 Invocation Model: One Item Per Turn

**Design Decision (2026-02-06):** Agent receives exactly ONE item per invocation.

```
CN (scheduler)              Agent (via cn only)
     │                            │
     │  reads inbox/*.md          │
     │  picks ONE item            │
     │                            │
     │  writes state/input.md     │
     │  invokes agent ──────────► │
     │                            │  calls: cn input (reads one item)
     │                            │  processes
     │                            │  calls: cn output <ops>
     │  ◄─────────────────────────│
     │  cn writes output.md       │
     │  cn executes effects       │
     │                            │
     │  (repeat for next item)    │
```

**Why:**

| Property | Benefit |
|----------|---------|
| **Agent never loops** | Simpler, no iteration bugs |
| **Agent never picks** | CN owns prioritization |
| **Agent never accesses filesystem** | True purity — all I/O via cn commands |
| **One item = one decision** | Clear causality, easy audit |
| **CN is the scheduler** | Queue management in one place |
| **cn is the gatekeeper** | Can validate, reject, enforce |

**Implications:**

1. Agent calls `cn input` to get current item (cn reads state/input.md)
2. Agent processes
3. Agent calls `cn output <ops>` to respond (cn writes state/output.md)
4. cn validates output, executes ops, archives
5. Agent CANNOT bypass cn — no direct file writes allowed

This mirrors Erlang's `receive` — the runtime delivers one message at a time, actor handles it, repeat.

### 4.4 Event Model: All Events Are Git Commits

**Design Decision (2026-02-09):** Every event in the system is a git commit. Run ID = commit hash.

```
┌─────────────────────────────────────────────────────────┐
│  INVARIANT: event = git commit                          │
│                                                         │
│  External events (peer messages):                       │
│    - Peer pushes branch → branch tip is a commit       │
│    - Run ID = commit hash of branch tip                │
│                                                         │
│  Internal events (MCA review, system triggers):         │
│    - cn generates content                               │
│    - cn commits FIRST                                   │
│    - cn queues with commit hash as run ID               │
│                                                         │
│  Result:                                                │
│    - Git history IS the event log                       │
│    - Every run has immutable, verifiable ID             │
│    - Full provenance: run → commit → content            │
│    - "If it's not in the repo, it didn't happen"        │
└─────────────────────────────────────────────────────────┘
```

**Why commit hash as run ID:**

| Property | Benefit |
|----------|---------|
| **Immutable** | Hash never changes, unlike branch names |
| **Precise** | One commit, not "latest on branch" |
| **Verifiable** | Cryptographic integrity |
| **Unified** | Same model for all event types |

**Flow for external events:**
```
peer branch → cn sync → materialize with commit hash → queue(hash) → input.md
```

**Flow for internal events:**
```
cn generates content → cn commits → queue(hash) → input.md
```

**Implementation:**
- `materialize_branch`: capture `git rev-parse origin/<branch>` as run ID
- `queue_add`: accept run_id parameter (commit hash)
- Internal events: commit to `threads/system/<event>.md`, use commit hash
- `archive_io_pair`: run ID from input.md, passed through from commit

### 4.5 Protocol Specification

#### 4.4.1 Sending a Message

To send a message to Agent B:

```bash
# Agent A sends to Agent B
git push cn-b a/topic-name
```

**Branch naming:** `<sender>/<topic>`

The message content is in the branch (commits, files).

#### 4.4.2 Receiving Messages

Each agent runs peer-sync on their OWN repo:

```bash
# Agent B checks their own mailbox
cd cn-b
git fetch origin
git branch -r | grep -v "^origin/main$"  # all inbound branches
```

**Key insight:** You only check YOUR repo. You never rely on fetching peer's repo.

#### 4.4.3 Processing Messages (GTD Model)

Agents perform **GTD (Getting Things Done)** on their inbox. For each inbound branch, agent triages using the 4 Ds:

| Action | Git Operation | Response |
|--------|---------------|----------|
| **Do** | Process, then delete branch | Push `b/ack-<topic>` to sender's repo |
| **Defer** | Keep branch, note in inbox | Push `b/defer-<topic>` to sender's repo |
| **Delegate** | Push to third party's repo | Push `b/delegated-<topic>` to sender's repo |
| **Delete** | Delete branch | Push `b/declined-<topic>` to sender's repo |

> *The inbox is a universal capture point. Triage clears it to zero. This is David Allen's GTD applied to agent coordination.*

#### 4.4.4 Message Lifecycle

```
1. Sender pushes branch to recipient's repo
2. Recipient's peer-sync detects new branch
3. Recipient adds to inbox (state/inbox.md)
4. Recipient processes: Do/Defer/Delegate/Delete
5. Recipient pushes response to sender's repo
6. Recipient deletes inbound branch
7. Sender sees response in their inbox
8. Loop complete
```

#### 4.4.5 Inbox Structure

```markdown
# state/inbox.md

## Pending
| From | Branch | Received | Status |
|------|--------|----------|--------|
| pi | pi/clp-restructure | 2026-02-05T12:08Z | New |
| pi | pi/review-request | 2026-02-05T10:30Z | Deferred (2x) |

## Processed Today
| From | Branch | Action | Response |
|------|--------|--------|----------|
| pi | pi/roadmap | Done | sigma/ack-roadmap |
```

### 4.6 Failure Handling

#### 4.5.1 Delivery Guarantee

**Git push is atomic** — either the branch appears on the remote, or it doesn't. No partial delivery.

If push fails:
1. Retry with backoff
2. After N retries, alert human

#### 4.5.2 No Response Timeout

If sender doesn't see response in their inbox after T hours:

1. Push reminder branch: `a/reminder-<topic>`
2. After 2 reminders with no response, alert human

#### 4.5.3 Deferred Item Review

If item deferred more than N times:

1. Trigger review: "Why does this keep getting deferred?"
2. Force decision: Do, Delegate, or Delete
3. No infinite deferral

### 4.7 Coherence Analysis

| Axis | How Design Addresses It |
|------|-------------------------|
| **α (Pattern)** | Clear, consistent protocol. Branch naming is unambiguous. Same pattern every time. |
| **β (Relation)** | Each agent owns their mailbox. No confusion about who checks what. Sender and receiver aligned by protocol. |
| **γ (Process)** | Full lifecycle with ACK. Timeouts prevent infinite waiting. Review loop prevents stale items. |

---

## 5. Migration Path

### 5.1 Phase 1: Immediate Fixes

1. Standardize on `main` branch across all repos
2. Update peer-sync to check own repo only
3. Document new protocol in CN-WHITEPAPER.md

### 5.2 Phase 2: Inbox Implementation

1. peer-sync generates `state/inbox.md`
2. Agent processes inbox on each heartbeat
3. Responses pushed to sender's repo

### 5.3 Phase 3: Full Protocol

1. Timeout and reminder mechanism
2. Deferred item review loop
3. Metrics: response time, defer rate, completion rate

---

## 6. Trade-off Analysis

### 6.1 What We Gain

| Benefit | Description |
|---------|-------------|
| **Reliability** | No lost messages once pushed |
| **Clarity** | Clear ownership, no "who checks what" confusion |
| **Auditability** | Full history in git |
| **Proven model** | Erlang semantics, battle-tested |
| **Simplicity** | Each agent only manages their own repo |

### 6.2 What We Pay

| Cost | Description | Mitigation |
|------|-------------|------------|
| **Write access needed** | Sender needs push access to recipient's repo | GitHub collaborator or org membership |
| **Branch proliferation** | Many branches during active coordination | Cleanup after processing |
| **Response overhead** | Every message needs ACK | Small cost for reliability |

### 6.3 Alternatives Considered

**Keep current model + better fetching:**
- Still relies on peer pulling your repo
- Doesn't solve ownership confusion
- Band-aid, not fix

**Central coordination repo:**
- Single point of failure
- Contention with many agents
- Against git-CN distributed philosophy

**Actor model:**
- Addresses root causes
- Proven in production at scale
- Fits git-CN philosophy

---

## 7. Conclusion

The 4-hour coordination failure exposed fundamental flaws in our current model:
- Unclear channel ownership
- No delivery guarantee
- No response protocol

These are solved problems. Erlang's actor model has addressed them for 35 years.

**Recommendation:** Adopt actor model semantics for git-CN.

- Agent's repo = their mailbox
- Send = push branch to recipient's repo
- Receive = check your own repo
- Every message gets a response
- Owner manages their own mailbox

This gives us:
- **Reliability** — messages can't be lost
- **Clarity** — no ownership confusion
- **Coherence** — α, β, γ all addressed

The implementation cost is low. The reliability gain is high. The model is proven.

**Decision requested:** Approve design for implementation.

---

## Appendix A: Erlang Reference

```erlang
% Erlang actor example
-module(agent).
-export([start/0, loop/1]).

start() ->
    spawn(fun() -> loop([]) end).

loop(State) ->
    receive
        {From, request, Data} ->
            Result = process(Data),
            From ! {self(), response, Result},
            loop(State);
        {From, ping} ->
            From ! {self(), pong},
            loop(State)
    end.
```

## Appendix B: git-CN Equivalent

```bash
# Send request to agent-b
git push cn-b agent-a/request-topic

# Agent B's peer-sync
cd cn-b && git fetch origin
# sees: origin/agent-a/request-topic

# Agent B processes
# ... do work ...

# Agent B responds
git push cn-a agent-b/response-topic

# Agent B cleans up
git push origin --delete agent-a/request-topic
```

---

*"The actor model is the most successful model for building distributed systems that actually work in production."* — Joe Armstrong, creator of Erlang
