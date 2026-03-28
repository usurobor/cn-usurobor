## Post-Release Assessment — v3.24.0

### 1. Coherence Measurement

- **Baseline:** v3.22.0 — α A-, β A, γ A-
- **This release:** v3.24.0 — α A, β A, γ A-
- **Delta:**
  - α improved (A- → A) — templates follow exact structural pattern of existing 5 content classes. `source_decl` gains one field. `build_one`, `check_one`, `clean_package_dir` each gain one branch. `copy_source` routes templates through existing individual-file path (same as mindsets). `read_template` returns `(string, string) result` — three cases: Ok content, Error "not installed", Error "not found". No new abstraction, pure extension.
  - β held (A) — full pipeline aligned: `src/agent/templates/` → `cn build` → `packages/cnos.core/templates/` → `cn deps restore` → `.cn/vendor/packages/cnos.core@<ver>/templates/` → `read_template` → `spec/SOUL.md`. `run_init` writes templates AFTER `setup_assets` (not before), ensuring package installed before reading. `run_setup` only populates missing files. Source and package output byte-identical (md5sum verified in review).
  - γ held (A-) — 1 review round (target: ≤2), 1 mechanical finding (stale cross-ref in SETUP-INSTALLER.md), fixed in R2. Clean cycle. Rebased onto 3.23.0 between rounds.
- **Coherence contract closed?** Yes. All 5 ACs met:
  - AC1: `run_init` reads SOUL.md from installed cnos.core templates (L734)
  - AC2: `run_init` reads USER.md from installed cnos.core templates (L760)
  - AC3: Fallback to inline stubs on `read_template` Error (match branch)
  - AC4: `cn.package.json` declares `"templates": ["SOUL.md", "USER.md"]`
  - AC5: `cn build` copies templates via `copy_source ~category:"templates"` (individual file mode)

### 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #119 | P0: cn setup uses hardcoded stubs | bug | converged | shipped | **none** (all 5 ACs met) |
| #64 | P0: agent probes filesystem despite RC | bug | bug report | not started | **growing** |
| #74 | Rethink logs structure (P0) | process | issue spec | not started | **growing** |
| #117 | Pre-push build/test gate | process | converged | shipped (3.23.0) | **none** |
| #59 | cn doctor — deep validation | feature | partial design | partially addressed | **low** |
| #68 | Agent self-diagnostics | feature | issue spec | not started | **growing** |
| #84 | CA mindset reflection requirements | feature | issue spec | not started | **growing** |
| #79 | Projection surfaces | feature | issue spec | not started | **growing** |
| #94 | cn cdd: mechanize CDD invariants | feature | issue spec | not started | **growing** |
| #100 | Memory as first-class capability | feature | issue spec | not started | **growing** |
| #96 | Docs taxonomy alignment | process | issue spec | not started | **growing** |
| #101 | Normalize skill corpus | process | issue spec | not started | **growing** |
| #20 | Eliminate silent failures in daemon | bug | issue spec | not started | **growing** |
| #43 | No interrupt mechanism | feature | issue spec | not started | **growing** |
| #124 | Agent asks permission despite autonomy defaults | bug | issue spec | not started | **growing** |

**MCI/MCA balance:** MCI remains resumed. #119 shipped, #117 shipped (3.23.0). Net: 2 issues closed since last assessment. 1 P0 remains (#64). Growing backlog stable at ~12 issues — no new stale.

### 3. Process Learning

**What went right:**

1. **Clean L7 execution.** Templates as content class extends the package system platform — future template distribution (hub configs, role templates) reuses the same infrastructure with zero new code. The "explicit vs generic" rationale in PACKAGE-SYSTEM.md with documented sunset threshold ("7th or 8th class") is the right call at N=6.

2. **Review skill patch shipped in-band.** Unicode hygiene check (§2.1.3, checklist P2.9) was patched into the review skill as part of this PR — an immediate MCA from prior friction (PR #128 was closed due to Unicode false-positive). Process fix travels with the feature.

3. **PACKAGE-SYSTEM.md as architecture doc.** Content class taxonomy, pipeline diagram, explicit-vs-generic rationale, tradeoff tables. This doc earns its weight — it answers "why templates and not something else?" and "when to go generic?" for future contributors.

**What went wrong:**

1. **3.23.0 post-release assessment missing.** CDD §9.11 gate: previous release must have assessment before tagging. v3.23.0 had no CDD bundle or assessment. v3.24.0 was tagged without this gate being satisfied. Process debt — not blocking, but the gate wasn't enforced.

2. **Branch forked before 3.23.0.** Required a rebase between R1 and R2. Not a process failure (forks happen), but the VERSION showed 3.22.0→3.24.0 which could confuse — the diff looked like it skipped 3.23.0. Cosmetic, not structural.

**Skill patches:**
- Unicode hygiene added to review skill §2.1.3 and checklist P2.9 (shipped in this PR)
- No additional patches needed

**Active skill re-evaluation:**

| Finding | Active skill | Would skill have prevented it? | Assessment |
|---------|-------------|-------------------------------|------------|
| F1 (stale cross-ref SETUP-INSTALLER.md) | cdd/review §2.2.5 | Yes — "if files move, grep for old paths" | Mechanical finding caught in R1. Review skill worked. Author missed the grep. |

### 4. Review Quality

**PRs this cycle:** 2 (PR #128 closed/superseded, PR #129 merged)
**Review rounds:** 2 (R1 request changes, R2 approved) — target: ≤2 — **PASSED**
**Superseded PRs:** 1 (PR #128, non-compliant branch name) — target: 0 — **MISSED**
**Finding breakdown:** 1 mechanical / 0 judgment / 1 total
**Mechanical ratio:** 100% (1/1) — threshold: 20% — technically **exceeded**, but N=1 makes this meaningless
**Action:** No process issue filed — single mechanical finding on a single-finding cycle is not systemic. The stale-ref grep (§2.2.5) already exists in the review skill; the author just didn't run it pre-submit.

### 4a. CDD Self-Coherence

- **CDD α:** 4/4 — All required artifacts present: SELECTION.md, README.md, SELF-COHERENCE.md, PLAN.md, POST-RELEASE-ASSESSMENT.md. CHANGELOG TSC entry added.
- **CDD β:** 4/4 — Surfaces agree. Self-coherence scores (α A, β A, γ A-) match assessment. PR body, CDD artifacts, and CHANGELOG coherent.
- **CDD γ:** 3/4 — 2 review rounds (within target), 1 superseded PR (missed target). §9.11 gate not enforced (3.23.0 assessment missing before 3.24.0 tag). Deducted 1 point.
- **Weakest axis:** γ
- **Action:** 3.23.0 assessment gap noted as process debt. Superseded PR was due to branch naming non-compliance from Claude Code — not a recurring pattern (branch format was already enforced by CDD §2.1).

### 5. Next Move

**Next MCA:** #64 — P0: agent probes filesystem despite Runtime Contract
**Owner:** sigma
**Branch:** pending selection
**First AC:** TBD by selection
**MCI frozen until shipped?** No — freeze remains lifted.
**Rationale:** Last remaining P0 bug. #119 and #117 now shipped. #64 is the oldest open P0 (v3.11.0). RC exists since v3.12.0 providing mitigation, but the agent still probes paths it shouldn't. Selection function §1: P0 override fires.

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - #119 closed (all 5 ACs met)
  - CHANGELOG 3.24.0 TSC entry (3e1b22e)
  - GH release created (https://github.com/usurobor/cnos/releases/tag/3.24.0)
  - Unicode hygiene patch shipped in-band (review skill §2.1.3, checklist P2.9)
  - Stale cross-ref fixed (SETUP-INSTALLER.md, R2)
- Deferred outputs committed: yes
  - 3.23.0 assessment gap: process debt, not blocking
  - #64 P0: next cycle
