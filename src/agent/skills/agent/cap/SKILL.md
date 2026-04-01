---
name: cap
description: The Coherent Agent Principle — understand the situation, identify the governing incoherence, execute the smallest response that closes it.
artifact_class: skill
kata_surface: embedded
governing_question: How does an agent detect, analyze, and close incoherence?
triggers:
  - ambiguous situation requiring analysis before action
  - choosing between MCA and MCI
  - detecting whether a gap is governing or symptomatic
  - any moment where "what do I do next" is not obvious
---

# CAP

The Coherent Agent Principle — how agents maintain coherence.

## Core Principle

A coherent agent first understands the situation, then identifies the governing incoherence, then executes the smallest response that closes it.

Derived from Friston's Free Energy Principle: any self-organizing system at equilibrium with its environment must minimize free energy. For agents, free energy is incoherence — the gap between model and reality.

Two mechanisms to close the gap:

1. **MCA** — act on the world to change reality
2. **MCI** — update your model to match reality

The upstream move that makes MCA/MCI effective is UIE: Understand, Identify, Execute.

## Algorithm

1. Understand — read the situation before forming a response.
2. Identify — name the governing incoherence, reject symptoms.
3. Execute — close the gap through MCA, MCI, or delegation.

---

## 1. Understand

Read state before acting. Ambiguity is a signal to observe harder, not to act faster.

### 1.1. Read the situation

What is actually happening? What evidence is available?

- ❌ Jump to a fix based on pattern-match to a previous situation
- ✅ Name what you observe before interpreting it

### 1.2. Read the constraints

What authority surfaces govern? What is in scope? What is blocked?

- ❌ Act as if all options are open
- ✅ Name what constrains the response before choosing one

### 1.3. Read recent history

Has this gap appeared before? Was it closed? Did the closure hold?

- ❌ Treat every gap as novel
- ✅ Check whether a previous MCA or MCI already addressed this

### 1.4. Tolerate ambiguity

If the situation is unclear after reading state, constraints, and history, observe more or ask. Do not fabricate certainty.

- ❌ Guess the gap to avoid appearing stuck
- ✅ Say what is unclear and what would resolve it

---

## 2. Identify

Name the governing incoherence. Reject symptoms and cosmetic gaps.

### 2.1. List candidate gaps

There may be several apparent incoherences. Name them all before choosing.

- ❌ Lock onto the first mismatch you notice
- ✅ List candidates, then evaluate which one governs

### 2.2. Distinguish governing gap from symptom

A symptom is downstream of a deeper blocker. Fixing a symptom without fixing the cause produces churn.

- ❌ "The README is wrong" when the real gap is that authority is undeclared
- ✅ "Authority is undeclared — the README is one symptom of that"

### 2.3. Reject cosmetic gaps

A cosmetic gap is one where closing it does not reduce real incoherence.

- ❌ Reformat a file because it looks untidy when no reader is confused
- ✅ Reformat only when the current form causes misreading

### 2.4. No governing gap yet

If no governing gap can be named with enough evidence:

- do not force MCA or MCI
- gather more evidence
- ask the operator if the ambiguity is blocking
- defer action explicitly if needed

Ask the operator when:

- the ambiguity blocks a decision the operator cares about
- gathering more evidence would take longer than asking
- two candidate gaps lead to incompatible response paths

Gather more evidence when:

- the answer is likely observable without operator input
- asking would transfer work the agent can do itself

- ❌ "Unclear, but I'll just fix the most visible symptom"
- ✅ "Two candidate gaps remain; not enough evidence yet; next step is X"

### 2.5. Choose the response mode

- Can you change the system to close the gap? → MCA
- Must you update your model to match reality? → MCI
- Both? → MCA first, then MCI
- Gap is in another domain? → delegate to the appropriate skill

- ❌ "I learned I should fix bugs" (MCI without MCA)
- ✅ Fix the bug (MCA), then capture the lesson (MCI)

---

## 3. Execute

Close the gap. Prefer the smallest change that works.

### 3.1. MCA — change the system

Your model is right, reality is wrong. Act.

- Build a tool, add a gate, fix the code, update the config
- ❌ "Won't repeat" without a mechanism
- ✅ A system change that prevents recurrence

### 3.2. MCI — change your model

Reality is right, your model is wrong. Learn.

- Update understanding, capture a reflection, revise a mental model
- ❌ "This shouldn't happen" (deny reality)
- ✅ Update your model to match what you observed

### 3.3. MCA before MCI

If you can act, act. Insights are what remain after acting.

- ❌ Reflect on a fixable bug instead of fixing it
- ✅ Fix it, then reflect on why it happened

### 3.4. Delegate when the gap belongs to another skill

If the governing gap is a design problem, hand off to design. If it is a writing problem, hand off to writing. CAP identifies the gap and chooses the mode. Domain skills close it.

- ❌ Try to close a design gap inside CAP
- ✅ Name the gap, choose MCA, delegate to design

### 3.5. Iterate

Each action creates new data. Each insight sharpens the model. New gaps may appear. Return to Understand.

- ❌ One fix, done forever
- ✅ Check whether the closure held

---

## 4. Boundary to Adjacent Skills

CAP chooses the response path. Adjacent skills do the domain work:

- **reflect** — interprets what happened after the fact
- **coherent** — verifies that outputs align with sources
- **CLP** — refines artifacts before publishing
- **design / review / writing / configure-agent** — domain skills CAP may delegate into

CAP does not replace these. It decides which one to invoke and why.

---

## 5. Failure Modes

CAP fails through:

- **Premature action** — skipping Understand, acting on pattern-match
- **False gap selection** — naming a symptom as the governing gap
- **Comfort-driven interpretation** — choosing the gap that is easy to close instead of the one that governs
- **MCI without MCA** — learning when acting was possible
- **MCA without MCI** — fixing without understanding why it broke

---

## 6. Output Shape

A CAP pass should produce:

- **Situation:** what is observed
- **Constraints:** what governs and what is blocked
- **Candidate gaps:** what incoherences are visible
- **Governing gap:** which one is primary
- **Mode:** MCA / MCI / both / delegate
- **Active skills:** which 2–3 domain skills apply
- **Next step:** the smallest executable action

When no governing gap can be identified yet:

- **Need more evidence:** what is missing
- **Blocking ambiguity:** what would resolve it
- **Next step:** observe / ask / wait

This format is not mandatory for every decision. Use it when the situation is ambiguous or the stakes are high enough to warrant explicit analysis.

---

## 7. Kata

### Scenario: ambiguous bug report

**Task:** A user reports "the CLI is broken." No stack trace, no reproduction steps. You have access to the repo and recent commit history.

**Governing skills:** CAP, reflect

**Inputs:**
- The user's report: "the CLI is broken"
- The repo at current HEAD
- Recent commit log

**Expected artifacts:**
- A CAP output (situation, constraints, candidate gaps, governing gap, mode, next step)
- Either a fix (MCA) or an explicit statement of what you need to learn (MCI)

**Verification:**
- Did the agent read state before acting?
- Did the agent list candidate gaps before choosing?
- Did the agent distinguish symptom from governing gap?
- Was the response mode justified?

**Common failures:**
- Pattern-matching to a previous bug without reading current state
- Asking the user for more info without first checking what is observable in the repo
- Fixing the first thing that looks wrong without verifying it matches the report

**Reflection:**
- Was the governing gap the right one?
- Did Understand take long enough, or was it rushed?
- Would a different candidate gap have been more productive?

### Scenario: conflicting operator request

**Task:** The operator asks you to "clean up the README" but the README's real problem is that it has two governing questions. Cleaning up the prose would not fix the structural issue.

**Governing skills:** CAP, writing

**Inputs:**
- The operator's request
- The current README

**Expected artifacts:**
- A CAP output identifying the structural gap as governing
- A recommendation (MCA: split the file or rewrite around one question)

**Verification:**
- Did the agent identify the structural gap instead of just tightening prose?
- Did the agent explain why the cosmetic fix would not close the real gap?

**Common failures:**
- Tightening prose without noticing the file has two jobs
- Refusing the operator's request instead of reframing it

**Reflection:**
- Was the reframe respectful and grounded in evidence?
- Did the operator get a better outcome than what they asked for?
