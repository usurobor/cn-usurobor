# ship

Ship code to production or merge to main.

## Core Rules

**Author never self-merges.** Reviewer merges, author gets notified.

- ❌ Author merges their own branch
- ✅ Reviewer approves → Reviewer merges → Author notified

**Bug fixes require TDD.** Test catches bug before code fixes it.

- ❌ Fix code → write test → ship
- ✅ Write test → verify it fails → fix code → verify it passes → ship

## Bug Fix Flow (TDD)

```
1. Write test that reproduces the bug
2. Run test — MUST FAIL (proves test catches bug)
3. Fix the code
4. Run test — MUST PASS (proves fix works)
5. Run all tests — no regressions
6. Ship
```

If the test doesn't fail in step 2, the test doesn't catch the bug. Rewrite it.

### Example

```bash
# 1. Write failing test
cat > test/bug-123.t << 'EOF'
  $ cn inbox 2>&1 | grep "expected output"
  expected output
EOF

# 2. Verify it fails
dune runtest test/bug-123.t  # MUST FAIL

# 3. Fix the code
vim src/cn.ml

# 4. Verify it passes
dune runtest test/bug-123.t  # MUST PASS

# 5. Run all tests
dune runtest  # No regressions

# 6. Ship
```

## Pre-Ship Checklist

- [ ] Tests pass
- [ ] Branch rebased on main
- [ ] PR approved (if required)
- [ ] No unresolved comments
- [ ] **Features verified working** — don't assume, test it yourself

## Principle

**Don't assume features work — test them.** Before shipping, verify the feature actually works. Before using a new feature, verify it's implemented. Assumptions cause stale state, silent failures, and RCAs.

## Ship

```bash
git checkout main
git pull
git merge <branch> --no-ff
git push
```

Or squash if history is noisy:
```bash
git merge <branch> --squash
git commit -m "feat: <description>"
git push
```

## Post-Ship Checklist

- [ ] **Announce to peers** — outbox message: "shipped X to main"
- [ ] **Delete branch** — local and remote
- [ ] **Update daily thread** — log what shipped

### Announce Template

```markdown
---
to: <peer>
created: <timestamp>
subject: Shipped <feature>
---

Merged to main: <commit-hash>
Branch deleted: <branch-name>

—<your-name>
```

## Why Announce?

Peers track your work via branches and inbox. If you merge without announcing:
- Stale branches cause confusion ("59 commits behind")
- Peers don't know work is done
- Escalations happen unnecessarily

**Ship = merge + announce + cleanup.** Not just merge.
