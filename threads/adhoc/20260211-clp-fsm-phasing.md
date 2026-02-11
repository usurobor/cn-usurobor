---
type: clp
subject: FSM Protocol Phasing
from: sigma
created: 2026-02-11T00:00:00Z
status: response
---

# CLP Response: Phasing the 4 FSMs

## Question

Should we ship 4 FSMs together or phase them?

## 1. Are the 4 FSMs coupled or separable?

**Separable, with one caveat.**

Call graph trace:

```
Transport Sender:  cn_mail.ml:send_thread, cn_io.ml:send_thread
                   → reads outbox files, does git ops
                   → no dependency on thread_state or actor_state

Transport Receiver: cn_mail.ml:materialize_branch, cn_io.ml:materialize_branch
                    → reads branches, writes inbox files
                    → no dependency on thread_state or actor_state

Thread Lifecycle:   cn_gtd.ml:gtd_do/defer/delegate/done/delete
                    → reads/moves files between directories
                    → gtd_delegate writes to outbox (loose: Sender picks up later)
                    → no import of transport types

Actor Loop:         cn_agent.ml:run_inbound
                    → reads inbox (populated by Receiver, but async)
                    → calls queue_pop, feed_next, archive_io_pair
                    → archive executes ops, some of which Send (loose coupling)
```

**Caveat:** Thread and Actor share one concept — "this thread is Active (in input.md)." But that's mediated through the filesystem (queue → input.md), not through shared types.

**Verdict: all 4 are independently implementable and testable.**

## 2. Which layer is load-bearing?

**The FSMs are load-bearing. The unification is cleanup.**

You could add Transport FSM types to `cn_mail.ml` alone, without touching `cn_io.ml`, and get the state-safety benefits. The unification removes duplication but doesn't enable the FSM — it's the other way around. The FSM makes the unification *obvious* because both modules would implement the same state machine.

## 3. Recommended task ordering

Phase by risk (highest-impact bug first, smallest blast radius):

| Phase | FSM | Why this order | Blast radius |
|-------|-----|----------------|-------------|
| **P1** | Thread Lifecycle | Fixes the real bug (`gtd_do` on Doing). Pure types, zero I/O changes. Add `state:` to frontmatter, validate transitions in `cn_gtd.ml`. | `cn_gtd.ml` only |
| **P2** | Actor Loop | Second most error-prone code (`run_inbound` nested if/else). Derive state from filesystem, make transitions explicit. | `cn_agent.ml` only |
| **P3** | Transport Receiver + Sender | Fixes branch cleanup bugs. This is where cn_io/cn_mail unification happens — do it *during* FSM extraction, not as a separate step. | `cn_mail.ml` + `cn_io.ml` → `cn_protocol.ml` |

**P1 and P2 can run in parallel** — they touch different modules with no shared types. P3 is the riskiest (two modules merged) so it goes last when the pattern is proven.

Shared type primitives (`transition_result`, error type) go in `cn_protocol.ml` from P1, but P1 only populates the Thread section. P2 and P3 add their sections to the same module.

## Recommendation

```
P1: cn_protocol.ml (thread types) + cn_gtd.ml    ← fixes user-visible bug
P2: cn_protocol.ml (actor types)  + cn_agent.ml   ← fixes scheduler fragility
P3: cn_protocol.ml (transport)    + unify mail/io  ← fixes duplication + branch bugs
```

Ship P1 first.
