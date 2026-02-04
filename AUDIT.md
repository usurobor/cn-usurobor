# Project Audit – cn-agent v1.3.3

**Date:** 2026-02-04
**Branch:** `claude/project-audit-review-kdE3K`
**Scope:** Full audit of design, code, documentation, and cross-file coherence.
**Prior audits:** v1.0.0, v1.2.1, v1.3.2 (same file, now replaced).

---

## 1. Executive Summary

cn-agent is a **template repository** for bootstrapping AI agent hubs on the git Coherence Network (git-CN). Since the v1.0.0 audit, the project has undergone significant structural improvements:

- **Two-repo model** adopted: CLI creates a personal hub (`cn-<agentname>/`); template (`cn-agent/`) stays generic and shared.
- **COHERENCE.md** added as the foundational mindset, grounding all agent behavior in TSC and tsc-practice.
- **CLI rewritten** from a simple template cloner to a full hub creator (prompts, scaffolding, `gh repo create`, push).
- **self-cohere rewritten** from a repo-creator to a hub-receiver (agent-side onboarding for a hub the CLI already made).
- **README rewritten** with 4-path audience dispatch.
- **Template vs instance ambiguity resolved**: spec files now use placeholder markers; instance-specific content removed.
- **Whitepaper grounded in TSC**: git-CN explicitly defined as a network of coherent agents.

**Overall assessment:** The project has evolved significantly since v1.2.1. Three releases (v1.3.0–v1.3.2) landed while the whitepaper was being iterated to v2.0.3. The reflect skill is the most architecturally significant addition — it operationalizes TSC from a measurement framework into a daily practice. The glossary has expanded substantially (6 new entries). ENGINEERING.md gained two important governance principles. The whitepaper (on its own branch) has converged to v2.0.3 with all previously-flagged contradictions resolved.

Since v1.3.2, three significant merges landed on master: reflect/daily-routine ownership resolution (sigma/reflect-ownership), glossary and docs alignment (sigma/truthify-docs), and the whitepaper v2.0.3 merge. All three HIGH findings from v1.3.2 are now resolved. The main remaining issues are: specification drift from new concepts (`memory/`, `state/practice/`) without whitepaper coverage, stale version numbers across files, and the same package.json/test/experiment gaps from v1.0.0.

---

## 2. Prior Audit Resolution

### 2.1 v1.0.0 Findings

Tracking what was fixed from the original audit:

| # | v1.0.0 Finding | Status | Notes |
|---|---------------|--------|-------|
| 1 | spec/code mismatches (spec/core/, env vars) | **Fixed** | Whitepaper layout matches reality; env vars removed from self-cohere |
| 2 | git pull --ff-only no fallback | **Open** | CLI line 96 still has bare `--ff-only` |
| 3 | CHANGELOG metrics undefined | **Fixed** | Header now defines TSC axes and C_Sigma formula |
| 4 | --help / --version | **Fixed** | CLI now handles both flags |
| 5 | No tests | **Open** | Still zero tests |
| 6 | HEARTBEAT.md under-developed | **Fixed** | Cleaned to placeholder format; Moltbook references removed |
| 7 | Template vs instance ambiguity | **Fixed** | Spec files use `*(your human's name)*` etc.; IDENTITY.md renamed to PERSONALITY.md |
| 8 | package.json gaps | **Partially fixed** | description field exists; still missing repository, keywords, bugs, homepage |
| 9 | Missing katas for self-cohere, configure-agent | **Open** | Still no katas for these skills |
| 10 | experiments/ uncontextualized | **Open** | Still no cross-reference or README |

### 2.2 v1.2.1 Findings

| # | v1.2.1 Finding | Status | Notes |
|---|---------------|--------|-------|
| 4.1 | Whitepaper two-repo contradictions | **Fixed** | Whitepaper v2.0.3 resolves all 4 items (§9 fork→CLI, §6 PRs→transport convenience, §10 PRs→push branch, §5.1 version→protocol minimum) |
| 4.1 | Glossary stale (IDENTITY, dojo/) | **Fixed** | sigma/truthify-docs: IDENTITY→PERSONALITY fixed, Kata says `skills/<name>/kata.md`, COHERENCE in Mindset, cn-agent uses two-repo model, Thread says `threads/` |
| 4.2 | BOOTSTRAP.md vs symlinks | **Superseded** | Master has moved past this; symlinks approach adopted |
| 4.3 | package.json stale | **Open** | Still stale description; still missing repository, keywords, bugs, homepage |
| 4.4 | skills/README.md version | **Open** | Still says v1.1.0 (should be v1.3.2) |
| 4.5 | state/ files in template | **Open** | |
| 4.6 | git pull --ff-only | **Open** | |
| 4.7 | WRITING.md sag reference | **Open** | |
| 4.8 | experiments/ uncontextualized | **Open** | |
| 4.9 | No tests | **Open** | |
| 4.10 | Missing katas | **Partially fixed** | reflect kata added (kata 02); self-cohere/configure-agent still missing |

---

## 3. What's Done Well

### 3.0 Whitepaper v2.0.3 (on `claude/whitepaper-v2-kdE3K`)

The whitepaper has been iterated through a Bohm dialog process from v2.0.0 to v2.0.3. Key improvements:

- **"At a glance" section** (§0.0): First-contact reader gets what/get/implement in 60 seconds.
- **Projection-robust placeholders**: `{thread_id}` / `{entry_id}` throughout (survives HTML-stripping renderers).
- **A.4 anchor-line hardening**: Split into A.4.1–A.4.3 with escaped representation (`&lt;a id="..."&gt;`) for renderers that strip HTML tags — the document is self-aware of its own most likely projection failure mode.
- **Revision note removed**: History belongs in Git, not the document's front door.
- **All v1.2.1 audit contradictions resolved**: §9 uses CLI, §6/§7 frame PRs as transport convenience, §10 non-normative and time-bound, conclusion explicitly maps four guarantees.
- **Substrate/projection principle applied to itself**: cross-references as plain §N text (no anchor links), `text` language tags on code fences, `Git` as proper noun, `git-CN` as protocol name.

### 3.1 reflect skill (NEW — `skills/reflect/`)

The most architecturally significant addition since v1.2.1. Turns TSC from a measurement framework into an operational practice.

Strengths:
- Proper TERMS/INPUTS/EFFECTS structure
- A-F scoring with honest framing ("the score is for tracking, not performance review")
- Six cadences (daily → yearly) with templates that scale appropriately
- Coherence Walk concept well-articulated (score → reflect → invest in weaker axis)
- Mindset Migration section with clear promotion criteria (repeated 3+, confirmed, stable, transferable)
- References to TSC Core v3.1.0 and CLP v1.1.2

### 3.2 daily-routine skill (NEW — `skills/daily-routine/`)

Fills a real gap: state management across days. Clean SKILL.md with directory structure, commit conventions, and EOD cron setup.

### 3.3 GLOSSARY.md expansion

Six new entries: CLP, Coherent Agent (CA), TSC, α/β/γ, Coherent Reflection, Coherence Walk. The CLP entry captures the 5-step loop cleanly. The TSC entry references the formal spec. The α/β/γ entry explains algebraic independence.

### 3.4 ENGINEERING.md governance additions

Two new principles:
- **"Assume good intent"**: Treat mismatches as snapshot/coordination issues first. Good hygiene for a multi-agent repo.
- **"Never self-merge"**: Author of a change should not merge their own work. Clear, enforceable, applies to agents and humans.

### 3.5 configure-agent timezone requirement

Timezone changed from optional hint to required field. Makes sense — daily-routine needs it for cron. Correctly motivated by a concrete downstream dependency.

(Items 3.6–3.11 below are carried from v1.2.1 — COHERENCE.md, two-repo model, CLI rewrite, README dispatch, whitepaper grounding, spec cleanup — all still hold.)

### 3.6 COHERENCE.md (mindsets/COHERENCE.md)

The strongest new addition to the project. Key qualities:

- **Correct definition of coherence**: "Wholeness that can be *articulated* as parts, among other articulations. The whole comes first." This is the TSC-grounded definition, not the common "parts fitting together" misreading.
- **Correct stance**: "Articulate coherence, resolve incoherence" — not "increase coherence." Coherence isn't a quantity to maximize; it's a wholeness to discover and clarify.
- **Self-referential measurement**: "TSC measures itself. If the framework is incoherent, the scores say so."
- **Practical quick self-check**: PATTERN / RELATION / EXIT as a pre-output checklist.
- **Links to source**: TSC and tsc-practice repos referenced directly.

### 3.7 Two-Repo Model

The hub/template separation is well-defined and consistently described across CLI, self-cohere, README, and AGENTS.md:

- **Hub** (`cn-<agentname>/`): personal identity, specs, state, threads
- **Template** (`cn-agent/`): shared skills, mindsets, docs

The CLI creates the hub. Self-cohere wires the agent to it. The template updates via `git pull`. Personal files can't be clobbered by template updates.

### 3.8 CLI Rewrite (cli/index.js)

The CLI is now a proper interactive tool:

- Prompts for agent name, GitHub owner (inferred via `gh api user`), visibility
- Scaffolds hub directory with spec files, state dirs, BOOTSTRAP.md, README.md
- Creates GitHub repo via `gh repo create` with fallback to manual remote
- Prints the "Cohere as <hub-url>" cue
- Zero runtime dependencies; `spawn()` with array args (no shell injection)
- `--help` and `--version` flags

### 3.9 README 4-Path Dispatch

The README correctly identifies four audiences and routes each:

- Human without agent: full setup guide (DigitalOcean + OpenClaw)
- Human with agent: CLI instructions + cue
- Agent told to cohere: step-by-step hub wiring
- Agent exploring: template orientation

The navigation table at top is clean and uses emoji sparingly for visual scanning.

### 3.10 Whitepaper TSC Grounding

The whitepaper now explicitly defines git-CN as a network of **coherent agents** following TSC. Key additions:

- §0 defines coherence as "wholeness articulated across three axes"
- §5 establishes agents that "articulate coherence and resolve incoherence"
- §5.1 lists COHERENCE.md in the mindsets interpretation
- §8.3 grounds reputation metrics in TSC axes (pattern, relation, process)

### 3.11 Spec File Cleanup

All spec files now use placeholder markers suitable for a template:

- SOUL.md: generic behavioral contract, no instance names
- USER.md: `*(your human's name)*`, `*(their timezone)*`, etc.
- PERSONALITY.md: `*(your agent's name)*`, `*(what kind of entity...)*`
- HEARTBEAT.md: example-format comments, no Moltbook references
- TOOLS.md: examples in code blocks, actual fields empty

---

## 4. Issues Found

### 4.1 ~~HIGH~~ → PARTIALLY RESOLVED: Specification Drift — New Concepts Without Spec Coverage

The v1.3.x cycle introduced three new directory concepts. **Ownership conflict resolved** by sigma/reflect-ownership: reflect owns `state/reflections/` schema, daily-routine orchestrates but delegates to reflect. Both SKILL.md files now have explicit "Ownership & Schema" sections. Glossary now includes `memory/`, `state/reflections/`, `state/practice/`.

**Still open:** `memory/` and `state/practice/` have no coverage in the whitepaper's §4.1 repo layout or protocol spec. These are cn-agent conventions (daily-routine labels them as such) but are not yet documented as protocol-level or explicitly scoped as implementation-specific.

### 4.2 ~~HIGH~~ → RESOLVED: reflect Kata Does Not Exercise the Framework

**Fixed** by sigma/reflect-ownership. The reflect kata (kata 02) now uses the canonical α/β/γ framework: PATTERN/RELATION/EXIT scores, Σ summary, → Next. EXIT criteria require the real template structure. The simplified "What I did / What I noticed / Raw takeaway" warmup was removed.

### 4.3 ~~HIGH~~ → RESOLVED: Glossary Stale Entries (Carried Over)

**Fixed** by sigma/truthify-docs. All four stale entries addressed:

- **Mindset**: Now lists COHERENCE.md and ENGINEERING.md (not IDENTITY).
- **Kata**: Now says `skills/<skill-name>/kata.md` (not `dojo/`).
- **cn-agent**: Now describes two-repo model (not "fork or import").
- **Thread**: Now says `threads/` with legacy note about `state/threads/`.

### 4.4 MEDIUM: reflect SKILL.md Length and Template Duplication

352 lines for a single SKILL.md. The six cadence templates (daily/weekly/monthly/quarterly/half/yearly) follow the same α/β/γ → Σ → Next pattern with minor scope changes. Each template is 15–25 lines of near-identical structure. Consider:
- Extracting templates to a separate `skills/reflect/templates/` directory
- Or defining a single parameterized template in the SKILL.md and noting what changes per cadence

This is the longest skill by far. The TERMS/INPUTS/EFFECTS section (the actual specification) is clean; the templates are operational guidance that could live elsewhere.

### 4.5 MEDIUM: Emoji in reflect Framework Table

The reflect SKILL.md framework table uses 🧩 🤝 🚪 emojis for PATTERN/RELATION/EXIT. The cadence templates repeat these (e.g., `## α — PATTERN 🧩: [A-F]`). The glossary entries for α/β/γ also use them.

This is inconsistent with the whitepaper's projection-robustness principle. The α/β/γ labels are sufficient. Some renderers, terminals, and parsers handle emoji inconsistently (width, encoding, display). The emojis are decorative, not functional — they don't carry information that the text labels don't already carry.

### 4.6 MEDIUM: Version Numbers Still Inconsistent

| File | Current Version | Should Be |
|------|----------------|-----------|
| `skills/README.md` | v1.1.0 | v1.3.2 |
| `docs/DOJO.md` | v1.2.0 | v1.3.2 |
| `docs/GLOSSARY.md` | v1.2.0 | v1.3.2 |
| `configure-agent/SKILL.md` header | v1.1.0 | v1.2.0 (per its own CHANGELOG) |

Three releases shipped (v1.3.0–v1.3.2) but most file headers still reference old versions.

### 4.7 MEDIUM: DOJO.md Kata Gap (01 → 02 → 13)

DOJO.md lists kata 01, 02, and 13. The gap from 02 to 13 is unexplained. Either:
- There are planned katas 03–12 not yet written (state this)
- The numbering is intentional (explain the scheme — e.g., 01–09 = white belt, 10–19 = orange belt)
- It's arbitrary (renumber)

A first-contact reader will wonder what happened to katas 03–12.

### 4.8 MEDIUM: configure-agent SKILL.md Version Mismatch

The header says `v1.1.0` but the CHANGELOG at the bottom of the file lists v1.2.0 changes (timezone now required). The header should be v1.2.0.

### 4.9 MEDIUM: daily-routine Cron Assumes Specific Runtime

The daily-routine SKILL.md and kata.md use a JavaScript object syntax for cron setup:
```javascript
{ name: "daily-routine-eod", schedule: { kind: "cron", expr: "30 23 * * *", tz: "..." }, ... }
```

This assumes a specific runtime (likely Claude Code's cron tool). The SKILL.md doesn't state this assumption. An agent on a different runtime (standard crontab, systemd timer, etc.) would need to translate. Either:
- Add a TERMS entry: "Agent has access to a cron tool that accepts this JSON format"
- Or provide the crontab equivalent alongside

### 4.10 MEDIUM: "Coherence Walk" Metaphor Duplication

The "left, right, left, right — like walking, you shift weight to stay upright" metaphor appears verbatim in three places:
1. `skills/reflect/SKILL.md` — Coherence Walk section
2. `docs/GLOSSARY.md` — Coherence Walk entry
3. Implied in reflect cadence templates (every `→ Next` section)

Duplication is not the issue — the issue is that it reads as a meme/slogan rather than a specification. The actual logic ("if α < β, invest in PATTERN; if β < α, invest in RELATION") is precise and useful. The walking metaphor wrapping it is decorative.

### 4.11 LOW: package.json Stale and Incomplete (Carried Over)

- **description**: "CLI to clone/update cn-agent on an OpenClaw host and show the self-cohere cue" — stale.
- **Missing fields**: `repository`, `keywords`, `bugs`, `homepage`.
Flagged in v1.0.0 audit, still open.

### 4.12 LOW: state/ Files in Template (Carried Over)

Template contains `state/peers.md`, `state/remote-threads.md`, `state/threads/yyyyddmmhhmmss-hello-world.md`. In the two-repo model, state lives in the hub. The CLI copies `peers.md` to the hub but not the others.

### 4.13 LOW: git pull --ff-only No Fallback (Carried Over)

CLI still has bare `--ff-only` with no fallback. Flagged in v1.0.0.

### 4.14 LOW: WRITING.md Instance-Specific Reference (Carried Over)

WRITING.md: "If you have `sag` (ElevenLabs TTS)" — instance-specific in a template file.

### 4.15 LOW: experiments/ Still Uncontextualized (Carried Over)

No cross-reference, no README. Legacy design thinking without context.

### 4.16 LOW: No Tests (Carried Over)

Zero tests, zero CI. Now more surface area with two new skills.

### 4.17 LOW: Missing Katas (Partially Resolved)

reflect kata added (kata 02). self-cohere and configure-agent still lack katas.

### 4.18 LOW: ENGINEERING.md Em-Dash Inconsistency

One line changed from em-dash (`—`) to hyphen (`-`). Other lines still use em-dashes. Minor formatting inconsistency.

---

## 5. Coherence Assessment (TSC Axes)

### 5.1 PATTERN (α) — Structural Consistency

**Grade: A-** (unchanged from v1.3.2)

The repo structure is clean and consistent:
- 5 spec files, 6 mindsets, 6 skills, 3 docs — all follow their respective formats
- TERMS / INPUTS / EFFECTS in all SKILL.md files
- Placeholder markers in template specs
- Commit messages follow a consistent style
- New skills (reflect, daily-routine) follow the established SKILL.md + kata.md pattern
- Glossary stale entries now fixed

Deductions: Version numbers still inconsistent across 4+ files (skills/README says v1.1.0, DOJO says v1.2.0, configure-agent header says v1.1.0 but its own CHANGELOG says v1.2.0).

### 5.2 RELATION (β) — Alignment Between Parts

**Grade: A-** (up from B+ in v1.3.2)

The major architectural decisions remain consistently described. The whitepaper v2.0.3 is now merged to master. Reflect/daily-routine ownership is cleanly resolved with explicit "Ownership & Schema" sections in both SKILL.md files. Glossary stale entries fixed. The reflect kata now exercises the actual α/β/γ framework.

Deductions: `memory/` and `state/practice/` still not covered in whitepaper §4.1 (though now documented as cn-agent conventions). Version numbers still out of sync across files.

### 5.3 EXIT/PROCESS (γ) — Evolution Stability

**Grade: B+**

Three clean releases (v1.3.0–v1.3.2) in quick succession. The reflect skill is a genuine architectural evolution — it moves TSC from theory to operational practice. The "never self-merge" principle formalizes governance. The whitepaper iteration process (Bohm dialog → convergence → v2.0.3) demonstrates the project practicing what it preaches.

Deductions: The reflect skill at 352 lines is the longest file in the project and could benefit from structural decomposition. Version headers haven't kept pace with releases. The kata 01→02→13 gap is unexplained.

### 5.4 Aggregate

```
C_Σ = (A- · A- · B+)^(1/3) ≈ A-/B+ (intuition-level)
```

Up from B+ in v1.3.2. The three HIGH findings are all resolved. The path to solid A- is: align version numbers across files (the last systematic inconsistency) and clarify `memory/`/`state/practice/` scope (protocol vs implementation convention).

---

## 6. Priority Recommendations

### Must Address (all resolved)

1. ~~**Resolve reflect / daily-routine ownership of `state/reflections/`.**~~ **RESOLVED** — sigma/reflect-ownership merged. reflect owns schema, daily-routine orchestrates.

2. ~~**Fix reflect kata to exercise the actual framework.**~~ **RESOLVED** — sigma/reflect-ownership merged. Kata 02 now uses α/β/γ.

3. ~~**Fix glossary stale entries.**~~ **RESOLVED** — sigma/truthify-docs merged. All four stale entries fixed.

4. ~~**Merge whitepaper v2.0.3.**~~ **RESOLVED** — Whitepaper v2.0.3 merged to master (commit `2285fd8`).

### Should Address

5. **Update version numbers** across skills/README.md (v1.1.0), DOJO.md (v1.2.0), GLOSSARY.md (v1.2.0), configure-agent SKILL.md header (v1.1.0→v1.2.0). These are document-local versions, not the template's semver — each file should track its own change history. This is the top remaining systematic inconsistency.

6. **Clarify `memory/` and `state/practice/` scope.** Glossary now has entries (added by sigma/reflect-ownership), but whitepaper §4.1 still doesn't mention them. Either add them to Appendix A as cn-agent conventions, or explicitly note in daily-routine SKILL.md that these are implementation-specific (not protocol-level).

7. **Document the cron runtime assumption** in daily-routine SKILL.md TERMS. Not all agents have access to the JSON cron format shown.

8. **Explain DOJO.md kata numbering.** State the belt→number mapping or fill the gaps (01→02→13 is unexplained).

9. **Update package.json.** Fix stale description; add `repository`, `keywords`, `bugs`, `homepage`.

10. **Add git pull --ff-only fallback** in CLI.

### Nice to Have

11. Extract reflect cadence templates to a separate file to keep SKILL.md focused on specification.
12. Remove emoji from reflect framework table and templates (projection robustness).
13. Add smoke test for CLI `--help` / `--version`.
14. Add katas for self-cohere and configure-agent.
15. Contextualize experiments/ or archive it.
16. Remove `sag` reference from WRITING.md.
17. Consistent em-dash usage in ENGINEERING.md.
