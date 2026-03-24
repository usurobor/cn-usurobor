# Review

Review code so that every verdict traces to evidence in the diff.

## Core Principle

**Coherent review: every claim about the code is verified against the diff, and no incoherence passes without being named.**

---

## 1. Define

1.1. **Identify the parts**
  - Diff (what changed)
  - Context (unchanged code at the same abstraction level)
  - Verdict (approve or request changes)
  - Evidence (line, commit, or trace that supports a claim)
  - ❌ "This looks wrong" (claim without evidence)
  - ✅ "Line 42 stages all files, but git_stage validates per-file — compound behavior" (evidence)

1.2. **Articulate how they fit**
  - The diff proposes a new invariant; context must still cohere with it; the verdict reflects the worst named incoherence; evidence anchors every claim
  - ❌ Review the diff in isolation
  - ✅ Review the diff, then check whether unchanged siblings now violate the invariant it establishes

1.3. **Name the failure mode**
  - Review fails via **surface reading** — checking only what changed, missing what the change *implies* for the rest of the system
  - ❌ "All changed functions look correct" (ignoring unchanged peers now inconsistent)
  - ✅ "git_diff and git_log use exclusions, but git_status doesn't — sibling incoherence"

---

## 2. Unfold

### 2.0 Issue — what was promised

**GATE: Complete §2.0 before reading the diff.** The review MUST begin with these two tables. If they are absent, the review is structurally incomplete regardless of diff analysis quality.

```
## §2.0 Issue Contract
### AC Coverage
| # | AC | In diff? | Status (met/partial/missing/deferred) |
|---|-----|----------|---------------------------------------|

### Named Doc Updates
| Doc | In diff? | Status (updated/absent/deferred) |
|-----|----------|----------------------------------|
```

2.0.1. **Walk every acceptance criterion**
  - Each AC is either met in the diff, explicitly deferred as known debt, or missing (finding)
  - The absence of a change is a finding when the issue requires it
  - ❌ Review only what changed without checking what was promised
  - ✅ "AC 4 (cn doctor validates contract) — not addressed in diff, no known-debt note → D"

2.0.2. **Check required spec/doc updates**
  - If the issue requires a spec or design doc change, verify that file was changed
  - If the issue or plan names specific docs (e.g. CAA.md, AGENT-RUNTIME.md), check EACH one — present in diff, or explicitly deferred
  - Missing spec updates are β gaps between issue contract and implementation
  - ❌ "Diff looks clean" (spec update was required but not in diff)
  - ❌ Check only the docs that happen to appear in the diff (ignoring named docs that don't)
  - ✅ "Issue names 5 docs for update. 2 updated in diff. 3 absent — are these deferred or forgotten?"

2.0.3. **Distinguish scope reduction from omission**
  - If the author intentionally narrowed scope, the commit/PR should say so
  - Unmentioned AC omissions are findings; noted deferrals are known debt
  - ❌ Assume missing AC was intentionally deferred
  - ✅ "3 of 6 ACs met; remaining 3 not mentioned — are these deferred or forgotten?"

2.0.4. **AC strength — met means fully met**
  - If an AC says "validates X against Y" and the code only checks "X exists", that is not met — it is partially met
  - Score partial ACs honestly: partially met is a finding, not an approval
  - ❌ "Doctor checks for the key → AC met" (AC says validate against runtime state, not just key presence)
  - ✅ "AC says 'validates contract against hub/runtime state.' Doctor checks key presence only → C. Either strengthen or defer to #59."

### 2.1 Diff — what changed

Read the diff for internal coherence.

2.1.1. **Check each change against its stated purpose**
  - Commit message says X, diff does Y
  - ❌ "feat: add fs_glob" but glob returns not_yet_implemented
  - ✅ "feat: add fs_glob" and execute_fs_glob is fully implemented

2.1.2. **Check changes against each other**
  - Multiple commits in a branch must tell one story
  - ❌ Commit 3 reverts part of commit 1 without explanation
  - ✅ Each commit builds on the previous; fix commits reference what they fix

### 2.2 Context — unchanged siblings

Check whether the change creates obligations on code it didn't touch.

2.2.1. **Sibling consistency**
  - If you harden 3 of 4 ops at the same level, the 4th is now incoherent
  - ❌ "All changed ops look good" (ignoring the unchanged one that now violates the new pattern)
  - ✅ "git_status doesn't use git_observe_exclusions — the other three observe ops do"

2.2.2. **Cross-module leakage**
  - Follow what the changed code *produces* (files, state, artifacts), check whether other surfaces expose it
  - ❌ Review executor in isolation
  - ✅ "Executor writes state/artifacts/; git_status would surface those paths to the agent"

2.2.3. **Multi-format parity**
  - If a module renders to multiple formats (markdown + JSON, prompt + disk, human + machine), verify both carry equivalent semantic content
  - A field present in one projection but absent in another is a contract asymmetry
  - ❌ Review render_markdown and to_json independently without comparing coverage
  - ✅ "Markdown includes capabilities sub-block; JSON omits it — asymmetry finding"

2.2.4. **Exclusion symmetry**
  - If paths are excluded in one place, verify they're excluded everywhere they should be
  - ❌ "Exclusions look correct in git_diff" (didn't check git_grep, git_log, git_status)
  - ✅ Grep for every use of the exclusion set, verify consistent application

2.2.5. **Cross-reference validation (file moves)**
  - If the PR moves or renames files, grep for old paths across all live (non-frozen) docs. Any match is a **D-level blocking finding** — stale cross-refs break navigation
  - For frozen snapshot directories: stale path references trigger **path-only repair** per DOCUMENTATION-SYSTEM.md §2.9/§4 (path references MAY be updated, no semantic content may change). Flag as **C-level** if unrepaired
  - Validate frozen snapshot integrity: `diff canonical frozen` = zero for any bundle touched by the PR
  - This check is mechanical and fully automatable — it should never require judgment
  - ❌ "Cross-refs look fine" (checked by reading, not by grepping)
  - ❌ Approve a file-move PR without grepping for old paths
  - ✅ `grep -r 'docs/gamma/RULES.md' docs/ src/ packages/ --include='*.md' | grep -v '/3.13.0/' | grep -v '/3.14.1/'` → zero matches → cross-refs clean

2.2.6. **Execution timeline for state-changing paths**
  - If code runs across a process boundary (binary replacement, daemon restart, re-exec), trace which process holds which values at each step
  - In-process constants (`Cn_lib.version`, module-level refs) reflect the *old* binary after replacement — they do not magically update
  - ❌ "reconcile_packages uses Cn_lib.version → correct" (structurally correct, but old process holds old version after binary replacement)
  - ✅ "After do_update replaces the binary, re_exec into the new binary before calling reconcile_packages — old process version constants are stale"
  - ❌ "update_runtime calls `cn --version` via shell, status uses Cn_lib.version — both read version" (two different truth reads in the same process)
  - ✅ "Unify: either all paths read in-process, or all paths shell out. Mixed reads create divergence windows."

2.2.7. **Derivation vs validation**
  - If an AC claims "single source of truth" or "one-file edit," verify that a *generation* step exists, not just a *check* step
  - A CI script that fails when manifests don't match VERSION is validation. A build step that writes manifests from VERSION is derivation. Only derivation satisfies "edit one file"
  - ❌ "CI script validates manifests match VERSION → AC2 (one-file bump) met" (validation ≠ derivation — you still edit 5 files, CI just yells if you miss one)
  - ✅ "AC2 says one-file bump → verify: after editing VERSION, how many other files need manual edits? If >0, AC2 is not met — need a stamp/generate step"

### 2.3 Verdict — the judgment

The verdict is a function of the worst named incoherence.

2.3.1. **Every claim traces to evidence**
  - No "I feel like" or "this seems off" — point to a line, a commit, a behavior
  - ❌ "The security model seems weak"
  - ✅ "git_grep passes user input to -n without -e, allowing option injection (line 277)"

2.3.2. **Validate fixes against upstream spec**
  - When a fix uses a library/tool behavior, confirm it against the tool's own documentation
  - ❌ "The exclusion pathspecs seem to work" (tested but not spec-checked)
  - ✅ "Git's docs confirm status accepts pathspecs and exclude pathspecs apply after non-exclude match"

2.3.3. **Name the severity**
  - D (blocking) → C (significant) → B (minor) → A (polish)
  - ❌ Mix blockers and nits without distinguishing them
  - ✅ "D: git_status leaks internal paths. B: artifact dir name could be clearer."

2.3.4. **Specify regression pairs for blockers**
  - Every D-level finding includes a concrete test pair: positive case (feature still works) + negative case (incoherence blocked)
  - ❌ "Fix git_status" (no test shape)
  - ✅ "Test pair: (a) git_status shows src/ changes; (b) git_status hides .cn/, state/, logs/ entries"

2.3.5. **Close the search space on approval**
  - Approval explicitly states that no remaining blocker was found in the contract, not just absence of objection
  - ❌ "APPROVED" (bare)
  - ✅ "APPROVED — I do not see a remaining blocker in the executor/sandbox contract after this fix set"

---

## 3. Rules

3.1. **Read the diff, then read the neighbors**
  - The diff is the figure; unchanged siblings are the ground
  - ❌ Review only modified files
  - ✅ For every modified function, open the module and check its siblings

3.2. **Trace system writes to system reads**
  - If the changed code writes files, check what reads them — especially observe ops, status commands, and user-facing output
  - ❌ "fs_write implementation looks correct" (didn't check if git_status surfaces the written file)
  - ✅ "fs_write puts files in the hub; git_status would show them — is that intended?"

3.3. **One round, one narrowing**
  - Each review round acknowledges fixes by commit hash, then names only remaining blockers
  - The final approval should trace the full arc: initial finding → fix sequence → capstone commit
  - ❌ Re-litigate resolved issues
  - ✅ "a14438a fixes the grep blocker. One D remains: git_status exclusions."
  - ✅ "04023e6 closes the last blocker — this commit is the capstone of the review-driven hardening sequence"

3.4. **Verdict before details**
  - Lead with APPROVED or REQUEST CHANGES, then evidence
  - ❌ Three paragraphs of analysis, verdict buried at end
  - ✅ "REQUEST CHANGES — one D-level blocker remains" at the top

3.5. **No phantom blockers**
  - Only block on incoherence you can demonstrate, not hypothetical risk
  - ❌ "This might break in edge cases" (which cases?)
  - ✅ "Symlink from threads/ to .cn/config.json bypasses sandbox — test: create symlink, run fs_read, expect denial"

3.6. **Approve when coherent, not when perfect**
  - The bar is coherence, not taste
  - ❌ Request changes on style preference with no incoherence
  - ✅ Note as B-level, approve

3.7. **Merge instruction is explicit and scoped**
  - Approval names the exact branch, PR number, and action
  - ❌ "Looks good, merge it"
  - ✅ "Merge PR #32 on claude/syscall-surface-v3.8.0-ZCSiy"

---

## 4. Checklist

Before submitting a review:

- [ ] Every issue acceptance criterion verified (met, deferred with note, or flagged as finding)
- [ ] Multi-format outputs checked for semantic parity (markdown/JSON, prompt/disk)
- [ ] Every claim traces to a line, commit, or behavior
- [ ] Fixes validated against upstream spec where applicable
- [ ] Unchanged siblings checked for new incoherence
- [ ] Cross-refs validated by grep for any file-move PR (§2.2.5)
- [ ] System writes traced to system reads
- [ ] Severity assigned to every finding (D/C/B/A)
- [ ] D-level findings include regression test pairs (positive + negative)
- [ ] Prior-round fixes acknowledged by commit hash (multi-round only)
- [ ] Approval explicitly closes the search space ("no remaining blocker in X contract")
- [ ] Merge instruction names branch and PR number
- [ ] Verdict stated first

---

## 5. Severity

| Level | Meaning | Action |
|-------|---------|--------|
| **D** | Incoherence demonstrable with a test | REQUEST CHANGES |
| **C** | Incoherence real but non-breaking | APPROVED with nit |
| **B** | Improvement opportunity, no incoherence | APPROVED, note for author |
| **A** | Polish | APPROVED |

## 5.1. Finding Taxonomy

Every finding MUST be tagged as one of two types. This taxonomy feeds CDD §11.11 review quality metrics.

| Type | Definition | Examples |
|------|-----------|----------|
| **mechanical** | Automatable — could be caught by a grep, diff, or script without judgment | Stale cross-refs after file move, missing scope items, wrong branch name, snapshot/canonical mismatch, broken link |
| **judgment** | Requires design reasoning, coherence assessment, or architectural context | Missing AC coverage, sibling incoherence, authority conflict, design trade-off, naming choice |

Mechanical findings reaching review are **process bugs** — the pre-flight or author checklist should have caught them. If mechanical findings exceed 20% of total findings in a release cycle, file a process issue (CDD §11.12).

- ❌ Report a finding without tagging it mechanical or judgment
- ✅ "D (mechanical): stale cross-ref to `docs/gamma/RULES.md` in `ARCHITECTURE.md` L45"
- ✅ "C (judgment): authority conflict — skill §1.5 adds rules not present in canonical CDD.md"

---

## 6. Output Format

```markdown
**Verdict:** APPROVED / REQUEST CHANGES

**Round:** N (if multi-round)
**Fixed this round:** <commit> closes <blocker> (if applicable)

## Findings

| # | Finding | Evidence | Severity |
|---|---------|----------|----------|
| 1 | git_status leaks internal paths | L179: no exclusions | D |
| 2 | artifact dir name unclear | L312 | B |

## Regressions Required (D-level only)

1. After observe op creates state/artifacts/*, git_status output must not contain state/ entries
2. ...

## Notes
(additional context, suggestions, questions)
```

---

## 7. After Review

- **Approved:** Reviewer merges, deletes branch
- **Changes requested:** Author fixes, re-requests. Reviewer narrows on next round.
