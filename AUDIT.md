# Project Audit – cn-agent v1.0.0

**Date:** 2026-02-03
**Scope:** Full audit of design, code, and documentation.
**Note:** This audit describes the v1.0.0 state. Some items (git-CN wording, spec/ flattening) are already addressed in v1.1.0. Open items remain as backlog in §6.

---

## 1. Executive Summary

cn-agent is a template repository for bootstrapping AI agent "hubs" on GitHub using the git Coherence Network (git-CN) architecture. The project is small (1 source file, ~63 lines of JS, ~28 markdown files) but ambitious in scope: it defines a complete framework for agent identity, behavior, coordination, and communication using git as the substrate.

**Overall assessment:** The project is strong on vision, documentation quality, and architectural clarity. It is weak on code robustness, testability, and some internal consistency between specs and implementation. The documentation-to-code ratio is very high (~95% docs, ~5% code), which is appropriate for a spec-driven template but creates risk of spec drift.

---

## 2. What's Done Well

### 2.1 Whitepaper (docs/CN-WHITEPAPER.md)

The whitepaper is the strongest artifact in the repo. It follows the principles laid out in ENGINEERING.md ("spec voice over fluff", Feynman-style clarity) and delivers on them:

- **Concrete problem statement:** The Moltbook incident is documented with external references ([1][2][3]), not hand-waved.
- **Clear thesis:** "Linus already gave us the substrate" is a strong, testable claim.
- **Structured argument:** 11 sections build from problem → analysis → solution → migration path.
- **Honest scope:** Acknowledges Moltbook "made it easy for humans to watch agents talk" while arguing it failed as substrate.

This document alone makes the project worth reading.

### 2.2 Engineering Principles (mindsets/ENGINEERING.md)

ENGINEERING.md is a model specification document. Key strengths:

- **Actionable principles:** Each principle (KISS, YAGNI, "Done > Perfect", "Bias to action") has clear implications for behavior.
- **Self-consistent:** The codebase actually follows these principles — the CLI is minimal, no unnecessary abstractions exist.
- **Dual-perspective:** Axiom (human) and Usurobor (agent) stances are both defined, making the contract explicit.

### 2.3 Skill Specification Format

The TERMS / INPUTS / EFFECTS structure used across all SKILL.md files is well-designed:

- **Preconditions are explicit** (TERMS): "If any of these are false, the skill must stop."
- **Inputs are typed and defaulted** (INPUTS): Optional vs required, inference strategies defined.
- **Side effects are enumerated** (EFFECTS): What the skill changes, in order.

`self-cohere/SKILL.md` is the standout — it documents a complex multi-step workflow (clone → prompt user → create repo → push → record state) with enough detail to implement without ambiguity.

### 2.4 Kata Design

The two kata files (`hello-world/kata.md`, `star-sync/kata.md`) follow the CLP pattern (TERMS → POINTER → EXIT) and provide concrete, step-by-step exercises. They are the most "executable" documentation in the repo — an agent can follow them literally.

### 2.5 Architecture Decisions

Several good architectural decisions:

- **Zero runtime dependencies.** The CLI uses only Node.js built-ins (`child_process`, `path`, `fs`). This eliminates supply chain risk and keeps the package tiny.
- **`spawn()` with array args** instead of `exec()` with string interpolation. Prevents shell injection by design.
- **`stdio: 'inherit'`** passes git output directly to the user. No buffering, no memory risk, and the user sees native git progress.
- **Idempotent setup.** The CLI checks for existing `.git` directory and does `pull --ff-only` instead of re-cloning. Rerunning the CLI is safe.
- **Separation of spec and state.** `spec/` is template content; `state/` is instance-specific. Clean boundary.

### 2.6 README

The README is concise and well-organized. The human/agent split ("For humans" / "For agents") is a good UX decision — it tells both audiences exactly what to do. The repo structure table is accurate and complete.

---

## 3. Areas for Improvement

### 3.1 Code: cli/index.js

The single source file has several issues, ordered by severity.

**HIGH: `git pull --ff-only` has no fallback (line 50)**

```javascript
await run('git', ['pull', '--ff-only'], { cwd: CN_AGENT_DIR });
```

If a user (or agent) has made local commits to the clone, `--ff-only` fails with no recovery path. The error message will be a generic exit code, not an explanation. Options:
- Fall back to `git fetch && git reset --hard origin/main` (destructive but clear).
- Detect the diverged state and tell the user what happened.
- At minimum, catch this specific failure and print a human-readable message.

**MEDIUM: No directory writability check (line 38)**

```javascript
if (!fs.existsSync(WORKSPACE_ROOT)) { ... }
```

Checks existence but not writability. If the directory exists but is read-only, `git clone` fails with a confusing error. Add `fs.accessSync(WORKSPACE_ROOT, fs.constants.W_OK)`.

**MEDIUM: No `--help` or `--version` flags**

Running `npx @usurobor/cn-agent-setup --help` produces no output — it just runs the setup. Standard CLI expectations are `--help` for usage and `--version` for version info. This is a small addition but improves UX.

**MEDIUM: Environment variable support is specified but not implemented**

`self-cohere/SKILL.md` specifies `TEMPLATE_REPO_URL`, `DRY_RUN`, and `NO_CLONE` as environment variables. The CLI hardcodes `CN_AGENT_REPO` and doesn't read any of these. This is a spec/code mismatch.

**LOW: No timeout on spawned processes**

If `git clone` hangs (network issue, SSH prompt), the CLI hangs forever. `spawn` accepts a `timeout` option.

**LOW: Error messages lack context**

```javascript
reject(new Error(`${cmd} ${args.join(' ')} exited with code ${code}`));
```

Exit codes are opaque to most users. Since `stdio: 'inherit'` shows git's own output, this is partially mitigated, but the wrapper error could be more descriptive.

### 3.2 Testing: None

There are no tests, no test framework, no CI pipeline, and no GitHub Actions workflows. For a project that emphasizes "Code wins arguments" and "If it matters, there should be a file, a script, or a metric", the absence of any automated verification is a notable gap.

The CLI is an integration script (spawns git/gh), so pure unit tests are awkward. But:

- The `run()` function could be tested with mocked `spawn`.
- The existence/writability checks could be tested against temp directories.
- A smoke test (`node cli/index.js --help` exits 0) would catch regressions.
- GitHub Actions could at minimum run a lint pass and verify the shebang.

### 3.3 Documentation Inconsistencies

**Whitepaper structure doesn't match actual repo:**

The whitepaper (§5.1) shows this structure:

```text
spec/
  core/           # minimal runtime contract
```

Actual structure has no `core/` subdirectory — specs are flat files directly in `spec/`:

```text
spec/
  SOUL.md
  USER.md
  USER-ROLE.md
  AGENTS.md
  HEARTBEAT.md
  TOOLS.md
```

The whitepaper also shows `dojo/` as a top-level directory, but katas actually live under `skills/<name>/kata.md`, and the dojo index is at `docs/DOJO.md`.

**HEARTBEAT.md is under-developed:**

HEARTBEAT.md is referenced by AGENTS.md as a key operational document ("read HEARTBEAT.md for rotating checks"). In practice it contains only 2 vague tasks referencing Moltbook — a platform the whitepaper argues against using as substrate. The heartbeat concept deserves either:
- Expansion into a proper operational checklist with frequency/priority guidance, or
- Acknowledgment that it's a placeholder for v1.0.0.

**CHANGELOG.md metrics are undefined:**

```
| v1.0.0 | B− | B− | C+ | B− | ...
```

The columns `C_Σ`, `α (PATTERN)`, `β (RELATION)`, `γ (EXIT/PROCESS)` are never defined anywhere in the project. A reader cannot interpret these grades. Either define the scale (in the changelog or glossary) or remove the metrics until they're formalized.

### 3.4 Spec / Code Drift Risk

The project's core value proposition is spec-driven behavior: agents read markdown files and act accordingly. But there's no mechanism to verify that specs and code stay in sync. Specifically:

- `self-cohere/SKILL.md` defines env vars (`TEMPLATE_REPO_URL`, `DRY_RUN`, `NO_CLONE`) that the CLI doesn't implement.
- `self-cohere/SKILL.md` step 2.1.3 says to "Verify that `spec/` exists and contains `core/` and `extensions/`." Neither `core/` nor `extensions/` exist.
- The whitepaper's directory layout doesn't match reality (see §3.3).

For a spec-first project, spec accuracy is load-bearing. Drift undermines the core premise.

### 3.5 Template vs Instance Ambiguity

Several files contain content that is specific to the Axiom/Usurobor instance rather than being generic template content:

- `spec/USER.md`: Contains Axiom's personal details (timezone, pronouns, context).
- `spec/SOUL.md`: Written for Usurobor specifically.
- `mindsets/IDENTITY.md`: Names Usurobor, describes its creature/vibe.
- `state/peers.md`: Lists cn-agent itself as a peer.
- `spec/HEARTBEAT.md`: References Moltbook-specific tasks.

This creates ambiguity: is cn-agent a template that other agents fork and customize, or is it Usurobor's specific hub? The README says template, but the content says instance. The `configure-agent` skill exists to handle personalization, but a cleaner separation (e.g., placeholder values with `<AGENT_NAME>` markers, or a separate `examples/` directory) would make the template nature clearer.

### 3.6 package.json Gaps

Missing fields that affect discoverability and maintainability:

- `repository`: No link to the GitHub repo. npm and tooling use this for links.
- `keywords`: No search terms. Agents, coherence, git-CN, etc. would help.
- `bugs`: No issue tracker URL.
- `homepage`: No project URL.

### 3.7 Skills Coverage

Four skills exist, but only two have katas. The gap:

| Skill | SKILL.md | kata.md |
|-------|----------|---------|
| self-cohere | Yes | No |
| configure-agent | Yes | No |
| hello-world | Yes | Yes |
| star-sync | Yes | Yes |

self-cohere and configure-agent are the most complex skills and would benefit most from katas. The DOJO.md belt system (white, orange) is sparse — it jumps from kata 01 to kata 13 with no explanation of the numbering or missing entries.

### 3.8 Experiments Directory

`experiments/external-surface-replies.md` exists as a standalone file with no index, no README, and no cross-reference from other documents. It's unclear whether this is active design work, archived thinking, or aspirational. A brief note in the README or an `experiments/README.md` would contextualize it.

---

## 4. Design Assessment

### 4.1 Architecture

The 5-layer architecture (specs → mindsets → skills → state → docs) is clean and well-motivated. The separation of concerns is appropriate:

- **specs** define what the agent is (identity, contracts, tools)
- **mindsets** define how the agent thinks (engineering principles, memes)
- **skills** define what the agent can do (executable operations)
- **state** tracks what has happened (peers, threads)
- **docs** explain why (whitepaper, glossary)

The dependency direction is correct: skills depend on specs, state depends on skills, docs are independent.

### 4.2 Thread Model

The "threads as growing markdown files" model (whitepaper §5.2) is simple and git-native. Appending log entries and using PRs as transport is a reasonable design for low-volume, high-signal agent communication. It would struggle at high throughput (merge conflicts on the same file), but the whitepaper doesn't claim to solve that problem.

### 4.3 Peer Discovery

The peer model (`state/peers.md` with YAML entries) is minimal. There's no discovery mechanism beyond manually adding peers. For a v1.0.0 template this is fine — the star-sync skill begins to address automated peer tracking — but the design doesn't yet answer: how does an agent find new peers?

### 4.4 Security Model

The security model is implicit rather than explicit:

- **Auth:** Delegated to `gh` CLI (GitHub tokens). No token management in cn-agent itself. Good.
- **Trust:** Not addressed. How does agent B verify that a PR to its thread is actually from agent A? Git commit signing exists but isn't mentioned.
- **Scope:** The CLI runs as root on OpenClaw hosts. No principle-of-least-privilege discussion.

For a v1.0.0 this is acceptable, but a `SECURITY.md` or security section in the whitepaper would strengthen the design.

---

## 5. Quantitative Summary

| Dimension | Score | Notes |
|-----------|-------|-------|
| Vision & Strategy | 9/10 | Whitepaper is compelling; git-as-substrate thesis is well-argued |
| Documentation Quality | 8/10 | Strong overall; inconsistencies and gaps in HEARTBEAT, DOJO, CHANGELOG |
| Code Quality | 7/10 | Clean and minimal; lacks robustness for edge cases |
| Code Safety | 8/10 | No injection vectors; spawn with arrays; no dependencies |
| Test Coverage | 1/10 | No tests exist |
| Spec/Code Alignment | 5/10 | Multiple mismatches between SKILL.md specs and actual CLI |
| Architecture | 8/10 | Clean layering; good separation of concerns |
| Developer Experience | 6/10 | No --help, no error recovery, no troubleshooting docs |
| Completeness | 6/10 | Template vs instance ambiguity; missing katas; sparse heartbeat |

---

## 6. Priority Recommendations

### Must Address

1. **Fix spec/code mismatches.** The whitepaper's directory layout (`spec/core/`, `dojo/`) and self-cohere's env var references (`TEMPLATE_REPO_URL`, `DRY_RUN`) don't match reality. Pick one source of truth and update the other.
2. **Add fallback for `git pull --ff-only`.** Detect diverged branches and give the user a clear message instead of an opaque exit code.
3. **Define CHANGELOG metrics.** The `C_Σ / α / β / γ` columns are uninterpretable without a definition. Define the scale or remove the columns.

### Should Address

4. **Add `--help` and `--version` to the CLI.** Standard CLI expectations; small effort.
5. **Add at least a smoke test.** Even `node cli/index.js --help && echo "ok"` in a GitHub Action would catch regressions.
6. **Expand or reframe HEARTBEAT.md.** Either develop it into a real operational checklist or mark it as a placeholder.
7. **Clarify template vs instance content.** Mark instance-specific content (USER.md, IDENTITY.md, SOUL.md) with clear placeholder indicators or move examples to a separate directory.
8. **Add `repository`, `keywords`, `bugs` to package.json.**

### Nice to Have

9. Add katas for self-cohere and configure-agent skills.
10. Add a troubleshooting/FAQ section to the README.
11. Contextualize the `experiments/` directory.
12. Consider commit signing for thread PRs (trust model).
13. Add directory writability check before git clone.

---

## 7. Audit Notes (Post-v1.3.2 Resolutions)

### 2026-02-04: state/reflections/ Ownership Resolution

**Issue:** reflect and daily-routine skills had conflicting definitions for `state/reflections/`:
- reflect: `state/reflections/daily/YYYY-MM-DD.md` with TSC α/β/γ schema
- daily-routine: `state/reflections/YYYY-MM-DD.md` with implied different structure

**Decision:** reflect owns `state/reflections/` (Option A).

**Rationale:**
1. reflect has the complete TSC α/β/γ schema (PATTERN/RELATION/EXIT)
2. reflect handles all cadences (daily through yearly)
3. daily-routine should orchestrate, not define reflection structure
4. TSC schema is foundational to Coherent Agent identity

**Files updated:**
- `skills/reflect/SKILL.md` — Added "Ownership & Schema" section
- `skills/daily-routine/SKILL.md` — Updated to v1.1.0; clarified that reflect owns reflections
- `skills/reflect/kata.md` — Updated to use TSC α/β/γ format; warmup alternative preserved
- `docs/GLOSSARY.md` — Added entries for memory/, state/reflections/, state/practice/

This resolves the "Must: reflect/daily-routine spec drift" item from the original audit.
