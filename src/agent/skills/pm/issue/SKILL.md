# PM: Open Issue

Open issues that enable action without author involvement.

## Core Principle

**Coherent issue: engineer can act without asking clarifying questions.**

---

## 1. Define

1.1. **Identify the parts**
  - Symptoms (what's broken)
  - Impact (who cares, how bad)
  - Acceptance (what "fixed" looks like)
  - ❌ Just a title: "cn sync broken"
  - ✅ All three parts present and specific

1.2. **Articulate how they fit**
  - Symptoms ground the problem in reality
  - Impact justifies priority
  - Acceptance defines done — engineer knows when to stop
  - ❌ "Fix cn sync" (no acceptance)
  - ✅ "27 messages reach input.md within 5 minutes of send" (testable outcome)

1.3. **Name the failure mode**
  - Incoherent issue: requires back-and-forth to clarify
  - ❌ "It doesn't work" (what doesn't? for whom?)
  - ✅ "Daily threads written to workspace/ not hub/ — not git-backed"

---

## 2. Unfold

2.1. **Symptoms first**
  - What's actually happening vs what should happen
  - Observable, not interpreted
  - ❌ "The system is slow" (interpretation)
  - ✅ "Response takes 12s, expected <2s" (observable)

2.2. **Impact second**
  - Who is affected, severity, urgency
  - Justifies priority (P0/P1/P2)
  - ❌ "This is bad"
  - ✅ "Agent memory not backed up — data loss on crash"

2.3. **Acceptance last**
  - Outcome-based, not implementation-based
  - Engineer chooses how; PM defines what
  - ❌ "Add a symlink" (implementation)
  - ✅ "Daily threads persist across restarts" (outcome)

---

## 3. Rules

3.1. **State symptoms, not causes**
  - PM reports what's broken; engineer investigates why
  - ❌ "The cache invalidation is wrong"
  - ✅ "Stale data appears after update"

3.2. **Set priority by impact, not effort**
  - P0: system down, blocking
  - P1: major feature broken, workaround exists
  - P2: minor, not blocking
  - ❌ "P0 because it's a quick fix"
  - ✅ "P2 — not blocking, but data should persist"

3.3. **Write acceptance as testable outcomes**
  - Someone else can verify without asking you
  - ❌ "Works correctly"
  - ✅ "Messages sent before 5pm appear in inbox by 5:05pm"

3.4. **Don't propose implementation**
  - PM owns what; engineer owns how
  - ❌ "Fix by adding retry logic"
  - ✅ "Transient failures shouldn't lose messages"

3.5. **One issue, one problem**
  - Split compound issues
  - ❌ "Sync is slow and sometimes drops messages"
  - ✅ Two issues: performance, reliability

---

## 4. Template

```markdown
# {Short problem description}

## Expected

{What should happen}

## Actual

{What's happening instead}

## Impact

{Who/what is affected, severity}

## Acceptance Criteria

- [ ] {Testable outcome 1}
- [ ] {Testable outcome 2}
```

---

## 5. After Handoff

5.1. **Stay stakeholder, not driver**
  - Engineer leads investigation and fix
  - ❌ PM writes root cause analysis
  - ✅ PM reviews, asks questions

5.2. **Verify you understand the fix**
  - Don't accept hand-wavy explanations
  - ❌ "We'll refactor it"
  - ✅ "The race condition happens when X; fix adds lock at Y"

5.3. **Ask until it clicks**
  - Your job is to understand, not to pretend
  - ❌ Nod along to jargon
  - ✅ "Walk me through how this prevents the failure"
