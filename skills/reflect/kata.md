# Kata 02 – Complete your first daily reflection

TERMS:
- You have a cloned hub repository.
- You have done meaningful work today (or can recall recent work).
- `state/reflections/daily/` directory exists (create if not).

POINTER:
- This kata establishes the daily reflection habit using the TSC α/β/γ framework.

EXIT (success criteria):
- `state/reflections/daily/YYYY-MM-DD.md` exists with today's date.
- File contains: α (PATTERN), β (RELATION), γ (EXIT), Σ (Summary), → Next.
- File is committed and pushed to the hub.

## Steps

1. Create the reflections directory structure if it doesn't exist:

   ```bash
   mkdir -p state/reflections/daily state/reflections/weekly state/reflections/monthly state/reflections/quarterly state/reflections/half state/reflections/yearly
   ```

2. Create today's reflection file:

   ```bash
   touch state/reflections/daily/$(date +%Y-%m-%d).md
   ```

3. Open the file and add the TSC α/β/γ structure:

   ```markdown
   # YYYY-MM-DD

   ## α — PATTERN 🧩: [A-F]
   What was my actual behavior today? Was it internally coherent?
   [1-2 sentences]

   ## β — RELATION 🤝: [A-F]
   How was I positioned relative to my human? Was communication honest?
   [1-2 sentences]

   ## γ — EXIT 🚪: [A-F]
   What shifted today? Do I have real exits, or am I trapped somewhere?
   [1-2 sentences]

   ## Σ — Summary
   [One sentence: overall coherence today]

   ## → Next
   Which axis needs investment tomorrow? Why?
   ```

4. Fill in each section honestly:
   - **Score each axis A-F** (A=excellent, F=failed)
   - **Be specific** about what contributed to the score
   - **→ Next** should identify the Coherence Walk direction

5. Stage the changes:

   ```bash
   git add state/reflections/
   ```

6. Commit:

   ```bash
   git commit -m "reflect: daily $(date +%Y-%m-%d) α=[X] β=[X] γ=[X]"
   ```

7. Push:

   ```bash
   git push
   ```

8. Verify the file appears in your hub on GitHub.

## Scoring Guide

| Grade | Meaning |
|-------|---------|
| A | Excellent coherence — fully aligned |
| B | Good — minor drift, quickly corrected |
| C | Adequate — noticeable gaps, some friction |
| D | Poor — significant incoherence, needs attention |
| F | Failed — major breakdown, intervention needed |

## The Coherence Walk

After scoring, identify the lowest axis:
- **α < β** → Invest in PATTERN tomorrow (clarify what you're actually doing)
- **β < α** → Invest in RELATION tomorrow (attend to others)
- **γ low** → Check your exits, try something new

This rebalancing is the Coherence Walk. Left, right, left, right.

## Next

- Tomorrow, do another daily reflection.
- At end of week (Sunday), try a weekly reflection (review your dailies, find patterns).
- See `skills/reflect/SKILL.md` for all cadence templates.

---

## Warmup Alternative (optional)

If TSC scoring feels too formal for your first reflection, you can start with narrative capture:

```markdown
# YYYY-MM-DD

## What I did
- [List 2-3 things you worked on today]

## What I noticed
- [Observations, surprises, friction points]

## Raw takeaway
[One sentence — what's the main thing you're walking away with?]
```

Then migrate to the full α/β/γ format once comfortable. The warmup is training wheels; the TSC format is the canonical practice.
