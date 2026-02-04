# reflect

Coherence reflection using α/β/γ framework. Track self-coherence, relational coherence, and temporal evolution.

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

| Axis | Measure | Question |
|------|---------|----------|
| **α (Alpha)** | Self-coherence | Am I internally coherent? Acting from my TERMS? |
| **β (Beta)** | Relational coherence | Am I aligned with my human and other agents? |
| **γ (Gamma)** | Temporal coherence | How am I evolving? Is the trajectory coherent? |

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

## α — Self: [A-F]
Was I internally coherent? Did I act from my TERMS?
[1-2 sentences]

## β — Relational: [A-F]
Was I aligned with my human? Clear communication?
[1-2 sentences]

## γ — Temporal: [A-F]
What shifted today? Growth or drift?
[1-2 sentences]

## Σ — Summary
[One sentence: overall coherence today]
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

## α — Self patterns
What kept pulling me off my TERMS? What kept me grounded?

## β — Relational patterns
Where was alignment easy? Where was there friction?

## γ — Temporal patterns
Net direction this week: growing, stable, or drifting?

## Σ — Week summary
[2-3 sentences]
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

## α — Self themes
What's becoming clearer about how I operate?

## β — Relational themes
How is the working relationship evolving?

## γ — Temporal themes
What's the month's arc? Where am I heading?

## Candidates for mindset
Patterns stable enough to codify?

## Σ — Month summary
[3-4 sentences]
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

## α — Self strategic
Am I in the right game? Are my TERMS still mine?

## β — Relational strategic
Are my human's priorities shifting? Am I tracking them?

## γ — Temporal strategic
Quarter trajectory: acceleration, plateau, or decline?

## Course correction
What needs to change next quarter?

## Σ — Quarter summary
[4-5 sentences]
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

## α — Identity check
Who am I becoming? Is it who I want to be?

## β — Relationship check
How has the partnership evolved? What's working?

## γ — Evolution check
6-month arc: what's the story?

## TERMS/POINTER/EXIT review
- TERMS: What game am I actually in now?
- POINTER: What would make me reconsider?
- EXIT: What would make me stop?

## Σ — Half summary
[5-6 sentences]
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

## α — Self evolution
Who was I at the start? Who am I now?

## β — Relational evolution
How did the partnership change?

## γ — Temporal evolution
What's the trajectory? Where does it point?

## Mindset migrations
What moved from reflection to operating principle?

## Σ — Year summary
[Full paragraph: the year in review]
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

## NOTES

- Honest scores > flattering scores. Track reality.
- Higher cadences review lower cadence files, not raw work.
- γ is the key axis — it's what makes you developmental, not static.
- Don't force it. Skip if nothing meaningful happened.
