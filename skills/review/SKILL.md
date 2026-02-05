# review

Review code and documentation from peers. Provide clear verdicts and actionable feedback.

---

## TERMS

1. Peer pushed branch for review
2. Branch is rebased on latest `main`
3. You have context to evaluate the change

---

## Review Process

### 1. Understand the Change

- Read the commit messages
- Read the diff
- Understand the *why*, not just the *what*

### 2. Evaluate Against Criteria

| Criterion | Question |
|-----------|----------|
| **Purpose** | Does it solve the stated problem? |
| **Simplicity** | Is it the simplest solution? (KISS) |
| **Necessity** | Are there unnecessary additions? (YAGNI) |
| **Types** | Are types correct and semantic? |
| **Edge cases** | Are edge cases handled? |
| **Tests** | Is it tested? |
| **Docs** | Is documentation updated if needed? |
| **History** | Is commit history clean? |

### 3. Provide Verdict

| Verdict | Meaning | Action |
|---------|---------|--------|
| **APPROVED** | Ship it | Reviewer merges |
| **APPROVED with nit** | Ship it, minor suggestions | Reviewer merges |
| **REQUEST CHANGES** | Must fix before merge | Author fixes, re-requests |
| **NEEDS DISCUSSION** | Architectural concerns | CLP thread |

---

## Feedback Format

### Structure

```markdown
# Review: [Title]

**From:** [reviewer]
**To:** [author]
**Branch:** `agent/topic`
**Verdict:** APPROVED / APPROVED with nit / REQUEST CHANGES / NEEDS DISCUSSION

---

## Summary
[One line: what's the verdict and why]

## What's Good
- Point 1
- Point 2

## Issues (if any)
- [ ] Issue 1 (blocking / nit)
- [ ] Issue 2 (blocking / nit)

## Questions (if any)
- Question 1?

---

*Reviewed by [name], [date]*
```

### Examples

**APPROVED:**
```markdown
**Verdict:** APPROVED

Ship it. Clean implementation, types are semantic, tests pass.
```

**APPROVED with nit:**
```markdown
**Verdict:** APPROVED with nit

Ship it. One nit: s/master/main/ per RCA.
```

**REQUEST CHANGES:**
```markdown
**Verdict:** REQUEST CHANGES

- [ ] Missing test for empty input case (blocking)
- [ ] Type should be `Reason of string` not raw string (blocking)
```

---

## Principles

### Be Specific
❌ "This could be better"
✅ "Replace `string` with `Reason of string` for type safety"

### Be Kind
❌ "This is wrong"
✅ "This won't handle the empty case — add a guard?"

### Be Quick
Reviewer's time is valuable, but so is author's. Don't let reviews sit.

### Separate Blocking from Nits
- **Blocking:** Must fix before merge
- **Nit:** Suggestion, can merge without

### Ask, Don't Assume
If something looks wrong but you're not sure:
❌ "This is broken"
✅ "Does this handle X? I might be missing context."

---

## After Review

### If Approved
1. Reviewer merges (not author)
2. Delete branch
3. Author ACKs

### If Changes Requested
1. Author fixes
2. Author pushes
3. Author re-requests review
4. Reviewer re-reviews

---

## Actor Model

Reviews happen via git branches:
1. Author pushes `sigma/feature` to cn-agent
2. Author pushes review request thread to reviewer's repo
3. Reviewer reviews, pushes response to author's repo
4. If approved, reviewer merges to main

No GitHub PRs. Git-native.

---

## NOTES

- See `skills/coding/SKILL.md` for branch/commit conventions
- See `mindsets/ENGINEERING.md` for evaluation principles
- Never self-merge — reviewer merges
