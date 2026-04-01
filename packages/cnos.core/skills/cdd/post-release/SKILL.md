# Post-Release Assessment

After every release, assess what shipped, what the system looks like now, and what to do next. This is CDD §9 (Assessment) and §10 (Closure) executed as a concrete procedure.

## When

After every `git tag` + `gh release create`. No exceptions — patch, minor, or major.

## Output

The assessment produces one artifact with five sections:

```markdown
## Post-Release Assessment — vX.Y.Z

### 1. Coherence Measurement
- **Baseline:** vPREV — α _, β _, γ _
- **This release:** vX.Y.Z — α _, β _, γ _
- **Delta:** which axes improved / held / regressed and why
- **Coherence contract closed?** Expected effect achieved? If not, what remains?

### 2. Encoding Lag
| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|

**MCI/MCA balance:** balanced / freeze MCI / resume MCI
**Rationale:** ...

### 3. Process Learning
**What went wrong:** ...
**What went right:** ...
**Skill patches:** (committed Y/N, link if Y)
**Active skill re-evaluation:** (for each review finding: skill underspecified → patch / application gap → note / already covered → skip)

### 4. Review Quality
**PRs this cycle:** N
**Avg review rounds:** N.N (target: ≤1 docs, ≤2 code)
**Superseded PRs:** N (target: 0)
**Finding breakdown:** N mechanical / N judgment / N total
**Mechanical ratio:** N% (threshold: 20% → file process issue)
**Action:** none / filed #NN

### 4a. CDD Self-Coherence
- **CDD α:** _/4 — (artifact integrity)
- **CDD β:** _/4 — (surface agreement)
- **CDD γ:** _/4 — (cycle economics)
- **Weakest axis:** α / β / γ
- **Action:** none / patch skill / patch doc / automate check

### 5. Production Verification

**Scenario:** [what to test]
**Before this release:** [what happened]
**After this release:** [what should happen]
**How to verify:** [concrete steps]
**Result:** [pass / fail / deferred]

### 6. CDD Closeout

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| §2.9 | observation surface | post-release | runtime/design alignment result |
| §2.10 | POST-RELEASE-ASSESSMENT.md | post-release | assessment completed |
| §2.11 | immediate fixes / next MCA issue | post-release (+ others if used) | cycle closed / deferred outputs committed |

### 7. Next Move
**Next MCA:** #NN — title
**Owner:** ...
**Branch:** ...
**First AC:** ...
**MCI frozen until shipped?** yes / no
**Rationale:** ...

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes / no
  - (list each with link/commit)
- Deferred outputs committed: yes / no
  - (issue # / owner / branch / first AC / freeze state for each)

**Immediate fixes** (executed in this session):
- ...
```

## Procedure

### Step 1: Score

Score α/β/γ for the release. Compare to baseline (previous release score from CHANGELOG TSC table).

Rules:
- Score the release, not the intent
- If an axis regressed, name the cause
- If an axis held, say whether that's expected or stagnation

### Step 2: Update CHANGELOG TSC table

Add a row:

```
| vX.Y.Z | C_Σ | α | β | γ | Coherence note |
```

The coherence note describes which incoherence was reduced, not what feature was added.

**Scoring sequence:** The CHANGELOG TSC entry written at release time is **provisional** — it is the author's self-score. The post-release assessment is the independent score and MAY revise the CHANGELOG entry. If the assessment disagrees with the self-score, update the CHANGELOG to match the assessment. The assessment governs.

### Step 3: Encoding lag table

All converged-but-unimplemented design commitments MUST appear in the lag table. This is not optional and has no wiggle room — if a design is converged and not shipped, it appears here.

For every open design issue (issues with design docs, architecture docs, or converged plans that are not yet fully implemented) and every open process issue (repeatable failure modes from §9–§10):

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|

Type: `feature` (design/code gap) or `process` (development method gap).

Lag levels:
- **none** — shipped in this or prior release
- **low** — implementation in progress (branch exists, PR open)
- **growing** — design converged, no implementation started
- **stale** — design aging without implementation plan

### Step 4: MCI/MCA balance decision

Based on the lag table:
- **Balanced:** roughly equal design and implementation activity. Continue normally.
- **Freeze MCI:** ≥3 issues at "growing" lag, OR designs outnumber implementations 3:1, OR any "SHALL" in substrate docs without runtime enforcement. Stop designing, start shipping.
- **Resume MCI:** implementation caught up to design frontier. Can advance designs again.

This decision is **mandatory**. Every release states the balance.

**What "freeze MCI" means operationally:** No new substantial design docs, plans, or architecture proposals until the committed MCA backlog is reduced below the freeze threshold. Small clarifications to existing designs are allowed; new design commitments are not.

### Step 5: Process learning

Answer three questions:
1. **What went wrong?** What broke, was caught late, or slipped through?
2. **What went right?** What process improvement paid off?
3. **Skill patches needed?** If a repeatable failure mode is identified, patch the skill NOW — not next session.
4. **Active skill re-evaluation.** For each review finding: would the declared active skills, as written, have prevented it? If not, is the skill underspecified for this pattern, or was it just not applied deeply enough? Underspecified → patch the skill. Application gap → note it but don't patch (the skill was right, the agent didn't follow it).

### Step 5.5: Review quality

For every PR in this release cycle, record:
1. **Review rounds** — how many iterations before merge (fix commits + review comments requesting changes). Target: ≤1 for docs PRs, ≤2 for code PRs.
2. **Superseded PRs** — count of PRs closed-not-merged and replaced. Target: 0.
3. **Finding taxonomy** — tag each review finding as `mechanical` (automatable: stale cross-refs, missing scope items, wrong branch name) or `judgment` (design coherence, architecture trade-offs).
4. **Mechanical ratio** — mechanical findings / total findings. If >20%, file an issue to add the missing pre-flight check.

This step closes the loop from CDD §9 (Assessment). The review quality section in the output template must be filled.

### Step 5.6: CDD self-coherence

Did this cycle itself follow CDD coherently? Score each axis 1–4:

- **CDD α (artifact integrity):** required artifacts present? Bootstrap/frozen snapshot complete? Self-coherence present?
- **CDD β (surface agreement):** canonical doc, executable skill, PR artifacts, changelog, and assessment agree? Authority conflicts or stale references?
- **CDD γ (cycle economics):** review rounds within target? Superseded PRs low? Mechanical ratio under threshold? Immediate outputs executed, deferred outputs committed?

```markdown
### 4a. CDD Self-Coherence

- **CDD α:** _/4 — (rationale)
- **CDD β:** _/4 — (rationale)
- **CDD γ:** _/4 — (rationale)
- **Weakest axis:** α / β / γ
- **Action:** none / patch skill / patch doc / automate check
```

This drives action, not score-keeping:
- low α → patch artifact contract / templates / bootstrap
- low β → patch canonical doc / executable skill / authority hierarchy
- low γ → automate mechanical checks, reduce ceremony, tighten selection

If no axis scores below 3, write "no action" and move on.

### Step 5.7: Production verification

After release, verify the change works in production — not just that CI passes. Design a concrete test that demonstrates the new capability (or blocked failure mode) in a real environment.

**The question:** What can the system do now that it couldn't before? Or: what failure is now impossible that was previously possible?

Write a verification scenario:

```markdown
### Production Verification

**Scenario:** [what to test]
**Before this release:** [what happened]
**After this release:** [what should happen]
**How to verify:** [concrete steps]
**Result:** [pass / fail / deferred — with evidence]
```

Rules:
- The scenario must be executable, not hypothetical
- "CI passes" is not production verification — it's build verification
- If the change is structural (L7), the test should demonstrate the boundary move, not just a single path
- If verification requires a running agent or daemon, say so — defer if the environment doesn't support it, but commit to when/how it will be verified
- If deferred, add to the next session's checklist

This is the kata: each release earns a concrete demonstration that the system changed.

### Step 6: Decide next move

Based on measurement + lag + learning, state what happens next as a **concrete commitment**:

- **Next MCA issue:** the specific issue number to implement next
- **Owner:** who is responsible for the next MCA
- **Branch:** name of branch (or "pending branch creation")
- **First AC to close:** which acceptance criterion ships first
- **MCI frozen?** Whether MCI is frozen until this MCA ships

This turns the assessment into an executable handoff, not just reflection.

**Execution rule:**
- Small process/skill fixes discovered in the assessment → execute immediately (same session)
- Everything larger → becomes the next cycle's work via the commitment above
- Do not attempt to execute a large MCA inside the post-release assessment itself

## Pre-publish gate

Before committing the assessment, verify mechanically:

- [ ] §1 has Baseline, This release, Delta, and Coherence contract closed
- [ ] §2 has encoding lag table with every open design/process issue
- [ ] §2 has MCI/MCA balance decision with rationale
- [ ] §3 has What went wrong, What went right, Skill patches, Active skill re-evaluation
- [ ] §4 has all fields: PRs, review rounds, superseded PRs, finding breakdown, mechanical ratio, action
- [ ] §4 mechanical ratio: if >20%, a process issue is **filed and referenced** (not just noted)
- [ ] §4a CDD self-coherence: α/β/γ scored, weakest axis named, action stated (or "none" if all ≥3)
- [ ] §5.7 has production verification scenario (or explicit deferral with commitment)
- [ ] §6 CDD Closeout trace present with rows for observe/assess/close steps
- [ ] §7 has all 6 fields: Next MCA, Owner, Branch, **First AC**, MCI frozen?, Rationale
- [ ] §7 Closure evidence: immediate outputs listed with links, deferred outputs with issue/owner
- [ ] CHANGELOG TSC row added or updated to match assessment scores

This gate is mechanical. Two agents checking the same template must find the same missing fields.

## Anti-patterns

- ❌ Skip assessment for patch releases ("it's just a small fix")
- ❌ Score without the lag table ("coherence is fine" while 5 designs age)
- ❌ Note process failures without patching skills ("we should fix this")
- ❌ Ship and immediately start the next feature without assessing balance

## Examples

### Good assessment (MCI freeze triggered)

```
## Post-Release Assessment — v3.12.2

### Coherence Measurement
- Baseline: v3.12.1 — α A, β A, γ A
- This release: v3.12.2 — α A, β A+, γ A
- Delta: β improved (contract authority enforced). α/γ held.

### Encoding Lag
| #62 | RT Contract v2 | converged | branch exists | low |
| #65 | Communications | converged | not started | growing |
| #73 | Extensions | converged | not started | growing |
| #67 | Network | subsumed by #73 | not started | growing |

MCI/MCA balance: **Freeze MCI** — 3 issues at growing lag.
No new design docs until backlog reduced below threshold.

### Process Learning
Wrong: Review missed CAA.md (§2.0 gate not followed). Fixed with structural table format.
Right: Three-agent review loop caught complementary gaps.
Skill patches: review §2.0 gate (committed), CDD §7.6 output format (committed).

### Next Move
Next MCA: #62 — Runtime Contract v2
Owner: sigma
Branch: claude/runtime-contract-v2-VWKUT
First AC: CAA.md updated with wake-time architecture
MCI frozen until shipped? Yes
Rationale: Vertical self-model is foundation for #73, #65, #59.

Immediate fixes (executed this session):
- review §2.0 structural gate (eeca922)
- CDD §7.6 output format (64634fb)
```
