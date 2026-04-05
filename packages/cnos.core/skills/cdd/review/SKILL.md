---
name: review
description: Review changes so every verdict traces to evidence in the diff, the surrounding contract, and the relevant unchanged context.
artifact_class: skill
kata_surface: embedded
governing_question: How do we verify that a change closes its declared gap without creating a larger incoherence elsewhere?
---

# Review

Review code so that every verdict traces to evidence in the diff and its surrounding contract.

## Core Principle

**Coherent review: every claim is verified against the diff, its required surrounding contract, and the relevant unchanged context — and no incoherence passes without being named.**

---

## 1. Define

### 1.1. Identify the parts

- Diff — what changed
- Context — unchanged code, named docs/specs, required branch artifacts, CI/release-gate state
- Verdict — approve or request changes
- Evidence — line, commit, artifact, or behavior that supports a claim
  - ❌ "This looks wrong"
  - ✅ "Line 42 stages all files, but git_stage validates per-file — compound behavior"

### 1.2. Articulate how they fit

- The diff proposes or modifies an invariant.
- Context must still cohere with that invariant.
- The verdict reflects the worst named incoherence.
- Evidence anchors every claim.
  - ❌ Review the diff in isolation
  - ✅ Review the diff, then check whether unchanged siblings now violate the invariant it establishes

### 1.3. Name the failure mode

Review fails via **surface reading** — checking only what changed, missing what the change implies for the rest of the system.

  - ❌ "All changed functions look correct"
  - ✅ "Three observe ops now use exclusions; the unchanged fourth one no longer matches the pattern"

---

## 2. Unfold

### 2.0. Issue — what was promised

**GATE: Complete §2.0 before reading the diff.** The review is structurally incomplete if these tables are absent.

```markdown
## §2.0 Issue Contract

### AC Coverage
| # | AC | In diff? | Status (met / partial / missing / deferred) |
|---|----|----------|---------------------------------------------|

### Named Doc Updates
| Doc / File | In diff? | Status (updated / absent / deferred) |
|------------|----------|--------------------------------------|
```

2.0.1. **Walk every acceptance criterion**
  - Each AC is either:
    - met
    - partially met
    - explicitly deferred
    - missing
  - The absence of a required change is a finding.
  - ❌ Review only what changed without checking what was promised
  - ✅ "AC 4 (cn doctor validates contract) — not addressed in diff, no known-debt note → D"

2.0.2. **Check required spec/doc updates**
  - If the issue requires a spec or design doc change, verify that file was changed.
  - If the issue or plan names specific docs, check each one.
  - Missing required doc/spec updates are β gaps between issue contract and implementation.
  - ❌ "Diff looks clean" (required spec update missing)
  - ✅ "Issue names 5 docs; 2 updated, 3 absent — are these deferred or forgotten?"

2.0.3. **Distinguish scope reduction from omission**
  - If scope was intentionally narrowed, the commit/PR should say so.
  - Unmentioned AC omissions are findings.
  - Noted deferrals are known debt.
  - ❌ Assume missing AC was intentionally deferred
  - ✅ "3 of 6 ACs met; remaining 3 not mentioned — are these deferred or forgotten?"

2.0.4. **AC strength — "met" means fully met**
  - If an AC says "validate X against Y" and the code only checks "X exists," that is partial, not met.
  - Partial ACs are findings.
  - ❌ "Doctor checks for the key → AC met"
  - ✅ "AC says validate against runtime state; code checks key presence only → partial"

2.0.5. **CDD artifact contract**
  - Determine the change class:
    - bugfix
    - substantial feature
    - governance/process
    - release hardening
  - Verify the required CDD artifacts for that class exist in the diff or branch. Suggested minimums:
    - substantial feature — design doc, coherence contract, implementation plan, tests, code, docs, self-coherence
    - bugfix — coherence contract (may live in issue/PR/commit body), tests, code, self-coherence if substantial
    - governance/process — self-coherence, frozen snapshot if versioned, plan if the branch formalizes process changes
    - release hardening — changelog, release artifacts, post-release assessment if method requires it
  - Missing required artifacts are findings.
  - ❌ "Diff looks clean" (governance branch has no self-coherence report)
  - ✅ "Substantial feature branch — design doc exists, self-coherence exists, bootstrap stubs present"

2.0.6. **Process economics check**
  - If the diff adds or changes process, governance, artifacts, or gates, verify:
    - the failure class being prevented is named
    - the consumer of the new artifact/gate is named
    - a lighter alternative was considered
    - the process burden is proportionate to the failure class
    - an automation boundary or sunset/review criterion is stated where appropriate
  - ❌ "Added a new required artifact for rigor"
  - ✅ "SELF-COHERENCE.md is required for governance branches because reviewer and releaser need branch-local proof of process conformance"
  - ✅ "This stale-path check should be a script, not a repeated reviewer burden"

2.0.7. **Active skill consistency (CDD §4.4)**
  - If the design/contract artifact declares active skills, verify:
    - the declared skills are present in the branch or loaded context
    - the implementation is consistent with them
    - findings that a declared active skill would have prevented are process debt (§6.1 / mechanical)
  - ❌ "Active skills: ocaml" but code has `List.hd` and bare `with _ ->` (OCaml skill §3.1 violations)
  - ✅ "Active skills: ocaml, performance-reliability — implementation consistent with both"

2.0.8. **CDD execution trace (CDD §5.4)**
  - For substantial changes, verify that the primary branch artifact contains a CDD Trace.
  - Check that rows exist for all completed steps through the current review point.
  - Check that step 5 records: mode, active skills, work shape, and level if level shorthand is used.
  - Check that any lifecycle skill already used (review, writing, release) is recorded when relevant.
  - Missing or contradictory rows are findings.
  - ❌ "Design exists" but no visible trace of selection, mode, or loaded skills
  - ✅ "Trace rows cover observe, select, mode, and current artifacts; decisions align with the diff"

---

### 2.1. Diff — what changed

Read the diff for internal coherence.

2.1.1. **Check each change against its stated purpose**
  - Commit/PR says X, diff does Y.
  - ❌ "feat: add fs_glob" but glob still returns not_yet_implemented
  - ✅ "feat: add fs_glob" and executor path is complete

2.1.2. **Check changes against each other**
  - Multiple commits in a branch must tell one story.
  - ❌ Commit 3 silently undoes commit 1
  - ✅ Fix commits narrow the remaining blockers and reference what they fix

2.1.3. **Mechanical diff scan**
  - Before judgment checks, run mechanical scans on the diff itself:
    - Grep for duplicate entries in any list/array literal added or modified
    - Verify branch name matches project convention (e.g. CDD branch format)
    - If tests are in the diff, verify expect-test outputs are plausible (exact strings, whitespace)
    - Check new type definitions for overlapping field names within the same module — each shared name creates a disambiguation burden at every access site (see OCaml skill §3.1)
    - **Unicode hygiene**: scan added lines for hidden/bidi control characters (U+200B..U+200F, U+202A..U+202E, U+2066..U+2069, U+FEFF, Unicode category Cf). These are blocker-worthy. Visible Unicode (emoji, em dashes, arrows, Greek letters) in human-facing content files (templates, docs) is allowed and not a finding. Do not conflate GitHub's "hidden characters" warning with the presence of visible Unicode — the warning targets invisible control characters, not content.
  - These are deterministic — two reviewers running the same grep must find the same results.
  - ❌ Read the diff for logic only
  - ✅ "L74: `<invoke>` appears twice in `xml_prefixes` — duplicate entry"
  - ✅ "`extension_op.kind` and `backend.kind` share field name in same module — rename to `op_kind`/`backend_kind`"
  - ❌ "File contains Unicode" (without naming specific hidden/bidi codepoints)
  - ✅ "L42 contains U+202E (RIGHT-TO-LEFT OVERRIDE) — hidden bidi control, D finding"
  - ✅ "SOUL.md contains U+2705 (CHECK MARK) — visible content emoji, not a finding"

---

### 2.2. Context — unchanged siblings

Check whether the change creates obligations on code it did not touch.

2.2.1. **Sibling consistency**
  - If you harden 3 of 4 peers at the same level, the 4th is now incoherent.
  - ❌ "All changed ops look good"
  - ✅ "Three observe ops use exclusions; git_status still doesn't"

2.2.1a. **Input-source enumeration for filters/sanitizers/validators**
  - When the diff adds or modifies a function that filters, sanitizes, or validates, enumerate every input source (caller/call site) that feeds it. Verify each input gets the full pipeline.
  - This is mandatory for security-relevant paths (sanitization, auth, access control).
  - This is also mandatory when the PR claims a failure class is "impossible by construction" or "structurally prevented" — any such claim requires exhaustive input-source enumeration at the same rigor as a security boundary. An unchecked input source contradicts the closure claim and is a D-level finding.
  - ❌ "Body goes through the stripper — looks good"
  - ❌ "fs_read is intercepted — membrane complete" (didn't check fs_list children, fs_glob, git_grep)
  - ✅ "Body goes through strip_xml + strip_frontmatter. Reply goes through is_control_plane_like only. Reply is missing strip_xml — sibling gap."
  - ✅ "Self-knowledge membrane covers fs_read and fs_list direct path. Remaining input sources: fs_list child entries, fs_glob results, git_grep content — 3 surfaces still open. Claim 'impossible by construction' is not yet earned."
  - When the diff introduces a **new data surface** (new log stream, new file format, new query endpoint), enumerate both write paths (what emits to it) AND read paths (what consumes from it). Verify read-path semantics (ordering, filtering, truncation) match the operator-facing contract, not just that writes are correct.
  - ❌ "All 6 emission points are correct" (didn't verify the reader returns correct chronological order across day boundaries)
  - ✅ "6 emission points verified. Reader `read_recent` iterates files newest-first, reverses — cross-day order is wrong. Filtered path concatenates without global sort."

2.2.1b. **Sibling fallback audit for compatibility/legacy paths**
  - When the diff removes, converts, or justifies one legacy/fallback/compatibility path, enumerate sibling fallback paths in the same module/family and verify they are:
    - also removed,
    - also converted,
    - or explicitly kept with justification.
  - This is mandatory for patterns such as:
    - `with _ -> []`
    - `with _ -> None`
    - silent compatibility aliases
    - resolver/scanner paths that swallow missing resources
  - ❌ "Converted one `with _ ->` — looks good"
  - ✅ "Converted `read_opt`, then audited sibling `with _ -> []` in `list_installed_packages` and `walk_skills`"

2.2.2. **Cross-module leakage**
  - Follow what the changed code writes/produces and inspect what reads/exposes it.
  - ❌ Review executor in isolation
  - ✅ "Executor writes state/artifacts/; git_status now exposes those paths"

2.2.3. **Multi-format parity**
  - If a module renders to multiple formats (markdown + JSON, prompt + disk, human + machine), verify both carry equivalent semantic content.
  - ❌ Review render_markdown and to_json independently
  - ✅ "Markdown includes capabilities sub-block; JSON omits it"

2.2.4. **Exclusion symmetry**
  - If paths are excluded in one place, verify they are excluded everywhere they should be.
  - ❌ "Exclusions look correct in git_diff"
  - ✅ Grep every use of the exclusion set and verify parity

2.2.5. **Cross-reference validation (file moves)**
  - If files move or are renamed, grep for old paths across all live docs.
  - Any live stale path is a D-level blocker.
  - Frozen snapshot dirs may allow path-only repair if the docs system explicitly permits it.
  - ❌ Approve a file-move PR without grepping
  - ✅ Grep old path → zero live matches

2.2.6. **Execution timeline for state-changing paths**
  - If code crosses process or binary boundaries, trace which process owns which values at each step.
  - ❌ "This reads the version in process, so it's current"
  - ✅ "Old process still holds old constants after replacement; re-exec before reading"

2.2.7. **Derivation vs validation**
  - If an AC claims "single source of truth" or "one-file edit," verify that a generation step exists, not only a check.
  - ❌ "CI script checks VERSION parity → one-file bump met"
  - ✅ "No generation step exists; multiple manual edits still required"

2.2.8. **Authority-surface conflict**
  - When multiple surfaces claim to define the same thing, verify they agree. Common conflict sites:
    - canonical doc vs executable skill
    - runtime prompt-visible contract vs machine-readable JSON
    - issue ACs vs narrower coherence contract in PR body
    - branch summary vs actual branch state
    - runtime defaults vs documented defaults
  - ❌ "Skill looks correct" (didn't compare with canonical doc)
  - ✅ "Canonical doc and executable skill agree on artifact contract"

2.2.9. **Module-truth audit for model-correctness changes**
  - When a change is about **correctness of a model** (package truth, config truth, type safety, schema alignment, profile/manifest consistency), do not limit review to the diff. Scan the full touched module for other assumptions of the same kind.
  - Ask: "What else in this module assumes the same thing the diff is fixing? Are those assumptions still valid?"
  - Common sites: hardcoded lists, profile/package name references, format assumptions, default values, conditional branches for categories that no longer exist.
  - ❌ "The diff fixes the restore path — approve" (didn't check whether the same module still hardcodes a stale package name elsewhere)
  - ✅ "Diff fixes restore_one for AC3; but default_manifest_for_profile in the same module still references cnos.pm which doesn't exist — C finding"

2.2.10. **Contract-implementation confinement check**
  - When a function's docstring, AC, or PR description claims a restricted input domain (e.g. "bare names only," "positive integers," "known enum values"), verify the implementation actually **rejects** inputs outside that domain.
  - The function may correctly handle the claimed inputs while silently accepting unclaimed ones — that's a confinement gap, not a correctness bug.
  - Ask: "What inputs does the contract exclude? Does the code reject them, or just not test them?"
  - ❌ "resolve_command handles bare names correctly — approve" (didn't check that `../foo` is also accepted)
  - ✅ "Contract says 'bare command names' but code accepts any relative path including `../foo` — path confinement gap, D finding"

2.2.11. **Architecture leverage check**
  - Ask explicitly whether the diff merely improves the current architecture or misses a higher-leverage boundary move.
  - Useful prompts:
    - Is this repeated pressure being treated as a one-off patch?
    - Is the right abstraction being introduced at the right layer?
    - Should this become a primitive, package, extension, config rule, or be deleted instead?
  - ❌ "The local fix is correct" (never asked whether the architecture assumption should change)
  - ✅ "This fix is coherent locally, but the repeated capability-growth pressure suggests an extension architecture instead of another built-in"

2.2.12. **Process overhead check**
  - If the diff adds new docs, artifacts, gates, or procedures, ask:
    - What exact failure does this prevent?
    - Who uses the new artifact?
    - Could this be automated instead?
    - Is this branch class carrying the right amount of ceremony?
  - ❌ "More governance is always safer"
  - ✅ "This new step catches stale artifact references, but the check is mechanical and should move to CI/lint"

---

### 2.3. Verdict — the judgment

The verdict is a function of the worst named incoherence.

2.3.1. **Every claim traces to evidence**
  - No "seems wrong." Point to a line, commit, file, artifact, or runtime behavior.
  - ❌ "Security model seems weak"
  - ✅ "Line 277 passes user input to git grep without -e"

2.3.2. **Validate fixes against upstream spec where applicable**
  - If a fix relies on external behavior (Git, library, API), verify against upstream docs.
  - ❌ "The pathspec seems to work"
  - ✅ "Git docs confirm exclude-pathspec semantics"

2.3.3. **Name the severity**
  - D — blocker, demonstrable incoherence
  - C — significant incoherence, non-blocking
  - B — improvement opportunity
  - A — polish

2.3.4. **Specify regression pairs for blockers**
  - Every D-level finding includes:
    - positive case
    - negative case
  - ❌ "Fix git_status"
  - ✅ "Positive: show src/ changes. Negative: hide .cn/, state/, logs/."

2.3.5. **Close the search space on approval**
  - Approval explicitly states that no remaining blocker was found in the relevant contract.
  - ❌ "APPROVED"
  - ✅ "APPROVED — I do not see a remaining blocker in the executor/sandbox contract"

2.3.6. **Evidence depth matches claim strength**
  - When judging whether an AC is met, verify that the evidence depth matches the claim:
    - structural claim → unit/schema proof may suffice
    - runtime behavior claim → path/integration proof may be required
    - operator contract claim → output/projection/state artifact may be required
  - ❌ "Predicate tests exist → runtime filtering AC met"
  - ✅ "Predicate tests prove the predicate; no integration test proves the queue/offset path"

2.3.7. **Review divergence is a review-skill gap**
  - When two reviewers review the same PR and one catches findings the other missed, the divergence is a gap in this skill — not in the reviewer who missed it.
  - After identifying the divergence:
    1. Name which review-skill step, if followed, would have caught the missed finding
    2. If no step covers it, add one
    3. If a step exists but is too vague, sharpen it
  - The fix is always a patch to this skill. Never "reviewer should have been more careful."
  - After patching the skill, capture the divergence analysis in a durable adhoc thread (what happened, why, what changed, what to watch for). This converts session-local learning into cross-session continuity.
  - ❌ "I missed the stale cnos.pm reference — I'll look harder next time"
  - ✅ "I missed it because no review-skill step says to scan the full touched module for same-kind assumptions. Added §2.2.9 (module-truth audit). Adhoc thread: `20260328-review-divergence-pr130.md`."

2.3.8. **Higher-leverage alternative check**
  - A diff may be locally correct and still miss the more coherent system move.
  - Name that explicitly as a review note or finding when appropriate.
  - ❌ "Looks correct, approved" when the change repeats a known architectural pressure
  - ✅ "Locally correct, but repeated pressure suggests a higher-leverage architecture move; approve with note / request changes depending on scope"

---

## 3. Rules

3.1. **Read the diff, then read the neighbors**
  - The diff is the figure; unchanged siblings are the ground.

3.2. **Trace system writes to system reads**
  - If changed code writes files/state, check what reads/exposes them.

3.3. **One round, one narrowing**
  - Each review round acknowledges fixes by commit hash and names only remaining blockers.

3.4. **Verdict before details**
  - Lead with APPROVED / REQUEST CHANGES.

3.5. **No phantom blockers**
  - Only block on incoherence you can demonstrate.

3.6. **Approve when coherent, not when perfect**
  - The bar is coherence, not taste.

3.7. **CI / release-gate state**
  - If merge is requested, verify required CI/build checks are complete and green.
  - "Green" means all required checks have **completed** with a passing status — not that a single snapshot of `gh pr checks` showed green. Checks may be re-running, queued, or in an intermediate state.
  - If checks are missing, stale, re-running, or red, approval is provisional and the merge instruction must say "Do not merge until checks finish green."
  - Do not issue an unconditional merge instruction when required checks have not run or are not in a final completed state.

3.8. **Merge instruction is explicit and scoped**
  - Approval names the exact branch, PR number, and action.

---

## 4. Checklist

Before submitting a review:

- [ ] Every issue AC verified (met, partial, missing, or deferred)
- [ ] Required named docs/files checked
- [ ] Required CDD artifacts for this change class exist and are internally consistent
- [ ] New governance/process artifacts earn their cost and name their consumer
- [ ] Declared active skills verified: present, implementation consistent, violations are process debt
- [ ] Mechanical diff scan: duplicates in lists, branch name convention, expect-test plausibility
- [ ] Every claim traces to evidence
- [ ] Severity assigned to every finding
- [ ] Type assigned to every finding (mechanical / judgment)
- [ ] Multi-format outputs checked for semantic parity
- [ ] Authority surfaces checked for conflict where multiple define the same thing
- [ ] Sibling fallback paths audited when one fallback/compatibility path was touched (§2.2.1b)
- [ ] Higher-leverage architecture move considered where repeated pressure is visible
- [ ] Added process burden checked for lighter alternatives / automation boundary
- [ ] Unchanged siblings checked for new incoherence
- [ ] For model-correctness changes: full touched module scanned for other assumptions of the same kind
- [ ] For restricted-domain functions: contract claims verified against actual rejection of out-of-domain inputs
- [ ] For filters/sanitizers/validators: all input sources enumerated, full pipeline verified on each
- [ ] For "impossible by construction" / structural closure claims: input-source enumeration at security-level rigor (§2.2.1a)
- [ ] For new data surfaces (logs, streams, query endpoints): both write paths AND read paths verified (§2.2.1a)
- [ ] File-move cross-refs validated by grep where applicable
- [ ] System writes traced to system reads
- [ ] Evidence depth matches claim strength
- [ ] D-level findings include regression test pairs
- [ ] Prior-round fixes acknowledged by commit hash (multi-round only)
- [ ] CI/build checks green, or approval explicitly marked provisional
- [ ] Approval explicitly closes the search space
- [ ] Merge instruction names branch and PR number
- [ ] Verdict stated first

---

## 5. Severity

| Level | Meaning | Action |
|-------|---------|--------|
| **D** | Incoherence demonstrable with a test or direct contradiction | REQUEST CHANGES |
| **C** | Real incoherence, non-blocking | APPROVED with note |
| **B** | Improvement opportunity | APPROVED |
| **A** | Polish | APPROVED |

### 5.1. Finding taxonomy

Every finding MUST be tagged as one of:

| Type | Definition | Examples |
|------|-----------|----------|
| **mechanical** | Could be caught by grep/diff/script without judgment | stale path, wrong branch name, snapshot mismatch, broken link |
| **judgment** | Requires design/coherence assessment | missing AC coverage, authority conflict, design trade-off |

Mechanical findings reaching review are **process bugs**. If mechanical findings exceed 20% of total findings in a release cycle, file a process issue.

---

## 6. Output Format

```markdown
**Verdict:** APPROVED / REQUEST CHANGES

**Round:** N (if multi-round)
**Fixed this round:** {commit hashes} closes {prior findings} (if applicable)
**CI state:** green / provisional / out of scope
**Merge instruction:** Merge PR #{n} on {branch} / Do not merge yet

## §2.0 Issue Contract

### AC Coverage
| # | AC | In diff? | Status | Notes |
|---|----|----------|--------|-------|

### Named Doc Updates
| Doc / File | In diff? | Status | Notes |
|------------|----------|--------|-------|

### CDD Artifact Contract
| Artifact | Required? | Present? | Notes |
|----------|-----------|----------|-------|

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| 1 | git_status leaks internal paths | L179: no exclusions | D | judgment |
| 2 | stale path to docs/gamma/RULES.md | grep match in ARCHITECTURE.md | D | mechanical |

## Regressions Required (D-level only)

1. Positive case ...
2. Negative case ...

## Notes

(additional context, suggestions, questions)
```

---

## 7. After Review

- **Approved:** Reviewer merges (or signals merge-ready per repo workflow), branch cleaned up
- **Changes requested:** Author fixes, re-requests; reviewer narrows on the next round

### 7.1. Review identity

The reviewer must have a different GitHub identity than the PR author so that:
- `gh pr review --request-changes` and `--approve` use native GitHub review state
- Branch protection can enforce "approving review from non-author"
- Review audit trail is platform-native, not comment-based

If the reviewer shares the author's GitHub account, reviews degrade to comments and review state is unenforceable. This is a known gap (tracked in #45 migration queue) — when it applies, note "posted as comment (shared identity)" in the review.

---

## 8. Kata

**Scenario:** A PR adds a new validation function and claims "structurally prevented" for a failure class. Review it.

1. Complete §2.0 before reading the diff — walk every AC, check named docs
2. Read the diff for internal coherence
3. Enumerate all input sources that feed the validator (§2.2.1a)
4. Check unchanged siblings for new incoherence
5. Verify the "structurally prevented" claim against exhaustive input-source enumeration
6. Assign severity and type to each finding
7. State verdict with evidence

**Verify:** Did you complete §2.0 before the diff? Did you enumerate input sources at security-level rigor for the closure claim? Does every finding trace to a line, file, or artifact?
