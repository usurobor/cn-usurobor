# Why CDD Looks Like This

**Version:** 1.0.0
**Status:** Draft
**Date:** 2026-03-25
**Placement:** γ document (`docs/gamma/cdd/`)
**Audience:** Contributors, reviewers, maintainers, release operators
**Scope:** Rationale for why CDD is a closed-loop, artifact-driven development method rather than a checklist or a generic agile overlay

---

## 0. Purpose

CDD exists because ordinary development process language is too weak for cnos.

Issue queues are not enough. CI green is not enough. A release tag is not enough. A merged PR is not enough.

cnos needs a method that answers a stricter question:

> Did this cycle actually reduce incoherence?

That is the role of CDD.

---

## 1. Why selection starts from observation

Most teams start from:

- whatever issue looks interesting
- whoever claimed something first
- whatever can be shown quickly

CDD does not. Selection begins from:

- coherence history
- encoding lag
- live system health
- previous assessment

Why? Because the system already knows where it is weak. Ignoring those signals and starting from preference is how incoherence accumulates while everyone stays busy.

CDD therefore treats selection itself as part of the algorithm, not as a pre-algorithm human whim.

---

## 2. Why the method is closed-loop

A linear pipeline produces a familiar failure:

- design
- implement
- release
- move on

That shape is convenient and incomplete. It does not guarantee that:

- the release was measured
- the observed system matched the intended design
- the next move was selected from real lag
- the process learned from its own failures

CDD closes the loop because coherence is not proven at merge time. It is proven only after:

- release
- observation
- assessment
- closure

That is why CDD ends by feeding back into selection.

---

## 3. Why artifacts matter so much

CDD is strict about artifacts because undocumented coherence is not inspectable.

A team can "feel" aligned and still have:

- stale docs
- duplicated truth sources
- untracked debt
- broken release mechanics
- runtime/design drift

Artifact requirements are not bureaucracy. They are how the system makes its own state inspectable.

Bootstrap stubs matter because they force the author to name the target outputs before improvising content.

Self-coherence matters because it forces the author to prove AC coverage before handing work to review.

Frozen snapshots matter because they preserve what was actually shipped.

---

## 4. Why CDD is not fully mechanical

There is a temptation to say: if the artifacts exist, the method is complete.

That would be convenient and false.

Mechanical checks can validate:

- branch naming
- artifact presence
- frozen snapshot integrity
- AC accounting
- stale cross-references
- release prerequisites

But they cannot decide:

- what the real incoherence is
- whether MCA or MCI is the correct move
- whether a design is actually coherent
- whether a reviewer is right
- whether a cycle should stop

CDD therefore puts mechanical gates around judgment. It does not pretend to replace judgment.

That is why CDD is rigorous, but not fully mechanical.

---

## 5. Why release is not the finish line

A release is a public articulation of a cycle. It is not proof that the cycle succeeded.

Two common pathologies follow from treating release as the end:

1. unmeasured releases accumulate
2. process failures repeat because nobody patched the method

Post-release assessment exists to prevent both. It measures:

- what actually improved
- what lag remains
- what process failed
- what the next move must be

Closure exists to ensure that assessment outputs are not just noted, but turned into:

- immediate fixes
- explicit next-cycle commitments

Without that, the loop is fake.

---

## 6. Why CDD keeps immediate and deferred outputs separate

Not every MCA named by assessment can be executed inside the same cycle.

Some are small enough to fix immediately:

- changelog corrections
- missing docs
- skill micro-patches
- metadata fixes

Some are large enough that they are obviously the next cycle's work.

If CDD says every MCA must be executed before closure, some cycles can never close. If CDD lets all MCAs float forward informally, closure becomes meaningless.

So the method distinguishes:

- immediate outputs — execute now
- deferred outputs — commit concretely as next work

That is the only way to make closure both real and practical.

---

## 7. Why CDD lives in gamma

CDD is not doctrine and not runtime behavior. It is the method by which the system changes without losing itself.

That makes it γ:

- evolution
- movement
- transition
- closure
- next move

CDD is the development-scale application of coherence, not merely a project-management preference.

---

## 8. Relationship to other documents

### Canonical spec

CDD.md is the normative algorithm.

### Executable summary

`src/agent/skills/ops/cdd/SKILL.md` is the operational summary for agents.

### Supporting skills

Review, design, release, and post-release each own their detailed execution surface. CDD owns the order and the closure logic.

---

## 9. Non-claims

CDD does not claim:

- that every project needs this much structure
- that speed is unimportant
- that all judgment can be replaced by automation
- that feature output is irrelevant

It claims something narrower:

For cnos, coherence must be made explicit, measured, and closed in a loop. Otherwise drift wins.
