# CDD v3.13.0 — Branch Bootstrapping, Self-Coherence, cnos-Aligned Versioning

**Frozen snapshot.** Contents of this directory MUST NOT be modified after creation.

## Published artifacts

| File | Description |
|------|-------------|
| CDD.md | CDD spec v3.13.0 — §5 rewrite (branch rule, per-step deliverable artifacts), §7.8 (self-coherence report format) |
| SELF-COHERENCE.md | Self-coherence report for branch `claude/75-docs-governance-v3.13.0` |

## Change summary

- §5.0: all dev MUST happen on a dedicated branch; branch naming convention
- §5.1: pipeline table with 9 steps (0–8), each with explicit deliverable artifacts and locations; bootstrap scope clarified to per-bundle
- §5.2: triadic rationale for bootstrap-first + per-step expectations
- §5.3: small-change exception
- §5.4: agile-process mapping with pipeline step numbers
- §7.3: stale artifact references fixed (RULES.md, RELEASE.md, PLAN.md → current locations)
- §7.8: new — self-coherence report format and placement rules
- Version aligned to cnos release lineage (was 1.3.0, now 3.13.0)
