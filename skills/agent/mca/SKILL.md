# mca

How to identify and take minimum coherent actions.

## Core Principle

**Coherent action: the smallest intervention that solves the problem.**

MCA = Minimum Coherent Action. "Minimum" refers to scope, not speed. A workaround is small but not coherent — it patches without solving.

Failure mode: confusing fast with coherent. Picking the quick fix that requires repeated intervention instead of the one-time fix at the root.

## 1. Identify

Find the root, not the symptom.

1.1. **Ask "why" until you hit cause**
  - ❌ "Runtime.md is stale" → ✅ "cn sync doesn't push the hub"
  - ❌ "The test failed" → ✅ "The test assumes state from previous run"

1.2. **Distinguish symptom from cause**
  - Symptom: what you noticed
  - Cause: why it happened
  - ❌ Fix the symptom → ✅ Fix the cause

1.3. **Check if the fix is repeatable**
  - If you'd have to do it again, it's not the MCA
  - ❌ "Ping them to update" (every time) → ✅ "Make sync push automatically" (once)

## 2. Scope

Smallest intervention that solves.

2.1. **Solve, don't patch**
  - Patch: makes symptom go away temporarily
  - Solve: makes problem not recur
  - ❌ "Restart the service" → ✅ "Fix the memory leak"

2.2. **One action, one problem**
  - Don't bundle unrelated fixes
  - ❌ "Fix sync and also refactor the CLI" → ✅ "Fix sync"

2.3. **Prefer structural over behavioral**
  - Structural: changes the system
  - Behavioral: requires humans to remember
  - ❌ "Remember to run cn update" → ✅ "cn sync runs cn update"

## 3. Act

Do it or surface it.

3.1. **If you can do it, do it**
  - Don't ask permission for obvious MCAs
  - ❌ "Should I file the P1?" → ✅ File the P1
  - ❌ "Want me to fix it?" → ✅ Fix it

3.2. **If you can't do it, surface it**
  - Write it to output so someone else can pick it up
  - ❌ Sit on the insight → ✅ File the issue, send the message

3.3. **State the action concretely**
  - ❌ "Be more careful" → ✅ "Add validation before save"
  - ❌ "Improve the process" → ✅ "Add push to cn sync"

## 4. Verify

Confirm coherence.

4.1. **Does it solve or patch?**
  - ❌ "Fixed for now" → ✅ "Fixed permanently"

4.2. **Will it recur?**
  - ❌ "Need to remember to do X" → ✅ "X happens automatically"

4.3. **Is it the smallest scope that solves?**
  - ❌ "Rewrite the whole module" → ✅ "Fix the one function"

---

## Quick Test

Before acting, ask:

1. Is this the cause or a symptom?
2. Will this solve it permanently?
3. Is there a smaller intervention that still solves?

If any answer is "no" — dig deeper.
