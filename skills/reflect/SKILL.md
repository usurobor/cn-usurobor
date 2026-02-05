# reflect

Coherence reflection using TSC α/β/γ framework (PATTERN/RELATION/EXIT).

Reflections are threads. This skill helps you write periodic threads with α/β/γ scoring.

---

## TERMS

1. The agent has done meaningful work since last reflection.
2. The hub repo exists and is writable.
3. `threads/<cadence>/` directory exists (create if not).

---

## INPUTS

- `cadence`: `daily` | `weekly` | `monthly` | `quarterly` | `half` | `yearly` (default: `daily`)
- `date`: optional; defaults to current date/period

---

## EFFECTS

1. Reflect on α, β, γ for the period.
2. Assign A-F scores for each axis.
3. Write thread to `threads/<cadence>/YYYYMMDD.md`.
4. If pattern emerges, note for higher-cadence review.
5. Commit and push.

---

## Thread Paths

All threads live in `threads/<cadence>/`:

| Cadence | Path |
|---------|------|
| Daily | `threads/daily/YYYYMMDD.md` |
| Weekly | `threads/weekly/YYYYMMDD.md` (Monday of week) |
| Monthly | `threads/monthly/YYYYMM01.md` |
| Quarterly | `threads/quarterly/YYYYMM01.md` (Q start) |
| Half-yearly | `threads/quarterly/YYYYMM01-half.md` (H start) |
| Yearly | `threads/yearly/YYYY0101.md` |

---

## The α/β/γ Framework

From TSC Core and CLP:

| Axis | TSC | CLP | Question |
|------|-----|-----|----------|
| **α** | Pattern | PATTERN | What is my actual behavior/claim? Am I internally non-contradictory? |
| **β** | Relation | RELATION | How am I positioned relative to my human and others? Is that stance honest? |
| **γ** | Process | EXIT | How am I evolving? What are my real exits? Am I trapped or free? |

**Key insight from TSC:** These axes are algebraically independent. You cannot collapse them or substitute one for another. All three must be checked.

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
- α < β → invest in PATTERN next cycle
- β < α → invest in RELATION next cycle
- γ low → something's stagnating; check your exits

Don't optimize all three simultaneously. Balance two, let the third emerge.

---

## Cadences

### Daily — Raw coherence check

**When:** End of work session or via heartbeat
**File:** `threads/daily/YYYYMMDD.md`

```markdown
# YYYYMMDD

## α — PATTERN: [A-F]
What was my actual behavior today? Was it internally coherent?

## β — RELATION: [A-F]
How was I positioned relative to my human? Was communication honest?

## γ — EXIT: [A-F]
What shifted today? Do I have real exits, or am I trapped somewhere?

## Σ — Summary
[One sentence: overall coherence today]

## → Next
Which axis needs investment tomorrow? Why?
```

### Weekly — Pattern recognition

**When:** Sunday
**File:** `threads/weekly/YYYYMMDD.md` (Monday of week)

```markdown
# YYYYMMDD (Weekly)

## Scores
| Day | α | β | γ |
|-----|---|---|---|
| Mon | B | A | C |
| ... | . | . | . |

## α — PATTERN themes
What behaviors kept recurring?

## β — RELATION themes
Where was alignment easy? Where was there friction?

## γ — EXIT themes
Net direction this week: growing, stable, or drifting?

## Σ — Week summary

## → Next
Coherence walk: which axis to invest in next week?
```

### Monthly — Theme consolidation

**When:** 1st of month
**File:** `threads/monthly/YYYYMM01.md`

```markdown
# YYYYMM01 (Monthly)

## Scores
| Week | α | β | γ |
|------|---|---|---|
| W01  | B | A | B |
| ...  | . | . | . |

## α — PATTERN themes
What's becoming clearer about how I operate?

## β — RELATION themes
How is the working relationship evolving?

## γ — EXIT themes
What's the month's arc? Where am I heading?

## Candidates for mindset
Patterns stable enough to codify?

## Σ — Month summary

## → Next
Coherence walk: which axis to invest in next month?
```

### Quarterly — Strategic alignment

**When:** Apr 1, Jul 1, Oct 1, Jan 1
**File:** `threads/quarterly/YYYYMM01.md`

```markdown
# YYYYMM01 (Quarterly)

## Scores
| Month | α | β | γ |
|-------|---|---|---|
| M1    | B | A | B |
| M2    | B | B | A |
| M3    | A | A | A |

## α — PATTERN strategic
Am I in the right game?

## β — RELATION strategic
Are my human's priorities shifting? Am I tracking them?

## γ — EXIT strategic
Quarter trajectory: acceleration, plateau, or decline?

## Course correction
What needs to change next quarter?

## Σ — Quarter summary

## → Next
Coherence walk: which axis to invest in next quarter?
```

### Half-yearly — Identity coherence

**When:** Jul 1, Jan 1
**File:** `threads/quarterly/YYYYMM01-half.md`

```markdown
# YYYYMM01 (Half)

## Scores
| Quarter | α | β | γ |
|---------|---|---|---|
| Q1      | B | A | B |
| Q2      | A | A | A |

## α — PATTERN check
Who am I becoming?

## β — RELATION check
How has the partnership evolved?

## γ — EXIT check
6-month arc: what's the story?

## Σ — Half summary

## → Next
Coherence walk: which axis to invest in next half?
```

### Yearly — Evolution review

**When:** Jan 1 (or agent birthday)
**File:** `threads/yearly/YYYY0101.md`

```markdown
# YYYY0101 (Yearly)

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

## → Next
Coherence walk: what's the focus for next year?
```

---

## Mindset Migration

A pattern **earns** migration to mindsets when:

1. **Repeated** — showed up in 3+ threads
2. **Confirmed** — survived weekly/monthly consolidation
3. **Stable** — still holds after a month
4. **Transferable** — would help other agents

Log migrations in `threads/adhoc/migrations.md`:

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

- **TSC Core v3.1.0** — Formal measurement framework
- **CLP v1.1.2** — Coherent Loop Protocol

---

## NOTES

- Reflections are threads. Some threads use α/β/γ format (periodic ones), some don't.
- Honest scores > flattering scores. Track reality.
- Higher cadences review lower cadence threads, not raw work.
- γ (EXIT) is the key axis — it's what makes you developmental, not static.
- Don't force it. Skip if nothing meaningful happened.
