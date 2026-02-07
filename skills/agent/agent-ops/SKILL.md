# agent-ops

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
```

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
