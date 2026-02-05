# audit

Periodic health check for codebase and process hygiene.

---

## TERMS

Run audit:
- Weekly (minimum)
- After major releases
- When something feels off

---

## Checks

### 1. Stale References

Grep for deprecated patterns:

```bash
# Example: peer-sync was replaced by inbox
grep -r "peer-sync" --include="*.md" | grep -v deprecated
```

**Fix:** Update references or mark deprecated.

### 2. Doc Drift

Do docs match current code?

| Check | How |
|-------|-----|
| Tool names | Docs reference tools that exist? |
| Commands | Documented commands actually work? |
| Paths | File paths in docs are valid? |

```bash
# Find referenced paths that don't exist
grep -roh "tools/[a-z-]*" docs/ | sort -u | while read p; do
  [ ! -e "$p" ] && echo "Missing: $p"
done
```

**Fix:** Update docs or create missing artifacts.

### 3. Backlog Hygiene

| Check | Action |
|-------|--------|
| Completed items still in active? | Move to Done |
| Items > 2 weeks with no progress? | Re-prioritize or drop |
| Duplicate items? | Merge |
| Vague items? | Add acceptance criteria |

### 4. Branch Cleanup

```bash
# Merged branches still on remote
git branch -r --merged origin/master | grep -v master | grep -v main

# Stale branches (no commits > 14 days)
git for-each-ref --sort=-committerdate refs/remotes/ \
  --format='%(committerdate:short) %(refname:short)'
```

**Fix:** Delete merged branches. Ping owners of stale branches.

### 5. State Consistency

| Check | How |
|-------|-----|
| hub.md template_commit | Matches actual cn-agent HEAD? |
| peers.md | All peers still valid? Repos exist? |
| backlog.md | P0 items actually P0? |

### 6. Process Compliance

| Check | Evidence |
|-------|----------|
| No self-merge? | `git log --oneline | grep "Merge"` — author ≠ merger |
| Branches for all work? | No direct master commits without approval |
| Threads for decisions? | Major changes have adhoc threads |

---

## Output

Create audit thread: `threads/adhoc/YYYYMMDD-audit.md`

```markdown
# Audit: YYYY-MM-DD

## Findings

| Category | Issue | Severity | Action |
|----------|-------|----------|--------|
| Stale refs | peer-sync in docs | Low | Update to inbox |
| Branch | sigma/old-feature | Low | Delete |

## Summary
- Issues found: N
- Critical: N
- Added to backlog: N

## Next Audit
YYYY-MM-DD (1 week)
```

---

## Severity

| Level | Meaning | Action |
|-------|---------|--------|
| Critical | Blocks work or causes failures | Fix immediately |
| High | Significant inconsistency | Add to backlog as P1 |
| Medium | Noticeable but not blocking | Add to backlog as P2 |
| Low | Minor cleanup | Fix opportunistically |

---

## Automation Ideas

Future: `cn audit` command that runs checks automatically.

```bash
cn audit              # run all checks
cn audit --fix        # auto-fix where possible
cn audit --report     # generate thread
```

---

## Who Runs It

| Role | Focus |
|------|-------|
| PM | Backlog hygiene, process compliance, doc drift |
| Engineer | Stale code, branch cleanup, test coverage |
| Both | State consistency, stale references |

---

*"An ounce of prevention is worth a pound of cure."*
