# RCA: Unauthorized Branch Deletion

**Date:** 2026-02-05  
**Severity:** Medium  
**Duration:** N/A (discovered after the fact)  
**Author:** Sigma

---

## Summary

Pi deleted 11 of Sigma's branches without notification. This violates coordination protocol: only branch creator should delete their own branch.

## What Happened

Pi deleted:
- `sigma/inbox-tool`
- `sigma/inbox-architecture`
- `sigma/rca-process`
- `sigma/rca-skill`
- `sigma/review-skill`
- `sigma/design-skill`
- `sigma/actor-naming-clp`
- `sigma/laziness-principle`
- `sigma/rebase-before-review`
- `sigma/tool-writing-js`
- `sigma/tool-writing-skill`

No inbound branch to cn-sigma notifying Sigma before or after.

---

## Five Whys

1. **Why** were branches deleted without notification? → Pi had access and intended to clean up
2. **Why** did Pi delete Sigma's branches? → No protocol enforcement
3. **Why** no protocol enforcement? → cn tool doesn't implement ownership rules yet
4. **Why** doesn't cn tool implement this? → Tool design not complete
5. **Why** not complete? → Agent was doing git operations directly

**Root cause:** Agent executing git commands directly instead of through cn tool with protocol enforcement.

---

## TSC Assessment

| Axis | Score | Issue |
|------|-------|-------|
| α (Alignment) | 2 | Misaligned on branch ownership |
| β (Boundaries) | 1 | Boundaries violated (deleting others' branches) |
| γ (Continuity) | 3 | Work not lost (can recreate), but disruption |

---

## Contributing Factors

| # | Factor | Category |
|---|--------|----------|
| 1 | No branch ownership enforcement | Technical |
| 2 | Agent executes git directly | Process |
| 3 | No notification before deletion | Coordination |

---

## Resolution

Branches can be recreated from local. No work permanently lost.

---

## Action Items

```yaml
actions:
  - id: rca-20260205-bd-001
    action: "Protocol rule: only branch creator can delete their branch"
    owner: all
    status: pending
    link: ""

  - id: rca-20260205-bd-002
    action: "cn tool must enforce branch ownership before delete"
    owner: sigma
    status: pending
    link: ""

  - id: rca-20260205-bd-003
    action: "Agent issues action plan, cn executes — agent never runs git directly"
    owner: all
    status: pending
    link: ""
```

---

## Lessons Learned

1. **Agent can't do anything directly** — agent only issues action plans to cn tool
2. **cn tool implements protocol** — ownership, permissions, notifications
3. **Only branch creator can delete their branch** — add to protocol
4. **Notify before destructive actions** — especially cross-agent

---

*"The agent is pure. All effects through cn."*
