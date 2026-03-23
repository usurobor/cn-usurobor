# Post-Release Assessment

After every release, assess what shipped, what the system looks like now, and what to do next. This is CDD §11 executed as a concrete procedure.

## When

After every `git tag` + `gh release create`. No exceptions — patch, minor, or major.

## Output

The assessment produces one artifact with four sections:

```markdown
## Post-Release Assessment — vX.Y.Z

### 1. Coherence Measurement
- **Baseline:** vPREV — α _, β _, γ _
- **This release:** vX.Y.Z — α _, β _, γ _
- **Delta:** which axes improved / held / regressed and why
- **Coherence contract closed?** Expected effect achieved? If not, what remains?

### 2. Encoding Lag
| Issue | Title | Design | Impl | Lag |
|-------|-------|--------|------|-----|

**MCI/MCA balance:** balanced / freeze MCI / resume MCI
**Rationale:** ...

### 3. Process Learning
**What went wrong:** ...
**What went right:** ...
**Skill patches:** (committed Y/N, link if Y)

### 4. Next Move
**Priority:** ...
**Rationale:** ...
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

### Step 3: Encoding lag table

For every open design issue (issues with design docs, architecture docs, or converged plans that are not yet fully implemented):

| Issue | Title | Design | Impl | Lag |
|-------|-------|--------|------|-----|

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

### Step 5: Process learning

Answer three questions:
1. **What went wrong?** What broke, was caught late, or slipped through?
2. **What went right?** What process improvement paid off?
3. **Skill patches needed?** If a repeatable failure mode is identified, patch the skill NOW — not next session.

### Step 6: Decide next move

Based on measurement + lag + learning, state what happens next:
- Which issue to implement
- Whether to freeze or resume MCI
- Any skill/process patches to ship first

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
Next sessions are pure MCA until #62 and #73 Phase 1 ship.

### Process Learning
Wrong: Review missed CAA.md (§2.0 gate not followed). Fixed with structural table format.
Right: Three-agent review loop caught complementary gaps.
Skill patches: review §2.0 gate (committed), CDD §7.6 output format (committed).

### Next Move
#62 (land branch with doc fixes) → #73 Phase 1 (open op registry).
```
