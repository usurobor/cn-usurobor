# Project Audit – cn-agent v1.4.0

**Date:** 2026-02-04
**Branch:** `claude/repo-quality-audit-7Nwae`
**Auditor:** Independent automated audit (Claude Opus 4.5)
**Scope:** Full engineering quality — code, documentation, architecture, security, testing, CI, configuration, git practices, cross-file coherence.
**Prior audits:** v1.0.0 → v1.3.5 (same file, now replaced).

---

## 1. Executive Summary

cn-agent is a template repository for bootstrapping AI agent hubs on the git Coherence Network (git-CN). It contains a CLI tool (448 lines of JavaScript across two files), six skills, six mindsets, a protocol whitepaper (v2.0.3), a companion whitepaper (EXECUTABLE-COHERENCE, DRAFT v0.1.0), a manifesto, and supporting documentation. The project is primarily Markdown (33 of 42 files) with three JavaScript files and zero runtime dependencies.

**v1.4.0 improvements over v1.3.5:** The most critical issues from the v1.3.5 audit have been addressed. Tests exist (14 passing), CI runs on push, agent name input is sanitized, `package.json` metadata is complete, `git pull --ff-only` has a fallback, README no longer references `BOOTSTRAP.md`, DOJO katas use belt.sequence numbering, and daily-routine documents alternative cron runtimes. Seven of twenty-three findings from v1.3.5 are now resolved.

**Key remaining strengths:** Zero-dependency CLI, thorough whitepaper with honest implementation-status tracking, clean hub/template separation, working test suite, CI pipeline, good git governance, no secrets in repo.

**Key remaining weaknesses:** The "new name" code path bypasses the new `sanitizeName()` function (sanitization regression), `AGENTS.md` still references the removed `BOOTSTRAP.md`, README heading still shows `v1.2.0`, `.gitignore` is still fragile, the protocol-vs-implementation gap remains (9 features), CI only tests one Node version, and `experiments/` is still orphaned.

**Overall grade: A-** — up from B+ in v1.3.5. The testing, CI, and sanitization additions address the most impactful engineering gaps. The remaining issues are medium-to-low severity.

---

## 2. Repository Overview

| Metric | Value |
|--------|-------|
| Total tracked files | 42 |
| Markdown files | 33 |
| JavaScript files | 3 (`cli/index.js` 315 lines, `cli/sanitize.js` 26 lines, `test/cli.test.js` 107 lines) |
| PDF files | 1 (`docs/CN-WHITEPAPER-v2.0.3.pdf`, 435 KB) |
| JSON files | 1 (`package.json`) |
| YAML files | 1 (`.github/workflows/ci.yml`) |
| Runtime dependencies | 0 |
| Test files | 1 (14 tests, all passing) |
| CI/CD workflows | 1 (GitHub Actions) |
| Linting config | None |
| License | Apache 2.0 |

---

## 3. What Changed in v1.4.0

### 3.1 v1.3.5 Findings Resolved

| v1.3.5 Ref | Finding | Resolution |
|------------|---------|------------|
| H1 | Zero tests, zero CI/CD | **Resolved.** 14 tests in `test/cli.test.js` using Node's built-in `node:test` (zero dependencies). CI via `.github/workflows/ci.yml` on push to master and PRs. |
| H2 | Agent name input not sanitized | **Resolved.** `cli/sanitize.js` extracts sanitization into a testable module. Strips non-alphanumeric/hyphen chars, rejects empty/leading-hyphen/trailing-hyphen names. 10 test cases cover edge cases. |
| H4 | README references nonexistent `BOOTSTRAP.md` | **Resolved.** README.md no longer mentions `BOOTSTRAP.md`. (Note: `AGENTS.md` still does — see N2 below.) |
| M2 | `git pull --ff-only` no fallback | **Resolved.** Try/catch with user-friendly warning, suggestion to inspect/fix, and continues with existing template clone. `cli/index.js:134-143`. |
| M4 | `package.json` incomplete | **Resolved.** Added `repository`, `keywords`, `bugs`, `homepage` fields. Updated `description`. Added `test` script. Added `cli/sanitize.js` to `files` array. |
| L2 | DOJO kata numbering gap (03→13) | **Resolved.** Renumbered to belt.sequence format (1.1, 1.2, 1.3, 2.1). Full belt legend table with 7 levels. |
| L12 | daily-routine cron assumes specific runtime | **Resolved.** Added "Runtime Note" section with standard crontab and systemd timer alternatives. `skills/daily-routine/SKILL.md:110-127`. |

### 3.2 New Additions in v1.4.0

| Addition | Location | Notes |
|----------|----------|-------|
| Input sanitization module | `cli/sanitize.js` | 26 lines, exported `sanitizeName()` function |
| Test suite | `test/cli.test.js` | 14 tests: 4 CLI flag tests + 10 sanitizeName tests |
| CI pipeline | `.github/workflows/ci.yml` | GitHub Actions, Node 20, `npm test` |
| CN Manifesto | `docs/CN-MANIFESTO.md` | 136 lines, philosophical companion to whitepaper |
| Executable Coherence whitepaper | `docs/EXECUTABLE-COHERENCE.md` | 369 lines, DRAFT v0.1.0, CTB as skill language |

---

## 4. Documentation Quality

### 4.1 README.md — Grade: A-

**Strengths:**
- Four-path audience dispatch table remains effective.
- `BOOTSTRAP.md` references removed (was H4 in v1.3.5).
- Step-by-step setup with concrete commands.
- Clean repo structure table.

**Weaknesses:**
- Version in heading still says `v1.2.0` — now two major versions behind `package.json` (`v1.4.0`). This is the first thing a visitor sees.
- Setup guide assumes Ubuntu/root; no mention of other OS or non-root setups.
- Missing: badges (build status, version, license), contributing guidelines, link to CHANGELOG.

### 4.2 Whitepaper (docs/CN-WHITEPAPER.md) — Grade: A

Unchanged since v1.3.5. Well-structured with honest implementation status (§10). RFC 2119 keywords in normative appendix. Reference [3] Reddit URL slug may not resolve correctly.

### 4.3 CN-MANIFESTO.md (NEW) — Grade: A-

**Strengths:**
- Clean philosophical document grounding git-CN in the lineage of open-source infrastructure projects.
- Eight concrete principles, each with an engineering definition (not just aspirational language).
- Proper cross-references to whitepaper [1] and reference implementation [2].
- "The Work" section (§5) lists five concrete implementation steps.

**Weaknesses:**
- §5, step 1 lists `state/peers.json` — correct per protocol spec, but the actual implementation uses `state/peers.md`. Minor inconsistency between aspirational/normative language and current state.

### 4.4 EXECUTABLE-COHERENCE.md (NEW) — Grade: A-

**Strengths:**
- Solid companion whitepaper connecting CTB to cn-agent skill architecture.
- "At a glance" section provides quick orientation.
- Honest "Open Questions" section (§7) with five concrete gaps.
- Implementation path (§5.2) with six defined milestones.
- Correct Haskell analogy for pure effects-as-data architecture.

**Weaknesses:**
- DRAFT status — expected to evolve. No issues for a draft.
- Code blocks use 4-space indentation instead of fenced blocks (inconsistent with repo-wide convention but still valid Markdown).

### 4.5 GLOSSARY.md — Grade: A-

Unchanged since v1.3.5. 17 entries covering all key terms. Doc-local versioning note. Good ownership annotations.

### 4.6 DOJO.md — Grade: A-

**Improved:** Belt.sequence numbering with full legend table. Seven belt levels (White through Black).

**Remaining issue:** Kata files still use old numbering in their titles (Kata 01, Kata 02, Kata 13) — doesn't match DOJO's belt.sequence format (1.1, 1.2, 2.1). See N10.

### 4.7 CHANGELOG.md — Grade: B

Added v1.4.0 entry with `B+ | A− | A− | B+` grades. Still lacks detailed change notes per version — only one-line coherence summaries. A reader cannot reconstruct what actually changed from the changelog alone.

### 4.8 Skill Documentation — Grade: B+

**Improved:** daily-routine SKILL.md (v1.1.1) now documents cron runtime alternatives with standard crontab and systemd examples. Ownership & Schema sections remain clear.

**Remaining issues:**
- reflect SKILL.md is still 370 lines (longest by 3x).
- self-cohere and configure-agent still have no kata files.
- hello-world thread filename `yyyyddmmhhmmss` still puts day before month.

### 4.9 Mindsets — Grade: A-

Unchanged since v1.3.5. PERSONALITY.md is all placeholders (intentional for template). WRITING.md has instance-specific `sag` reference.

### 4.10 Spec Files — Grade: A-

AGENTS.md still references `BOOTSTRAP.md` on line 7: "If `BOOTSTRAP.md` exists, that's your birth certificate." This was removed from README but not from AGENTS.md. See N2.

### 4.11 skills/README.md — Grade: B

Version header says `v1.2.0` — stale. Lists all six skills correctly. The "Adding a Skill" section references `spec/HEARTBEAT.md` — a hub file that wouldn't exist in the template context.

---

## 5. Code Quality

### 5.1 CLI (`cli/index.js`) — 315 lines — Grade: B+

**Improvements over v1.3.5:**
- Agent name validation via imported `sanitizeName()` (`cli/index.js:153-157`).
- `git pull --ff-only` wrapped in try/catch with user-friendly fallback (`cli/index.js:134-143`).

**Remaining issues:**

| # | Severity | Issue | Location |
|---|----------|-------|----------|
| C1 | **HIGH** | "New name" path bypasses `sanitizeName()` — uses old unsanitized `toLowerCase().replace(/\s+/g, '-')` logic | `cli/index.js:202-210` |
| C2 | **MEDIUM** | Hardcoded workspace path `/root/.openclaw/workspace` — no env var override | `cli/index.js:50` |
| C3 | **MEDIUM** | Duplicate `gh api user` call — same API call on lines 120 and 161 | `cli/index.js:120,161` |
| C4 | **MEDIUM** | "New name" path still doesn't recalculate `hubRepo`/`hubUrl` | `cli/index.js:202-210` |
| C5 | **LOW** | `readline` interface not closed on error paths (lines 85, 102, 116, 122) | `cli/index.js` |
| C6 | **LOW** | ANSI colors unconditional — no `NO_COLOR` env var support | `cli/index.js:26-28` |
| C7 | **LOW** | `IDENTITY.md` still in `ocFiles` cleanup list — stale filename | `cli/index.js:270` |

**C1 Detail (HIGH — sanitization bypass):** The primary agent name path correctly uses `sanitizeName()` (line 153). But when the user chooses "New name" at the directory collision prompt (line 203), the code applies `newAgentName.toLowerCase().replace(/\s+/g, '-')` directly — the exact unsanitized logic that `sanitizeName()` was created to replace. A name like `../../etc` or `test;rm -rf /` would pass through on the "new name" path. This is a regression: the fix for v1.3.5 H2 created a code path that bypasses the fix.

**C4 Detail (MEDIUM — new-name variable staleness):** When the user chooses "New name", only `hubDir` is recalculated (line 209). But `hubRepo` (line 177), `hubUrl` (line 178), and `hubName` (line 158) still reference the original name. The `gh repo create` call (line 257) and the success message (line 295) would use the old name, not the new one.

### 5.2 Sanitize Module (`cli/sanitize.js`) — 26 lines — Grade: A-

Clean extraction of validation logic into a testable module.

**Minor issue:** The error message for leading/trailing hyphen rejection (lines 19-21) says "must contain at least one alphanumeric character" — misleading when the name does contain alphanumerics (e.g., `test-`). The actual issue is the leading/trailing hyphen.

### 5.3 Code Style

- No linter configuration (eslint, prettier).
- Consistent 2-space indentation.
- Good inline comments.
- `async` IIFE pattern at top level is idiomatic.
- `sanitize.js` is well-structured with clear input/output contract.

---

## 6. Testing & CI/CD — Grade: B-

### 6.1 Test Suite

| Aspect | Status |
|--------|--------|
| Test runner | Node built-in `node:test` (zero dependencies) |
| Test file | `test/cli.test.js` (107 lines) |
| Total tests | 14 (4 CLI flags + 10 sanitizeName) |
| Pass rate | 14/14 (100%) |
| Test time | ~413ms |

**Strengths:**
- Zero-dependency testing using Node's built-in test runner — consistent with the project's zero-dependency philosophy.
- `sanitizeName` has good edge case coverage: empty, null, special chars, mixed input, leading/trailing hyphens, collapse-to-empty, collapse-to-hyphen.
- CLI flag tests verify both long (`--help`) and short (`-h`) forms.

**Gaps:**
- No tests for the "new name" code path.
- No tests for the `run()` or `runCapture()` helper functions.
- No integration/end-to-end tests (workspace creation, directory scaffolding, symlink creation).
- No tests for the `ask()` function or interactive prompt logic.
- No code coverage measurement.
- No Markdown linting or link checking.

### 6.2 CI Pipeline

`.github/workflows/ci.yml` (18 lines):
- Triggers: push to `master`, PRs to `master`.
- Runs: `npm test` on `ubuntu-latest` with Node 20.
- Uses: `actions/checkout@v4`, `actions/setup-node@v4`.

**Issues:**

| # | Severity | Issue |
|---|----------|-------|
| CI1 | **MEDIUM** | Only tests Node 20 — doesn't test Node 18 (the minimum engine version in `package.json`). A feature that works on 20 but not on 18 would ship undetected. |
| CI2 | **LOW** | No matrix strategy — could easily test both 18 and 20. |
| CI3 | **LOW** | No caching (`actions/cache` for npm) — minor performance concern. |

---

## 7. Architecture & Design

### 7.1 Two-Repo Model — Grade: A

Unchanged. Hub/template separation is well-conceived and consistently described across CLI, self-cohere, AGENTS.md, README, and the whitepaper.

### 7.2 Skill Framework — Grade: B+

TERMS/INPUTS/EFFECTS remains a clean contract format. All six skills follow it. Ownership model (reflect owns reflections, daily-routine orchestrates) is clear.

**Gaps unchanged from v1.3.5:**
- No machine-readable skill discovery mechanism.
- No skill versioning convention (some have versions, others don't).
- No machine-readable skill dependency declaration.

### 7.3 Protocol vs Implementation Gap — Grade: B-

The nine unimplemented protocol features from whitepaper §10.2 remain unchanged:

| Protocol Feature | Status |
|-----------------|--------|
| `cn.json` manifest | Not implemented |
| `.gitattributes` with `merge=union` | Not implemented |
| `cn.thread.v1` schema | Not implemented |
| `state/peers.json` (JSON) | Not implemented (uses `peers.md`) |
| `threads/` at repo root | Not implemented (uses `state/threads/`) |
| Commit signing | Not implemented |
| Signature verification | Not implemented |
| Multiple `repo_urls` | Not implemented |
| Operational metrics (A.9) | Not implemented |

The honest acknowledgment in §10.3 remains valuable. The EXECUTABLE-COHERENCE whitepaper implicitly adds another row (executable skills via CTB — also not implemented). The gap is intentional and documented but worth tracking.

### 7.4 Experiments Directory — Grade: D

`experiments/external-surface-replies.md` remains a 212-line orphaned design document. No README, no cross-reference, no status indicator, instance-specific content (`author: 'usurobor'`).

---

## 8. Configuration & Dependencies

### 8.1 package.json — Grade: A-

**Resolved from v1.3.5:** Now includes `repository`, `keywords`, `bugs`, `homepage`, `test` script, updated `description`, `cli/sanitize.js` in `files` array.

**Remaining minor issues:**
- No `start` script needed — `"start": "node cli/index.js"` is identical to `"cn-agent-setup": "cli/index.js"` in `bin`. Redundant but harmless.
- No `engines.npm` specifier.

### 8.2 .gitignore — Grade: C+

Still only 5 entries:
```
memory/
media/
*.db
*.log
.DS_Store
```

**Still missing:**
- `node_modules/` — one accidental `npm install` pollutes the repo.
- `.env` / `.env.*` — prevents accidental secrets.
- `*.swp`, `*.swo`, `*~` — editor temp files.
- `.vscode/`, `.idea/` — IDE configurations.
- `coverage/` — for future test coverage.

---

## 9. Security

### 9.1 CLI Security — Grade: B

**Positive:**
- `spawn()` with array args throughout — no shell injection.
- No `eval()`, `Function()`, or dynamic `require()`.
- No external HTTP requests (uses git/gh as subprocesses).
- No secrets stored or transmitted.
- Primary agent name path now properly sanitized.

**Concerns:**
- **"New name" path bypasses sanitization (C1).** The fallback path at `cli/index.js:202-210` uses the old unsanitized logic. Directory traversal is possible via this code path.
- **`fs.rmSync` with `recursive: true, force: true`** at line 200 — called after user confirmation with abort as default.
- **`git push -u origin HEAD:main`** in fallback (line 262) — could push to existing branch on a repo the user doesn't control if name collides.

### 9.2 Spec Security Model — Grade: A-

Unchanged. SOUL.md, AGENTS.md, OPERATIONS.md maintain clear security boundaries.

### 9.3 Sensitive Files — Grade: A

No secrets, credentials, or API keys in the tracked tree.

---

## 10. Git Practices & Repo Hygiene

### 10.1 Commit History — Grade: A-

~193 total commits. Clean topic-branch workflow. Descriptive merge commits. Scoped prefixes (`docs:`, `fix:`, `chore:`, `merge:`) used consistently.

### 10.2 Large Files — Grade: B

One 435 KB PDF (`docs/CN-WHITEPAPER-v2.0.3.pdf`) tracked directly. Binary files don't diff in git and bloat history on updates.

---

## 11. Cross-File Coherence

### 11.1 Terminology Consistency — Grade: A-

Terms used consistently across the project:
- "hub" vs "template" — clean everywhere.
- "TSC", "α/β/γ", "CLP" — defined in GLOSSARY and used consistently.
- "TERMS/INPUTS/EFFECTS" — consistent across all skill files.

**Remaining inconsistencies:**
- `peers.md` (implementation) vs `peers.json` (whitepaper & manifesto spec).
- `state/threads/` (implementation) vs `threads/` (whitepaper spec).
- Thread file naming `yyyyddmmhhmmss` vs ISO 8601 `YYYY-MM-DD` used everywhere else.

### 11.2 Version Coherence — Grade: B-

| File | Version | Expected | Status |
|------|---------|----------|--------|
| `package.json` | v1.4.0 | — | Source of truth |
| `README.md` heading | v1.2.0 | v1.4.0 | **Stale** (2 versions behind) |
| `skills/README.md` | v1.2.0 | — | **Stale** |
| `CHANGELOG.md` latest | v1.4.0 | — | Current |
| `GLOSSARY.md` | v1.3.0 | — | Doc-local (OK) |
| `DOJO.md` | v1.2.2 | — | Doc-local (OK) |
| `CN-WHITEPAPER.md` | v2.0.3 | — | Protocol version (OK) |
| `EXECUTABLE-COHERENCE.md` | v0.1.0 | — | DRAFT (OK) |
| `CN-MANIFESTO.md` | v1.0.2 | — | Standalone (OK) |
| `daily-routine SKILL.md` | v1.1.1 | — | OK |
| `self-cohere SKILL.md` | v2.1.0 | — | OK |
| `configure-agent SKILL.md` | v1.2.0 | — | OK |

### 11.3 Kata Numbering Coherence — Grade: C

DOJO.md renumbered to belt.sequence (1.1, 1.2, 1.3, 2.1) but kata files still use old titles:
- `skills/hello-world/kata.md` → "Kata 01" (should be 1.1)
- `skills/reflect/kata.md` → "Kata 02" (should be 1.2)
- `skills/daily-routine/kata.md` → No number (OK)
- `skills/star-sync/kata.md` → "Kata 13" (should be 2.1)

### 11.4 BOOTSTRAP.md Reference Residue — Grade: B

README.md: Cleaned (v1.3.5 H4 resolved).
AGENTS.md line 7: **Still references BOOTSTRAP.md** — "If `BOOTSTRAP.md` exists, that's your birth certificate. Follow it, figure out who you are, then delete it."

This is the spec file agents read on every session. An agent encountering this instruction would look for a file that doesn't exist in the current flow.

### 11.5 configure-agent Hub README Template — Grade: B

`skills/configure-agent/SKILL.md:128-133` shows a README template for agent hubs that lists `skills/` and `mindsets/` as hub directories:

```markdown
## 📁 Hub Structure
| Path | What's there |
|------|--------------|
| `spec/` | Core identity |
| `state/` | Threads, peers |
| `skills/` | What I can do |
| `mindsets/` | How I think |
```

But `skills/` and `mindsets/` only exist in the template, not the hub. An agent following this template would create a misleading README.

---

## 12. Issues Found (Prioritized)

### HIGH

| # | Issue | Impact | Location |
|---|-------|--------|----------|
| N1 | **"New name" path bypasses `sanitizeName()`** | The sanitization fix (v1.3.5 H2) only covers the primary path. The fallback "new name" path at lines 202-210 still uses `toLowerCase().replace(/\s+/g, '-')`, allowing directory traversal and special characters. | `cli/index.js:202-210` |

### MEDIUM

| # | Issue | Impact | Location |
|---|-------|--------|----------|
| N2 | **AGENTS.md still references `BOOTSTRAP.md`** | Line 7 tells agents to look for a file the CLI no longer creates. This is the spec file read every session. | `spec/AGENTS.md:7` |
| N3 | **README version stale (`v1.2.0`)** | Now two versions behind v1.4.0. First impression suggests project is unmaintained. | `README.md:1` |
| N4 | **"New name" path doesn't recalculate variables** | `hubRepo`, `hubUrl`, `hubName` still reference old name after user picks new name. GitHub repo creation and success message use wrong values. | `cli/index.js:202-210` |
| N5 | **CI tests only Node 20** | `package.json` specifies `"engines": { "node": ">=18" }` but CI doesn't test Node 18. Breakage on the minimum version ships undetected. | `.github/workflows/ci.yml` |
| N6 | **Protocol vs implementation gap (9 features)** | Whitepaper §10.2 lists 9 specified-but-unbuilt features. Template doesn't conform to its own spec. Honestly documented. | Whitepaper §10.2 vs repo |
| N7 | **`.gitignore` incomplete** | Missing `node_modules/`, `.env*`, editor temps, IDE dirs. Fragile against accidental additions. | `.gitignore` |
| N8 | **`experiments/` uncontextualized** | 212-line orphaned design doc. No README, no cross-reference, no status. Instance-specific content in a template repo. | `experiments/` |
| N9 | **Hardcoded workspace path** | CLI only works on OpenClaw with root user. No env var override or `--workspace` flag. | `cli/index.js:50` |

### LOW

| # | Issue | Impact | Location |
|---|-------|--------|----------|
| N10 | Kata file titles use old numbering | DOJO renumbered to belt.sequence but kata files say "Kata 01", "Kata 02", "Kata 13". | `skills/*/kata.md` |
| N11 | `sanitize.js` misleading error message | Leading/trailing hyphen rejection says "must contain at least one alphanumeric character" — the name does, the issue is the position of the hyphen. | `cli/sanitize.js:19-21` |
| N12 | Missing katas for self-cohere and configure-agent | DOJO lists them as skills but they have no kata file. skills/README.md says katas SHOULD exist. | `skills/self-cohere/`, `skills/configure-agent/` |
| N13 | Duplicate `gh api user` call | Same API call on lines 120 and 161. Wastes a round-trip. | `cli/index.js:120,161` |
| N14 | `IDENTITY.md` in `ocFiles` cleanup list | Line 270 deletes `IDENTITY.md` — renamed to `PERSONALITY.md` long ago. Harmless but stale. | `cli/index.js:270` |
| N15 | ANSI colors unconditional / no `NO_COLOR` support | Colors not disabled when `NO_COLOR` env var is set. | `cli/index.js:26-28` |
| N16 | `readline` not closed on early exits | Minor resource leak on error paths (process exits anyway). | `cli/index.js:85,102,116,122` |
| N17 | `skills/README.md` version stale (`v1.2.0`) | — | `skills/README.md:1` |
| N18 | WRITING.md `sag` reference | Instance-specific (ElevenLabs TTS) in a template repo. | `mindsets/WRITING.md:24` |
| N19 | reflect SKILL.md length (370 lines) | 3x any other skill. Six cadence templates are structurally repetitive. | `skills/reflect/SKILL.md` |
| N20 | Thread file naming non-standard | `yyyyddmmhhmmss` puts day before month; rest of project uses `YYYY-MM-DD`. | `skills/hello-world/` |
| N21 | Coherence Walk duplicated verbatim | "Left, right, left, right" appears in 3 places. | reflect SKILL.md, GLOSSARY.md, reflect kata.md |
| N22 | PDF tracked directly in git | 435 KB binary doesn't diff. Bloats history on updates. | `docs/CN-WHITEPAPER-v2.0.3.pdf` |
| N23 | configure-agent README template lists hub dirs incorrectly | Lists `skills/` and `mindsets/` as hub directories; they only exist in template. | `skills/configure-agent/SKILL.md:128-133` |
| N24 | `state/` files in template repo | Template contains state files that conceptually belong in hubs. | `state/` |
| N25 | CHANGELOG lacks detailed change notes | Only one-line coherence summaries per version. | `CHANGELOG.md` |
| N26 | Contributor name casing | `usurobor` vs `Usurobor` in git history. | git config |

**Total: 1 HIGH, 8 MEDIUM, 16 LOW = 25 findings.**

---

## 13. Prior Audit Tracking

### v1.3.5 → v1.4.0 Resolution Matrix

| v1.3.5 Ref | Finding | v1.4.0 Status | v1.4.0 Ref |
|------------|---------|---------------|------------|
| H1 | Zero tests, zero CI/CD | **RESOLVED** | — |
| H2 | Agent name not sanitized | **PARTIALLY RESOLVED** (primary path fixed, "new name" path still bypasses) | N1 |
| H3 | Protocol vs implementation gap | **Open** | N6 |
| H4 | README references BOOTSTRAP.md | **RESOLVED** (README clean; AGENTS.md still has reference) | N2 |
| M1 | README version stale | **Open** (now worse: v1.2.0 vs v1.4.0) | N3 |
| M2 | git pull --ff-only no fallback | **RESOLVED** | — |
| M3 | .gitignore incomplete | **Open** | N7 |
| M4 | package.json incomplete | **RESOLVED** | — |
| M5 | reflect SKILL.md length | **Open** | N19 |
| M6 | Thread naming non-standard | **Open** | N20 |
| M7 | Hardcoded workspace path | **Open** | N9 |
| M8 | experiments/ uncontextualized | **Open** | N8 |
| M9 | "New name" path variable staleness | **Open** (and now also bypasses sanitize) | N1, N4 |
| L1 | Missing katas | **Open** | N12 |
| L2 | DOJO kata numbering | **RESOLVED** (DOJO fixed; kata files not updated) | N10 |
| L3 | WRITING.md sag reference | **Open** | N18 |
| L4 | Duplicate gh api user call | **Open** | N13 |
| L5 | NO_COLOR support | **Open** | N15 |
| L7 | Emoji in framework tables | **Open** (kept as acceptable) | — |
| L8 | PDF tracked in git | **Open** | N22 |
| L9 | Contributor name casing | **Open** | N26 |
| L10 | readline not closed on exits | **Open** | N16 |
| L11 | Coherence Walk duplication | **Open** | N21 |
| L13 | state/ files in template | **Open** | N24 |
| L14 | CHANGELOG detail | **Open** | N25 |
| L15 | IDENTITY.md in cleanup list | **Open** | N14 |

**Summary: 7 resolved, 2 partially resolved, 14 still open, 5 new = 25 total open.**

---

## 14. Coherence Assessment (TSC Axes)

### 14.1 α (PATTERN) — Structural Consistency — Grade: A-

The repo structure is clean and consistent:
- 5 spec files, 6 mindsets, 6 skills, 5 docs — all follow their respective formats.
- TERMS/INPUTS/EFFECTS in all SKILL.md files.
- New files (CN-MANIFESTO.md, EXECUTABLE-COHERENCE.md) follow established document conventions.
- Test file follows Node.js built-in test runner conventions.
- CI follows standard GitHub Actions patterns.

**Deductions:**
- Kata file numbering doesn't match DOJO's belt.sequence format.
- README version is stale.
- Thread file naming remains non-standard.

### 14.2 β (RELATION) — Alignment Between Parts — Grade: A-

Cross-file references are mostly accurate. Terminology is consistent. The hub/template separation is cleanly described everywhere. New documents (Manifesto, EXECUTABLE-COHERENCE) reference existing documents correctly.

**Deductions:**
- AGENTS.md still references BOOTSTRAP.md.
- configure-agent README template lists incorrect hub directories.
- "New name" path is internally inconsistent (bypasses the module it should use).
- Protocol spec vs implementation gap.

### 14.3 γ (EXIT/PROCESS) — Evolution Stability — Grade: A-

Significant forward motion from v1.3.5:
- 7 of 23 findings resolved (30% closure rate).
- All four HIGH findings from v1.3.5 addressed (though H2 partially).
- Clean commit history through ~193 commits.
- "Never self-merge" governance practiced.
- Tests and CI now provide a safety net for future evolution.

**Deductions:**
- 14 findings carried unchanged from v1.3.5.
- One new HIGH finding (sanitization bypass in "new name" path).
- Spec is still evolving faster than implementation.

### 14.4 Aggregate

```
C_Σ = (A- · A- · A-)^(1/3) ≈ A-
```

Up from B+ in v1.3.5. The testing, CI, and sanitization additions close the most impactful engineering gaps. The project now has a safety net for evolution.

---

## 15. Recommendations (Prioritized)

### Must Address

1. **Fix the "new name" path** (`cli/index.js:202-210`). Use `sanitizeName()` for the new agent name. Recalculate `hubName`, `hubRepo`, and `hubUrl` from the new name. This is both a security issue (sanitization bypass) and a correctness issue (wrong variables used downstream).

2. **Remove BOOTSTRAP.md reference from AGENTS.md** (line 7). The CLI no longer creates this file. Agents reading this spec on every session encounter a dead instruction.

3. **Update README version** in heading to `v1.4.0` or remove the version from the heading entirely (let `package.json` be the source of truth).

### Should Address

4. **Add Node 18 to CI matrix.** The engine minimum is `>=18` but CI only tests 20. A simple matrix strategy catches compatibility issues.

5. **Harden `.gitignore`** — add `node_modules/`, `.env*`, `*.swp`, `.vscode/`, `.idea/`.

6. **Update kata file titles** to match DOJO belt.sequence format (1.1, 1.2, 1.3, 2.1).

7. **Fix configure-agent README template** to not list `skills/` and `mindsets/` as hub directories.

8. **Fix sanitize.js error message** for leading/trailing hyphen — describe the actual issue.

9. **Contextualize `experiments/`** — add a README with status, or move to a branch, or remove.

### Nice to Have

10. Cache the `gh api user` result to avoid duplicate API call.
11. Remove `IDENTITY.md` from CLI cleanup list.
12. Add `NO_COLOR` env var support.
13. Add workspace path override (`CN_WORKSPACE` env var or `--workspace` flag).
14. Extract reflect cadence templates to reduce SKILL.md length.
15. Add katas for self-cohere and configure-agent.
16. Remove `sag` reference from WRITING.md.
17. Fix thread file naming to ISO 8601.
18. Add detailed change notes to CHANGELOG entries.
19. Consider Git LFS for the PDF or CI-generated PDFs.
20. Update `skills/README.md` version.

---

## 16. Scorecard

| Dimension | Grade | v1.3.5 | Delta | Notes |
|-----------|-------|--------|-------|-------|
| Documentation | A- | A- | = | New Manifesto + EXECUTABLE-COHERENCE add value; README version still stale |
| Code Quality | B | B- | ↑ | Sanitization added, ff-only fallback; "new name" path still buggy |
| Architecture | B+ | B+ | = | Hub/template solid; protocol gap unchanged |
| Testing & CI | B- | F | ↑↑ | From zero to 14 tests + CI — biggest improvement |
| Security | B | B | = | Primary path secured; "new name" bypass is new |
| Git Practices | A- | A- | = | Clean history, good governance |
| Configuration | A- | C+ | ↑ | package.json complete; .gitignore still fragile |
| Cross-file Coherence | B+ | A- | ↓ | AGENTS.md BOOTSTRAP ref, kata numbering mismatch, version staleness |

**Weighted Overall: A-** (up from B+)

---

## 17. What's Done Well

1. **Zero-dependency CLI** — ships exactly what it needs, no supply chain risk.
2. **Working test suite** — 14 tests using Node's built-in test runner. Zero test dependencies.
3. **CI pipeline** — automated testing on push and PR. Standard GitHub Actions.
4. **Input sanitization** — extracted into testable module with 10 edge-case tests.
5. **Whitepaper quality** — honest, well-structured, self-aware of its own projection failures.
6. **New companion documents** — Manifesto and EXECUTABLE-COHERENCE add strategic depth.
7. **Audit-driven improvement** — six iterations of self-assessment. 30% issue closure rate between v1.3.5 and v1.4.0.
8. **Git governance** — "never self-merge", descriptive merges, topic-branch workflow.
9. **TSC framework integration** — coherence is operationalized through reflect skill and measured in CHANGELOG.
10. **Hub/template separation** — clean, well-documented, consistently applied.
11. **Apache 2.0 license** — clear, permissive, standard.
12. **Honest spec-vs-impl tracking** — §10 doesn't pretend features exist when they don't.
