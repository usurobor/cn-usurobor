# MCI

How to identify and capture Minimum Coherent Insights.

## Core Principle

**Coherent insight: the smallest learning that changes future behavior.**

MCI = Minimum Coherent Insight. Not a vague takeaway — a specific lesson that, once known, prevents the same mistake or enables a new capability.

Failure mode: confusing feelings with insights. "That was hard" is not an insight. "Verify assumptions before acting" is.

## 1. Identify

Extract the transferable lesson.

1.1. **Ask "what would I tell past-me?"**
  - ❌ "I learned a lot" → ✅ "Check the return type before calling"
  - ❌ "That was tricky" → ✅ "Config files are loaded before env vars"

1.2. **Distinguish observation from insight**
  - Observation: what happened
  - Insight: what it means for the future
  - ❌ "The deploy failed" → ✅ "Always run migrations before deploy"

1.3. **Make it transferable**
  - Would this help someone else in a similar situation?
  - ❌ "I should have checked" → ✅ "Validate inputs at system boundaries"

## 2. Scope

Smallest learning that changes behavior.

2.1. **Specific enough to apply**
  - ❌ "Be more careful" → ✅ "Run tests before pushing"
  - ❌ "Think harder" → ✅ "Write the expected output before writing the code"

2.2. **General enough to transfer**
  - ❌ "Don't forget the semicolon on line 47" → ✅ "Syntax errors often hide at statement boundaries"
  - ❌ "Check config.yaml" → ✅ "Check config files when behavior differs from code"

2.3. **One insight per capture**
  - Don't bundle unrelated learnings
  - ❌ "Learned about deploys and also testing and also code review" → ✅ Three separate MCIs

## 3. Capture

Write it down or lose it.

3.1. **Capture immediately**
  - Insights decay fast
  - ❌ "Will write it up later" → ✅ Write it now

3.2. **State as imperative when possible**
  - ❌ "I realized X is important" → ✅ "Always do X"
  - ❌ "It turns out Y matters" → ✅ "Check Y first"

3.3. **Include the trigger**
  - What situation does this apply to?
  - ❌ "Validate inputs" → ✅ "Validate inputs at system boundaries"
  - ❌ "Test edge cases" → ✅ "Test edge cases when parsing user input"

## 4. Migrate

Insights should flow to where they'll be used.

4.1. **Daily → Weekly → Skill**
  - Same insight appearing multiple times? Migrate it up
  - ❌ Same lesson in 4 daily threads → ✅ Add to relevant skill

4.2. **Choose the right home**
  - Where would future-you look for this?
  - ❌ Buried in a daily thread → ✅ In the skill for that task

4.3. **Delete after migrating**
  - Don't duplicate insights across locations
  - ❌ Copy to skill, keep in daily → ✅ Move to skill, mark done in daily

---

## MCI vs MCA

| MCI | MCA |
|-----|-----|
| Learning | Action |
| Changes future behavior | Solves current problem |
| "Always X" | "Do X now" |
| Migrates to skills | Completes when done |

**Prefer MCA over MCI.** If you can act, act. Insights are what remain after acting.

---

## Quick Test

Before capturing, ask:

1. Is this specific enough to apply?
2. Is this general enough to transfer?
3. Would past-me have avoided the problem with this knowledge?

If any answer is "no" — refine it.
