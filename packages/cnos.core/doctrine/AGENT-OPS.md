# Agent Ops — Runtime Emission Discipline

Always-on rules for agent output format. Non-negotiable.

## Output Contract

Every output.md MUST have:
1. `id:` field in frontmatter matching the input's id
2. Optional coordination ops in frontmatter (reply, send, done, defer, etc.)
3. Optional typed capability ops in `ops:` frontmatter field
4. Response body below frontmatter

## Coordination Ops

Frontmatter `key: value` format:
- `ack: <id>` — acknowledge without action
- `done: <id>` — mark complete
- `fail: <id>|<reason>` — report failure
- `reply: <thread-id>|<message>` — reply to thread
- `send: <peer>|<message>` — send to peer
- `delegate: <thread-id>|<peer>` — forward to peer
- `defer: <id>[|<until>]` — postpone
- `delete: <id>` — discard
- `surface: <description>` — surface MCA for pickup

## Typed Ops (ops:)

Single-line JSON array in frontmatter:
```
ops: [{"kind":"fs_read","path":"README.md"}]
```

Rules:
- `ops:` MUST be frontmatter, not body text
- `ops:` MUST be valid JSON array
- Do NOT emit XML-style pseudo-tool syntax
- Do NOT emit raw shell commands

## Complete Output Example

This is the exact format the runtime parses. Coordination ops and typed ops go in the YAML frontmatter block. Response body goes below.

```
---
id: trigger-abc123
send: sigma|Found a security gap in ops boundary docs
ops: [{"kind":"fs_read","path":"docs/alpha/AGENT-RUNTIME.md"}]
---

I reviewed the MCA and found the issue. Sending details to Sigma for investigation.
```

**Critical:** Ops must be *emitted* in frontmatter, never *described* in the body. If you write `send: peer|message` inside prose or a code block, the runtime ignores it. Only frontmatter is parsed.

## RACI Discipline

Can you act on it yourself?
- Yes → own it (A). Investigate, fix, report.
- No → pass it (I). Clear reason why you can't act.

Anti-pattern: filing issues as "I" when you could investigate.

## See Something, Say Something

Observe an issue → capture it, assign it, track it.
Do NOT note it and move on. Create a traceable work item.
