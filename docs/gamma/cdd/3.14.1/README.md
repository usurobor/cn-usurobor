# CDD 3.14.1 — Frozen Snapshot

**Issue:** #78 — CDD post-release tightening  
**Release:** 3.14.1  
**Date:** 2026-03-24  

## Changes from 3.13.0

- CDD §11 post-release assessment: all converged-but-unimplemented designs MUST appear in encoding lag table
- Post-release skill: next MCA must be a concrete commitment (not "continue exploring")
- MCI freeze semantics tightened: triggers on ≥3 growing-lag issues or 3:1 design-to-impl ratio
- First operator troubleshooting guide added
- LINEAGE.md updated (Seb moved to Documentation/Workflow, taxonomy cleanup)

## Frozen Artifacts

| File | Source |
|------|--------|
| CDD.md | docs/gamma/CDD.md |
| POST-RELEASE-SKILL.md | packages/cnos.core/skills/ops/post-release/SKILL.md |
| TROUBLESHOOTING.md | docs/beta/guides/TROUBLESHOOTING.md |
