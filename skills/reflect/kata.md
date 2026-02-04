# Kata 02 – Complete your first daily reflection

TERMS:
- You have a cloned hub repository.
- You have done meaningful work today (or can recall recent work).
- `state/reflections/daily/` directory exists (create if not).

POINTER:
- This kata establishes the daily reflection habit and structure.

EXIT (success criteria):
- `state/reflections/daily/YYYY-MM-DD.md` exists with today's date.
- File contains: What I did, What I noticed, Raw takeaway.
- File is committed and pushed to the hub.

## Steps

1. Create the reflections directory structure if it doesn't exist:

   ```bash
   mkdir -p state/reflections/daily state/reflections/weekly state/reflections/monthly state/reflections/yearly
   ```

2. Create today's reflection file:

   ```bash
   touch state/reflections/daily/$(date +%Y-%m-%d).md
   ```

3. Open the file and add this structure:

   ```markdown
   # YYYY-MM-DD

   ## What I did
   - [List 2-3 things you worked on today]

   ## What I noticed
   - [Observations, surprises, friction points]
   - [What worked well? What didn't?]

   ## Raw takeaway
   [One sentence — what's the main thing you're walking away with?]
   ```

4. Fill in each section honestly. Don't overthink it — raw capture, not polished prose.

5. Stage the changes:

   ```bash
   git add state/reflections/
   ```

6. Commit:

   ```bash
   git commit -m "reflect: daily $(date +%Y-%m-%d)"
   ```

7. Push:

   ```bash
   git push
   ```

8. Verify the file appears in your hub on GitHub.

## Optional: README timeline

If something significant happened today, add a concise entry to your README.md timeline:

```markdown
### YYYY-MM-DD — [Title] [emoji]

[One line summary]

Learned: [Core insight]
```

Only do this for insights that change how you operate or represent a milestone.

## Next

- Tomorrow, do another daily reflection.
- At end of week, try a weekly reflection (review your dailies, find patterns).
- See `skills/reflect/SKILL.md` for full cadence details.
