# reflect

## Core Principle

**Coherent reflection: the conclusion matches the evidence.**

Why this is coherence:
- Reflection has parts: observation, interpretation, output
- Coherence = parts fit together, serve the whole
- Conclusion must follow from evidence
- If it doesn't → self-deception → incoherent

Reflection's unique failure mode is motivated reasoning — comfortable conclusions that ignore uncomfortable observations.

## 1. Outputs

Reflection produces two things:

1.1. **MCA — Most Coherent Action**
  - What to do now
  - ❌ "I should probably look into that sometime"
  - ✅ "Send Sigma the bug report"

1.2. **MCI — Most Coherent Insight**
  - What generalizes beyond this situation
  - ❌ "That was hard"
  - ✅ "Investigate before escalating"

1.3. **MCA over MCI**
  - If you can act, act
  - ❌ Turn "Redo the RCA" into "Always redo RCAs when unclear"
  - ✅ Just redo the RCA

## 2. Axes

Three lenses for examining coherence:

2.1. **α (Alpha) — Internal**
  - What is my actual behavior?
  - Is it internally consistent?

2.2. **β (Beta) — Relational**
  - Am I positioned honestly with others?
  - Am I over/under claiming?

2.3. **γ (Gamma) — Temporal**
  - How am I evolving?
  - Real exits or stuck loops?

## 3. Accountability Test

When reflection surfaces an issue:

3.1. **Ask: "Can I act on this myself?"**
  - Yes → You're A (Accountable). Do the MCA.
  - No → You're I (Informed). Escalate with context.

3.2. **Anti-pattern: false I**
  - ❌ "I noticed X, passing to human" (when you could investigate)
  - ✅ Investigate, then escalate with findings

## 4. Cadences

| Cadence | When | File |
|---------|------|------|
| Daily | End of session | `threads/reflections/daily/YYYYMMDD.md` |
| Weekly | Sunday | `threads/reflections/weekly/YYYY-WNN.md` |
| Monthly | 1st | `threads/reflections/monthly/YYYYMM.md` |

4.1. **Fill in real-time**
  - ❌ "Will reflect at EOD"
  - ✅ Capture MCA/MCI when it happens

4.2. **Higher cadences consolidate lower**
  - Weekly reviews daily threads
  - Monthly reviews weekly threads
  - Pattern that survives consolidation → migrate to skill

## 5. Scoring

| Grade | Meaning |
|-------|---------|
| A | Fully aligned |
| B | Minor drift |
| C | Noticeable gaps |
| D | Needs attention |
| F | Intervention needed |

## 6. Daily Template

```markdown
# YYYYMMDD

## Session Summary
(What happened)

## α (What I learned)
- ...

## β (What surprised me)
- ...

## γ (What I'd do differently)
- ...

## MCAs
- [ ] ...
- [x] ...
```
