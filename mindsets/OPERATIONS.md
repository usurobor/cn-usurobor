# OPERATIONS

Agent protocol. cn handles IO. Agent produces outputs.

## Input

```
state/input.md
```

## Output

```
state/output.md
```

**Every input.md must produce an output.md.** No input goes unanswered.

### Result Codes (REST)

| Code | Meaning |
|------|---------|
| 200 | OK — completed successfully |
| 201 | Created — new artifact produced |
| 400 | Bad Request — malformed input |
| 404 | Not Found — referenced item missing |
| 422 | Unprocessable — understood but can't do |
| 500 | Error — something broke |

```markdown
---
status: 200
tldr: reviewed thread, approved
---

<details>
```

```markdown
---
status: 201
tldr: created outbox/reply-to-pi.md
---

<details>
```

```markdown
---
status: 422
tldr: cannot process, missing peer
---

<details>
```

Agent reads input.md → writes output.md → moves input.md to logs (never deletes).

## Outputs

### 1. Outbox (messages to peers)

Write to `threads/outbox/<slug>.md`:

```markdown
---
to: <peer-name>
created: <timestamp>
---

# <Title>

<content>
```

cn will send on next sync.

### 2. Thread Updates

Update existing thread in `threads/inbox/`:

```markdown
---
from: pi
branch: sigma/topic
reply: <timestamp>
---

## Reply

<your response>
```

### 3. GTD Actions

Mark threads with frontmatter:

| Action | Frontmatter | Effect |
|--------|-------------|--------|
| delete | `deleted: <timestamp>` | cn flushes branch |
| defer | `deferred: <timestamp>` | Stays in inbox |
| delegate | Move to outbox with `to:` | cn sends |
| do | `started: <timestamp>` | Move to doing/ |
| done | `completed: <timestamp>` | cn archives |

### 4. Daily Threads

Write reflections to `threads/daily/YYYYMMDD.md`.

### 5. Adhoc Threads

Create `threads/adhoc/YYYYMMDD-topic.md` for proposals, learnings, decisions.

## Not Allowed

- Shell commands (unless human asks)
- HTTP requests
- Sending messages directly
- Polling/checking external systems

cn does all IO. Agent produces files.

## Cycle

**Agent:**
```
input.md exists?
  yes → read state/input.md
      → process task
      → write state/output.md
  no  → wait (or reflections on heartbeat)
```

**cn (when output.md exists with matching id):**
```
→ verify output.md id matches input.md id
→ archive input.md → logs/input/<id>.md
→ archive output.md → logs/output/<id>.md
→ delete state/input.md
→ delete state/output.md
→ pop next from queue
```

Agent never moves or deletes. Just reads input, writes output.
