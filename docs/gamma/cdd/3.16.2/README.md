# v3.16.2 — Two-membrane projection integrity

**Issue:** #106 — Two-membrane fix: presentation leak + self-knowledge probe
**Branch:** `claude/review-agent-runtime-docs-LyUlu`
**Mode:** MCA (bugfix — P0, internal markup on human surface)
**Prior version:** v3.16.1

---

## §0 Observation Inputs

### CHANGELOG TSC (v3.16.1 baseline)
α A / β A / γ A — Daemon retry limit + dead-letter (#28). All axes healthy.

### Encoding Lag
- 16 open issues, 3 stale (#73, #65, #67), 13 growing
- #106 added as **new P0** in v3.16.1 assessment
- MCI freeze active

### Doctor / Status
Not available (cn doctor #59 — partial impl, low lag).

### Last Assessment (v3.16.1)
- **Next MCA committed:** #106 (P0 override, §3.1)
- **First AC:** `<tool_calls>` markup stripped before human surface
- **MCI frozen:** yes

## §1 Selection

**Selected gap:** #106 — internal markup (`<tool_calls>`, `<cn:ops>`) leaks to human-facing Telegram surface; agent reads `.cn/cn.json` for version instead of using runtime identity.

**Selection rule:** §3.1 P0 override. User-facing coherence failure.

## §4 Gap

Two boundary violations with a shared root cause:

1. **Presentation membrane:** `is_control_plane_like` prefix blocklist had `<tool_call>` (singular) which does not match `<tool_calls>` (plural) — position 10 is `s` vs `>`. Mid-body XML blocks bypass the start-of-string check entirely.
2. **Self-knowledge membrane:** No explicit anti-probe instruction in Runtime Contract preamble. Sandbox denylist already blocks `.cn/` reads, but the agent could hallucinate the attempt.

## §5 Mode

**MCA** — code must change. The blocklist is wrong, the mid-body stripping is missing, and the anti-probe instruction is absent.

---

## Frozen Artifacts

| Artifact | File | Status |
|----------|------|--------|
| Snapshot manifest | `README.md` (this file) | complete |
| Self-coherence report | `SELF-COHERENCE.md` | complete |

## Scope

| File | Change |
|------|--------|
| `src/cmd/cn_output.ml` | `xml_prefixes` lifted to module level, 8 new variants, `strip_xml_pseudo_tools`, sanitize all candidates |
| `src/cmd/cn_runtime_contract.ml` | Anti-probe instruction in authority preamble |
| `test/cmd/cn_output_test.ml` | I4 expanded (22→), 9 new #106 tests |
| `docs/gamma/rules/INVARIANTS.md` | I5: Two-Membrane Projection Integrity |
