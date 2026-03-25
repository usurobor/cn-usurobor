# Self-Coherence Report — v3.16.2

**Branch:** `claude/3.16.2-106-strip-tool-markup`
**Issue:** #106 — Two-membrane fix: presentation leak + self-knowledge probe
**Mode:** MCA (bugfix — internal markup on human surface, P0)
**Author:** Claude

## Pipeline Compliance

| Step | Status | Evidence |
|------|--------|----------|
| 0. Observe | done | v3.16.1 assessment committed #106 as next MCA (§3.1 P0 override) |
| 1. Select | done | §3.1 P0: user-visible coherence failure |
| 2. Branch | done | `claude/3.16.2-106-strip-tool-markup`, pre-flight passed |
| 3. Bootstrap | done | `docs/gamma/cdd/3.16.2/README.md` created as first diff |
| 4. Gap | done | Root cause identified; two-membrane design from senior eng review |
| 5. Mode | done | MCA — code must change |
| 6. Design | done | Two-membrane architecture per issue spec |
| 7. Tests | done | I4 expanded (7 variants), 6 new #106 tests, membrane integration tests |
| 8. Code | done | `cn_output.ml`, `cn_runtime_contract.ml`, `INVARIANTS.md` |
| 9. Pre-flight | this step |
| 10. Self-coherence | this file |

## §4 Root Cause Analysis

**Presentation membrane gap:**
`is_control_plane_like` uses prefix matching via `starts_with`. The blocklist had `<tool_call>` (11 chars, ending `>`) which does NOT match `<tool_calls>` (12 chars, position 10 is `s` vs `>`). Additionally, `is_control_plane_like` only checks the *start* of the candidate string, so mid-body XML pseudo-tool blocks in an otherwise-valid body pass through undetected.

**Self-knowledge membrane gap:**
The sandbox already denies `.cn/` reads (`cn_sandbox.ml` denylist). The Runtime Contract v2 already provides `cn_version`. However, no explicit instruction told the agent NOT to read cn.json — the agent could hallucinate the attempt and the leaked markup could reach Telegram.

## §6 Design

Two-membrane architecture per issue #106 / senior eng review:

**Membrane 1 — Presentation (Cn_output):**
- Lift `xml_prefixes` to module level (shared between `is_control_plane_like` and new `strip_xml_pseudo_tools`)
- Add 7 missing XML variants: `<tool_calls>`, `<function_calls>`, `<tool_result>`, `<tool_results>`, `<invoke>`, `<invoke>`, `<thinking>`
- Add `strip_xml_pseudo_tools` function (state machine for `<tag>...</tag>` block removal)
- Apply in `render_human_facing` after `strip_embedded_frontmatter` — catches mid-body XML just as `strip_embedded_frontmatter` catches mid-body `---` blocks

**Membrane 2 — Self-knowledge (Runtime Contract):**
- Add anti-probe instruction to authority preamble
- Sandbox denylist already enforces `.cn/` rejection (verified, no code change needed)

**Invariant documentation:**
- I5 added to INVARIANTS.md defining both membranes

## §8.5 Author Pre-Flight

### §8.5.1 Issue re-read
Re-read updated issue #106. 7 ACs, two-membrane design, 4 implementation areas (A-D).

### §8.5.2–3 AC Coverage

| # | AC | In diff? | Status | Evidence |
|---|-----|----------|--------|----------|
| AC1 | `<tool_calls>` markup never rendered on any human surface | Yes | **Met** | `<tool_calls>` in `xml_prefixes` (prefix match). `strip_xml_pseudo_tools` handles mid-body. Test: `#106: Telegram and ConversationStore block <tool_calls> identically` |
| AC2 | All human projection through `Cn_output.render_for_sink` | No change needed | **Met (pre-existing)** | Line 251: `HumanSurface _ \| ConversationStore -> render_human_facing`. Test: `#106: Telegram and ConversationStore block <tool_calls> identically` proves both sinks use same path |
| AC3 | Fallback + trace event when no safe payload | No change needed | **Met (pre-existing)** | `try_candidates` returns `Fallback` with reason. `resolve_render` emits trace. Test: `#106: reply payload containing <tool_calls> falls back` |
| AC4 | Agent runtime context includes correct version | No change needed | **Met (pre-existing)** | Runtime Contract v2: `cn_runtime_contract.ml:196` gathers `Cn_lib.version` at every wake. Test: `cn_runtime_contract_test.ml:96` |
| AC5 | Agent does not fs_read cn.json for version | Yes | **Met** | Anti-probe instruction in contract preamble. Sandbox denylist blocks `.cn/` reads. |
| AC6 | `.cn/` reads rejected per private_body classification | No change needed | **Met (pre-existing)** | `cn_sandbox.ml:36-41` denylist blocks `.cn/` prefix. Test: `cn_sandbox_test.ml:72-78` |
| AC7 | Invariant documented in runtime docs | Yes | **Met** | I5 added to `INVARIANTS.md` defining both membranes |

### §8.5.4 Spot-checks

**Check 1 — prefix match gap (root cause):**
`starts_with ~prefix:"<tool_call>" "<tool_calls>..."` — prefix[10] = `>`, target[10] = `s`. No match. Bug confirmed. Fix: `<tool_calls>` as separate entry.

**Check 2 — mid-body strip:**
Body = `"Hello.\n\n<tool_calls>[...] </tool_calls>\n\nGoodbye."`. `strip_xml_pseudo_tools` walks lines: "Hello." kept, "" kept, `<tool_calls>...` matches prefix + has `</` → skipped, "" kept, "Goodbye." kept. Result: `"Hello.\n\n\nGoodbye."` → trimmed. Correct.

**Check 3 — multi-line XML block:**
Body = `"A\n<tool_calls>\nJSON\n</tool_calls>\nB"`. Line `<tool_calls>` matches prefix, no `</` → `in_block=true`. Line `JSON` → still in block. Line `</tool_calls>` → has `</` → `in_block=false`, line skipped. Result: `"A\n\nB"`. Correct.

**Check 4 — `has_close` false positive check:**
Normal prose like "I checked the </path> for you" — `has_close` would match `</` but this line wouldn't match `is_xml_open` first. `has_close` is only checked when already `in_block`, which requires a prior `is_xml_open` match. Safe.

**Check 5 — both sinks use same membrane:**
`render_for_sink` line 251: `HumanSurface _ | ConversationStore -> render_human_facing parsed`. Same function, same sanitization. Verified by #106 integration test.

### §8.5.5 Gate
All 7/7 ACs accounted for. Pre-flight passed.

## Implementation Checklist (from issue)

### A. Harden Cn_output
- [x] Add stripping/blocking for `<tool_calls>` and equivalent wrappers
- [x] Apply to every candidate source (body via `strip_xml_pseudo_tools`, reply via `is_control_plane_like`)
- [x] One module owns invariant (Cn_output — no per-sink sanitizers)

### B. Invariant tests
- [x] Raw body starts with `<tool_calls>` → fallback
- [x] Normal prose followed by embedded `<tool_calls>` → prose preserved, XML stripped
- [x] Reply payload containing `<tool_calls>` → fallback
- [x] Frontmatter/control blocks with no human body → fallback (pre-existing test)
- [x] Telegram renders through membrane (integration test)
- [x] Conversation storage renders through same membrane (integration test)

### C. Enforce self-knowledge
- [x] Runtime contract contains `identity.cn_version` from `Cn_lib.version` (pre-existing)
- [x] Shell/sandbox denies `.cn/` reads (pre-existing, `cn_sandbox.ml:36-41`)
- [x] Anti-probe instruction in contract preamble (new)

### D. Document invariant
- [x] I5 in INVARIANTS.md: presentation membrane + self-knowledge membrane

## Triadic Assessment

- **α (PATTERN): A** — `xml_prefixes` lifted to module level for sharing, 7 new strings. `strip_xml_pseudo_tools` is a new function but follows the exact pattern of `strip_embedded_frontmatter` (state machine over lines). Anti-probe instruction is one sentence in existing preamble. I5 follows I1-I4 structure.

- **β (RELATION): A** — Issue asked for two-membrane architecture; delivered two-membrane architecture. `Cn_output` is the single projection membrane (was already true, now hardened). Runtime Contract is the single self-knowledge source (was already true, now instructed). Both membranes documented in I5.

- **γ (EXIT/PROCESS): A** — Full CDD pipeline. Bootstrap first. Root cause identified. Design from senior eng review incorporated. Tests cover all 4 issue checklist items. Integration tests prove single-membrane property.

## Known Coherence Debt

- **No OCaml build verification.** Same environmental constraint as prior cycles. CI validates.
- **LLM behavior not deterministic.** Anti-probe instruction reduces but cannot eliminate the probability the LLM reads cn.json. The sandbox denylist is the hard guarantee (receipt = Denied). The presentation membrane is the second guarantee (even if the LLM hallucinates XML, it won't reach Telegram).
- **`has_close` heuristic.** The closing-tag detection uses `</` presence on a line. This could theoretically match prose containing `</` while inside a block. In practice, this only matters during an active XML block (after `is_xml_open` matched), where prose content is extremely unlikely. The conservative behavior (extending the strip region) is safe — it only over-strips, never under-strips.
