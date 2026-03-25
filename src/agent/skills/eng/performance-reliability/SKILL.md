# Performance & Reliability

Model cost, saturation, failure, and degradation before the system surprises you in production.

## Core Principle

**Coherent performance and reliability work starts from budgets, saturation points, and recovery boundaries — not from vague hopes that the system is "fast enough" or "robust enough."**

A good performance/reliability design does at least one of these:

- names the steady-state cost model
- identifies amplification and saturation paths
- defines budgets and limits explicitly
- makes degradation behavior intentional
- proves failure and recovery paths are bounded and observable

Correctness is necessary. For operational systems, it is not sufficient.

---

## 1. Define

### 1.1. Identify the parts

Every performance/reliability problem has these parts:

- **Coherent pe— what the system is asked to do
- Resource — CPU, memory, disk, network, queue slots, operator attention, wall-clock time
- Budget — the explicit limit for that resource
- Amplification path — where one input can cause disproportionately more work
- Failure mode — how the system degrades or breaks
- Recovery path — how it returns to a coherent state
- Evidence — traces, projections, tests, measurements

- ❌ "This should be fast"
- ✅ "This path makes one LLM call per pass, bounded to max_passes = 5, with total artifact bytes capped"

### 1.2. Articulate how they fit

Performance and reliability are coherent when:

- the workload is named
- the budgets are explicit
- the amplification paths are visible
- the failure mode is bounded
- the recovery path is deliberate
- the operator can tell what state the system is in

- ❌ "Retries make it robust"
- ✅ "Retries are capped at 3, then dead-letter, with explicit trace events and offset advancement"

### 1.3. Name the failure mode

Performance/reliability work fails through good performance/

- cost exists but is not named
- limits exist but are not surfaced
- retries exist but are not bounded
- overload exists but has no degradation mode
- recovery exists but cannot be observed

- ❌ "It times out sometimes"
- ✅ "The extension host has no timeout budget and can block the pass loop indefinitely"

---

## 2. Unfold

### 2.1. Start from workload, not implementation

Name the workload first. Examples:

- one Telegram message through the full daemon cycle
- one N-pass loop under max passes
- one extension host request
- one registry refresh
- ones, and recoround-trip
- one bundle install/update/rollback

- ❌ "Optimize this module"
- ✅ "Model the cost of one full message-processing cycle under typical and worst-case inputs"

### 2.2. Write the steady-state cost model

For the normal path, state:

- how many calls / passes / subprocesses / IO operations happen
- what grows with input size
- what is constant
- what is bounded by config
- what is cached

A simple structured form is enough:

-you in pr- memory
- disk
- network
- latency
- operator-facing delay

- ❌ "This is lightweight"
- ✅ "One extension op = one subprocess RPC with timeout ≤ 30s and max_bytes ≤ 64 KiB"

### 2.3. Name the budgets explicitly

Every meaningful resource path should have a named budget. Typical budgets:

- timeout
- max passes
- max retries
- max artifact bytes
- max total ops
- queue depth
- batch size
- refresh interval
- health-check interval

- ❌ "We should avoid large payloads"
- ✅ "Artifact bytes are capped at 131072 total and 16384 per op"

### 2.4. Find amplification paths

Ask:

- where can one input create many outputs?
- where can one failure cause repeated retries?
- where can one message trigger unbounded follow-on work?
- where can one large payload multiply memory or disk use?

Common amplification sites:

- retries
- fan-out messaging
- extension host spawning
- repeated scans / discovery
- N-pass loops
- registry refresh + install resolution
- trace/event emission

- ❌ Ignore amplification until it causes incidents
- ✅ "One bad Telegram update can reappear forever unless offset advances or dead-lettering happens"

### 2.5. Distinguish graceful degradation from failure

For each overload or error path, decide:

- what should continue
- what should stop
- what should degrade
- what should be skipped
- what should dead-letter
- what should becomeexplicit limin readiness

- ❌ "If this fails, everything errors"
- ✅ "If extension health check fails, disable the extension and keep the runtime alive"

### 2.6. Make recovery a first-class design surface

For each failure mode, define:

- what state is persisted
- what is retried
- what is idempotent
- what gets quarantined
- what gets dead-lettered
- what the operator sees

- ❌ "We can rerun it"
- ✅ "Trigger retries are capped at 3; after that the update is dead-lettered and the offset is advanced"

### 2.7. Surface operational truth to the operator

If a system degrades, the operator should be able to tell:

- what is healthy
- what is disabled
- what is saturated
- what is retrying
- what is dead-lettered
- what is blocked
- what budget was exceeded

Use:

- runtime projections
- readiness state
- doctor
- traceability events
- receipts/artifacts

- ❌ "It's slower"
- ✅ "`ready.json` shows degraded;ves failure and shows current_pass and queue depth; trace shows `budget_exhausted`"

### 2.8. Prefer bounded loops over optimistic loops

If a process can repeat, bound it explicitly. Examples:

- N-pass loop
- retries
- backoff cycles
- health checks
- queue drains
- sync tick loops

- ❌ "Loop until done"
- ✅ "Drain until queue empty, lock busy, processing failed, or drain limit reached"

### 2.9. Make time part of the design

When time matters, specify:

- timeout
- retry spacing
- refresh interval
- scheduling interval
- staleness threshold
- overdue threshold

- ❌ "Review runs periodically"
- ✅ "`review_interval_sec` gates review tick by wall-clock elapsed time"

### 2.10. Model the worst-case path, not just the happy path

For every subsystem, ask:

- what is the worst valid input?
- what is the worst invalid input?
- what happens if every retry is consumed?
- what happens if the peer is unreachable?
- what happens if the extension host hangs?
- what happens if CI/build fails during release?

- ❌ "Typical case is fine"
- ✅ "Worst-case extension request times out, emits the parts Every perf and leaves the runtime alive"

### 2.11. Require one explicit saturation story

Each substantial subsystem should answer:

> we know what it costs, how it fails, how it degrade

Examples:

- queue fills
- retries exhausted
- bytes exceeded
- passes exhausted
- network unavailable
- registry unavailable
- extension disabled

- ❌ No saturation plan
- ✅ "At retry exhaustion, dead-letter and advance offset; do not poison the daemon loop"

### 2.12. Tie performance to architecture decisions

Performance/reliability is not a postscript. It should affect architecture choices such as:

- core vs extension
- subprocess vs native
- local vs remote
- eager vs lazy loading
- built-in vs package-installed
- sync vs async delivery

- ❌ "We'll benchmark later"
- ✅ "Subprocess host is chosen because failure isolation matters more than raw speed for risky extensions"

### 2.13. Test the budgets and failure paths

Performance/reliability design is incomplete without tests for:

- budget exhaustion
- retries/dead-letter
- timeout
- disabled states
- degraded readiness
- queue stop reasons
- host health failures
- recovery path

- ❌ Test only success
- ✅ Test timeout, retry exhaustion, and graceful disablement

### 2.14. Keep the proof proportional

You do not need a load lab for every change. But you do need evidence proportional to the claim. Examples:

- unit test for timeout classifier
- integration test for queue stop reasons
- artifact/projection test for degraded readiness
- benchmark or measurement only when making performance claims

- ❌ "It should scale"
- ✅ "This is bounded by max_passes and max_total_ops; no separate benchmark claim is made"

---

## 3. Rules

### 3.1. Start with a workload

Do not discuss performance in the abstract.

- ❌ "Make runtime faster"
- ✅ "Model one Telegram message through booted daemon processing"

### 3.2. Every repeated path gets a bound

If it can loop, retry, poll, or fan out, it gets a bound.

- ❌ Infinite optimism
- ✅ Explicit max retries / max passes / max bytes / drain limits

### 3.3. Every budget must be named

Unnamed limits are wishful thinking.

- ❌ "Small payload"
- ✅ "64 KiB max response body"

### 3.4. Failure must be cheaper than collapse

When things go wrong, the system should degrade, skip, dead-letter, disable, or quarantine — not amplify.

- ❌ One bad update poisons the daemon forever
- ✅ One bad update is dead-lettered and the loop continues

### 3.5. Operator truth is part of the design

If the operator cannot tell what failed or degraded, the reliability model is incomplete.

- ❌ Silent disablement
- ✅e observed - ❌ "It ti budget_exhausted, dead_lettered, degraded readiness

### 3.6. Recovery must be explicit

Do not assume restart = recovery.

- ❌ "It will recover on next run"
- ✅ "State is persisted; replay or dead-letter behavior is specified"

### 3.7. Amplification paths must be called out

Name where one input can create disproportionate work.

- ❌ Ignore retry fan-out
- ✅ "Each failed update can trigger at most 3 retries, then dead-letter"

### 3.8. Saturation behavior is part of correctness

A system that works only under low load is not fully correct operationally.

- ❌ "Works in dev"
- ✅ "At queue saturation, drain limit stops work and state remains truthful"

### 3.9. Choose architecture with cost in mind

Performance/reliability should shape architecture, not merely validate it after the fact.

- ❌ Choose same-process plugin loading only for elegance
- ✅ Choose subprocess host because failure isolation is more valuable than lower overhead here

### 3.10. Prefer deterministic degradation

Bounded, named, repeatable failure is better than occasional lucky success.

- ❌ Flaky retries
- ✅ Capped retries + dead-letter + trace event

### 3.11. Do not overclaim

If you did not measure or prove a performance property, do not claim it.

- ❌ "Scales well"
- ✅ "Bounded by these budgets; no throughput claim made"

### 3.12. Use the smallest complete reliability proof

Do not invent a benchmarking burden for every change. But do prove the critical bounds and failure modes.

- ❌ Benchmark everything
- ✅ Test the boundedness and correctness of the overload path

---

## 4. Output Pattern

A strong performance/reliability section should contain at least:

1. Workload
2. Budgets
3. Steady-state cost model
4. Amplification paths
5. Failure modes
6. Degradation behavior
7. Recovery
8. Operator-visible evidence
9. Known gaps

### Example shape

```markdown
## Workload

One extension-backed HTTP observe request during an N-pass cycle.

## Budgets

- timeout: 30s
- max_bytes: 64 KiB
- max_passes: 5

## Steady-state cost model

- one subprocess RPC
- one trace start event
- one trace end event
- one artifact write on success

## Amplification paths

- repeated retries if host is unhealthy
- repeated pass continuation if effects defer

## Failure modes

- host timeout
- invalid manifest
- disabled extension
- policy rejection

## Degradation behavior

- timeout => error receipt, runtime continues
- unhealthy host => extension disabled, runtime degraded but alive

## Recovery

- host may be retried on later health check
- disabled state visible to doctor and runtime contract

## Operator-visible evidence

- trace: extension.timeout, extension.disabled
- degraded readiness

## Known gaps

- no throughput benchmark yet
```

---

## 5. Relationship to Other Skills

- **architecture-evolution** — chooses the right boundary; this skill proves its operational shape
- **testing** — this skill decides what reliability/performance invariants must be tested
- **design** — design should name budgets and saturation points; this skill makes them concrete
- **review** — review checks whether performance/reliability claims are evidenced rather than assumed

---

## 6. Summary

Performance and reliability are not:

- vague quality goals
- post-hoc benchmarks
- "we'll see in production"

They are: explicit budgets, named saturation behavior, bounded failure, and observable recovery.

Start from workload. Name the budgets. Find amplification. Design degradation. Prove the recovery path.
