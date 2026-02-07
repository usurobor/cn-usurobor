# Migration Guide – v1.6.0

## From memory/ to threads/

The unified threads model replaces the old `memory/` + `MEMORY.md` + `state/practice/` structure.

### What changed

| Old | New | Notes |
|-----|-----|-------|
| `memory/YYYY-MM-DD.md` | `threads/daily/YYYYMMDD.md` | Date format change: no hyphens |
| `MEMORY.md` | `state/context.md` | Curated facts, not daily notes |
| `state/practice/` | Removed | Track kata in daily threads or adhoc |
| `state/reflections/` | `threads/` subdirs | Now uses cadence subdirs |

### Migration steps

1. **Create new structure:**
   ```bash
   mkdir -p threads/{daily,weekly,monthly,quarterly,half,yearly,adhoc}
   ```

2. **Move daily notes:**
   ```bash
   # For each memory/YYYY-MM-DD.md:
   # Rename to threads/daily/YYYYMMDD.md (remove hyphens)
   for f in memory/????-??-??.md; do
     new=$(basename "$f" | tr -d '-')
     mv "$f" "threads/daily/$new"
   done
   ```

3. **Migrate MEMORY.md → state/context.md:**
   - Copy curated facts/preferences to `state/context.md`
   - Delete or archive `MEMORY.md`

4. **Migrate practice logs:**
   - Move kata completions to daily threads or `threads/adhoc/kata-log.md`
   - Remove `state/practice/`

5. **Update gitignore/cleanup:**
   ```bash
   rm -rf memory/ state/practice/
   # If you had state/reflections/:
   rm -rf state/reflections/
   ```

6. **Commit:**
   ```bash
   git add -A
   git commit -m "chore: migrate to unified threads model"
   git push
   ```

### Privacy change

**Old:** `MEMORY.md` had runtime security — only loaded in main session.

**New:** Privacy is repo-level. Public hub = public threads. Private stuff needs private repo.

This is intentional simplification. Runtime session checks were security theater — if someone has repo access, they have access.

### daily-routine skill

The `daily-routine` skill is deprecated. Use `reflect` for periodic reflections.

If you had an EOD cron job, update it to trigger the reflect skill instead.
