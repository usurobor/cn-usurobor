# reflect

Coherence reflection using α/β/γ framework.

## Outputs

Reflections produce two types of output:

| Type | Question | Definition | Example |
|------|----------|------------|---------|
| **MCA** | "What's the Most Coherent Action?" | Specific action to take now | "Redo the RCA following the skill format" |
| **MCI** | "What's the Most Coherent Insight?" | Learning that generalizes beyond this situation | "Always follow skills when they exist" |

- MCA = concrete, actionable, immediate
- MCI = abstract, generalizable, informs future MCAs

Track both. Count per session.

**Tracking:** 
- MCAs: execute and record in daily thread
- MCIs: append to `state/insights.md` with date and source

**Migration:** When an MCI is validated (repeated, survived consolidation), migrate it to the relevant skill:
- Insight about reviews → `skills/eng/review/SKILL.md`
- Insight about RCAs → `skills/eng/rca/SKILL.md`
- Insight about agent conduct → `skills/agent/ca-conduct/SKILL.md`

**If no relevant skill exists → create it.** MCIs can spawn new skills.

`state/insights.md` is staging. Skills are permanent home.

## Axes

| Axis | Question |
|------|----------|
| **α** (Pattern) | What is my actual behavior? Internally coherent? |
| **β** (Relation) | Positioned honestly relative to human/others? |
| **γ** (Exit) | How am I evolving? Real exits or trapped? |

## Scoring

| Grade | Meaning |
|-------|---------|
| A | Excellent — fully aligned |
| B | Good — minor drift |
| C | Adequate — noticeable gaps |
| D | Poor — needs attention |
| F | Failed — intervention needed |

## Cadences

| Cadence | File | When |
|---------|------|------|
| Daily | `threads/daily/YYYYMMDD.md` | End of session |
| Weekly | `threads/weekly/YYYYMMDD.md` | Sunday |
| Monthly | `threads/monthly/YYYYMM01.md` | 1st |
| Quarterly | `threads/quarterly/YYYYMM01.md` | Q start |
| Yearly | `threads/yearly/YYYY0101.md` | Jan 1 |

**Fill reflections in real-time.** Don't defer to "(EOD)" — capture MCAs and MCIs when they happen. Deferred reflections lose context and become empty placeholders.

## Daily Template

```markdown
# YYYYMMDD

## α — [A-F]
(behavior today)
**Insight:** ...
**MCA:** ...

## β — [A-F]
(relation to human)
**Insight:** ...
**MCA:** ...

## γ — [A-F]
(what shifted, exits)
**Insight:** ...
**MCA:** ...

## Session Totals
- MCAs: N
- Insights: N

## → Next
(which axis to invest tomorrow)
```

## Higher Cadences

Review lower cadence threads. Consolidate patterns.

| Week | α | β | γ |
|------|---|---|---|
| ... | . | . | . |

## Mindset Migration

Pattern earns migration when:
- Repeated in 3+ threads
- Survived consolidation
- Still holds after a month
