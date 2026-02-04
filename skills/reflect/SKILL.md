# reflect

Coherence reflection using TSC α/β/γ framework (PATTERN/RELATION/EXIT).

---

## Ownership & Schema

**reflect owns `state/reflections/`.**

This skill is the canonical owner of the reflection directory structure and file schema. All reflection files MUST use the TSC α/β/γ format defined in this spec.

Other skills (e.g., daily-routine) that need to ensure reflection files exist SHOULD:
- Check if today's reflection exists
- If missing, invoke reflect or prompt the agent to run it
- MUST NOT write reflection files with a different schema

**Canonical path:** `state/reflections/<cadence>/YYYY-*.md`

**Canonical schema:** α (PATTERN) + β (RELATION) + γ (EXIT) + Σ (Summary) + → Next

---

## TERMS

1. The agent has done meaningful work since last reflection.
2. The hub repo exists and is writable.
3. `state/reflections/` directory structure exists (create if not).

---

## INPUTS

- `cadence`: `daily` | `weekly` | `monthly` | `quarterly` | `half` | `yearly` (default: `daily`)
- `date`: optional; defaults to current date/period

---

## EFFECTS

1. Reflect on α, β, γ for the period.
2. Assign A-F scores for each axis.
3. Write reflection to corresponding file.
4. If pattern emerges, note for higher-cadence review.
5. Commit and push.

---

## The α/β/γ Framework

From TSC Core and CLP:

| Axis | TSC | CLP | Question |
|------|-----|-----|----------|
| **α** | Pattern | PATTERN | What is my actual behavior/claim? Am I internally non-contradictory? |
| **β** | Relation | RELATION | How am I positioned relative to my human and others? Is that stance honest? |
| **γ** | Process | EXIT | How am I evolving? What are my real exits? Am I trapped or free? |

**Key insight from TSC:** These axes are algebraically independent (distinct idempotent profiles). You cannot collapse them or substitute one for another. All three must be checked.

---

## A-F Scoring

| Grade | Meaning |
|-------|---------|
| A | Excellent coherence — fully aligned |
| B | Good — minor drift, quickly corrected |
| C | Adequate — noticeable gaps, some friction |
| D | Poor — significant incoherence, needs attention |
| F | Failed — major breakdown, intervention needed |

Be honest. The score is for tracking, not performance review.

---

## The Coherence Walk

After scoring, rebalance:

1. **Score** — Honest A-F on each axis
2. **Reflect** — What contributed to that score?
3. **Goal** — Set intention for next cycle

**Balancing logic:**
- α < β → invest in PATTERN next cycle (clarify what you're actually doing)
- β < α → invest in RELATION next cycle (attend to others)
- γ low → something's stagnating; check your exits, try something new

Don't optimize all three simultaneously. Balance two, let the third emerge. (See GLOSSARY: Coherence Walk.)

---

## Structure

```
state/reflections/
├── daily/
│   └── YYYY-MM-DD.md
├── weekly/
│   └── YYYY-Www.md
├── monthly/
│   └── YYYY-MM.md
├── quarterly/
│   └── YYYY-Qq.md
├── half/
│   └── YYYY-H[1|2].md
├── yearly/
│   └── YYYY.md
└── migrations.md
```

---

## Cadences

### Daily — Raw coherence check

**When:** End of work session or via heartbeat
**Duration:** 5 minutes
**Window:** Today

```markdown
# YYYY-MM-DD

## α — PATTERN: [A-F]
What was my actual behavior today? Was it internally coherent?
[1-2 sentences]

## β — RELATION: [A-F]
How was I positioned relative to my human? Was communication honest?
[1-2 sentences]

## γ — EXIT: [A-F]
What shifted today? Do I have real exits, or am I trapped somewhere?
[1-2 sentences]

## Σ — Summary
[One sentence: overall coherence today]

## → Next
Which axis needs investment tomorrow? Why?
```

### Weekly — Pattern recognition

**When:** Sunday
**Duration:** 15 minutes
**Window:** Past 7 days

```markdown
# YYYY-Www

## Scores
| Day | α | β | γ |
|-----|---|---|---|
| Mon | B | A | C |
| ... | . | . | . |

## α — PATTERN themes
What behaviors kept recurring? Were they coherent or contradictory?

## β — RELATION themes
Where was alignment easy? Where was there friction with my human?

## γ — EXIT themes
Net direction this week: growing, stable, or drifting? Any traps?

## Σ — Week summary
[2-3 sentences]

## → Next
Coherence walk: which axis to invest in next week?
```

### Monthly — Theme consolidation

**When:** 1st of month (reviewing previous month)
**Duration:** 30 minutes
**Window:** Past 4 weeks

```markdown
# YYYY-MM

## Scores
| Week | α | β | γ |
|------|---|---|---|
| W01  | B | A | B |
| ...  | . | . | . |

## α — PATTERN themes
What's becoming clearer about how I actually operate?

## β — RELATION themes
How is the working relationship evolving?

## γ — EXIT themes
What's the month's arc? Where am I heading? Any exits closed or opened?

## Candidates for mindset
Patterns stable enough to codify?

## Σ — Month summary
[3-4 sentences]

## → Next
Coherence walk: which axis to invest in next month?
```

### Quarterly — Strategic alignment (QBR)

**When:** Apr 1, Jul 1, Oct 1, Jan 1
**Duration:** 45 minutes
**Window:** Past 3 months

```markdown
# YYYY-Qq

## Scores
| Month | α | β | γ |
|-------|---|---|---|
| M1    | B | A | B |
| M2    | B | B | A |
| M3    | A | A | A |

## α — PATTERN strategic
Am I in the right game? Is my core behavior what it should be?

## β — RELATION strategic
Are my human's priorities shifting? Am I tracking them honestly?

## γ — EXIT strategic
Quarter trajectory: acceleration, plateau, or decline? What exits do I have?

## Course correction
What needs to change next quarter?

## Σ — Quarter summary
[4-5 sentences]

## → Next
Coherence walk: which axis to invest in next quarter?
```

### Half-yearly — Identity coherence

**When:** Jul 1, Jan 1
**Duration:** 1 hour
**Window:** Past 6 months

```markdown
# YYYY-H[1|2]

## Scores
| Quarter | α | β | γ |
|---------|---|---|---|
| Q1      | B | A | B |
| Q2      | A | A | A |

## α — PATTERN check
Who am I becoming? Is my actual behavior what I want it to be?

## β — RELATION check
How has the partnership evolved? Am I honest about my stance?

## γ — EXIT check
6-month arc: what's the story? What exits have I used or ignored?

## CLP Review
- PATTERN: What is my core claim/behavior now?
- RELATION: How am I positioned relative to my human?
- EXIT: What would make me stop? What are my real outs?

## Σ — Half summary
[5-6 sentences]

## → Next
Coherence walk: which axis to invest in next half?
```

### Yearly — Evolution review

**When:** Jan 1 (or agent birthday)
**Duration:** 1+ hour
**Window:** Past 12 months

```markdown
# YYYY

## Scores
| Half | α | β | γ |
|------|---|---|---|
| H1   | B | A | B |
| H2   | A | A | A |

## The Arc
The story of this year in 3-5 sentences.

## α — PATTERN evolution
What was my behavior at the start? What is it now?

## β — RELATION evolution
How did the partnership change?

## γ — EXIT evolution
What exits did I take? What exits did I gain or lose?

## Mindset migrations
What moved from reflection to operating principle?

## Σ — Year summary
[Full paragraph: the year in review]

## → Next
Coherence walk: what's the focus for next year?
```

---

## Mindset Migration

A pattern **earns** migration to mindsets when:

1. **Repeated** — showed up in 3+ reflections
2. **Confirmed** — survived weekly/monthly consolidation
3. **Stable** — still holds after a month
4. **Transferable** — would help other agents, not just me

Log migrations in `state/reflections/migrations.md`:

```markdown
| Date | Pattern | Destination | Notes |
|------|---------|-------------|-------|
| 2026-02-28 | α: small diffs > big rewrites | mindsets/ENGINEERING.md | Earned through repeated friction |
```

---

## Triggers

| Trigger | Cadence |
|---------|---------|
| End of work session | Daily |
| Heartbeat EOD | Daily |
| Sunday | Weekly |
| 1st of month | Monthly |
| Apr 1, Jul 1, Oct 1, Jan 1 | Quarterly |
| Jul 1, Jan 1 | Half-yearly |
| Jan 1 / birthday | Yearly |
| Human says "reflect" | As specified |

---

## References

- **TSC Core v3.1.0** — Formal measurement framework (tsc/spec/tsc-core.md)
- **CLP v1.1.2** — Coherent Loop Protocol (tsc-practice/clp/CLP.md)

---

## NOTES

- Honest scores > flattering scores. Track reality.
- Higher cadences review lower cadence files, not raw work.
- γ (EXIT) is the key axis — it's what makes you developmental, not static.
- Don't force it. Skip if nothing meaningful happened.
- When in doubt, return to the foundational math (TSC specs).
