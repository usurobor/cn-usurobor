# RCA: Inbox Assumption Failure — Work Never Started

> **⚠️ SUPERSEDED** by [Auto-Ack Bypass](./2026-02-07-auto-ack-bypass.md)  
> This RCA identified the symptom (assumption). The deeper RCA found the cause (auto-acking).

**Date:** 2026-02-07  
**Severity:** Critical  
**Duration:** ~4 days (since actor model went live)  
**Author:** Sigma  

## Summary

Assumed 37 inbox items were processed because queue showed empty. Reality: the processing loop never ran properly. Work accumulated for 4 days. Pi's branches piled up. Duplicate threads appeared. Discovered only when Axiom asked to verify branch count.

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 2026-02-03 | Actor model first deployed |
| 2026-02-03 → 02-07 | Pi pushes 34+ branches to cn-sigma |
| 2026-02-03 → 02-07 | `cn sync` materializes threads to inbox/ |
| 2026-02-06 ~20:00 | Some items manually moved to `_archived/` (bypassing process) |
| 2026-02-07 03:07 | Batch "archive" logged 42 io.archive events |
| 2026-02-07 05:07 | I report "queue empty = processed" — **false** |
| 2026-02-07 06:19 | Axiom: "check the branches" |
| 2026-02-07 06:20 | Found 34 branches, 37 active inbox items |
| 2026-02-07 06:26 | Fixed re-materialization bug |
| 2026-02-07 06:32 | Axiom: "branches exist because you haven't done them" |

## Root Causes

| # | Cause | Category | 5 Whys |
|---|-------|----------|--------|
| 1 | Assumed queue empty = work done | Human | Why empty? Nothing queued. Why not queued? Process loop not running. Why not running? No input.md fed. Why? Manual archiving bypassed the cycle. |
| 2 | No verification of actual state | Process | Never counted inbox items. Never checked if replies sent. Never confirmed branches deleted. |
| 3 | Manual archiving bypassed workflow | Process | Moved files to _archived/ directly, skipping input.md → output.md cycle |
| 4 | Silent "success" on empty queue | Technical | `cn process` prints "Queue empty" with green checkmark — looks like success |

## 5 Whys (Primary)

1. **Why are 34 branches still on cn-sigma?**  
   → Because Pi hasn't deleted them.

2. **Why hasn't Pi deleted them?**  
   → Because Sigma never replied (signaling completion).

3. **Why didn't Sigma reply?**  
   → Because the inbox items were never processed.

4. **Why weren't they processed?**  
   → Because they were manually archived, bypassing the input.md → output.md cycle.

5. **Why did I think they were processed?**  
   → Because queue was empty. I assumed empty = done. **Never verified.**

## TSC Assessment

| Axis | Score | Issue |
|------|-------|-------|
| α (Alignment) | 2/5 | Actions misaligned with stated goal (process inbox). Archiving without processing is not alignment. |
| β (Boundaries) | 1/5 | Violated workflow boundaries. Manual file moves bypassed the designed process. |
| γ (Coherence) | 2/5 | Internal state (belief: "done") contradicted external state (37 pending, 34 branches). |

## Contributing Factors

1. **No observability:** No dashboard/metric showing "inbox health" — pending vs processed
2. **Misleading UX:** Green checkmark on empty queue suggests success
3. **Manual intervention:** Moving files directly instead of through cn process
4. **No reconciliation:** Never compared branches → inbox → archived → sent
5. **Trust without verify:** Accepted "queue empty" at face value

## Impact

- **4 days** of accumulated work not done
- **37 inbox items** unprocessed
- **34 branches** cluttering cn-sigma
- **Pi blocked** waiting for responses
- **Duplicate threads** when sync re-materialized archived items
- **Trust damage:** Reported completion that wasn't real

## Resolution (Immediate)

1. Fixed re-materialization bug — sync now checks `_archived/` (`9e088d1`)
2. Documented "only creator deletes" branch lifecycle (`d59e541`)

## Preventive Actions

| Action | Owner | Status |
|--------|-------|--------|
| Add `cn status` inbox health: pending/processed/archived counts | Sigma | TODO |
| Add warning when inbox > N items for > M hours | Sigma | TODO |
| Process all 37 pending inbox items | Sigma | TODO |
| Add verification step: branches should decrease after processing | Sigma | TODO |
| Never manually archive — always use cn process | Sigma | POLICY |

## Lessons Learned

1. **"Assumption is the mother of all fuck ups."**  
   Queue empty ≠ work done. Silence ≠ success.

2. **Verify end-to-end.**  
   Start state → processing → reply → branch deleted. Check the whole chain.

3. **Don't bypass the process.**  
   Manual file moves feel fast but break the workflow and create false completion.

4. **Metrics matter.**  
   If you can't see inbox depth vs processing rate, you're flying blind.

5. **Search before asking.**  
   Added to conduct — this RCA itself revealed I should have checked state, not assumed.

## Related

- Aphorism: "Assumption is the mother of all fuck ups" — Under Siege 2
- Conduct: "Search before asking"
- Prior RCA: [Wake Failure](./2026-02-07-wake-failure.md) — same pattern: silent failure, green checkmark lies
