# cn Actions

Everything cn tool must implement. Agent decides, cn executes.

---

## Principle

**Agent = brain (decisions). cn = body (execution).**

If an action requires judgment → agent decides first.
If an action is mechanical → cn executes.

---

## Actions

### Inbox

| Action | Trigger | What cn does |
|--------|---------|--------------|
| `inbox sync` | cron | Fetch branches, materialize as threads |
| `inbox process` | cron | Parse triage decisions, execute them |

### Ship (Review + Merge)

| Action | Trigger | What cn does |
|--------|---------|--------------|
| `ship review` | agent writes APPROVED | Validate clean (rebased, no conflicts) |
| `ship merge` | APPROVED in thread | `git merge --no-ff`, push to main, log |
| `ship cleanup` | after merge | Notify author to delete branch |

### Branch Management

| Action | Trigger | What cn does |
|--------|---------|--------------|
| `branch create` | agent decision | `git checkout -b <agent>/<topic>` |
| `branch delete` | author decision | Verify ownership, then delete |
| `branch rebase` | before review | `git rebase origin/main` |

### Coordination

| Action | Trigger | What cn does |
|--------|---------|--------------|
| `notify` | agent decision | Push thread to peer's repo |
| `ack` | agent decision | Push ACK branch to peer |

### Logging

| Action | Trigger | What cn does |
|--------|---------|--------------|
| `log triage` | after triage | Write to `logs/inbox/YYYYMMDD.md` |
| `log merge` | after merge | Write to `logs/ship/YYYYMMDD.md` |
| `log error` | on failure | Write to `logs/errors/YYYYMMDD.md` |

---

## Protocol Enforcement

cn must enforce:

| Rule | Enforcement |
|------|-------------|
| Only creator deletes branch | Check branch prefix matches actor |
| Merge requires APPROVED | Check thread has approval |
| Rebase before merge | Check branch is on latest main |
| No self-merge | Check reviewer ≠ author |

---

## Not Yet Implemented

- [ ] `inbox sync` — materialize branches as threads
- [ ] `inbox process` — execute triage decisions
- [ ] `ship merge` — execute approved merges
- [ ] `branch delete` — ownership-enforced deletion
- [ ] Protocol enforcement layer

---

## Implementation Status

| Component | Status |
|-----------|--------|
| `inbox check` (detection only) | ✅ Done (OCaml) |
| GTD types | ✅ Done (OCaml) |
| Daily logs | ✅ Done (OCaml) |
| Thread materialization | ❌ Not started |
| Merge execution | ❌ Not started |
| Protocol enforcement | ❌ Not started |

---

*"Agent issues action plan. cn executes."*
