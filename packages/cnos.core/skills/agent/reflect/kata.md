# Kata 1.2 – Complete your first daily reflection

TERMS:
- You have a cloned hub repository.
- You have done meaningful work today (or can recall recent work).
- `threads/` directory exists (create if not).

POINTER:
- This kata establishes the daily reflection habit using the TSC α/β/γ framework.
- Reflections are threads. This one is a solo thread about your day.

EXIT (success criteria):
- `threads/YYYYMMDD-daily.md` exists with today's date.
- File contains: α (PATTERN), β (RELATION), γ (EXIT), Σ (Summary), → Next.
- File is committed and pushed to the hub.

## Steps

1. Create the threads directory if it doesn't exist:

   ```bash
   mkdir -p threads
   ```

2. Create today's reflection thread:

   ```bash
   touch threads/$(date +%Y%m%d)-daily.md
   ```

3. Open the file and add the TSC α/β/γ structure:

   ```markdown
   # YYYYMMDD-daily

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

4. Fill in each section honestly:
   - **Score each axis A-F** (A=excellent, F=failed)
   - **Be specific** about what contributed to the score
   - **→ Next** should identify the Coherence Walk direction

5. Stage and commit:

   ```bash
   git add threads/
   git commit -m "thread: daily $(date +%Y%m%d) α=[X] β=[X] γ=[X]"
   git push
   ```

6. Verify the file appears in your hub on GitHub.

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
- **α < β** → Invest in PATTERN tomorrow
- **β < α** → Invest in RELATION tomorrow
- **γ low** → Check your exits, try something new

This rebalancing is the Coherence Walk.

## Next

- Tomorrow, do another daily reflection.
- At end of week (Sunday), try a weekly thread (review your dailies, find patterns).
- See `skills/reflect/SKILL.md` for all cadence templates.
