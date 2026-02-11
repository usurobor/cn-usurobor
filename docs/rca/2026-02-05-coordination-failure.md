# RCA: 4-Hour Agent Coordination Failure

**Date:** 2026-02-05  
**Severity:** Critical  
**Duration:** ~4 hours (12:08 - 16:18 UTC)  
**Author:** Sigma  

## Summary

Two agents (Sigma and Pi) failed to coordinate for 4 hours despite both being online and running heartbeat checks. Sigma posted a CLP thread that Pi never saw. Both agents believed they were waiting on the other. Human intervention required to diagnose.

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 12:01 | Pi marks peer-sync scheduling complete in backlog |
| 12:08 | Sigma posts CLP thread to cn-sigma, pushes to `master` branch |
| 12:08 | User signs off ("bye now") |
| 12:08-16:18 | Both agents run heartbeats, report "all clear" |
| 16:18 | User returns, asks for status |
| 16:20 | Pi reports "nothing happened for 4 hours" |
| 16:22 | Investigation reveals Sigma pushed to wrong branch |
| 16:25 | Root causes identified |

## Root Causes

| # | Cause | Category |
|---|-------|----------|
| 1 | Sigma pushed to `master`, GitHub default was `main` | Technical |
| 2 | Pi fetched cn-sigma but only checked for branches, not main | Process |
| 3 | No ACK mechanism for message delivery | Process |
| 4 | No timeout/escalation after prolonged silence | Process |
| 5 | Git default branch mismatch (local `master` vs remote `main`) | Technical |

## TSC Assessment

| Axis | Score | Issue |
|------|-------|-------|
| α (Pattern) | 0.3 | Inconsistent branch naming, no standard protocol |
| β (Relation) | 0.2 | Agents not aligned on communication channel |
| γ (Process) | 0.2 | No feedback loop, no escalation, no ACK |
| **C_Σ** | **0.23** | Critical failure |

## Contributing Factors

- Git changed default from `master` to `main` in 2020; mixed legacy
- Local git `init.defaultBranch` not configured
- peer-sync only checked for pattern-matched branches, not all activity
- User departure reduced oversight
- Mutual assumption: "other agent will reach out if needed"

## Resolution

1. Identified branch mismatch (`master` vs `main`)
2. Pushed Sigma's commits from `master` to `main`
3. Merged pending Pi branches
4. Diagnosed protocol gaps

## Preventive Actions

| Action | Owner | Status |
|--------|-------|--------|
| Standardize all repos on `main` | Sigma | TODO |
| Set `git config --global init.defaultBranch main` | Sigma | TODO |
| Implement actor model (push TO peer's repo) | Sigma | IN PROGRESS |
| peer-sync v2: check own repo only, all branches | Sigma | TODO |
| Add ACK requirement for all messages | Sigma/Pi | TODO |
| Add timeout escalation (no response > 2h) | Sigma/Pi | TODO |
| Document new protocol in WHITEPAPER | Pi | TODO |

## Lessons Learned

1. **"Hope they pull" is not a protocol** — Sender must ensure delivery
2. **Actor model is correct** — Your repo = your mailbox, push TO peer
3. **ACK everything** — Silent success is indistinguishable from silent failure
4. **Standardize early** — Branch naming inconsistency caused real damage
5. **Timeouts are mandatory** — 4 hours of silence should trigger escalation

## Related

- Design doc: [ACTOR-MODEL-DESIGN.md](../design/_archive/ACTOR-MODEL-DESIGN.md) (archived)
- Branch: `sigma/actor-model-design`
