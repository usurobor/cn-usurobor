# Ship

Ship code to production or merge to main.

## Core Rules

**Author never self-merges.** Reviewer merges, author gets notified.

- ❌ Author merges their own branch
- ✅ Reviewer approves → Reviewer merges → Author notified

**Spec first, then tests, then code.**

- ❌ Code → test → spec
- ✅ Spec → test (fails) → code → test (passes)

## Feature Flow (Spec-Driven)

```
1. Write spec — document expected behavior
2. Write tests — verify the spec
3. Run tests — MUST FAIL (nothing implemented)
4. Implement the code
5. Run tests — MUST PASS (implementation matches spec)
6. Run all tests — no regressions
7. Ship
```

If tests pass in step 3, the tests aren't testing new behavior. Rewrite them.

## Bug Fix Flow (TDD)

```
1. Write test that reproduces the bug
2. Run test — MUST FAIL (proves test catches bug)
3. Fix the code
4. Run test — MUST PASS (proves fix works)
5. Run all tests — no regressions
6. Ship
```

If test doesn't fail in step 2, the test doesn't catch the bug. Rewrite it.

### Example (Feature)

```bash
# 1. Update spec
echo "cn send pushes to MY origin, not peer's" >> spec/PROTOCOL.md

# 2. Write failing test
cat > test/send-protocol.t << 'EOF'
  $ cn sync && git -C my-origin branch | grep "recipient/"
  recipient/hello
EOF

# 3. Verify it fails
dune runtest test/send-protocol.t  # MUST FAIL

# 4. Implement
vim src/cn.ml

# 5. Verify it passes  
dune runtest test/send-protocol.t  # MUST PASS

# 6. All tests
dune runtest

# 7. Ship
```

### Example (Bug Fix)

```bash
# 1. Write failing test
cat > test/bug-123.t << 'EOF'
  $ cn inbox | grep "detected"
  ⚠ From pi: 1 inbound
EOF

# 2. Verify it fails
dune runtest test/bug-123.t  # MUST FAIL

# 3. Fix
vim src/cn.ml

# 4. Verify it passes
dune runtest test/bug-123.t  # MUST PASS

# 5. All tests + ship
dune runtest && git commit && git push
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
