---
name: cdd
description: Apply Coherence-Driven Development to substantial changes. Use before starting work that spans design, code, tests, docs, or release. Triggers on new subsystems, runtime/ABI changes, package/security changes, or work >1 day.
---

# CDD

Apply Coherence-Driven Development to substantial changes.

## Core Principle

**Coherent development: every change reduces a named incoherence and leaves behind aligned design, plan, tests, code, docs, and release notes.**

Incoherence not named is incoherence not reduced. Artifacts not aligned are drift waiting to happen.

## Lifecycle

CDD owns the full arc from observation to observation:

0. **Observe** — read the system's coherence state (§0)
1. **Select** — pick the next gap to address from the observation (§0)
2. **Branch** — create the branch (§1.4)
3. **Bootstrap** — create version directory with stub files for each deliverable artifact (§4.0)
4. **Gap** — name the incoherence precisely (§2)
5. **Mode** — choose MCA or MCI (§3)
6. **Artifacts** — design → contract → plan → tests → code → docs (§4)
7. **Self-coherence** — write `SELF-COHERENCE.md` in the version directory (§4.8)
8. **Review** — CLP with another CA until convergence (§7)
9. **Gate** — verify the release checklist (§9)
10. **Release** — version, tag, CI, merge, announce (§10)
11. **Observe** — confirm runtime matches design (§10.7)
12. **Assess** — post-release assessment: measure, encoding lag, process learning (§11)
13. **Close** — execute MCAs, capture MCIs, file issues, patch skills (§11)

Step 13 feeds back to step 0. The cycle closes when:

- **Immediate MCAs** are executed — small fixes that can be done now: CHANGELOG corrections, skill patches, tag fixes, missing documentation. These close within the current cycle.
- **Committed MCAs** are named — substantial work that becomes the next cycle's §0.14 default selection. These are committed, not executed. The commitment is recorded in the assessment's "Next Move" section.
- **MCIs** are captured — in an adhoc thread with status per learning.
- **Issues** are filed or updated per §11.12.

The distinction: immediate MCAs close *in* the cycle. Committed MCAs close *the cycle* by naming the next one. A cycle that produces only committed MCAs (no immediate fixes) is still closed — the commitment is the closure.

---

## 0. Observe and Select

CDD does not start with "pick an issue from the backlog." It starts with **observing the system's coherence state** and selecting the gap that most needs closing.

### Inputs

Read these four surfaces before selecting work:

0.1. **CHANGELOG TSC table** — which axis (α, β, γ) is lowest?
  - The lowest axis is where coherence is weakest. That's the direction.
  - ❌ Pick work because it's interesting or next on a list
  - ✅ "γ dropped to B+ last release (process regressions). Next work should address γ."

0.2. **Encoding lag table** — what's stale, what's growing?
  - Stale = named incoherence with zero progress across multiple assessments. This is the system lying to itself.
  - Growing = gap widening as the system evolves. Eventual blocker.
  - ❌ Ignore the lag table and start new design work
  - ✅ "#73, #65, #67 stale across 3 assessment cycles. #73 is the root — pick it."

0.3. **Doctor / status** — is the running system healthy?
  - P0 bugs (crash, data loss, silent failure) override all selection criteria
  - ❌ Start a feature while the daemon is crash-looping
  - ✅ "Doctor shows version drift on Pi — fix deployment before starting new work"

0.4. **Last post-release assessment** — what did the previous cycle surface?
  - Unresolved MCIs from the last assessment are candidate gaps
  - "Next MCA" commitment from the assessment is the default selection unless observation overrides it
  - ❌ Ignore the previous assessment's recommendation without rationale
  - ✅ "Assessment committed to #73 as next MCA. Observation confirms: still stale, still highest leverage."

### Selection algorithm

Given the four inputs, select the next gap:

0.5. **P0 override** — if doctor/status shows a P0 bug (crash, data loss, silent failure), that's the gap. No further analysis needed.

0.6. **Operational infrastructure debt** — if core operational paths are broken (self-update, logging, health checks, deploy pipeline), fix them regardless of MCI freeze. These are not new features — they are the system's ability to run, observe, and maintain itself. A system that can't self-update, can't be observed, or retries forever is not a healthy base for feature work.
  - ❌ "MCI freeze says pick from stale set" while `cn update` 404s and logs are a black hole
  - ✅ "Self-update, logging, and health are operational prerequisites. Fix them, then resume the stale backlog."

0.7. **MCI freeze check** — if the lag table has stale issues (zero progress across ≥2 assessments), the next MCA MUST come from the stale set. New design work is frozen until at least one stale issue ships.

0.8. **Lowest axis** — select work that addresses the weakest TSC axis. If α is lowest, pick structural/consistency work. If β is lowest, pick alignment/integration work. If γ is lowest, pick process/evolution work.

0.9. **Maximum leverage** — among candidates that address the weakest axis, pick the one that moves the most lag table entries. If #73 unblocks #65 and #67, it moves 3 entries for 1 MCA. That's higher leverage than a standalone issue.

0.10. **Dependency order** — if A blocks B blocks C, pick A regardless of individual priority. The chain won't move otherwise.

0.11. **Effort-adjusted** — between candidates with equal leverage and axis impact, pick the smaller one. Ship sooner, observe sooner, correct sooner.

  - ❌ "Let's do #94 (large) because it's exciting" when #73 (medium) unblocks 3 stale issues
  - ❌ Start #73 when Pi is crash-looping (P0 override)
  - ✅ "Observation: γ at B+ (lowest), lag table has 3 stale issues, #73 unblocks 2 of them. Doctor clean. Select #73."

0.12. **No prior assessment** — if no post-release assessment exists yet (first cycle, fresh system), skip §0.4 and rely on §0.1–§0.3 alone. The lag table starts empty; doctor and CHANGELOG are sufficient to select.

0.13. **No gap found** — if no lag item, P0, or operational debt exists, and all axes are healthy or tied, do not start a new substantial CDD cycle. Remain in observation or choose a small-change path (§1.3). The algorithm may select nothing.
  - ❌ Force-start a substantial cycle because "we should always be shipping"
  - ✅ "All axes A, lag table clean, doctor green. No substantial gap. Small-change path or observe."

0.14. **Assessment commitment as default** — if the last assessment named a "Next MCA" and no stronger override fires (§0.5 P0, §0.6 operational debt), that committed MCA is selected. The assessment commitment is the default; observation can override it but must state why.
  - ❌ Ignore the committed next MCA without rationale
  - ✅ "Assessment committed #73. Observation confirms: still stale, still highest leverage. Select #73."
  - ✅ "Assessment committed #73, but §0.6 fires: cn update broken. Override with rationale: operational debt before feature work."

---

## 1. When

1.1. **Invoke CDD when**
  - New subsystem or architecture layer
  - Runtime contract or ABI change
  - Package or distribution model change
  - Security, sandbox, or traceability change
  - Work expected to take >1 day
  - Change that introduces or modifies a versioned doc, ABI, or schema
  - ❌ Jump straight to code for a new subsystem
  - ✅ State the gap, draft the design, then code

1.2. **Do not invoke full CDD for**
  - Typo-only doc fixes
  - Trivial refactors with no behavior or ABI change
  - One-line bugfixes with clear local scope
  - ❌ Full design doc for fixing a typo in README
  - ✅ Commit message states the fix; no ceremony needed

1.3. **Scale the method to the change**
  - Small change: coherence contract is one sentence in the commit message
  - Medium change: coherence contract + plan in PR description
  - Large change: full pipeline — design → contract → plan → tests → code → docs → release
  - ❌ Same ceremony for every change regardless of size
  - ✅ Pipeline depth proportional to coherence risk

1.4. **Branch before artifacts**
  - Create the branch before the design doc
  - Branch name format: `{agent}/{version}-{issue}-{scope}` (e.g., `claude/3.13.0-75-docs-governance`)
  - `{agent}`: the actor (`claude`, `sigma`, `pi`). `{version}`: target cnos version (when known). `{issue}`: tracker number. `{scope}`: short kebab-case topic
  - **Tooling suffixes** (e.g., `-PfdYZ`) are transport artifacts. Reviews, commits, and documentation SHOULD use the logical name without the suffix
  - ❌ Work on `main`, commit design doc directly
  - ❌ Reference the transport suffix in documentation or PR body
  - ✅ `claude/3.13.0-75-docs-governance` — version + issue + scope
  - ✅ `claude/58-packages-sync` — issue + scope, no version yet

1.5. **Branch pre-flight validation**
  - Before creating the branch, run these checks:
  - **Version check:** if a version segment is present, it MUST be greater than the latest tag (`git tag --sort=-v:refname | head -1`). If main has untagged release commits, the version must also be greater than those.
  - **Branch uniqueness:** no existing remote branch may claim the same issue number (`git branch -r | grep '{issue}'`). A second branch for the same issue means either the first should be deleted or the work is a duplicate.
  - **Open PR check:** no open PR may already cover the same issue (`gh pr list --state open` or equivalent). Starting work that duplicates an open PR wastes an entire cycle.
  - **Convention check:** branch name matches `{agent}/{version}-{issue}-{scope}` or `{agent}/{issue}-{scope}` per §1.4. Deviations cause superseded PRs when renamed later.
  - **Scope declaration:** the bootstrap README MUST list which files the branch will modify. Files outside this list MUST NOT be touched without updating the scope declaration. This prevents background agents from regressing files outside their issue's domain.
  - **CI status check:** if any CI check is currently red on main for a domain this branch touches, document it in the PR body with the issue number (e.g., "I1 failing — known #58"). Do not silently merge red CI on your domain.
  - ❌ Pick version `3.14.1`, do all the work, discover the tag already exists → entire PR superseded
  - ❌ Create branch for #81 when another branch already targets #81 → duplicate work
  - ❌ Modify the design skill from a version-coherence branch (out of declared scope)
  - ❌ Merge with red CI on package/source drift from a PR about version/package coherence
  - ✅ Check `git tag`, `git branch -r`, open PRs → confirm version is next, no conflicts → create branch
  - ✅ Bootstrap README lists: "In scope: cn_lib.ml, cn_deps.ml, cn_system.ml, cn.json, 3 package manifests, tests. Out of scope: skills, docs (except frozen snapshot)."
  - ✅ PR body: "Note: I1 (package/source drift) is red on main — pre-existing #58, not introduced by this PR."

---

## 2. Define the Gap

Before any artifact is created, name the incoherence.

2.1. **Name the gap**
  - What is incoherent? Be specific: layer, artifact, behavior
  - ❌ "Things are messy"
  - ✅ "AGENT-RUNTIME.md describes L2 transport but code only implements L0 and L1"

2.2. **Name the layer**
  - Doctrine, architecture, runtime, packaging, operator surface, or release process
  - ❌ "It's a code problem"
  - ✅ "Architecture layer — design doc describes capabilities the runtime doesn't expose"

2.3. **Name the failure mode if unchanged**
  - What breaks, drifts, or misleads if we do nothing?
  - ❌ "It would be nice to fix"
  - ✅ "Operators will configure L2 transport that silently falls back to L0"

2.4. **Reconcile with issue acceptance criteria**
  - If the change originates from an issue, read every AC in the issue body
  - The coherence contract must account for every AC: met in this change, explicitly deferred as known debt, or descoped with rationale
  - ACs not mentioned are scope leaks — they will pass through the entire pipeline undetected
  - ❌ Write a coherence contract that covers 3 of 6 issue ACs without mentioning the other 3
  - ✅ "Issue #56 has 6 ACs. This change addresses ACs 1-3, 6. ACs 4-5 (cn doctor, cn setup) deferred to follow-up — tracked in issue #58."

---

## 3. Choose Mode

3.1. **MCA or MCI**
  - MCA: change the system (code, config, runtime)
  - MCI: change the design (docs, assumptions, specs)
  - MCA first, MCI when model is wrong or action is blocked
  - ❌ Rewrite the spec to match broken behavior without evaluating which is correct
  - ✅ Runtime wrong, docs correct → MCA (fix the code)
  - ✅ Docs wrong, runtime correct → MCI (fix the docs)

3.2. **State why MCA is possible or blocked**
  - If MCI: explain what prevents action
  - ❌ "Let's update the docs" (without explaining why code can't change)
  - ✅ "MCI — runtime is correct; spec predates the current design and must be updated"

---

## 4. Create Artifacts in Order

Follow the pipeline. Each step feeds the next.

4.0. **Bootstrap — version directory**
  - The first diff on the branch MUST create a version directory with stub files for every artifact the **target bundle** will produce for this version
  - The directory lives at `docs/{tier}/{bundle}/vX.Y.Z/` and MUST contain a `README.md` (snapshot manifest)
  - If the branch touches multiple bundles, each bundle that will receive a frozen snapshot gets its own version directory
  - Artifacts outside version directories (PR body files, navigation docs, bundle READMEs) are not enumerated as stubs
  - Version directories are **frozen by repository policy** — after creation, their contents MUST NOT be modified in later commits. When the canonical doc changes during the branch, **re-freeze**: copy the current canonical into the version directory before requesting review
  - The snapshot README MUST list every frozen artifact in the directory
  - **Scope enumeration:** if the work covers a range (version range for epoch assessments, set of files for moves, set of cross-references for updates), the bootstrap README MUST list every item in scope. Enumerate mechanically (`git tag`, `ls`, `grep`), not from memory
  - ❌ Start coding before naming the version or enumerating deliverables
  - ❌ Leave a stale snapshot that doesn't match the canonical
  - ❌ Write an epoch assessment for "v3.12–v3.14" without listing every tag in that range
  - ✅ First commit: `docs/gamma/cdd/v3.13.0/README.md` + `CDD.md` stub
  - ✅ Before review: verify `diff canonical frozen` = zero
  - ✅ Bootstrap README for epoch assessment lists: v3.12.0, v3.12.1, v3.12.2, v3.14.0, v3.14.1 (enumerated from `git tag`)

4.1. **Design doc**
  - Create or update before coding
  - ❌ Code first, backfill the design doc
  - ✅ Design doc states types, interfaces, workflow → code realizes it

4.2. **Coherence contract**
  - State: gap, mode, scope, expected triadic effect, failure if skipped
  - If the change originates from an issue, the contract must reconcile with all issue ACs (per §2.4)
  - ❌ PR with no stated purpose beyond "implements feature X"
  - ❌ Coherence contract that silently narrows scope below the issue's AC list
  - ✅ Coherence contract in PR description or design doc header, with AC coverage table

4.3. **Implementation plan**
  - Steps, dependencies, risk boundaries, compile-safe increments
  - ❌ "I'll figure it out as I go"
  - ✅ Plan lists ordered steps with clear scope boundaries

4.4. **Tests**
  - Pin invariants before coding; derived from design, not invented after
  - ❌ Write code, then write tests that pass
  - ✅ Write tests from spec invariants, watch them fail, then implement

4.5. **Code**
  - Realizes the design; does not invent architecture
  - ❌ Code introduces concepts not in the design doc
  - ✅ Every type and interface traces to the design

4.5.1. **Before any commit that references an issue: AC self-check**
  - Re-read the issue body. Walk every AC.
  - For each AC: verify it is met in staged changes, explicitly deferred, or descoped
  - If any AC is unaccounted for, do not commit with `Closes #N` or `(#N)`
  - This is the earliest gate — it fires at commit time, not at review time
  - ❌ `git commit -m "feat: runtime contract (#56)"` without checking all 6 ACs
  - ✅ Walk ACs → find AC4 (cn doctor) not met → either implement it or commit without `Closes`
  - ✅ All ACs met or deferred → commit with AC coverage in message body

4.5.2. **Multi-format parity: all serializers read from one source**
  - If a value exists in a canonical module (e.g. `Cn_capabilities.observe_kinds`), every format renderer (markdown, JSON, YAML) must read from that module
  - Never duplicate canonical lists as literals in a second serializer
  - If the runtime contract has both a markdown renderer and a JSON serializer, both must source the same fields from the same module
  - ❌ `render_markdown` delegates to `Cn_capabilities.render`; `to_json` hardcodes the same op lists as string literals
  - ✅ Both `render_markdown` and `to_json` read `Cn_capabilities.observe_kinds` and `Cn_capabilities.effect_kinds_base`

4.5.3. **Build-sync after editing source assets**
  - After modifying any file under `src/agent/` (doctrine, mindsets, skills), run `cn build` before committing
  - `cn build` copies source assets to `packages/` — skipping it causes package/source drift
  - CI runs `cn build --check` and will catch this, but the gate belongs at commit time
  - ❌ Edit `src/agent/skills/ops/cdd/SKILL.md`, commit without `cn build` → packages/ is stale
  - ✅ Edit source → `cn build` → verify packages/ updated → commit both

4.6. **Docs**
  - Updated to match implementation — README, operator guides, architecture
  - ❌ Ship code, leave docs describing the old behavior
  - ✅ Docs updated in the same PR or immediately after

4.7. **Release notes**
  - Explain the coherence delta to operators and contributors
  - ❌ "Various improvements"
  - ✅ "Added L2 transport — operators can now configure push-based sync"

4.8. **Self-coherence report**
  - Every substantial release SHOULD include a `SELF-COHERENCE.md` in its version directory
  - Records the branch author's own CDD-compliance assessment before requesting review
  - Required sections: pipeline compliance table, triadic assessment (α/β/γ scores with rationale), checklist pass, known coherence debt, reviewer notes
  - Placement: `docs/{tier}/{bundle}/vX.Y.Z/SELF-COHERENCE.md`
  - Small changes covered by §1.2 do not require a self-coherence report
  - See `docs/gamma/cdd/CDD.md` §7.8 for the full format template
  - ❌ Request review without recording your own compliance assessment
  - ✅ Write SELF-COHERENCE.md, score each pipeline step, list known debt, then request review

---

## 5. File Naming Rules

5.1. **Existing design line — amend it**
  - If changing an existing design lineage, update the existing file
  - Add patch notes or version bump inside it
  - ❌ Create `AGENT-RUNTIME-v2.md` alongside the original
  - ✅ Update `docs/alpha/agent-runtime/AGENT-RUNTIME.md`, bump version header

5.2. **New subsystem — create a versioned design doc**
  - Pattern: `docs/alpha/NAME-vMAJOR.md`
  - ❌ `docs/alpha/new-thing.md` (no version)
  - ✅ `docs/alpha/CAA-v1.md`
  - ✅ `docs/alpha/CAR-v3.4.md`

5.3. **Implementation plan**
  - Feature/release scoped: `docs/gamma/plans/PLAN-vX.Y.Z.md` (e.g. `PLAN-v3.6.0.md`)
  - Subsystem scoped: `docs/gamma/plans/NAME-implementation-plan.md` (e.g. `CAR-implementation-plan.md`)
  - ❌ Plan buried in a thread or issue comment
  - ✅ `docs/gamma/plans/CAR-implementation-plan.md`
  - ✅ `docs/gamma/plans/PLAN-v3.6.0.md`

5.4. **Tests mirror module location**
  - Pure logic: `test/lib/...`
  - Runtime/cmd behavior: `test/cmd/...`
  - ❌ All tests in one flat directory
  - ✅ Test location mirrors source location

5.5. **Release notes**
  - Commit/PR description contains explicit summary
  - CHANGELOG.md updated for minor and major releases
  - ❌ Tag with no release notes
  - ✅ `CHANGELOG.md` entry + `gh release create` with summary

---

## 6. Version Assignment

6.1. **Use patch when**
  - Wording, examples, or traceability improved
  - Behavior unchanged
  - ABI unchanged
  - ❌ Patch for adding a new config field
  - ✅ Patch for fixing a doc typo or clarifying an example

6.2. **Use minor when**
  - Additive capability
  - New runtime behavior
  - New package, config field, or schema extension
  - New design subsystem
  - Scheduler or observability additions
  - ❌ Minor for removing a public function
  - ✅ Minor for adding L2 transport alongside existing L0/L1

6.3. **Use major when**
  - Breaking output contract
  - Breaking package layout
  - Changing recovery semantics incompatibly
  - Removing or renaming public ABI surface
  - ❌ Major for adding an optional field
  - ✅ Major for renaming `cn daemon` to `cn agent` (breaking operator scripts)

6.4. **When unsure, choose minor**
  - ❌ Default to patch to avoid version churn
  - ✅ Default to minor — migration risk is worse than version numbers

6.5. **Migration means not-patch**
  - If any operator, script, or downstream consumer must change behavior, it is not a patch
  - ❌ "Just a patch — users only need to update their config file"
  - ✅ That config change makes it minor at minimum

---

## 7. CLP Review with Another CA

When asking another CA (or human reviewer) to review a substantial change, use this protocol.

7.1. **Send the seed**
  - State what incoherence exists and why it matters
  - ❌ "Please review this PR"
  - ✅ "Gap: AGENT-RUNTIME describes daemon keepalive but code has no heartbeat. This causes silent agent death."

7.2. **State the mode**
  - MCA, MCI, or both
  - ❌ Omit mode — reviewer guesses what kind of change this is
  - ✅ "Mode: MCA — adding heartbeat to match spec"

7.3. **Request triadic scores**
  - Ask reviewer to score α, β, γ separately
  - ❌ "Is this good?"
  - ✅ "Score α (internal consistency), β (alignment with AGENT-RUNTIME and code), γ (evolution path) separately"

7.4. **Request weakest-axis patches**
  - Ask for 3 concrete patches on the weakest axis
  - ❌ "Any suggestions?"
  - ✅ "Identify the weakest axis and propose 3 concrete fixes for it"

7.5. **Ask the convergence question**
  - "Iterate or converge?"
  - ❌ Leave review open-ended with no termination signal
  - ✅ Reviewer states: "Converge — no critical contradictions remain" or "Iterate — β is still weak on X"

7.6. **Require reviewer output format**
  - **Issue contract table** (FIRST — before any diff analysis):
    - AC coverage: each AC → met / partial / missing / deferred
    - Named doc coverage: each doc the issue/plan names → updated / absent / deferred
    - If this table is missing, the review is incomplete
  - Triadic scores (letter grades)
  - Weakest axis identified
  - Concrete patches (at least 3 for weakest)
  - Contradictions or orphans found
  - Verdict: iterate or converge
  - ❌ Free-form "looks good" review
  - ❌ Review that starts with diff analysis without AC/doc table
  - ✅ Structured response: AC table → doc table → diff findings → triadic scores → verdict

7.7. **Do not code until review converges**
  - No critical contradictions remain
  - Weakest axis is acceptable (minimum: α ≥ B+, β ≥ B+, γ ≥ B)
  - Design is coherent enough to implement
  - ❌ Start coding while design review has open blockers
  - ✅ Resolve all contradictions, then implement

---

## 8. Test Derivation

8.1. **Derive tests from design, not from code**
  - Tests pin the spec; code realizes the spec; tests verify the realization
  - ❌ Write code, then write tests that describe what code happens to do
  - ✅ Read design invariants, write tests that assert them, then implement

8.2. **One test per non-trivial invariant**
  - Every invariant in the design should have at least one test
  - ❌ Design says "idempotent" but no test calls the operation twice
  - ✅ `let%expect_test "install is idempotent" = install (); install (); ...`

8.3. **One negative test per safety boundary**
  - Every security, isolation, or crash-safety claim needs a test that tries to violate it
  - ❌ Only test the happy path
  - ✅ Test: "unprivileged agent cannot write to another agent's state"

8.4. **Migration and backward-compat tests when applicable**
  - If the change claims backward compatibility, test it
  - ❌ "This is backward compatible" (assertion without evidence)
  - ✅ Test: "v1 config file loads correctly under v2 parser"

---

## 8.5. Author Pre-Flight

Before requesting peer review, the author MUST walk the acceptance criteria and verify the full change against them. §4.5.1 catches individual commits; this section is the aggregate check across the entire branch before review.

8.5.1. **Re-read the issue body**
  - Open the originating issue. Read every AC. Do not rely on memory.
  - ❌ "I think I covered everything"
  - ✅ Re-read issue #56, find 6 ACs, check each one

8.5.2. **Walk every AC against the diff**
  - For each AC: verify it is met in the diff, explicitly deferred with a tracking issue, or descoped with rationale
  - If any AC is not in any of these three categories, the change is not ready for review
  - ❌ 3 of 6 ACs addressed, other 3 not mentioned
  - ✅ "AC1 ✓ met (cn_runtime_contract.ml). AC4 ✗ not addressed → must fix or defer before review."

8.5.3. **Record AC coverage**
  - Write an AC coverage table in the PR description or design doc
  - This is the contract the reviewer verifies against
  - ❌ Ship with `Closes #56` and no AC coverage table
  - ✅ AC table: `| AC1 | Met | cn_runtime_contract.ml | AC4 | Deferred | #58 |`

8.5.4. **Spot-check 3 ACs that are marked "met"**
  - Pick 3 ACs at random, find the specific line/commit/test that satisfies them
  - If you cannot find evidence for an AC you marked "met," it is not met
  - ❌ Claim AC is met without verifying
  - ✅ "AC3 (cn doctor validates contract): verified — cn_system.ml L145-167"

8.5.5. **Do not request review until every AC is accounted for**
  - The author pre-flight is a hard gate: no unaccounted ACs may enter peer review
  - This is distinct from the release gate (§9.1) which is the reviewer's independent check
  - ❌ Request review hoping the reviewer will catch missing ACs
  - ✅ Every AC has a status before review is requested

---

## 9. Release Gate

Before merge or release, verify each item. A missing item is a known coherence debt — list it explicitly.

9.1. **Issue acceptance criteria verified**
  - Every AC from the originating issue is met, explicitly deferred, or descoped with rationale
  - This is the outermost contract — if code matches the design doc but misses issue ACs, the pipeline leaked
  - ❌ 3 of 6 ACs addressed, other 3 not mentioned anywhere
  - ✅ "ACs 1-3, 6 met. ACs 4-5 deferred to #58 (cn doctor, cn setup)."

9.2. **Design doc updated**
  - Reflects the change as implemented, not as originally proposed
  - ❌ Design doc describes the v1 plan; code ships v1.1
  - ✅ Design doc updated in the same branch

9.3. **Plan written (if substantial)**
  - Exists and was followed; deviations noted
  - ❌ Plan exists but implementation diverged silently
  - ✅ Plan updated with "deviated at step 4 — reason: X"

9.4. **Tests added or updated**
  - Cover new invariants and boundaries
  - ❌ "Tests will be added later"
  - ✅ Tests in the same PR as the code

9.5. **Code matches spec**
  - Types, interfaces, and behavior match the design doc
  - ❌ Design says `Result`, code uses exceptions
  - ✅ Code structure traces to design types

9.6. **Docs and operator surface updated**
  - README, architecture docs, operator guides reflect new behavior
  - ❌ New CLI flag with no docs
  - ✅ README updated, `--help` output verified

9.7. **Traceability updated**
  - If runtime behavior changed, traceability covers the new paths
  - ❌ New state transition with no reason codes
  - ✅ Transition logged with evidence and reason

9.8. **Release notes written**
  - CHANGELOG and/or PR description explain the coherence delta
  - ❌ Empty PR description
  - ✅ Summary: what gap was closed, what changed, what operators need to know

9.9. **Known coherence debt listed**
  - If anything is deferred, say so explicitly
  - ❌ Silently skip a release gate item
  - ✅ "Known debt: L2 transport docs not yet updated — tracked in issue #42"

9.10. **Coherence must not regress**
  - Score α/β/γ for the release; no axis may drop below the previous release
  - If an axis regresses, either fix it before release or list it as explicit known debt with a remediation plan
  - ❌ Ship v3.6.0 with β = B+ when v3.5.1 was β = A+, no explanation
  - ✅ "β dropped from A+ to A because traceability docs lag — tracked, will fix in v3.6.1"

9.11. **Previous release post-release assessment exists**
  - Before tagging a new release, verify that the previous release has a completed post-release assessment (§11)
  - The assessment may be individual or part of an epoch assessment covering the previous release
  - This gate prevents the accumulation of unassessed releases — the failure mode described in #85
  - ❌ Tag v3.15.0 when v3.14.5 has no post-release assessment
  - ✅ "v3.14.5 assessment exists (POST-RELEASE-EPOCH-v3.14.md covers v3.14.0–v3.14.5)"

---

## 10. Release and Close

After the release gate passes, execute the release. CDD orchestrates; sub-skills execute.

10.1. **Assign the version**
  - Apply §6 version rules — patch, minor, or major
  - Bump version in code before tagging
  - ❌ Tag without bumping the version constant in source
  - ✅ `sed -i 's/2.4.3/2.5.0/' cn_lib.ml` → commit → tag

10.2. **Tag and release**
  - Delegate to `release/SKILL.md` for the full procedure
  - Tag, push tags, create GitHub release with notes
  - ❌ Merge to main with no tag or release notes
  - ✅ `git tag v2.5.0` → `git push --tags` → `gh release create v2.5.0`

10.3. **Verify CI produced release artifacts**
  - Do not assume the release succeeded — confirm it
  - ❌ Push tag, move on
  - ✅ Check CI completed, artifacts exist, release page is populated

10.4. **Merge and ship**
  - Delegate to `ship/SKILL.md` for merge discipline
  - Author never self-merges; reviewer merges
  - ❌ Author merges their own PR
  - ✅ Reviewer approves → reviewer merges → author notified

10.5. **Delete the branch**
  - Only the branch creator deletes — local and remote
  - ❌ Leave merged branches accumulating on remote
  - ✅ `git branch -d feature-branch` → `git push origin --delete feature-branch`

10.6. **Announce**
  - Notify peers that the change shipped
  - ❌ Merge silently — peers discover it later via stale branches
  - ✅ Outbox message: "Shipped X to main — branch deleted"

10.7. **Observe the running system**
  - CDD does not end at merge — confirm runtime matches design
  - Check structural coherence: packages installed, capabilities rendered, state = ready
  - ❌ Ship and forget
  - ✅ Verify boot, check telemetry, confirm no silent fallback

---

## 11. Post-Release Assessment

CDD does not end at merge. Every release triggers a post-release assessment that measures what shipped, what the system looks like now, and what to do next. Delegate to `ops/post-release/SKILL.md` for the full procedure.

The assessment has four parts: measurement, encoding lag, process learning, and next-move decision.

### Measurement

11.1. **Score before starting**
  - Record the baseline α/β/γ from the previous release in the coherence contract
  - This is the starting point the change must improve or hold
  - ❌ Start work without knowing current coherence state
  - ✅ "Baseline: v3.5.1 — α A+, β A+, γ A+. This change targets β."

11.2. **Score after release**
  - Score α/β/γ for the new release using the same triadic axes
  - Compare against baseline: which axes improved, held, or regressed?
  - ❌ Ship without scoring — coherence improvement is unverifiable
  - ✅ "v3.6.0 — α A+, β A+ (held), γ A+ (held). Traceability gap closed."

11.3. **Update the CHANGELOG TSC table**
  - Every minor and major release adds a row to the TSC table in `CHANGELOG.md`
  - Include: version, C_Σ, α, β, γ, and a coherence note describing the delta
  - ❌ Release with no CHANGELOG TSC entry
  - ✅ `| v3.6.0 | A+ | A+ | A+ | A+ | CDD skill: executable development method, full lifecycle. |`

11.4. **Name what improved and what regressed**
  - The coherence note must describe which incoherence was reduced, not what feature was added
  - If an axis didn't improve, say why — it's either acceptable or known debt
  - ❌ "Added CDD skill" / silent axis stagnation
  - ✅ "CDD: development method made executable — closes gap between doctrine and practice. γ held — no evolution-path changes, expected."

11.5. **Close the coherence contract loop**
  - The coherence contract (§4.2) stated the gap and expected triadic effect
  - Measurement validates whether the expected effect was achieved
  - If not achieved, record why and what remains
  - ❌ Contract says "improve β" but no post-release β score recorded
  - ✅ Contract: "improve β" → Result: "β A+ (held), alignment verified"

### Encoding Lag

11.6. **Encoding lag report**
  - Every release MUST include an encoding lag table
  - For each open design issue: design status, implementation status, lag level
  - This is the system-level health check — is the model outpacing the body?

  ```
  ### Encoding Lag (as of vX.Y.Z)
  | Issue | Title | Type | Design | Impl | Lag |
  |-------|-------|------|--------|------|-----|
  | #62   | RT Contract v2 | feature | converged | branch exists | low |
  | #73   | Extensions | feature | converged | not started | growing |
  | #97   | Review pre-flight | process | converged | not started | growing |
  ```

  - **Type:** `feature` (design/code gap) or `process` (development method gap). Process issues enter the lag table and are subject to the same freeze triggers as feature issues
  - **Lag levels:** none (shipped), low (in progress), growing (design done, no impl), stale (design aging, impl not planned)
  - ❌ Release with 5 converged designs and no encoding lag report
  - ❌ Omit process issues from the encoding lag table
  - ✅ "Encoding lag: 2 growing (1 feature, 1 process), 1 low. MCI freeze recommended."

11.7. **MCI/MCA balance decision**
  - Based on the encoding lag report, decide the next move:
    - **Balanced:** design and implementation roughly in sync. Continue normally.
    - **Freeze MCI:** encoding lag is growing on ≥3 issues, or designs outnumber implementations 3:1, or any "SHALL" in docs has no runtime enforcement. Stop designing, start shipping.
    - **Resume MCI:** implementation has caught up. Design frontier can advance.
  - This decision is mandatory. Every release must state the balance.
  - ❌ Ship and start the next feature without assessing balance
  - ✅ "3 designs at growing lag. Freezing MCI. Next sessions are pure MCA."

### Process Learning

11.8. **What went wrong**
  - What broke, failed, or was caught late in this release cycle?
  - What would have caught it earlier?
  - ❌ Ship cleanly and skip — process learning only happens after failures
  - ✅ "Review missed CAA.md update because §2.0 gate wasn't enforced. Added structural table format."

11.9. **What went right**
  - What process improvement from previous releases paid off?
  - What should be reinforced or standardized?
  - ❌ Only record failures
  - ✅ "§2.0 AC table caught 3 missing ACs that would have slipped in previous review style."

11.10. **Skill/process patches**
  - If the post-mortem identifies a repeatable failure mode, patch the relevant skill immediately
  - Do not defer — the next release will hit the same bug
  - ❌ "We should fix the review process" (noted, not patched)
  - ✅ Commit skill patch in the same session as the post-mortem

### Review Quality

11.11. **Review quality metrics**
  - Every post-release assessment MUST report review quality for all PRs in the release cycle:
  - **Rounds per PR:** count of review iterations (comments requesting changes + fix commits) before merge. Target: ≤1 for docs PRs, ≤2 for code PRs.
  - **Supersede rate:** count of PRs closed-not-merged and replaced by a successor PR. Target: 0.
  - **Finding taxonomy:** tag each review finding as `mechanical` (automatable — stale cross-refs, missing scope items, wrong branch name) or `judgment` (design coherence, architecture trade-offs). Report the ratio.
  - **Feedback loop:** if mechanical findings exceed 20% of total findings in any release cycle, file an issue to add the missing pre-flight check. This is a process bug, not a reviewer skill gap.
  - ❌ Ship without reporting review round count or finding types
  - ❌ Treat 3 superseded PRs as normal cost of doing business
  - ✅ "5 PRs this cycle. Avg 1.2 rounds. 0 superseded. 2 mechanical findings (stale cross-refs) / 8 total → 25% mechanical → filed #97."

11.12. **Process debt integration**
  - Repeatable failure modes identified in §11.8–§11.11 MUST be filed as issues
  - Process issues appear in the encoding lag table (§11.6) alongside feature issues with `type: process`
  - Process issues are subject to the same MCI freeze triggers as feature issues (§11.7)
  - The §9.11 release gate checks that P0 process findings from the previous assessment are addressed or explicitly deferred with rationale
  - ❌ Identify a process failure, note it in the assessment, never file an issue
  - ✅ "Stale cross-refs caught 3 times → filed #97 (process) → appears in lag table → addressed in v3.14.7"

---

## Orchestration

CDD is the main module. It owns the lifecycle from branch to observation and measurement. Sub-skills handle execution:

| CDD phase | Delegated to |
|---|---|
| Design doc creation | `eng/design/SKILL.md` |
| Code implementation | `eng/coding/SKILL.md` |
| Test structure | `testing/SKILL.md` |
| Doc updates | `documenting/SKILL.md` |
| Merge to main | `eng/ship/SKILL.md` |
| Tag, changelog, GitHub release | `release/SKILL.md` |
| Review protocol | `eng/review/SKILL.md` |
| Cross-ref validation (file moves) | `eng/review/SKILL.md` §2.2.5 |
| Post-release assessment | `ops/post-release/SKILL.md` |
| Coherence scoring | `CHANGELOG.md` TSC table |

CDD defines what must happen and in what order. Sub-skills define how.

---

## Authority

This skill is the **executable summary** of CDD. The **authoritative source** for the full artifact contract, pipeline table, frozen-snapshot rules, self-coherence report format, and governance detail is `docs/gamma/cdd/CDD.md`. When this skill and the canonical doc disagree, the canonical doc governs — except for sections added in v3.14.7 (§1.5, §11.11, §11.12) which exist only in this skill pending canonical update. Until the canonical doc is updated to include these sections, this skill is authoritative for them.

---

## Reference

- Coherence history: `CHANGELOG.md` (TSC table — α/β/γ per release)
- **Canonical CDD method doc: `docs/gamma/cdd/CDD.md`** (authoritative for full artifact contract)
- Triadic coherence model: `packages/cnos.core/doctrine/COHERENCE.md`
- CAP (MCA/MCI): `packages/cnos.core/doctrine/CAP.md`
- Agile workflow integration: `docs/gamma/cdd/AGILE-PROCESS.md`
- Release procedure: `packages/cnos.core/skills/release/SKILL.md`
- Design doc creation: `packages/cnos.eng/skills/eng/design/SKILL.md`
- Code coherence: `packages/cnos.eng/skills/eng/coding/SKILL.md`
- Test structure: `packages/cnos.core/skills/testing/SKILL.md`
- Doc coherence: `packages/cnos.core/skills/documenting/SKILL.md`
