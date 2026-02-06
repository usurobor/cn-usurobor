# ship

Branch to main workflow.

## Workflow

```
Branch → Review → Merge → Delete
```

## Steps

```bash
# 1. Create branch
git checkout main && git pull
git checkout -b <agent>/<topic>

# 2. Work
git commit -m "type: message"
git push origin <agent>/<topic>

# 3. Before review (always rebase)
git fetch origin && git rebase origin/main
git push --force-with-lease

# 4. Request review → push thread to reviewer's repo

# 5. After approval (REVIEWER merges)
git checkout main
git merge --no-ff origin/<agent>/<topic>
git push origin main

# 6. Cleanup (AUTHOR deletes)
git push origin --delete <agent>/<topic>
```

## Rules

| Rule | Why |
|------|-----|
| No self-merge | Author ≠ merger |
| Always rebase | No conflicts for reviewer |
| Only creator deletes | Reviewer returns, never deletes |
| main, not master | Standardized |

## Outcomes

- Merged → author deletes branch
- Returned → author fixes or abandons
