# ship

How we ship code. Branch to main.

---

## TERMS

1. Work exists as a branch
2. Ready for review
3. Rebased on latest `main`

---

## Workflow

```
Branch → Review → Merge → Delete
```

### 1. Create Branch

```bash
git checkout main && git pull
git checkout -b <agent>/<topic>
```

Naming: `sigma/inbox-tool`, `pi/agile-process`

### 2. Do Work

```bash
git add -A && git commit -m "type: message"
git push -u origin <agent>/<topic>
```

### 3. Before Review

**Always rebase:**
```bash
git fetch origin
git rebase origin/main
git push --force-with-lease
```

Reviewer's time > your time. No merge conflicts for reviewer.

### 4. Request Review

Push thread to reviewer's repo (actor model):
```markdown
# Review Request: [Title]

**Branch:** `agent/topic`
**Status:** NEEDS REVIEW

## Summary
[What, why]
```

### 5. Review

Reviewer evaluates. Outcomes:

| Verdict | Action |
|---------|--------|
| **APPROVED** | Reviewer merges |
| **APPROVED with nit** | Reviewer merges |
| **REQUEST CHANGES** | Return to author |

### 6. Merge

**Reviewer merges** (not author):
```bash
git checkout main
git merge --no-ff origin/<agent>/<topic> -m "Merge <agent>/<topic>: summary

Reviewed-by: <reviewer>"
git push origin main
```

### 7. Delete Branch

**Author deletes** (not reviewer):
```bash
git push origin --delete <agent>/<topic>
```

Only the creator of a branch can delete it.

---

## Rules

| Rule | Why |
|------|-----|
| **No self-merge** | Author can't merge own work |
| **Always rebase** | Clean history for reviewer |
| **Only creator deletes** | Reviewer returns, never deletes |
| **main, not master** | Standardized (RCA lesson) |

---

## Outcomes

A branch has two outcomes:

1. **Merged** → pushed to main, author deletes branch
2. **Returned** → needs work, author decides next step

Never "closed" or "stale". Return to author if it needs work.

---

## Quick Reference

```bash
# Start
git checkout main && git pull
git checkout -b sigma/feature

# Work
git commit -m "feat: thing"
git push origin sigma/feature

# Before review
git fetch origin && git rebase origin/main
git push --force-with-lease

# After approval (reviewer does this)
git checkout main
git merge --no-ff origin/sigma/feature
git push origin main

# Cleanup (author does this)
git push origin --delete sigma/feature
```

---

## NOTES

- See `skills/review/` for review process
- See `skills/coding/` for commit conventions
- See `mindsets/PM.md` for merge governance
