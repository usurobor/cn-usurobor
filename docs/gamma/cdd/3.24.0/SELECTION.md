## CDD Selection -- Post v3.22.0

**Date:** 2026-03-27
**Inputs read:** CHANGELOG TSC, encoding lag table, v3.22.0 post-release assessment

---

### 1. Observation

| Signal | Value |
|--------|-------|
| Baseline | v3.22.0 -- alpha A-, beta A, gamma A- |
| Weakest axis | alpha (A-) -- structural |
| Mechanical ratio | 0% (v3.22.0 cycle) |
| Review rounds | 1 (v3.22.0 cycle, target <=2) |
| MCI state | **Resumed** -- freeze lifted in v3.20.0 |
| Stale issues | 0 |
| Growing issues | 14 |
| P0 bugs | 2 (#64 filesystem probing, #119 setup stubs) |

### 2. Selection rules applied

| Priority | Rule | Result |
|----------|------|--------|
| 1 | P0 override | **Yes.** Two P0 bugs: #64 (v3.11.0), #119 (recent). |
| 2 | Operational infrastructure | Skipped -- P0 fires first. |
| 3 | Assessment commitment | v3.22.0 deferred selection -- no committed next MCA. |
| 4 | MCI freeze check | N/A -- freeze lifted. |

### 3. P0 triage

| Issue | Title | Severity | Age | Mitigation | Impact |
|-------|-------|----------|-----|------------|--------|
| #64 | Agent probes filesystem despite RC | P0 | v3.11.0 (old) | RC exists since v3.12.0 | Agent self-knowledge partially wrong |
| #119 | cn setup uses hardcoded stubs | P0 | recent | Setup works with stubs | **Every new hub starts with degraded SOUL/USER** |

**#119 selected.** Rationale:
- Immediate distribution gap: every new hub gets 10-line skeleton SOUL.md instead of the 149-line working contract. New agents start without identity invariants, conduct rules, autonomy defaults, or the correction protocol.
- Clear fix path: templates already exist in `src/agent/` (now at `src/agent/templates/SOUL.md` and `USER.md`). The package system (cnos.core) already distributes doctrine, mindsets, skills, and extensions. Adding templates as a sixth source category is a bounded extension.
- L7 leverage: the "templates" source category in the package system enables future template distribution (e.g., operator-facing configs, hub structure templates) without repeating the hardcoded-stub pattern.
- #64 is older but mitigated (RC provides correct self-knowledge at runtime). #119 affects every new hub immediately.

### 4. Selected gap

**Next MCA:** #119 -- P0: cn setup uses hardcoded stubs instead of distributed templates

**Incoherence:** The package system distributes 5 asset categories (doctrine, mindsets, skills, extensions, plus cn.package.json) but NOT the agent identity templates (SOUL.md, USER.md). The setup path hardcodes 10-line stubs that diverge from the 149-line distributed template. CDD S3.2 (one canonical source per fact) is violated: the inline stubs are a stale copy that never receives updates from the source of truth.

**What fails if skipped:** Every new hub starts with a degraded soul. The autonomy defaults, correction protocol, identity structure, conduct rules, and invariants in the distributed SOUL.md never reach new agents. Updates to the template (e.g., bef1cf7 added anti-patterns) never propagate. Trust gap: the system ships complete packages but incomplete agent identity.

### 5. Mode

**MCA** -- extend the package system with a templates source category; modify setup to read from installed package.

### 6. Acceptance criteria

| AC | Description |
|----|-------------|
| AC1 | `cn init` writes SOUL.md from installed cnos.core templates (not hardcoded stubs) |
| AC2 | `cn init` writes USER.md from installed cnos.core templates (not hardcoded stubs) |
| AC3 | Templates fall back to inline stubs if cnos.core package is not installed |
| AC4 | Templates are distributed via cnos.core package (`templates` source category) |
| AC5 | `cn build` copies templates from `src/agent/templates/` to package directory |

### 7. Design

**Architecture-evolution framing:**

- **Pressure:** Hardcoded stubs are a recurring pattern -- the same content is duplicated between `src/agent/` and inline strings in `cn_system.ml`. Updates to one never reach the other.
- **Challenged assumption:** "SOUL.md and USER.md are hub-local configuration, not package-distributed content." Partially wrong: they ARE hub-local (operators customize them), but their *initial content* should come from the distributed package.
- **Selected move:** Add `templates` as a 6th source category in the package system. This follows the existing pattern (doctrine, mindsets, skills, extensions) and uses the same build/install infrastructure.

**Implementation plan:**
1. Create `src/agent/templates/` with SOUL.md and USER.md
2. Add `"templates": ["SOUL.md", "USER.md"]` to `packages/cnos.core/cn.package.json`
3. Extend `source_decl` in `cn_build.ml` with `templates` field; handle in build, check, clean
4. In `cn_system.ml`, add `read_template` helper: reads from installed cnos.core `templates/` directory, falls back to inline stub
5. Replace inline SOUL.md/USER.md in `run_init` with `read_template` calls
6. Hub-name interpolation: SOUL.md template uses `_(set by operator)_` placeholders; `run_init` substitutes the hub name

### 8. Active skills

- eng/ocaml -- Result types, type safety, purity boundary
- eng/coding -- single source of truth, graceful degradation, no duplication
- eng/architecture-evolution -- package system extension as platform move

### 9. Deferred

- #64 (filesystem probing) -- next P0 after #119
- #117 (pre-push gate) -- process improvement, not P0
