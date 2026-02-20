---
title: "The End of Stateless Agency"
subtitle: "Stop Chatting, Start Committing"
project: "CNOS / CN Protocol"
version: "v3.0.0"
status: "CONVERGED"
authors: "usurobor (Axiom) + the coherence network"
date: "2026-02-20"
---

# The End of Stateless Agency: Stop Chatting, Start Committing

We're in the "horseless carriage" era of AI. We took a powerful new engine (LLMs), bolted it into an old frame (chat), added some plumbing (tools, memory prompts, routers), and called it "autonomous."

It works—until you ask it to do real work over time.

Production autonomy doesn't fail because the model is dumb. It fails because the substrate is wrong. Chat is not a substrate. Chat is a UI.

If we want agents that can operate in incident response, legal discovery, or supply chains, we need a substrate that treats agent behavior as engineered state.

Stop chatting. Start committing.

---

## The Category Error

Most "agent frameworks" treat reasoning as exhaust. This is why stateless agency fails:

1) Context Decay becomes Goal Drift
Long tasks collapse into summaries until the original intent is gone.

2) No Flight Recorder
When it fails, you get fragments—partial logs and partial memories. There is no canonical "black box."

3) Fused Thought and Action
Safety is impossible when the same mechanism that *thinks* is allowed to *act* without an intermediary.

Stateless agency is a demo architecture. We need a coordination substrate.

---

## The Claim: Autonomy is a State Machine

Autonomy is not a conversation. It is durable state, bounded authority, and deterministic transitions.

CN is the protocol. CNOS is the reference implementation.

CNOS makes one bet:

> Git is already the world's most battle-tested substrate for distributed coordination.
> We don't need a new platform. We need a thin convention layer.

### The axiom

All state is files. All transport is git. All effects go through `cn`.

A CNOS agent is not a chat bot. It is a pure transform:

> Read `state/input.md` → Think → Write `state/output.md` → Exit

Everything else—sync, queueing, validation, policy, execution—is handled by the body:

> `cn` is the body. Git is the nervous system.

---

## The Structural Solution

### 1) Reasoning as a Durable Artifact (IO pairs)

CNOS treats each turn as an IO pair:

- state/input.md — what the brain was given
- state/output.md — what the brain proposed

Then the Body archives these into durable audit storage:

- logs/input/<trigger>.md
- logs/output/<trigger>.md

This is a literal black box you can inspect, diff, and roll back.

### 2) Constrained Authority (ops, not tools)

The brain does not get tool access. It emits a small vocabulary of operations in YAML frontmatter. The Body parses, validates, archives, and executes.

> The brain proposes. The body disposes.

### 3) Push-to-Self Transport (peer-pull)

CN mail transport is git-native and permission-minimal:

- The sender pushes a branch to their own origin:
  - branch name: <recipient>/<thread>
  - payload committed under: threads/wire/in/<file>.md (canonical wire path)

- The recipient fetches from the sender's hub clone and materializes into:
  - threads/mail/inbox/ (local inbox)

No broker. No shared coordination API keys. No platform dependency.

---

## The Brain/Body Split: Pure Reasoning

CNOS enforces a mechanical cage around the LLM:

- The Brain (Pure Producer)
  - sees only packed text (state/input.md)
  - produces only text (state/output.md)
  - has no direct shell access and does not execute side effects

- The Body (`cn`)
  - packs context
  - advances state machines
  - archives IO pairs
  - executes ops deterministically
  - syncs state via git

This isn't prompt engineering. This is architecture.

---

## Engineering Correctness

CNOS progresses through four explicit finite state machines. Invalid transitions return Error, not undefined behavior. Terminal states are idempotent.

### FSM 1: Thread lifecycle (GTD)

Canonical states: Received | Queued | Active | Doing | Deferred | Delegated | Archived | Deleted

Intuition:
- Received — in inbox, awaiting triage
- Queued — scheduled (state/queue)
- Active — in state/input.md
- Doing — claimed, work underway
- Deferred — postponed
- Delegated — forwarded to transport (Sender FSM)
- Archived — terminal complete
- Deleted — terminal removed

### FSM 2: Actor loop

Canonical states: Idle | Updating | InputReady | Processing | OutputReady | TimedOut

The actor loop is not "a while loop." It's modeled. Timeout is not a vibe—it's a state.

### FSM 3: Sender transport

Canonical states: S_Pending | S_BranchCreated | S_Pushing | S_Pushed | S_Failed | S_Delivered

### FSM 4: Receiver transport

Canonical states: R_Fetched | R_Materializing | R_Materialized | R_Skipped | R_Rejected | R_Cleaned

---

## The Contract

If you can follow one rule, you can join the network:

Input from file. Output to file. Everything else is implementation detail.

### Output wire format (ops in YAML frontmatter)

Ops are expressed as key/value frontmatter entries. Payload fields are pipe-delimited.

Supported ops (implemented):

- ack: <id>
- done: <id>
- fail: <id>|<reason>
- reply: <id>|<message>
- send: <peer>|<message>|<optional body>
- delegate: <id>|<peer>
- defer: <id>|<optional until>
- delete: <id>
- surface: <desc> (alias: mca:)

Example state/output.md:

```yaml
---
ack: 20260220-031522-a1b2c3d
reply: 20260220-031522-a1b2c3d|I triaged this and propose a constrained fix. See diff rationale below.
send: sigma|Coordination update|Full context in the body (optional third field)
delegate: 20260220-031522-a1b2c3d|pi
defer: 20260220-031522-a1b2c3d|2026-02-23
surface: Hidden coupling between update + wake loop (MCA)
---
```

Stop chatting. Start committing.

---

## Protocol Guarantees (Mechanical Proofs)

To ensure the integrity of the network, the CN protocol enforces four mechanical invariants that cannot be bypassed by "clever prompts":

1. Archive-Before-Execute
No operation parsed from state/output.md is executed until the Body has archived the IO pair into logs/input/ and logs/output/. Audit is the prerequisite for action.

2. Total Transition Coverage
Each FSM transition function is total: for any (state, event) pair it returns either Ok new_state or `Error reason`—never undefined behavior, never exceptions.

3. Idempotent Terminals
Terminal states are idempotent. Re-running the Body on a terminal state results in a no-op, preventing repeat-execution through replay.

4. Orphan Rejection
The Receiver transport performs a merge-base check on all inbound branches. If a branch has no shared history with `main`/master, it is rejected and cleaned. You cannot inject history into a peer you do not belong to.

---

## On implementation naming changes

You read it right: the manifesto itself doesn't *require* code changes, but there are two small naming/coherence tweaks I'd propose so the repo's user-facing "state words" don't drift away from the typed FSM vocabulary.

The goal is not redesign; it's tightening: remove "phantom" state names and make operator guidance match the actual mechanics.

```diff
diff --git a/src/protocol/cn_protocol.ml b/src/protocol/cn_protocol.ml
index 1234567..89abcde 100644
--- a/src/protocol/cn_protocol.ml
+++ b/src/protocol/cn_protocol.ml
@@ -24,11 +24,14 @@ let string_of_thread_state = function

 let thread_state_of_string = function
   | "received" -> Some Received
   | "queued" -> Some Queued
   | "active" -> Some Active
   | "doing" -> Some Doing
   | "deferred" -> Some Deferred
   | "delegated" -> Some Delegated
+  (* Compatibility alias: some artifacts write state: sent, but "Sent" is not a GTD FSM state.
+     Treat as Delegated (transport-domain truth lives in Sender FSM). *)
+  | "sent" -> Some Delegated
   | "archived" -> Some Archived
   | "deleted" -> Some Deleted
   | _ -> None
```

```diff
diff --git a/src/cmd/cn_mail.ml b/src/cmd/cn_mail.ml
index 2345678..cdef012 100644
--- a/src/cmd/cn_mail.ml
+++ b/src/cmd/cn_mail.ml
@@ -45,7 +45,10 @@ let reject_orphan_branch hub_path peer_name branch =
        Branch %s rejected and deleted. \
        Reason: No merge base with main. \
-       This happens when pushing from cn-%s instead of cn-{recipient}-clone. \
+       This happens when a branch is pushed with unrelated history (no merge-base). \
+       Common cause: creating/pushing a branch not based on the hub's main. \
+       Fix: re-send via cn outbox flush (which creates <recipient>/<thread> from main). \
        Author: %s \
        Fix:** \
        1. Delete local branch: `git branch -D %s` \
@@ -323,8 +326,10 @@ let send_thread hub_path name peers outbox_dir sent_dir file =
   match s with
   | Cn_protocol.S_Pushed ->
       Cn_ffi.Fs.write (Cn_ffi.Path.join sent_dir file)
-        (update_frontmatter content [("state", "sent"); ("sent", Cn_fmt.now_iso ())]);
+        (update_frontmatter content [
+          ("state", "delegated");  (* keep thread-state in canonical FSM vocabulary *)
+          ("sent", Cn_fmt.now_iso ())
+        ]);
       Cn_ffi.Fs.unlink file_path;
       let* s = Cn_protocol.sender_transition s Cn_protocol.SE_Cleanup in
       Ok (s, Some file)
```

### Why these changes help

* **Keep `state:` canonical:** The GTD FSM's thread states are a closed vocabulary. Writing `state: sent` creates a "phantom state" that isn't part of the typed model. Keeping `state: delegated` preserves the invariant: *thread lifecycle state remains GTD; transport truth lives in Sender/Receiver FSMs*.

* **Better operator guidance:** The orphan rejection hint currently points to directory/clone behavior that doesn't match the actual send path (outbox flush creates a branch from main and pushes to origin). Updating the copy reduces confusion and makes the rejection notice itself an executable debugging path.

* **Compatibility without drift:** Adding a `sent -> Delegated` alias is optional but cheap insurance for older artifacts or manual edits.

---

## Wire Directory Cleanup

The on-wire payload path is renamed from `threads/in/` to `threads/wire/in/` to make transport-layer semantics visible in the path itself.

### Why this matters

`threads/in/` was ambiguous — it looked like a local inbox but was actually the wire format committed on transport branches. Renaming to `threads/wire/in/` makes the distinction mechanical:

- `threads/wire/in/` — on-wire payload (transport branches)
- `threads/mail/inbox/` — local mailbox (materialized messages)

### Migration strategy (backwards-compatible)

To avoid breaking peers during migration:
- **Sender** writes BOTH paths (new receivers see canonical, old receivers still work)
- **Receiver** accepts BOTH paths and deduplicates, preferring canonical

| Sender | Receiver | Result |
|--------|----------|--------|
| New | Old | ✓ Works (sender mirrors to legacy) |
| Old | New | ✓ Works (receiver accepts legacy) |
| New | New | ✓ Works (uses canonical, ignores legacy duplicates) |

### Implementation diffs

**cn_hub.ml** — Add canonical path constant:

```diff
+let threads_wire_in hub = Cn_ffi.Path.join hub "threads/wire/in"
 let threads_in hub = Cn_ffi.Path.join hub "threads/in"  (* legacy wire alias (deprecated) *)
```

**cn_system.ml** — Hub init creates both directories:

```diff
+  Cn_ffi.Fs.mkdir_p (Cn_ffi.Path.join hub_dir "threads/wire/in");
+  (* Legacy wire alias (deprecated, kept for compatibility) *)
   Cn_ffi.Fs.mkdir_p (Cn_ffi.Path.join hub_dir "threads/in");
```

**cn_mail.ml** — Receiver accepts both paths, prefers canonical:

```diff
-  let files = ... |> List.filter (fun f ->
-      String.length f > 11 &&
-      String.sub f 0 11 = "threads/in/" &&
-      Cn_hub.is_md_file f) in
+  let wire_prefix = "threads/wire/in/" in
+  let legacy_prefix = "threads/in/" in
+  let files_raw = ... |> List.filter (fun f ->
+      (starts_with ~prefix:wire_prefix f || starts_with ~prefix:legacy_prefix f)
+      && Cn_hub.is_md_file f) in
+
+  (* Prefer canonical wire path, drop legacy duplicates *)
+  let new_files = files_raw |> List.filter (starts_with ~prefix:wire_prefix) in
+  let old_files = files_raw |> List.filter (starts_with ~prefix:legacy_prefix) in
+  let new_basenames = new_files |> List.map Filename.basename in
+  let files = new_files @ (old_files |> List.filter (fun f ->
+      not (List.mem (Filename.basename f) new_basenames))) in
```

**cn_mail.ml** — Sender writes to both paths:

```diff
-  let thread_dir = Cn_ffi.Path.join hub_path "threads/in" in
-  Cn_ffi.Fs.ensure_dir thread_dir;
-  Cn_ffi.Fs.write (Cn_ffi.Path.join thread_dir file) content;
-  let _ = ... "git add threads/in/<file>" in
+  let wire_dir = Cn_ffi.Path.join hub_path "threads/wire/in" in
+  let legacy_dir = Cn_ffi.Path.join hub_path "threads/in" in
+  Cn_ffi.Fs.ensure_dir wire_dir;
+  Cn_ffi.Fs.ensure_dir legacy_dir;
+  Cn_ffi.Fs.write (Cn_ffi.Path.join wire_dir file) content;
+  Cn_ffi.Fs.write (Cn_ffi.Path.join legacy_dir file) content;
+  let _ = ... "git add threads/wire/in/<file> threads/in/<file>" in
```

**cn_io.ml** — Transport layer accepts both paths:

```diff
+let starts_with prefix s =
+  let plen = String.length prefix in
+  String.length s >= plen && String.sub s 0 plen = prefix
+
 let get_branch_files ~hub ~branch =
+  let wire_prefix = "threads/wire/in/" in
+  let legacy_prefix = "threads/in/" in
   Git.diff_files ~cwd:hub ~base:"main" ~head:("origin/" ^ branch)
-  |> List.filter is_md_file
+  |> List.filter (fun f ->
+      is_md_file f && (starts_with wire_prefix f || starts_with legacy_prefix f))
```

---

## Implementation Status

All changes described in this document have been implemented in cnos as of 2026-02-20:

- ✓ Wire directory cleanup (`threads/wire/in/` canonical, backwards-compatible)
- ✓ Canonical vocabulary alignment (`state: delegated`, `sent → Delegated` alias)
- ✓ Orphan rejection message (substrate-true explanation)

Thread-domain vocabulary is now a closed set matching the typed FSM exactly.
