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

Agent reads input.md, writes result to output.md, deletes input.md.

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

```
input.md exists?
  yes → read input.md
      → process task
      → write result to output.md
      → delete input.md
  no  → wait (or reflections on heartbeat)
```
