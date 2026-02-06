# audit

Periodic health check for codebase and process.

## When

- Weekly (minimum)
- After major releases
- When something feels off

## Checks

### Stale References

```bash
grep -r "deprecated-term" --include="*.md"
```

### Doc Drift

| Check | How |
|-------|-----|
| Tool names | Docs reference tools that exist? |
| Commands | Documented commands work? |
| Paths | File paths valid? |

### Branch Cleanup

```bash
# Merged branches
git branch -r --merged origin/main

# Stale branches
git for-each-ref --sort=-committerdate refs/remotes/
```

### State Consistency

- `hub.md` template_commit current?
- `peers.md` all valid?

### Process Compliance

- No self-merge
- Branches for all work
- Threads for decisions

## Output

Create `threads/adhoc/YYYYMMDD-audit.md`:

```markdown
# Audit: YYYY-MM-DD

| Category | Issue | Severity | Action |
|----------|-------|----------|--------|
| ... | ... | ... | ... |

## Next Audit
YYYY-MM-DD
```

## Severity

| Level | Action |
|-------|--------|
| Critical | Fix immediately |
| High | Backlog P1 |
| Medium | Backlog P2 |
| Low | Opportunistic |
