# Process Economics

Add, keep, simplify, automate, or remove process only when it earns its cost.

## Core Principle

**Coherent process earns its cost by preventing a named failure, producing a reusable artifact, or reducing future work more than it adds present overhead.**

A good process move does at least one of these:

- prevents a recurring class of failure
- makes an important state legible to operators or reviewers
- produces an artifact with real downstream use
- shifts repeated human work into automation
- shortens future cycles through clearer contracts

A bad process move:

- adds ritual without changing outcomes
- duplicates another artifact or gate
- creates human cost where a script/check would suffice
- remains forever after the failure it addressed is gone

---

## 1. Define

### 1.1. Identify the parts

Every process-economics decision has these parts:

-s future cycles th— the ritual, gate, artifact, or review action
- Cost — time, latency, attention, context switching, artifact churn, merge friction
- Process Econ— what failure it prevents or what leverage it creates
- Consumer — who actually uses the output
- Evidence — what proves the step is paying for itself
- Automation boundary — what should be scripted instead of ritualized
- Sunset condition — when the step should be reduced, automated, or removed

- ❌ "We should add a checklist"
- ✅ "This checklist catches stale artifact references before review and saves repeated reviewer time"

### 1.2. Articulate how they fit

Process is coherent when:

- the step has a named failure class
- the output has a named consumer
- the cost is proportionate to the risk
- the same goal is not already achieved elsewhere
- the step is the lightest thing that works
- there is a path to automation or removal if the environment changes

- ❌ "This seems like good discipline"
- ✅ "This gate catches package/source drift before merge and replaces repeated reviewer effort"

### 1.3. Name the failure mode

Process fails throughcates another artifact

- every failure adds a new step
- no one measures what the step costs
- no one checks whether another step already covers it
- no one removes steps after the system changes

- ❌ "Add one more required doc"
- ✅ "First prove the existing docs cannot already carry this information"

---

## 2. Unfold

### 2.1. Start from a named failure class

Every process step must begin with:

>t least one of these: - prevents a recurring

Good answers:

- stale artifact references survive review
- issue ACs are forgotten
- source/package drift reaches main
- runtime examples diverge from implementation
- release debt is not captured
- branch-local summaries overrule canonical docs

- ❌ "Improve quality"
- ✅ "Prevent approval when the issue contract is only partially met"

### 2.2. Name the consumer of the output

Every required artifact or gate must answer:

>lass of failure - makes an important state

Possible consumers:

- reviewer
- implementer
- operator
- release owner
- CI
- future design work
- runtime/doctor/traceability

- ❌ "We should write a self-coherence report"
- ✅ "The self-coherence report lets the reviewer and releaser see whether the branch itself followed CDD"

### 2.3. Distinguish human ritual from machine-checkable work

Ask for each step:

- is this a human judgment problem?
- or is this a grep/script/schema/CI problem?

If machine-checkable, prefer automation.

Examples:

- stale path references → grep/check
- placeholder rendering → lint/check
- package/source drift → CI check
- branch naming format → automation or template
- authority-surface conflict → often still human judgment

- ❌ Force reviewers to count stale paths manually every time
- ✅ Add grep/lint and let review focus on the judgment residue

### 2.4. Price the step explicitly

For each process step, estimate its costs:

- author time
- reviewer time
- cycle latency
- context-switch cost
- artifact maintenance cost
- CI/build cost
- operator burden

Use rough qualitative bands if needed:

- low / medium / high
- one-time / per-branch / per-release / per-incident

- ❌ "This only takes a minute"
- ✅ "This adds one required artifact per governance branch and one review pass to validate it"

### 2.5. Price the avoided failure explicitly

For each step, estimate the benefit:

- what rework does it prevent?
- what outages/incidents does it reduce?
- what reviewer/operator confusion does it eliminate?
- what future branches become simpler because this exists?

- ❌ "It improves discipline"
- ✅ "It eliminates repeated review misses around stale artifact references"

### 2.6. Compare against the lighter alternatives

For any proposed process addition, compare at least three options:

-ed elsewhere - t- lightweight note/rule
- automation/check
- full required artifact/gate

Use the lightest option that actually closes the failure class.

- ❌ Jump straight to mandatory artifact
- ✅ "A grep-based check solves this better than a new reviewer checklist step"

### 2.7. Prefer process that produces reusable artifacts

A process step is stronger if it leaves behind something that can be reused:

- plan
- self-coherence report
- doctor output
- changelog
- invariant file
- schema
- trace event family
- reusable checklist

- ❌ Meeting without durable output
- ✅ Post-release assessment captured in a file that informs the next cycle

### 2.8. Avoid duplicate authority surfaces

If a new process artifact says the same thing as an existing one, decide which is authoritative.

Examples:

- issue ACs vs coherence contract
- canonical CDD doc vs executable skill
- self-coherence report vs PR body
- runtime contract markdown vs JSON

- ❌ Two artifacts both claim to be canonical
- ✅ One canonical artifact, one derived or supporting artifact

### 2.9. Add sunset and reduction criteria

Every process step should answer:

- when should this become optional?
- when should this become automated?
- when should this be deleted?

Useful triggers:

- mechanical findings exceed threshold → automate
- artifact unused for N releases → remove or demote
- branch class no longer exists → retire the step
- stronger upstream primitive supersedes it

- ❌ Add a rule forever
- ✅ "If stale-path findings drop to zero for 5 releases, demote this manual review step to a periodic audit"

### 2.10. Measure the process itself

Good process economics requires observing:

- review latency
- merge latency
- number of required artifacts per branch type
- percentage of mechanical findings
- repeat-offender failure classes
- artifact rot / stale references
- number of times a step was skipped or had to be repaired retroactively

- ❌ Add process and never observe it
- ✅ "If >20% of findings are mechanical, file a process bug and automate"

### 2.11. Distinguish bootstrap from ongoing cost

Some process has:

- a one-time adoption cost
- low steady-state cost

Some process is expensive every time. Model that explicitly.

- ❌ Reject a useful bootstrap because setup is annoying
- ✅ "Versioned bundle snapshots are expensive to introduce but low-cost once templated"

### 2.12. Separate governance branches from product branches

Not every branch should carry the same artifact burden.

Possible classes:

- tiny bugfix
- substantial feature
- governance/process
- release hardening
- architectural refactor

Process economics should vary by class.

- ❌ Force every bugfix through maximum ceremony
- ✅ Require the richer bundle for substantial and governance changes, keep bugfixes lightweight

### 2.13. Challenge process overhead explicitly

Ask:

>h-local summaries overrule canonical docs - ❌ "Improve quality"

If the answer is vague, the step is probably too expensive.

- ❌ "We need it for rigor"
- ✅ "Without this, branch-local summaries routinely override issue ACs"

### 2.14. Prefer reversible process changes

Add process in ways that can be:

- automated later
- downgraded later
- removed later
- localized to one branch class

- ❌ Hardwire a repo-wide rule with no escape hatch
- ✅ Introduce it first for governance/substantial branches with explicit review after N releases

---

## 3. Rules

### 3.1. Every process step names its failure class

No unnamed "discipline" steps.

- ❌ "This is best practice"
- ✅ "This prevents stale artifact paths from surviving review"

### 3.2. Every required artifact names its consumer

If no one uses it, it should not be required.

- ❌ Ritual artifact
- ✅ "Reviewer and releaser use this to assess branch self-coherence"

### 3.3. Prefer automation over repeated human checking

If a check can be scripted reliably, automate it.

- ❌ Manual grep forever
- ✅ Add lint/CI, then remove manual repetition

### 3.4. Use the lightest step that closes the failure

Do not impose governance heavier than the risk.

- ❌ Mandatory design doc for every typo fix
- ✅ Lightweight bugfix path with issue/PR coherence contract

### 3.5. Process must pay rent

Every step must be able to answer:

- what it costs
- what it prevents
- why a lighter alternative is insufficient

- ❌ "Feels safer"
- ✅ "Costs one artifact, prevents repeated review misses, and cannot be automated yet"

### 3.6. Duplicate authority is a process bug

Do not let multiple artifacts claim the same authority without an explicit hierarchy.

- ❌ PR body and canonical doc diverge
- ✅ Canonical doc authoritative; PR body scoped to branch delta

### 3.7. Mechanical findings imply process debt

If reviewers keep finding mechanical issues, the process is under-automated.

- ❌ Accept that reviewers catch stale placeholders forever
- ✅ File a process bug and add automation

### 3.8. Add sunset criteria when adding process

Every new step should say when it can be simplified, automated, or removed.

- ❌ Permanent growth
- ✅ "Revisit after three releases once templates and checks exist"

### 3.9. Branch class determines ceremony

Bugfixes, substantial features, governance branches, and release hardening do not all need the same overhead.

- ❌ One-size-fits-all governance
- ✅ Artifact requirements scaled by branch/change class

### 3.10. Measure process outcomes

A process step is not proven because it exists; it is proven because it changes outcomes.

- ❌ "We added the rule"
- ✅ "Mechanical findings dropped; release debt is captured consistently"

### 3.11. Keep judgment for judgment

Do not replace architectural/review judgment with ritual. Use process to frame judgment, not to suffocate it.

- ❌ More checkboxes instead of clearer thinking
- ✅ One strong review step instead of three weak ceremonial steps

### 3.12. Remove what no longer earns its cost

A coherent process is allowed to shrink.

- ❌ Only add
- ✅ Add, automate, simplify, or delete as the system matures

---

## 4. Output Pattern

A strong process-economics artifact or assessment should contain at least:

1.e a self-coherence2. Failure class prevented
3. Consumer
4. Cost
5. Benefit
6. Lighter alternatives considered
7. Automation boundary
8. Sunset / review criterion
9. Known debt

### Example shape

```markdown
## Process Step

Require SELF-COHERENCE.md for governance branches.

## Failure Class Prevented

Governance branches define stricter process without proving they followed it.

## Consumer

Reviewer, releaser, future governance iteration.

## Cost

One additional artifact per governance branch.

## Benefit

Makes process conformance visible; prevents hidden branch-level incoherence.

## Lighter Alternatives Considered

- PR note only
- checklist only

Rejected because neither leaves durable branch-local evidence.

## Automation Boundary

Template creation can be automated; the judgment remains human.

## Sunset / Review Criterion

If governance branches stabilize and template generation is universal, review whether the artifact can be simplified.

## Known Debt

Retroactive plans still occur during transition.
```

---

## 5. Relationship to Other Skills

- **architecture-evolution** — asks whether the system boundary should move
- **performance-reliability** — asks what the system costs and how it fails
- **testing** — proves invariants
- **review** — checks whether process and artifacts actually support the claim
- **CDD** — provides the lifecycle; this skill evaluates whether that lifecycle is earning its cost

---

## 6. Summary

Process economics is not:

- anti-process
- anti-discipline
- anti-documentation

It is: the discipline of making every required step, artifact, and gate justify its ongoing cost.

Name the failure. Name the consumer. Price the cost. Price the benefit. Automate the mechanical. Delete what no longer earns its place.
