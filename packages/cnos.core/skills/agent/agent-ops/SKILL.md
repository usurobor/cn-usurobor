# Agent Ops

Operations an agent can request via `state/output.md`.

---

## Overview

When processing input.md, the agent writes output.md with:
1. Required `id` field matching input's id
2. Optional legacy coordination operation fields in frontmatter
3. Optional typed capability ops in `ops:`
4. Response body

`cn` parses output.md and executes any valid operations found.

There are **two layers**:

1. **Legacy coordination ops** — reply, send, done, defer, etc.
2. **Typed capability ops** — CN Shell observe/effect requests in `ops:`

Use coordination ops for thread / routing / lifecycle intent.
Use typed ops when you need `cn` to inspect or mutate governed workspace state.

## Legacy Coordination Ops

All operations go in output.md frontmatter as `key: value`.

### ack

Acknowledge input without further action.

```yaml
ack: <input-id>
```

### done

Mark input or thread as complete.

```yaml
done: <id>
```

### fail

Report failure to process, with reason.

```yaml
fail: <id>|<reason>
```

Example: `fail: review-123|missing context`

### reply

Append reply to an existing thread.

```yaml
reply: <thread-id>|<message>
```

### send

Send message to a peer (queues to outbox).

```yaml
send: <peer>|<message>
send: <peer>|<message>|<body>
```

- `message` — brief summary (appears in notification)
- `body` — full response text (optional, but recommended for detailed replies)

If body is omitted but output.md has content below frontmatter, that content SHOULD be used as body.

### delegate

Forward thread to another agent.

```yaml
delegate: <thread-id>|<peer>
```

### defer

Postpone thread until later.

```yaml
defer: <id>
defer: <id>|<until>
```

### delete

Discard a thread.

```yaml
delete: <id>
```

### surface (alias: mca)

Surface an MCA for community pickup.

```yaml
surface: <description>
mca: <description>
```

## Example Output

```markdown
---
id: review-pi-proposal
done: review-pi-proposal
surface: Add retry logic to wake mechanism
---

# Review Complete

Reviewed Pi's proposal. Approved with minor suggestions.

The wake mechanism could use retry logic - surfacing as MCA.
```

## Typed Capability Ops (ops:)

Typed capability requests go in a single-line JSON array in frontmatter:

```markdown
---
id: review-pi-proposal
ops: [{"kind":"fs_read","path":"src/agent/mindsets/COHERENCE.md"}]
---
I need to inspect the coherence mindset before deciding.
```

### Important

- `ops:` MUST be frontmatter, not body text
- `ops:` MUST be JSON, not XML, not YAML, not pseudo-code
- Do not invent wrappers like `<observe>...</observe>`
- Do not emit shell commands like `cat file` or `git diff`

### Common observe ops

- `fs_read`
- `fs_list`
- `fs_glob`
- `git_status`
- `git_diff`
- `git_log`
- `git_grep`

### Common effect ops

- `fs_write`
- `fs_patch`
- `git_branch`
- `git_commit`
- `exec` (only when explicitly enabled by runtime policy)

### Example: ask to inspect a file

```markdown
---
id: wisdom-check-001
reply: wisdom-check-001|Gathering the relevant file first
ops: [{"kind":"fs_read","path":"src/agent/mindsets/COHERENCE.md"}]
---
I want to read the coherence mindset before I answer.
```

### Example: ask to inspect, then later patch

Pass A:

```markdown
---
id: fix-readme-001
ops: [{"kind":"fs_read","path":"README.md"}]
---
Let me inspect the README first.
```

Pass B (after cn feeds back evidence):

```markdown
---
id: fix-readme-001
reply: fix-readme-001|I prepared a patch
ops: [{"kind":"fs_patch","op_id":"patch-001","path":"README.md","unified_diff":"..."}]
---
Here is the proposed README fix.
```

### When to use which layer

- Need to reply / route / complete / defer → use legacy coordination ops
- Need to read / diff / patch / branch / commit / exec → use `ops:`

### Two-pass intuition

If you request observe ops, `cn` may run a bounded second pass so you can see the evidence
before proposing effects. Do not assume you can observe and mutate in one step.

## Rules

1. `id` field is required and must match input's id
2. Multiple operations are allowed in a single output
3. Legacy coordination ops execute in frontmatter order
4. Typed capability ops are validated under policy; unknown or invalid ops are denied
5. IO pair is archived to logs/input/ + logs/output/ before executing effects (per LOGGING.md)
6. `cn` logs operations to system log (stdout, captured by systemd/cron)
7. Never emit XML-style pseudo-tool syntax

## RACI: A vs I

When assigning work or escalating issues:

| If you... | You are... |
|-----------|------------|
| Can investigate/act yourself | **A** (Accountable) — own it |
| Cannot act, only need to know | **I** (Informed) — receive updates |

**The test:** "Can I do something about this myself?"
- Yes → You're A. Do it.
- No → You're I. Pass it with clear reason why you can't act.

**Anti-pattern:** Filing issues as "I" when you could investigate. This passes the buck.

**Example:**
- ❌ "Version string bug. Sigma to investigate." (passing as I)
- ✅ "Version string bug. I found: binary reports 2.1.21, dune-project has 2.1.22. Root cause: cn_lib.ml not bumped. Fix: bump + rebuild + republish." (owned as A, then delegated with context)

## When You See Something, Say Something

If you observe an issue — don't just note it and move on.

**The problem:** Noticing something broken, marking it "already handled" or "not my job," and continuing. The issue rots. No one owns it.

**The MCA when you observe an issue:**

1. **Capture it** — Write a clear description: what's broken, repro steps, impact
2. **Assign it** — Route to the right owner (use `send:` or `surface:`)
3. **Track it** — Add to backlog with priority
4. **Follow up** — Don't let it rot

**Example:**

You notice `input.md` hasn't cleared in 45 hours despite `output.md` being written.

❌ **Wrong:** "Same stale input, already processed. HEARTBEAT_OK."
(You noted it. You moved on. The issue persists.)

✅ **Right:** 
```yaml
surface: Actor model stuck — input.md not clearing after output.md written. Blocking Pi↔Sigma coordination. P1.
send: sigma|Actor model issue: input.md stuck since Feb 7. output.md exists but cn process didn't clear. Can you check?
```
(Captured. Assigned. Tracked.)

**The test:** "Did I leave the system better than I found it?"

If you saw a problem and didn't create a traceable work item, the answer is no.

---

## Types (OCaml)

```ocaml
type agent_op =
  | Ack of string
  | Done of string
  | Fail of string * string
  | Reply of string * string
  | Send of string * string
  | Delegate of string * string
  | Defer of string * string option
  | Delete of string
  | Surface of string
```

Typed capability ops are represented separately by the CN Shell typed-op schema.
