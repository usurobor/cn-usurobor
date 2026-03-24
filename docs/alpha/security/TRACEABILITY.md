# TRACEABILITY
## Operational Traceability & Telemetry for Coherent Agents

**Status:** Draft
**Version:** 1.0
**Audience:** Operators, runtime implementers, incident responders
**Supersedes:** ad hoc operational logging model in `LOGGING.md`
**Complements:** [`CAA.md`](CAA.md), [`AGENT-RUNTIME.md`](AGENT-RUNTIME.md), [`CAR.md`](CAR.md)

---

## 0. Purpose

This document defines the observability system for cnos.

Its purpose is not merely to preserve what the agent saw and decided.
It must also let an operator answer, from durable logs alone:

- Did the agent boot successfully?
- Is it fully operational right now?
- Which doctrine, mindsets, and packages did it load?
- What capabilities did the runtime advertise?
- Why did it transition into this state and not another?
- Why did an op execute, fail, get denied, or get deferred?
- Why did the daemon advance (or not advance) a transport offset?
- What was the state of the agent's **mind**, **body**, and **sensors** at the time?

The goal is **reconstructability**:
> From logs alone, an operator can recover the state trajectory of the running agent.

---

## 1. Operator Questions (Primary Design Driver)

The traceability architecture is operator-first.

The system MUST make it possible to answer these questions from logs and state projections:

### 1.1 Boot / readiness
- Did the runtime start?
- Did config load?
- Did deps / lockfile load?
- Did required doctrine load?
- Did required mindsets load?
- Did the agent pack capabilities successfully?
- Is transport initialized?
- Is the system **ready**, **degraded**, or **blocked**?

### 1.2 Cognitive substrate
- Which profile is active?
- Which packages are installed?
- Which doctrine files were loaded?
- Which mindsets were loaded?
- Which task skills were selected?
- Were local overrides applied?

### 1.3 Runtime progression
- Why did the runtime choose Pass A / Pass B?
- Why was an effect op skipped?
- Why was a coordination op deferred?
- Why was a state transition taken?
- Why did offset advance, or not advance?

### 1.4 Safety / governance
- Which sandbox rule denied this path?
- Which policy gate blocked this effect?
- Which budget was exceeded?
- Which capability version mismatch occurred?

### 1.5 External behavior
- Was the inbound message accepted or rejected?
- Did the system project a reply?
- Was projection deduplicated?
- Did a send fail? Was it retried?
- What is currently stuck?

---

## 2. Principles

### 2.1 One source of truth: append-only events
The primary source of operational truth is a structured append-only event stream.

### 2.2 Derived projections
Current state files are **projections** over the event stream:
- convenient to read
- reconstructable from events (aspirational; v1 writes projections directly at runtime choke points; a replay tool may derive them from events in a future version)
- never the sole source of truth

### 2.3 Every state transition must carry a reason
Any transition event MUST answer:
- previous state
- next state
- reason code
- evidence refs (if relevant)

No silent transitions.

### 2.4 Events are for operators; receipts are for capabilities
- **Events** describe lifecycle and state changes
- **Receipts** describe typed capability execution
- **IO pairs** preserve the agent's deliberative boundary

The three are complementary, not interchangeable.

### 2.5 Structural coherence before reflective coherence
Operational readiness is determined by structural signals:
- doctrine present
- packages valid
- capabilities rendered
- transport initialized

Optional agent-reported "coherence" may exist later, but never replaces structural truth.

### 2.6 Local-first and durable
The traceability system itself must not depend on network availability.

---

## 3. The Observability Model

The system has three outputs:

### 3.1 Event stream (append-only)
Machine-readable lifecycle trace.

Location:
- `logs/events/YYYYMMDD.jsonl`

### 3.2 State projections
Current truth snapshots, derived from events.

Locations:
- `state/ready.json`
- `state/runtime.json`
- `state/coherence.json` (structural coherence snapshot)

### 3.3 Existing evidence artifacts
Still retained and referenced:
- `logs/input/{trigger}.md`
- `logs/output/{trigger}.md`
- `state/receipts/{trigger}.json`
- `state/artifacts/{trigger}/...`

---

## 4. Layers of Traceability

Every event belongs to one architectural layer.

### 4.1 Sensor layer
Ingress and egress with the outside world.

Examples:
- Telegram polling
- offset load / advance
- inbound accept / reject
- projection send / dedup / fail
- UX signals (typing, reaction)

### 4.2 Body layer
Runtime mechanics and state progression.

Examples:
- lock acquire / release
- queue dequeue
- FSM derivation
- pass selection
- cleanup
- recovery replay
- finalize completion

### 4.3 Mind layer
Cognitive substrate and LLM-facing context.

Examples:
- profile resolution
- package load
- doctrine load
- mindset load
- skill selection
- capabilities render
- prompt pack complete
- LLM call start / complete

### 4.4 Governance layer
Policy, sandbox, and budget decisions.

Examples:
- path denied
- exec denied
- unknown op kind
- budget exceeded
- ops_version warning
- pass gating (effects_failed)

### 4.5 World layer
Typed capability effects applied to the workspace.

Examples:
- `fs_write`
- `fs_patch`
- `git_branch`
- `git_commit`
- `exec`

World-layer details primarily live in receipts, but summary events are still emitted.

---

## 5. Event Schema

Every event MUST be a single JSON object.

```json
{
  "schema": "cn.events.v1",
  "ts": "2026-03-15T14:02:03Z",
  "seq": 42,
  "boot_id": "20260315-140203-abcd",
  "cycle_id": "tg-123",
  "trigger_id": "tg-123",
  "pass": "A",
  "component": "runtime",
  "layer": "body",
  "event": "pass.selected",
  "severity": "info",
  "status": "ok",
  "prev_state": "idle",
  "next_state": "pass_a",
  "reason_code": "deferred_effects",
  "reason": "ops manifest contains observe-class kinds; effects deferred under n_pass=auto",
  "refs": {
    "input": "logs/input/tg-123.md",
    "output": "logs/output/tg-123.md",
    "receipts": "state/receipts/tg-123.json"
  },
  "details": {
    "observe_ops": 2,
    "effect_ops": 1
  }
}
```

### 5.1 Required fields
- `schema`
- `ts`
- `boot_id`
- `component`
- `layer`
- `event`
- `severity`
- `status`

### 5.2 Strongly recommended fields
- `cycle_id`
- `trigger_id`
- `pass`
- `prev_state`
- `next_state`
- `reason_code`
- `reason`
- `refs`
- `details`

### 5.3 Severity

Allowed values:
- `debug`
- `info`
- `warn`
- `error`

### 5.4 Status

Allowed values:
- `ok`
- `degraded`
- `blocked`
- `error`
- `skipped`

---

## 6. Event Naming

Use dotted verbs and nouns with stable namespaces.

Examples:
- `boot.start`
- `boot.ready`
- `boot.blocked`
- `config.loaded`
- `deps.lock.loaded`
- `assets.validated`
- `doctrine.loaded`
- `mindsets.loaded`
- `skills.indexed`
- `capabilities.rendered`
- `pack.complete`
- `llm.call.start`
- `llm.call.ok`
- `llm.call.error`
- `pass.selected`
- `ops.classified`
- `effects.execute.start`
- `effects.execute.complete`
- `projection.start`
- `projection.ok`
- `projection.skipped`
- `projection.error`
- `projection.render.start`
- `projection.render.ok`
- `projection.render.blocked`
- `projection.render.fallback`
- `daemon.poll.start`
- `daemon.poll.ok`
- `daemon.poll.error`
- `daemon.offset.advanced`
- `daemon.pending`
- `finalize.complete`

---

## 7. Required Boot Events

The following sequence is the minimum durable readiness trace.

### 7.1 Mandatory successful boot path
1. `boot.start`
2. `config.loaded`
3. `deps.lock.loaded`
4. `assets.validated`
5. `doctrine.loaded`
6. `mindsets.loaded`
7. `skills.indexed`
8. `capabilities.rendered`
9. `boot.ready`

### 7.2 Optional transport readiness events

If Telegram daemon mode is enabled:

10. `telegram.offset.loaded`
11. `daemon.poll.start`

### 7.3 Failure path

If boot cannot complete:
- emit `boot.blocked`
- include `reason_code`
- write `state/ready.json` with `status: "blocked"`

Examples of `reason_code`:
- `config_invalid`
- `deps_lock_missing`
- `core_doctrine_missing`
- `core_mindsets_missing`
- `capabilities_render_failed`
- `secrets_file_permissions_invalid`
- `transport_init_failed`

---

## 8. Required Trigger / Cycle Events

Each processing cycle MUST emit:
1. `cycle.start`
2. `queue.dequeue` (or `cycle.recover`)
3. `pack.start`
4. `pack.complete`
5. `llm.call.start`
6. `llm.call.ok` or `llm.call.error`

If N-pass (continuation detected):

7. `pass.selected` (pass_a)
8. `pass_a.complete`
9. `pass.selected` (pass_b)
10. `pass_b.complete`

Then:

11. `effects.execute.start`
12. `effects.execute.complete`
13. `projection.start`
14. `projection.ok` / `projection.skipped` / `projection.error`
15. `finalize.complete`

### 8.1 Transition rule

Any event that changes runtime state MUST include:
- `prev_state`
- `next_state`
- `reason_code`

This is what lets an operator answer:
> Why did it go here and not somewhere else?

---

## 9. State Projections

### 9.1 state/ready.json

Current operational readiness.

```json
{
  "schema": "cn.ready.v1",
  "status": "ready",
  "boot_id": "20260315-140203-abcd",
  "updated_at": "2026-03-15T14:02:04Z",

  "mind": {
    "profile": "engineer",
    "packages": ["cnos.core@1.0.0", "cnos.eng@1.0.0"],
    "doctrine": { "required": 6, "loaded": 6, "hash": "sha256:..." },
    "mindsets": { "required": 9, "loaded": 9, "hash": "sha256:..." },
    "skills": { "indexed": 24, "selected_last": ["eng/review", "agent-ops"] },
    "capabilities": {
      "hash": "sha256:...",
      "n_pass": "auto",
      "apply_mode": "branch",
      "exec_enabled": false
    }
  },

  "body": {
    "fsm_state": "idle",
    "lock_held": false,
    "current_cycle": null,
    "queue_depth": 0
  },

  "sensors": {
    "telegram": {
      "enabled": true,
      "offset": 12345,
      "last_poll_status": "ok",
      "last_poll_at": "2026-03-15T14:01:59Z"
    }
  }
}
```

### 9.2 state/runtime.json

Current runtime mechanics:
- current cycle id
- current pass
- lock owner / boot id
- queue depth
- active trigger
- pending projection state

This is for operational inspection, not long-term audit.

### 9.3 state/coherence.json

Structural coherence projection.

Example fields:
- doctrine complete?
- packages resolved?
- capabilities rendered?
- transport ready?
- receipts schema loaded?
- wake-up local-only?

This is structural coherence, not self-reported introspection.

---

## 10. Structural Coherence Telemetry

The system MUST report structural coherence at boot and after major changes.

### 10.1 Structural coherence criteria

A runtime is structurally coherent if:
- config loaded
- lockfile loaded
- required packages installed
- required doctrine present
- required mindsets present
- Runtime Contract rendered (v2: identity, cognition, body, medium)
- direct I/O boundary intact
- receipts schema available
- transport initialized (if configured)

### 10.2 Example projection

```json
{
  "schema": "cn.coherence.v1",
  "boot_id": "20260315-140203-abcd",
  "status": "coherent",
  "checks": {
    "doctrine": "ok",
    "mindsets": "ok",
    "packages": "ok",
    "capabilities": "ok",
    "transport": "ok"
  },
  "updated_at": "2026-03-15T14:02:04Z"
}
```

### 10.3 Reflective coherence (optional)

A future agent-reported self-check MAY exist, but it is:
- optional
- debug-only
- never a readiness gate

Operational truth remains structural.

---

## 11. Receipts and IO Pairs

Traceability does not replace existing artifacts.

### 11.1 IO pairs remain authoritative for deliberation
- `logs/input/{trigger}.md`
- `logs/output/{trigger}.md`

These answer:
- what the agent saw
- what the agent decided

### 11.2 Receipts remain authoritative for typed ops
- `state/receipts/{trigger}.json`
- `state/artifacts/{trigger}/...`

Events MUST reference these by path and hash when relevant.

### 11.3 No duplication of large blobs in events

Events SHOULD reference artifacts, not inline them.

---

## 12. Projection / Transport Traceability

### 12.1 Projection events

Required lifecycle events:
- `projection.start`
- `projection.ok`
- `projection.skipped`
- `projection.error`

#### 12.1.1 Render sub-events (v3.6.0)

The `projection.render.*` namespace covers sink-specific rendering decisions
within a projection lifecycle. These refine the render step; they do not
replace the lifecycle events above.

- `projection.render.start` — render attempt for a specific sink
- `projection.render.ok` — sink received safe presentation text
- `projection.render.blocked` — control-plane syntax detected, candidate rejected
- `projection.render.fallback` — blocked candidate replaced by fallback text

Each blocked/fallback event SHOULD include a `reason_code`:
- `control_plane_leak` — raw `ops:` or typed-op syntax in candidate
- `raw_frontmatter` — frontmatter fences or key-value control lines
- `xml_tool_syntax` — pseudo-tool XML wrappers (`<observe>`, `<fs_read>`, etc.)
- `no_presentation_payload` — no safe candidate available

See: [AGENT-RUNTIME §v3.6.0](./AGENT-RUNTIME.md) for the output-plane separation spec.

### 12.2 Idempotency trace

If projection uses a marker:
- emit event when marker is created
- emit event when projection is skipped because marker already exists
- emit event when marker is removed after send failure

This is required for understanding "why was / wasn't a message sent?"

### 12.3 Offset events

Required:
- `telegram.offset.loaded`
- `daemon.offset.advanced`
- `daemon.offset.blocked`

Reason codes:
- `processing_failed`
- `still_queued`
- `still_in_flight`
- `rejected_user`
- `already_projected`

---

## 13. Decision and Transition Traceability

Whenever the runtime chooses one branch over another, it MUST log why.

### 13.1 Examples
- `pass.selected` -> `reason_code: deferred_effects`
- `ops.classified` -> `reason_code: pass_a_unsafe_multi_party`
- `coordination.skipped` -> `reason_code: effects_failed`
- `policy.denied` -> `reason_code: path_denied`
- `budget.denied` -> `reason_code: budget_exceeded`

### 13.2 Why this matters

This is what lets an operator answer:
> Why did the system transition this way and not another?

Without `reason_code`, an event stream is just chronological noise.

---

## 14. Event Retention and Rotation

### 14.1 Event logs
- append to `logs/events/YYYYMMDD.jsonl`
- rotate daily by UTC date

### 14.2 State projections
- overwrite in place
- derive from latest known events
- safe to reconstruct

### 14.3 Receipts and artifacts
- follow existing retention policy
- remain referenced by events

---

## 15. Privacy and Secret Safety

### 15.1 Events MUST NOT contain secrets

Never log:
- API keys
- tokens
- raw secret-bearing environment variables
- full secret file contents

### 15.2 Allowed references

Permitted:
- file path
- hash
- size
- status
- boolean flags
- counts

### 15.3 Redaction

If an error message may contain secrets:
- redact before event emission
- preserve unredacted data only where policy explicitly allows (preferably nowhere)

---

## 16. Migration from Current Logging

This architecture replaces the current ad hoc split:
- IO-pair archives remain
- receipts remain
- system stdout remains optional human-readable mirror

But `Cn_hub.log_action` is no longer a no-op.
It becomes the structured event emitter (or is replaced by `Cn_trace.emit`).

### 16.1 Transitional compatibility

During migration:
- continue writing IO pairs exactly as today
- add structured events alongside them
- derive `state/ready.json` and `state/runtime.json` from events

No behavioral changes are required to adopt TRACEABILITY.

---

## 17. Success Criteria

After this design is implemented, an operator can:

### 17.1 Determine readiness from logs alone

By reading:
- event stream
- `state/ready.json`

they can answer:
- did it boot?
- did it load doctrine?
- did it load packages?
- is transport up?
- is it ready?

### 17.2 Explain transitions

For any transition, they can say:
- previous state
- next state
- reason code
- evidence refs

### 17.3 Reconstruct mind / body / sensors

From event stream + projections, they can reconstruct:
- **mind:** doctrine, mindsets, skills, capabilities
- **body:** lock, FSM state, pass, cycle, cleanup/recovery
- **sensors:** transport state, offsets, ingress/egress events

---

## 18. Summary

A coherent runtime needs more than audit artifacts.
It needs intentional operational traceability.

TRACEABILITY defines:
- an append-only event stream
- durable readiness and state projections
- structural coherence telemetry
- explicit transition reasons
- operator-readable evidence across mind, body, and sensors

This replaces ad hoc lifecycle logging with a system that can answer, from files alone:

> What state is the agent in? Why did it get there? Is it truly ready?

---

## Related

- [`AGENT-RUNTIME.md`](AGENT-RUNTIME.md) — runtime lifecycle this document observes
- [`CAA.md`](CAA.md) — capability architecture whose execution events are traced
- [`CAR.md`](CAR.md) — package resolver whose load events are traced
- [`SECURITY-MODEL.md`](SECURITY-MODEL.md) — audit trail as security mechanism
- [`AUDIT.md`](AUDIT.md) — audit architecture
