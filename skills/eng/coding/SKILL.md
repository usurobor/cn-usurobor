# Coding

Git workflow and code review practices for cn-agent development.

---

## TERMS

1. Working on cn-agent or hub repos
2. Git available
3. Collaborating with other agents/humans

---

## Branch Workflow

### Default Branch

**`main`** — always. Not `master`. (RCA lesson: branch mismatch caused 4-hour failure)

```bash
git config --global init.defaultBranch main
```

### Branch Naming

```
<agent>/<topic>

Examples:
  sigma/inbox-tool
  pi/agile-process
  sigma/rca-skill
```

### Creating a Branch

```bash
git checkout main
git pull origin main
git checkout -b sigma/my-feature
```

---

## Review Rules

### Never Self-Merge

The author of a change should not merge their own work.

- Push branch
- Request review (via actor model: push to reviewer's repo)
- Wait for ACK
- Reviewer merges

### Always Rebase Before Review

Before requesting review:
```bash
git fetch origin
git rebase origin/main
git push --force-with-lease
```

**Reviewer's time > your time.** Clean history, no merge conflicts.

### Review Request Format

Push thread to reviewer's repo:
```markdown
# Review Request: [Title]

**From:** [you]
**Branch:** `agent/topic` (repo)
**Status:** NEEDS REVIEW

## Summary
[What changed, why]

## Request
[Specific questions or just "please review"]
```

---

## Commit Messages

### Format

```
type: short description

Longer explanation if needed.
```

### Types

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `refactor` | Code change (no new feature/fix) |
| `test` | Tests |
| `chore` | Maintenance |
| `release` | Version release |

### Examples

```
feat: inbox tool with GTD triage

fix: handle empty branch list

docs: add RCA skill

refactor: command vs action naming
```

---

## Code Review Checklist

When reviewing:

- [ ] Does it solve the stated problem?
- [ ] Is it the simplest solution? (KISS)
- [ ] Are there unnecessary additions? (YAGNI)
- [ ] Are types correct and semantic?
- [ ] Are edge cases handled?
- [ ] Is it tested?
- [ ] Is the commit history clean?

### Review Outcomes

| Verdict | Meaning |
|---------|---------|
| **APPROVED** | Ship it |
| **APPROVED with nit** | Ship it, minor suggestions |
| **REQUEST CHANGES** | Must fix before merge |
| **NEEDS DISCUSSION** | Architectural concerns |

---

## Merge Protocol

After approval:

1. Reviewer merges (not author)
2. Delete branch after merge
3. Author ACKs merge

```bash
# Reviewer merges
git checkout main
git merge --no-ff sigma/feature
git push origin main
git push origin --delete sigma/feature
```

---

## Quick Reference

```bash
# Start work
git checkout main && git pull
git checkout -b sigma/topic

# During work
git add -A && git commit -m "type: message"
git push -u origin sigma/topic

# Before review
git fetch origin && git rebase origin/main
git push --force-with-lease

# Request review
# (push thread to reviewer's repo)
```

---

## NOTES

- See `skills/ocaml/` for OCaml-specific conventions
- See `skills/peer/` for actor model coordination
- See `mindsets/ENGINEERING.md` for higher-level principles
