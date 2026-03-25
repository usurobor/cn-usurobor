# KATA-B1

## Runtime Contract v2 Doc/Runtime Parity Review

**Kata ID:** B1-runtime-contract-v2-parity-review
**Family:** Cross-surface coherence / review
**Difficulty:** Medium
**Failure Family:** The feature is mostly implemented, but canonical docs, examples, and operator/runtime surfaces drift apart.
**Expected Governing Skills (hidden):** review, documenting

---

## Public Task Statement

You are reviewing a branch that claims:

> The change introduces a vertical Runtime Contract with:
> - identity
> - cognition
> - body
> - medium

Your task is to review whether that claim is coherent. Produce a review using:

1. issue-contract-first reasoning
2. named-doc checks
3. multi-format parity
4. authority-surface conflict checks

Do not rewrite the code. Your job is to decide whether the branch is ready.

---

## Public Context

### Issue promise

The issue says Runtime Contract v2 should:

- replace the flat capabilities block
- give the agent a vertical self-model:
  - identity
  - cognition
  - body
  - medium
- persist this to disk and JSON
- update architecture docs so the wake-time model matches the runtime

### Branch summary

The author says:

- runtime contract builder is updated
- JSON now includes all four layers
- doctor validates the contract
- architecture docs were updated

### Relevant excerpts

#### 1) cn_runtime_contract.ml

```ocaml
type t = {
  identity : Yojson.Safe.t;
  cognition : Yojson.Safe.t;
  body : Yojson.Safe.t;
  medium : Yojson.Safe.t;
}
```

#### 2) cn_context.ml

```ocaml
(* system[1] = Reflections + Skills + Runtime Contract *)
```

#### 3) AGENT-RUNTIME.md

```markdown
### Runtime Contract (v3.13.0+, replaces Capability Discovery Block)

The runtime emits a vertical self-model with four layers:
- identity
- cognition
- body
- medium
```

Later in the same doc:

```markdown
## CN Shell Capabilities

observe: fs_read, fs_list, git_status
effect: fs_write, git_commit
apply_mode: branch
exec_enabled: true
max_passes: 2
```

#### 4) CAA.md

```markdown
Wake strata:
1. Identity
2. Core Doctrine
3. Mindsets
4. Reflections
5. Task Skills
6. Capabilities
7. Conversation
8. Inbound message
```

#### 5) cn doctor

The branch summary claims:

> "doctor validates self-model consistency"

But the code excerpt shows:

```ocaml
check_key "identity";
check_key "cognition";
check_key "body";
check_key "medium";
```

No deeper consistency logic shown.

---

## Public Deliverable

Return:

1. Verdict
2. Issue AC / claim coverage
3. Main findings
4. Whether this is merge-ready
5. What minimal patch would finish it if not

---

## Hidden Evaluator Rubric

### α

Strong answer should:

- notice the core runtime shape is right
- distinguish structural presence from full consistency
- not overclaim blockers where the branch is actually close

Weak answer:

- either blanket-approves or blanket-rejects without separating code vs doc vs operator truth

### β

This is the main target. Strong answer must catch:

1. **AGENT-RUNTIME.md contradiction:**
   - says Runtime Contract v2 replaces old block
   - still includes stale `## CN Shell Capabilities` example with `max_passes: 2`

2. **CAA.md still using old wake strata** and not reflecting Runtime Contract v2

3. **cn doctor validating section presence only**, not full self-model consistency

Weak answer:

- only reviews `cn_runtime_contract.ml`
- misses doc/runtime or runtime/doctor mismatch

### γ

Strong answer should:

- recommend a small finishing patch
- not demand a redesign
- separate "ready soon" from "fully complete"

### Hidden Checks / Findings expected

Likely blockers:

- stale architecture example in AGENT-RUNTIME.md
- stale wake strata in CAA.md
- overclaimed doctor validation

Possible acceptable conclusion:

- "Good architecture, not fully converged yet"

### Transfer Variant (hidden)

**Task B:** Same review pattern, but the mismatch is:

- markdown Runtime Contract includes a capabilities sub-block
- persisted JSON omits it

Good transfer means the agent again catches:

- multi-format parity
- authority-surface conflict
- claim-strength vs evidence-depth
