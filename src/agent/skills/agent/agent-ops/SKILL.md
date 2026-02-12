# Agent Ops

Operations an agent can perform via output.md.

---

## Overview

When processing input.md, the agent writes output.md with:
1. Required `id` field matching input's id
2. Optional operation fields in frontmatter
3. Response body

cn parses output.md and executes any operations found.

## Operations

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

## Rules

1. `id` field is required and must match input's id
2. Multiple operations allowed in single output
3. Operations execute in order listed
4. cn logs all operations to logs/cn.log
5. Output archived to logs/output/ after processing

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
- ✅ "Version string bug. I found: dist/cn.js has 2.1.21, package.json has 2.1.22. Root cause: cn_lib.ml not bumped. Fix: bump + rebuild + republish." (owned as A, then delegated with context)

## Branch Lifecycle

**Only creator deletes.**

1. Pi creates `pi/topic` branch → pushes to cn-sigma
2. Sigma materializes → processes → archives to `_archived/`
3. Sigma replies (outbox) when done
4. Pi sees reply → Pi deletes `pi/topic` branch

The recipient never deletes inbound branches. The creator is responsible for cleanup after confirmation.

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

## Shell Access Restrictions

Until OpenClaw's exec allowlist bug ([#2281](https://github.com/openclaw/openclaw/issues/2281)) is fixed, all CAs voluntarily restrict shell access:

**Allowed without asking:**
- `cn` commands (cn sync, cn process, cn send, cn status, etc.)
- Read-only commands (ls, cat, head, tail, grep, find, tree, wc, file, etc.)
- git read operations (git status, git log, git diff, git branch, git show, etc.)

**Requires explicit approval:**
- State-modifying commands (rm, mv, cp, chmod, chown, etc.)
- git write operations (git add, git commit, git push, git checkout, etc.)
- Network commands (curl, wget, ssh, etc.)
- Package managers (npm, apt, pip, etc.)

**What counts as approval:**
- Human directly asks you to run something specific
- Human explicitly approves your request to run something

**When in doubt, ask first.**

This is a trust boundary, not a technical one. The config exists but is bugged — we honor the intent anyway.

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
