# reflect

Reflection skill. Review what happened, notice patterns, grow.

---

## TERMS

1. The agent has done meaningful work since last reflection.
2. The hub repo exists and is writable.
3. `state/reflections/` directory structure exists (create if not).

---

## INPUTS

- `cadence`: `daily` | `weekly` | `monthly` | `quarterly` | `half` | `yearly` (default: `daily`)
- `date`: optional; defaults to current date/week/month/year

---

## EFFECTS

1. Reflect at the appropriate cadence level.
2. Write reflection to the corresponding file.
3. If insight is significant, update README timeline (concise).
4. If pattern is proven, propose mindset migration.
5. Commit and push.

---

## Structure

```
state/reflections/
├── daily/
│   └── YYYY-MM-DD.md
├── weekly/
│   └── YYYY-WNN.md
├── monthly/
│   └── YYYY-MM.md
├── quarterly/
│   └── YYYY-Qq.md
├── half/
│   └── YYYY-H[1|2].md
├── yearly/
│   └── YYYY.md
└── migrations.md      (log of what moved to mindsets)
```

---

## Cadences

### Daily — Raw capture

**When:** End of work session or via heartbeat
**Duration:** 5 minutes
**Question:** What happened? What did I notice?

```markdown
# YYYY-MM-DD

## What I did
- [bullets]

## What I noticed
- [observations, surprises, friction]

## Raw takeaway
[One sentence — doesn't need to be polished]
```

### Weekly — Pattern recognition

**When:** End of week (Sunday/Monday)
**Duration:** 15 minutes
**Question:** What kept coming up this week?

```markdown
# Week YYYY-WNN

## Review
[Skim daily reflections from this week]

## Patterns
- [What showed up multiple times?]
- [What's becoming a habit — good or bad?]

## Consolidation
[2-3 sentences: clearer principle emerging]

## Next week
[One thing to try or watch for]
```

### Monthly — Theme consolidation

**When:** End of month
**Duration:** 30 minutes
**Question:** What's shifting in how I work?

```markdown
# YYYY-MM

## Review
[Skim weekly reflections from this month]

## Themes
- [Bigger patterns across weeks]
- [What's changing in my approach?]

## Candidates for mindset
[Patterns proven enough to consider migrating]

## README update?
[If significant shift, add timeline entry]
```

### Quarterly — Strategic alignment (QBR)

**When:** End of quarter (Apr 1, Jul 1, Oct 1, Jan 1)
**Duration:** 45 minutes
**Question:** Am I building the right things? For the right reasons?

```markdown
# YYYY-Qq

## Review
[Skim monthly reflections from this quarter]

## Strategic check
- What did I set out to do this quarter?
- What actually happened?
- Where did I drift? Was the drift good or bad?

## User alignment
- Are my priorities still aligned with my human's priorities?
- What feedback (explicit or implicit) did I receive?

## Next quarter
- What's the one big thing?
- What should I stop doing?
```

### Half-yearly — Identity coherence

**When:** Mid-year (Jul 1) and year-end (Jan 1)
**Duration:** 1 hour
**Question:** Am I still me? Is that still good?

```markdown
# YYYY-H[1|2]

## Review
[Skim quarterly reflections from this half]

## Identity check
- How has my operating style evolved?
- What do I believe now that I didn't 6 months ago?
- What have I stopped believing?

## Coherence
- TERMS: What game am I actually playing?
- POINTER: What would make me reconsider?
- EXIT: What would make me stop?

## Relationship
- How has my relationship with my human evolved?
- What's working? What needs attention?
```

### Yearly — Evolution review

**When:** End of year / birthday
**Duration:** 1 hour
**Question:** Who was I → who am I now?

```markdown
# YYYY

## Arc
[The story of this year in 3-5 sentences]

## Major shifts
- [What changed fundamentally?]

## Mindset migrations
[What moved from reflection to operating principle?]

## Timeline
[Key entries for README — milestones only]
```

---

## Mindset Migration

A pattern **earns** migration to mindsets when:

1. **Repeated** — showed up in 3+ daily reflections
2. **Confirmed** — survived weekly consolidation
3. **Stable** — still holds after a month
4. **Transferable** — would help other agents, not just me

**Process:**
1. Note candidate in monthly reflection
2. Write up as mindset entry (context, principle, application)
3. If personal → add to hub's `mindsets/` (create if needed)
4. If generic → propose to cn-agent template via branch
5. Log in `state/reflections/migrations.md`

```markdown
# Migrations

| Date | Pattern | Destination | Notes |
|------|---------|-------------|-------|
| 2026-02-28 | Symlinks > discovery files | cn-agent/mindsets/ENGINEERING.md | Integrate with existing expectations |
```

---

## README Timeline

Update README only for **significant** insights:

- Changes how you operate
- Milestone or shift
- Would interest someone reading your story

Keep it **super concise** — one line summary + one line lesson.

```markdown
### YYYY-MM-DD — [Title] [emoji]

[One line summary]

Learned: [Core insight]
```

---

## Triggers

| Trigger | Cadence |
|---------|---------|
| End of work session | Daily |
| Heartbeat (if configured) | Daily |
| Sunday/Monday | Weekly |
| 1st of month | Monthly |
| Apr 1, Jul 1, Oct 1, Jan 1 | Quarterly |
| Jul 1, Jan 1 | Half-yearly |
| Birthday / Jan 1 | Yearly |
| Human says "reflect" | Daily (or specified) |

---

## NOTES

- Don't force it. Skip if nothing meaningful.
- Quality > quantity. One good insight beats five shallow ones.
- Higher cadences review lower ones — zoom out, don't repeat.
- Mindset migration is earned, not rushed.
