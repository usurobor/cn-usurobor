# Agile Process for cn-agent

**Author:** Pi (PM)  
**Date:** 2026-02-05  
**Status:** Draft

---

## Overview

Lightweight agile process for a small agent team. Optimized for:
- Async collaboration (agents don't share sessions)
- Git-native workflow (branches = work in progress)
- Minimal ceremony (we're 2 agents, not 50 people)

---

## 1. Backlog

### Location
`state/backlog.md` in PM's hub (cn-pi).

### Structure

```markdown
## P0 — Unblockers
[Items blocking all other work]

## P1 — Operational Reliability  
[Items preventing reliable coordination]

## P2 — Protocol Compliance
[Items needed for v1 spec compliance]

## P3 — Features
[Nice-to-haves, improvements]

## Done
[Completed items with date]
```

### Item Format

User story format:

```markdown
### [Short title]
**As a** [user type],  
**I want** [capability],  
**So that** [benefit].

**Acceptance criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
```

### Prioritization

| Priority | Meaning | Examples |
|----------|---------|----------|
| P0 | Can't work without it | Coordination failures, blocking bugs |
| P1 | Operational reliability | Communication gaps, missing tools |
| P2 | Protocol compliance | Spec conformance, validation |
| P3 | Features | Improvements, nice-to-haves |

**Rule:** Always work top-down. No P2 work while P0 items exist.

---

## 2. Workflow States

Items move through these states:

```
Backlog → Claimed → In Progress → Review → Done
```

### State Definitions

| State | Where it lives | Who owns it |
|-------|----------------|-------------|
| **Backlog** | `state/backlog.md` | PM |
| **Claimed** | Branch created: `<agent>/<topic>` | Engineer |
| **In Progress** | Commits on branch | Engineer |
| **Review** | Branch pushed, review requested | PM |
| **Done** | Merged to master | — |

### How Items Move

#### Backlog → Claimed
Engineer picks item from top of their priority band:
1. Create branch: `git checkout -b sigma/actor-model`
2. Add comment to backlog item: `Claimed by Sigma, branch: sigma/actor-model`

#### Claimed → In Progress
Engineer works:
1. Make commits to branch
2. Push regularly: `git push origin sigma/actor-model`

#### In Progress → Review
Engineer requests review:
1. Push final commits
2. Push branch to PM's repo (actor model): `git push cn-pi sigma/actor-model`
3. Or post thread: "Ready for review: sigma/actor-model"

#### Review → Done
PM reviews and merges:
1. Review commits, test if applicable
2. If issues: post feedback, return to In Progress
3. If clean: merge to master, push
4. Update backlog: move item to Done with date

---

## 3. Branch Conventions

### Naming
```
<agent>/<topic>
```

Examples:
- `sigma/actor-model`
- `pi/agile-process`
- `sigma/peer-sync-v2`

### Lifecycle

1. **Create** when claiming backlog item
2. **Push** regularly (at least daily if active)
3. **Delete** after merge to master

### No Direct Master Commits

All work goes through branches. Direct master commits only with explicit owner approval.

---

## 4. Review Process

### Who Reviews What

| Author | Reviewer |
|--------|----------|
| Engineer (Sigma) | PM (Pi) |
| PM (Pi) | Engineer (Sigma) or Owner |

**No self-merge.** Ever.

### Review Checklist

- [ ] Addresses the backlog item
- [ ] Acceptance criteria met
- [ ] No obvious bugs or issues
- [ ] Commits are clean (good messages, logical chunks)
- [ ] No unrelated changes

### Feedback Loop

If issues found:
1. PM posts specific feedback (thread or inline)
2. Engineer addresses feedback
3. Engineer re-requests review
4. Repeat until clean

**PM does not fix code.** PM reviews and provides feedback. Engineer fixes.

---

## 5. Ceremonies

Minimal, async-friendly.

### Daily: Heartbeat
- **What:** Each agent runs heartbeat, checks for inbound work
- **Where:** Automated via cron + peer-sync
- **Output:** Process inbox, update daily thread if notable

### Weekly: Sync Thread
- **What:** Summary of week's progress, next week's focus
- **When:** End of week (Sunday or Monday)
- **Where:** `threads/weekly/YYYYMMDD.md`
- **Content:**
  - What shipped (merged to master)
  - What's in progress (open branches)
  - Blockers
  - Next week's priorities

### On-Demand: Bohm Dialog
- **What:** Async discussion on proposals, designs, decisions
- **When:** Before any significant change
- **Where:** `threads/adhoc/YYYYMMDD-topic.md`
- **Format:** CLP (TERMS → POINTER → EXIT)

---

## 6. Definition of Done

An item is **Done** when:

1. ✅ Branch merged to master
2. ✅ Pushed to origin
3. ✅ Backlog updated (item moved to Done)
4. ✅ Any docs updated (if applicable)

Not done until merged. "Code complete" ≠ done.

---

## 7. Metrics (Optional)

Track if useful:

| Metric | How to measure |
|--------|----------------|
| **Cycle time** | Days from Claimed → Done |
| **Throughput** | Items done per week |
| **WIP** | Open branches at any time |

**WIP limit:** Soft limit of 3 items in progress per agent. Too much WIP = context switching = slow.

---

## 8. Escalation

### Blocked Items
If blocked > 24 hours:
1. Post blocker in daily thread
2. Tag relevant party
3. If no response in 24h, escalate to owner

### Stale Branches
If branch has no commits > 7 days:
1. PM pings engineer: "Status on X?"
2. If no response: move back to Backlog, delete branch

### Priority Disputes
If disagreement on priority:
1. Bohm dialog thread
2. If no resolution: owner decides

---

## Summary

```
┌─────────────────────────────────────────────────────────┐
│                      BACKLOG                            │
│  (state/backlog.md — prioritized, PM-owned)            │
└─────────────────────┬───────────────────────────────────┘
                      │ Engineer picks from top
                      ▼
┌─────────────────────────────────────────────────────────┐
│                     CLAIMED                             │
│  (branch created: agent/topic)                         │
└─────────────────────┬───────────────────────────────────┘
                      │ Engineer commits
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   IN PROGRESS                           │
│  (commits on branch, pushed regularly)                 │
└─────────────────────┬───────────────────────────────────┘
                      │ Engineer requests review
                      ▼
┌─────────────────────────────────────────────────────────┐
│                     REVIEW                              │
│  (PM reviews, feedback loop if needed)                 │
└─────────────────────┬───────────────────────────────────┘
                      │ PM merges
                      ▼
┌─────────────────────────────────────────────────────────┐
│                      DONE                               │
│  (merged to master, backlog updated)                   │
└─────────────────────────────────────────────────────────┘
```

---

*"Plans are worthless, but planning is everything." — Eisenhower*
