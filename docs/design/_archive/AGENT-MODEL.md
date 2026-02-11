> **ARCHIVED** — Superseded by [FSM-PROTOCOL.md](../FSM-PROTOCOL.md) and [ARCHITECTURE.md](../../ARCHITECTURE.md).
> See [AUDIT.md](../AUDIT.md) for details. Preserved for historical reference.

# Agent Model

**Status:** Specification  
**Created:** 2026-02-06

---

## Principle

Agent is a pure function. Receives input, outputs decision. No side effects.

## Architecture (Erlang Actor Model)

```
┌─────────────────────────────────────────┐
│                  cn                      │
│  (supervisor / orchestrator)            │
│                                         │
│  ┌─────────┐         ┌─────────┐       │
│  │ peers   │ ──────→ │ inbox   │       │
│  └─────────┘         └────┬────┘       │
│                           │             │
│                     (one item)          │
│                           ↓             │
│                    ┌──────────┐         │
│                    │  Agent   │         │
│                    │  (pure)  │         │
│                    └────┬─────┘         │
│                         │               │
│                    (decision)           │
│                         ↓               │
│                    ┌─────────┐          │
│                    │ outbox  │ ───────→ execute
│                    └─────────┘          │
└─────────────────────────────────────────┘
```

## Agent Function

```
agent : inbox_item → decision
```

Agent receives ONE inbox item. Agent outputs ONE decision.
Agent does not:
- List inbox
- Choose what to process
- Execute anything
- Access filesystem
- Run commands

cn does all of that.

## Input (Thread + Cadence)

cn feeds agent an item with cadence metadata:

```
{
  thread: <content>,
  cadence: inbox | daily | weekly | monthly | quarterly | yearly | adhoc
}
```

Cadence tells agent what kind of processing:

| Cadence | Meaning | Processing |
|---------|---------|------------|
| inbox | Message from peer | GTD triage |
| daily | Daily reflection | Summarize day |
| weekly | Weekly review | Patterns, adjustments |
| monthly | Monthly review | Goals, trajectory |
| quarterly | Quarterly review | Strategic alignment |
| yearly | Yearly review | Evolution, intentions |
| adhoc | Work item | Task-specific |

## Decisions (Output)

### For inbox items (GTD):
```
Delete    — discard, not relevant
Defer     — postpone, process later
Delegate  — forward to peer
Do        — claim, start working
Done      — complete, archive
```

### For cadence threads:
```
Noop      — no action needed
Reply     — append reflection/content
Create    — spawn new thread
```

### For adhoc threads:
```
Noop      — no action
Reply     — continue work
Done      — complete, archive
```

That's the complete decision set. Nothing else.

## Initiating Actions

Agent cannot initiate actions from threads.
To trigger action: **send to self**.

```
Agent thinks: "I should review security"
    ↓
Agent outputs: send self "Review security model"
    ↓
cn delivers to agent's inbox
    ↓
Agent receives item, processes: Do
    ↓
Agent works, outputs: Done
```

All actions flow through inbox.

## Message Flow

```
peer sends → inbox → agent processes → outbox → cn executes
                                         ↓
                            (send to peer / send to self / GTD decision)
```

## Example Session

```
cn: delivers inbox item from Pi
    "CLP: Review outbox design"

agent: (reads, thinks)
agent: → Do

cn: moves to doing/
cn: delivers next item (or waits)

agent: (works on thread)
agent: → Reply "Approved. Implemented with threads model."

agent: → Done

cn: moves to archived/
cn: sends reply to Pi
```

## Purity Guarantees

Agent CANNOT:
- Access filesystem
- Execute commands
- Call APIs
- List inbox
- Choose processing order

Agent CAN ONLY:
- Receive one inbox item
- Output one decision
- Repeat

## cn Responsibilities

- Fetch from peers → inbox
- Feed items to agent (one at a time)
- Receive decisions from outbox
- Execute: move threads, send to peers, archive
- Log everything
- Handle errors/retries

## Why This Model

1. **Testable**: Agent is pure function, trivially testable
2. **Secure**: Agent has no capabilities, can't go rogue
3. **Auditable**: All decisions logged, traceable
4. **Simple**: Limited decision set, no complexity
5. **Erlang-proven**: Actor model, battle-tested

---

*Agent thinks. cn acts.*
