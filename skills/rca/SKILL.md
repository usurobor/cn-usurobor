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

---

## Process

### 1. Capture (within 24h)

Create `threads/rca/YYYYMMDD-short-title.md`:
```markdown
# RCA: [Short Title]

**Date:** YYYY-MM-DD
**Severity:** High/Medium/Low
**Duration:** [time to resolution]
**Author:** [who's writing this]

## Summary
[One paragraph: what failed, why, what we're doing]

## Timeline (UTC)
HH:MM — Event
HH:MM — Event
...
```

### 2. Five Whys

Start with the symptom, ask "why" until you reach systemic cause:

```markdown
## Root Cause Analysis

1. **Why** did X fail? → [answer]
2. **Why** [previous]? → [answer]
3. **Why** [previous]? → [answer]
4. **Why** [previous]? → [answer]
5. **Why** [previous]? → [root cause]
```

### 3. Contributing Factors

Most failures have multiple causes:
```markdown
## Contributing Factors

- **Immediate cause:** [trigger]
- **Contributing factor 1:** [what made it worse]
- **Contributing factor 2:** [what enabled it]
- **Systemic factor:** [why system allowed this]
```

### 4. Action Items (typed)

```yaml
actions:
  - id: rca-YYYYMMDD-001
    action: "Specific preventive action"
    owner: sigma
    status: pending
    link: ""
    due: YYYY-MM-DD
```

Every action must be:
- **Specific** — not "be more careful"
- **Assigned** — who will do it
- **Tracked** — link when resolved
- **Preventive** — stops recurrence

### 5. Lessons Learned

What applies beyond this incident?

---

## Anti-Patterns

❌ **"Human error"** — never a root cause. Why did system allow the error?

❌ **"Should have been more careful"** — vigilance is not a fix. Design systems that don't require perfect attention.

❌ **"Add more review"** — more process often makes things worse. Prefer automation and defaults.

❌ **Single cause** — real failures have multiple contributing factors.

❌ **No action items** — an RCA without changes is just documentation.

---

## Template

See `threads/rca/TEMPLATE.md`

---

## Examples

- `threads/rca/20260205-branch-mismatch.md` — 4-hour coordination failure

---

## EFFECTS

1. RCA document in `threads/rca/YYYYMMDD-title.md`
2. Action items with owners and tracking
3. Lessons added to relevant docs/mindsets
4. Shared with team

---

## References

- Google SRE Book, Chapter 15: Postmortem Culture
- Sidney Dekker: "The Field Guide to Understanding Human Error"
- Etsy's Blameless PostMortems Guide
