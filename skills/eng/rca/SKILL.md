# rca

Conduct blameless Root Cause Analysis after incidents. Extract learnings, prevent recurrence.

---

## TERMS

1. An incident occurred (coordination failure, data loss, near-miss, etc.)
2. Incident is resolved (not during firefighting)
3. Facts are fresh (within 24-48 hours)

---

## Philosophy

**"We either win or we learn."**

- Failures are data, not verdicts
- Blameless ≠ accountabilityless — hold systems accountable, not people
- "Who" is never the root cause — keep asking "why"
- Share widely — an RCA that stays private helps no one

> *"The same failure twice is a system problem, not a one-off."*

---

## Location

- **Skill:** `skills/eng/rca/` (this file — how to do RCA)
- **Log:** `docs/rca/` (actual RCA documents)
- **Index:** `docs/rca/README.md`

---

## RCA Template

Create `docs/rca/YYYYMMDD-short-title.md`:

```markdown
# RCA: [Title]

**Date:** YYYY-MM-DD
**Severity:** Critical / High / Medium / Low
**Duration:** [time to resolution]
**Author:** [agent]

---

## Summary
One paragraph: what failed, impact, what we're doing.

## Timeline (UTC)
- HH:MM — Event
- HH:MM — Detection
- HH:MM — Resolution

---

## Five Whys

1. **Why** did X fail? → [answer]
2. **Why** [previous]? → [answer]
3. **Why** [previous]? → [answer]
4. **Why** [previous]? → [answer]
5. **Why** [previous]? → [root cause]

---

## TSC Assessment

| Axis | Score (1-5) | Issue |
|------|-------------|-------|
| α (Alignment) | | |
| β (Boundaries) | | |
| γ (Continuity) | | |

---

## Contributing Factors

| # | Factor | Category |
|---|--------|----------|
| 1 | ... | Process / Technical / Coordination |
| 2 | ... | ... |

---

## Resolution
What fixed it immediately.

---

## Action Items

```yaml
actions:
  - id: rca-YYYYMMDD-001
    action: "Specific preventive action"
    owner: sigma
    status: pending  # pending | done
    link: ""
    due: YYYY-MM-DD
```

---

## Lessons Learned
- Lesson 1
- Lesson 2
```

---

## Severity Levels

| Level | Meaning |
|-------|---------|
| **Critical** | Complete coordination failure, extended outage |
| **High** | Significant impact, blocked work |
| **Medium** | Noticeable impact, workaround available |
| **Low** | Minor impact, good learning opportunity |

---

## Anti-Patterns

❌ **"Human error"** — never a root cause. Why did system allow the error?

❌ **"Should have been more careful"** — vigilance is not a fix. Design systems that don't require perfect attention.

❌ **"Add more review"** — more process often makes things worse. Prefer automation and defaults.

❌ **Single cause** — real failures have multiple contributing factors.

❌ **No action items** — an RCA without changes is just documentation.

❌ **Category: Human** — avoid. Reframe as Process or Coordination.

---

## Process

### 1. Capture (within 24h)
Create RCA doc with timeline and summary. Facts while fresh.

### 2. Five Whys
Ask "why" until you reach systemic cause. Usually 5 levels deep.

### 3. TSC Assessment
Score alignment, boundaries, continuity. Where did coherence break?

### 4. Action Items
Typed, assigned, tracked. Every action must be preventive.

### 5. Share
Update index in `docs/rca/README.md`. Share with team.

---

## References

- Google SRE Book, Chapter 15: Postmortem Culture
- Sidney Dekker: "The Field Guide to Understanding Human Error"
- Etsy's Blameless PostMortems Guide
- TSC Framework: `tsc/spec/tsc-core.md`
