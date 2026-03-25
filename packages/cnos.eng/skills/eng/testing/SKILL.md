# Testing

Prove system behavior from invariants, not just examples.

## Core Principle

**Coherent testing starts from invariants, chooses the strongest proof form that matches the claim, and makes regressions visible before they become runtime surprises.**

A good testing strategy does at least one of these:

- proves a structural invariant
- proves a behavioral invariant
- proves cross-surface equivalence
- proves a state machine cannot enter invalid transitions
- proves a failure path is bounded and observable

Examples are useful, but examples alone are not enough for systems with parsers, registries, runtime contracts, dispatch, or stateful loops.

---

## 1. Define

### 1.1. Identify the parts

Every testing problem has these parts:

- Surface — what is under test
- Invariant — what must always hold
- Oracle — what decides pass/fail
- Evidence depth — how strong the proof must be
- Test family — example / property / model / integration / artifact / performance
- Counterexample — what failure would look like

  - ❌ "Add tests for this feature"
  - ✅ "The invariant is that active op kinds resolve uniquely; a conflict must be rejected deterministically"

### 1.2. Articulate how they fit

Testing is coherent when:

- the invariant is named before the test is written
- the oracle is stronger than the claim requires, not weaker
- the chosen test family matches the surface
- positive and negative cases are both visible
- artifacts, projections, and traces are tested when they are part of the contract

  - ❌ "This should probably work"
  - ✅ "This parser/compiler pair should round-trip and preserve semantic content"

### 1.3. Name the failure mode

Testing fails through example capture:

- treating one happy-path example as proof of a general claim
- testing local return values while leaving projections/artifacts untested
- validating shape when the claim is about behavior
- validating behavior when the claim is about invariants across many inputs

  - ❌ "The unit test passed, so the runtime contract is correct"
  - ✅ "The unit test proves one example; parity and schema tests prove the contract shape"

---

## 2. Unfold

### 2.1. Start from invariants, not test types

Name the invariant first.

Examples:
- round-trip preserves meaning
- invalid states are unreachable
- op dispatch is deterministic
- excluded paths never leak
- runtime contract JSON and markdown are semantically equivalent
- retries stop at the configured bound
- a disabled extension never executes

  - ❌ "We need unit tests and maybe an integration test"
  - ✅ "We need to prove deterministic dispatch under duplicate-op pressure"

### 2.2. Classify the evidence depth

Choose the proof depth that matches the claim. Use this ladder:

- **example** — one concrete case
- **predicate** — shape / required fields / formatting
- **property** — many generated cases under a stable invariant
- **model** — legal transitions and forbidden transitions
- **integration** — end-to-end runtime path
- **artifact/projection** — user/operator-visible outputs
- **performance/saturation** — bounds, budgets, saturation behavior

  - ❌ Use a unit example to prove a runtime path
  - ✅ Use a runtime path test to prove offset advance + no enqueue + trace event

### 2.3. Prefer the strongest cheap proof

Choose the strongest proof that is still economical.

Examples:
- parser/renderer round-trip → property test
- stateful retry logic → state-machine or path test
- registry conflict policy → property or table-driven negative tests
- runtime contract → markdown/JSON parity + schema test

  - ❌ Reach for end-to-end tests first for everything
  - ✅ Use property tests for input breadth and integration tests for lifecycle truth

### 2.4. Use example tests for semantics, not for exhaustiveness

Example tests are best for:
- edge semantics
- clear regressions
- human-readable intent
- named bugfixes

They are not enough for:
- parsers
- registries
- transforms
- dispatch tables
- stateful retry loops
- schema compilers

  - ❌ One example proves a parser
  - ✅ One example documents intent; properties prove the parser's shape

### 2.5. Use property-based tests where the surface is generative

Default to property tests when testing:
- parsers
- formatters
- round-trips
- transforms
- set/registry resolution
- conflict detection
- path filters
- normalization functions

Useful invariant forms:
- round-trip
- idempotence
- monotonicity
- determinism
- preservation
- rejection of invalid forms

  - ❌ Hand-enumerate 40 parser examples and stop
  - ✅ Add property tests for generated inputs plus named edge examples

### 2.6. Use model/state-machine tests for stateful systems

Default to model/state-machine tests when testing:
- schedulers
- retry logic
- queue processors
- N-pass loops
- lifecycle state transitions
- enable/disable/install/update/remove flows

Stateful test questions:
- what states exist?
- what transitions are valid?
- what transitions are impossible?
- what stops the loop?
- what evidence is emitted at each step?

  - ❌ Only test one retry scenario
  - ✅ Model the retry/dead-letter state machine and prove bounded exit

### 2.7. Test the negative space explicitly

Always ask:
- what must never happen?
- what must be rejected?
- what must be hidden?
- what must not leak?

Examples:
- internal XML must not reach human sinks
- duplicate op kinds must not silently shadow
- disabled extensions must not execute
- excluded paths must not appear in diffs/status/logs
- stale authority surfaces must not override runtime contract

  - ❌ Test only the allowed path
  - ✅ Test the forbidden path with the same seriousness

### 2.8. Test across projections when the system has more than one view

If the system renders multiple views of the same truth, test parity.

Examples:
- markdown ↔ JSON runtime contract
- packed prompt ↔ persisted state
- human rendering ↔ machine control plane
- design spec ↔ structured schema

  - ❌ Test render_markdown and to_json separately
  - ✅ Test that both carry equivalent semantic content

### 2.9. Test artifacts and projections, not just return values

If operators or users rely on files, events, or projections, those are part of the contract.

Examples:
- state/runtime-contract.json
- receipts/artifacts
- trace events
- projected Telegram output

  - ❌ Assert only the in-memory value
  - ✅ Assert the file/event/projection that the system actually uses

### 2.10. Make blockers come with positive and negative proof

For D-level regressions, specify:

- Positive — what must work
- Negative — what must not happen

  - ❌ "Fix extension conflicts"
  - ✅ "Positive: unique op kind dispatches. Negative: duplicate op kinds reject and never shadow"

### 2.11. Name the oracle explicitly

Every nontrivial test should say what makes it pass.

Oracle examples:
- semantic equality
- normalized equality
- exact artifact schema
- trace event presence
- state transition table
- monotonic counter progression
- "no output produced"

  - ❌ "Looks right"
  - ✅ "Oracle = parsed JSON contains identity/cognition/body/medium exactly once"

### 2.12. Distinguish derivation from validation

If the design claims:
- one source of truth
- generated output
- compiled markdown from structured source
- package built from source

then tests must verify:
- the derivation exists
- not just that two files happen to match today

  - ❌ Compare two manually edited files
  - ✅ Verify the build/compiler path produces the second artifact

### 2.13. Keep non-determinism bounded and named

When a test uses:
- time
- retries
- random generation
- process boundaries
- async loops

bound it explicitly:
- seed
- timeout
- retry count
- fake clock where possible
- fixture transport/state

  - ❌ Flaky timing-based assertions
  - ✅ Bounded timeout + deterministic fixture state

### 2.14. Test the migration path when the design includes one

If the feature includes:
- compatibility mode
- fallback path
- correction pass
- phased migration
- old/new contract coexistence

then test:
- old path
- new path
- transition behavior
- failure behavior

  - ❌ Test only the new ideal path
  - ✅ Test the correction/migration path that production will actually hit

---

## 3. Rules

### 3.1. Start from an invariant

Every substantial testable claim begins with: what must always hold?

  - ❌ "Add more tests"
  - ✅ "The installed and projected runtime contract must be semantically equivalent"

### 3.2. Match proof strength to claim strength

Stronger claims require stronger proof.

  - ❌ Example test for a lifecycle guarantee
  - ✅ State-machine or integration test for a lifecycle guarantee

### 3.3. Prefer properties for generative surfaces

If the surface accepts many shapes of input, use property tests unless there is a clear reason not to.

  - ❌ Manual parser examples only
  - ✅ Property + named regression examples

### 3.4. Prefer models for stateful systems

If the behavior depends on prior state, model the transitions.

  - ❌ One-step assertions for retry logic
  - ✅ State-machine reasoning for retry/dead-letter

### 3.5. Test the operator-visible truth

If an operator or user depends on it, it is part of the contract.

  - ❌ Ignore projections/files/events
  - ✅ Assert files/events/projections directly

### 3.6. Negative space is mandatory

Every meaningful boundary gets a "must not happen" test.

  - ❌ Only test success
  - ✅ Test both success and prohibition

### 3.7. Cross-format parity is an invariant

When the same truth exists in multiple forms, parity must be tested.

  - ❌ "Both functions have tests"
  - ✅ "Both functions encode the same meaning"

### 3.8. Generated outputs require generated tests

If the system claims one artifact is produced from another, test the generator/compiler/build path.

  - ❌ Compare checked-in outputs only
  - ✅ Run derivation and verify the result

### 3.9. Record the weakest proof

If a claim is only partially proven, say so.

  - ❌ "AC met" when only predicate tests exist
  - ✅ "AC partially met; integration path not yet proven"

### 3.10. Keep bugfix regressions named

Every bugfix should produce a regression test that names the bug class.

  - ❌ Generic "works now" test
  - ✅ Test named for the dead-letter / misplaced-ops / membrane leak class

### 3.11. Optimize for repeatability

A good test should fail the same way for the same cause.

  - ❌ Timing lottery
  - ✅ Deterministic fixtures, seeds, and bounded retries

### 3.12. Use the smallest complete proof set

Do not bloat the suite with redundant tests. Use the smallest set that proves the invariants.

  - ❌ Ten example tests for what one property test already proves
  - ✅ One property test plus a few named edge regressions

---

## 4. Output Pattern

A strong testing plan or testing section should contain at least:

1. Invariant
2. Surface
3. Evidence depth
4. Test family
5. Oracle
6. Positive case
7. Negative case
8. Known gaps

### Example shape

```markdown
## Invariant
Internal XML must never reach a human-facing sink.

## Surface
render_for_sink / sanitize pipeline

## Evidence depth
Integration/path + artifact/projection

## Test family
Named regression examples

## Oracle
Rendered output contains no XML pseudo-tool tags.

## Positive case
Normal human prose renders intact.

## Negative case
Reply/body with <cn:ops>... is stripped or blocked.

## Known gap
Inline same-line tags not yet covered.
```

---

## 5. Relationship to Other Skills

- **coding** — this skill proves the invariants the code claims to enforce
- **design** — design should name the invariants; testing should prove them
- **review** — review checks whether the evidence depth matches the claim
- **architecture-evolution** — architecture changes often demand stronger proof forms, not just more examples

---

## 6. Summary

Testing is not:

- a pile of examples
- a checkbox for CI
- a vague sense of safety

It is: the deliberate choice of the strongest practical proof form for the invariants that matter.

Start from invariants. Choose the right proof family. Test the negative space. Prove the projections people actually rely on.
