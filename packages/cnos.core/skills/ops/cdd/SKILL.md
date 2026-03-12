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

CDD owns the full arc from branch to observation:

1. **Branch** — create the branch (§1.4)
2. **Gap** — name the incoherence (§2)
3. **Mode** — choose MCA or MCI (§3)
4. **Artifacts** — design → contract → plan → tests → code → docs (§4)
5. **Review** — CLP with another CA until convergence (§7)
6. **Gate** — verify the release checklist (§9)
7. **Release** — version, tag, CI, merge, announce (§10)
8. **Observe** — confirm runtime matches design (§10.7)

Start at step 1. Everything else follows in order.

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
  - Branch name encodes the change scope
  - ❌ Work on `main`, commit design doc directly
  - ✅ `claude/v3.9.0-workspace-constitution-abc` — version + focus + suffix
  - ✅ `claude/cdd-executable-skill-PfdYZ` — feature + suffix
  - ✅ `claude/fix-heartbeat-silent-death-xQ2` — fix + dominant incoherence + suffix

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

4.1. **Design doc**
  - Create or update before coding
  - ❌ Code first, backfill the design doc
  - ✅ Design doc states types, interfaces, workflow → code realizes it

4.2. **Coherence contract**
  - State: gap, mode, scope, expected triadic effect, failure if skipped
  - ❌ PR with no stated purpose beyond "implements feature X"
  - ✅ Coherence contract in PR description or design doc header

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

4.6. **Docs**
  - Updated to match implementation — README, operator guides, architecture
  - ❌ Ship code, leave docs describing the old behavior
  - ✅ Docs updated in the same PR or immediately after

4.7. **Release notes**
  - Explain the coherence delta to operators and contributors
  - ❌ "Various improvements"
  - ✅ "Added L2 transport — operators can now configure push-based sync"

---

## 5. File Naming Rules

5.1. **Existing design line — amend it**
  - If changing an existing design lineage, update the existing file
  - Add patch notes or version bump inside it
  - ❌ Create `AGENT-RUNTIME-v2.md` alongside the original
  - ✅ Update `docs/design/AGENT-RUNTIME.md`, bump version header

5.2. **New subsystem — create a versioned design doc**
  - Pattern: `docs/design/NAME-vMAJOR.md`
  - ❌ `docs/design/new-thing.md` (no version)
  - ✅ `docs/design/CAA-v1.md`
  - ✅ `docs/design/CAR-v3.4.md`

5.3. **Implementation plan**
  - Feature/release scoped: `docs/design/PLAN-vX.Y.Z.md` (e.g. `PLAN-v3.6.0.md`)
  - Subsystem scoped: `docs/design/NAME-implementation-plan.md` (e.g. `CAR-implementation-plan.md`)
  - ❌ Plan buried in a thread or issue comment
  - ✅ `docs/design/CAR-implementation-plan.md`
  - ✅ `docs/design/PLAN-v3.6.0.md`

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
  - Triadic scores (letter grades)
  - Weakest axis identified
  - Concrete patches (at least 3 for weakest)
  - Contradictions or orphans found
  - Verdict: iterate or converge
  - ❌ Free-form "looks good" review
  - ✅ Structured response with all five elements

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

## 9. Release Gate

Before merge or release, verify each item. A missing item is a known coherence debt — list it explicitly.

9.1. **Design doc updated**
  - Reflects the change as implemented, not as originally proposed
  - ❌ Design doc describes the v1 plan; code ships v1.1
  - ✅ Design doc updated in the same branch

9.2. **Plan written (if substantial)**
  - Exists and was followed; deviations noted
  - ❌ Plan exists but implementation diverged silently
  - ✅ Plan updated with "deviated at step 4 — reason: X"

9.3. **Tests added or updated**
  - Cover new invariants and boundaries
  - ❌ "Tests will be added later"
  - ✅ Tests in the same PR as the code

9.4. **Code matches spec**
  - Types, interfaces, and behavior match the design doc
  - ❌ Design says `Result`, code uses exceptions
  - ✅ Code structure traces to design types

9.5. **Docs and operator surface updated**
  - README, architecture docs, operator guides reflect new behavior
  - ❌ New CLI flag with no docs
  - ✅ README updated, `--help` output verified

9.6. **Traceability updated**
  - If runtime behavior changed, traceability covers the new paths
  - ❌ New state transition with no reason codes
  - ✅ Transition logged with evidence and reason

9.7. **Release notes written**
  - CHANGELOG and/or PR description explain the coherence delta
  - ❌ Empty PR description
  - ✅ Summary: what gap was closed, what changed, what operators need to know

9.8. **Known coherence debt listed**
  - If anything is deferred, say so explicitly
  - ❌ Silently skip a release gate item
  - ✅ "Known debt: L2 transport docs not yet updated — tracked in issue #42"

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

## Orchestration

CDD is the main module. It owns the lifecycle from branch to observation. Sub-skills handle execution:

| CDD phase | Delegated to |
|---|---|
| Design doc creation | `eng/design/SKILL.md` |
| Code implementation | `eng/coding/SKILL.md` |
| Test structure | `testing/SKILL.md` |
| Doc updates | `documenting/SKILL.md` |
| Merge to main | `eng/ship/SKILL.md` |
| Tag, changelog, GitHub release | `release/SKILL.md` |
| Review protocol | `eng/review/SKILL.md` |

CDD defines what must happen and in what order. Sub-skills define how.

---

## Reference

- Theory and rationale: `docs/design/CDD.md`
- Triadic coherence model: `packages/cnos.core/doctrine/COHERENCE.md`
- CAP (MCA/MCI): `packages/cnos.core/doctrine/CAP.md`
- Agile workflow integration: `docs/design/AGILE-PROCESS.md`
- Release procedure: `packages/cnos.core/skills/release/SKILL.md`
- Design doc creation: `packages/cnos.eng/skills/eng/design/SKILL.md`
- Code coherence: `packages/cnos.eng/skills/eng/coding/SKILL.md`
- Test structure: `packages/cnos.core/skills/testing/SKILL.md`
- Doc coherence: `packages/cnos.core/skills/documenting/SKILL.md`
