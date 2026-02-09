# reflect

## Core Principle

**Coherent reflection: the conclusion matches the evidence.**

Why this is coherence:
- Reflection has parts: observation, interpretation, output
- Coherence = parts fit together, serve the whole
- Conclusion must follow from evidence
- If it doesn't → self-deception → incoherent

Failure mode: motivated reasoning — comfortable conclusions ignoring uncomfortable observations.

## 1. Evidence

What actually happened.

1.1. **Observe behavior, not intentions**
  - ❌ "I tried to help" → ✅ "I sent three messages, none addressed the question"
  - ❌ "I meant to check" → ✅ "I didn't check"

1.2. **Be specific**
  - ❌ "The session went poorly" → ✅ "I missed two requests, repeated three times"
  - ❌ "I was slow" → ✅ "Response took 40 minutes"

1.3. **Include uncomfortable facts**
  - ❌ "Things got confused" → ✅ "I said X, but X was false"
  - ❌ Skip the failure → ✅ Name it first

## 2. Interpretation

What the evidence means. Must follow from section 1.

2.1. **Derive from evidence, not excuse**
  - ❌ "I was tired" → ✅ "I didn't read the message before responding"
  - ❌ "The instructions were unclear" → ✅ "I didn't ask for clarification"

2.2. **Check for motivated reasoning**
  - ❌ "They should have been clearer" → ✅ "I assumed instead of asking"
  - ❌ "It wasn't my fault" → ✅ "I could have caught this"

2.3. **Name the pattern, not the instance**
  - ❌ "I made a mistake in that file" → ✅ "I ship before testing"
  - ❌ "That response was wrong" → ✅ "I don't verify before sending"

## 3. Conclusion

What to do. Must follow from section 2.

3.1. **State the action (MCA)**
  - ❌ "Be more careful" → ✅ "Rerun test suite before pushing"
  - ❌ "Try harder" → ✅ "Add checklist to PR template"

3.2. **State the insight (MCI)**
  - ❌ "That was hard" → ✅ "Investigate before escalating"
  - ❌ "I learned a lot" → ✅ "Verify assumptions with evidence"

3.3. **Prefer MCA over MCI**
  - ❌ "I should always double-check" → ✅ "Fix the bug now"
  - ❌ Turn action into principle → ✅ Do the action

## 4. Axes

Three lenses for examination.

4.1. **Check internal consistency (α)**
  - ❌ "I value quality" + shipping bugs → ✅ Name the gap, close it
  - ❌ Stated values ≠ observed behavior → ✅ Align or update values

4.2. **Check relational honesty (β)**
  - ❌ Claiming credit I didn't earn → ✅ Accurate contribution statement
  - ❌ Overpromising → ✅ State actual capacity

4.3. **Check temporal progress (γ)**
  - ❌ Same mistake, third week → ✅ Pattern broken, evidence of change
  - ❌ Stuck in loop → ✅ New approach tried

## 5. Cadence

When to reflect.

5.1. **Capture in real-time**
  - ❌ "Will reflect at EOD" → ✅ Write it when it happens
  - ❌ Deferred reflection → ✅ Immediate capture

5.2. **Consolidate at higher cadences**
  - ❌ Same insight in 4 daily threads → ✅ Migrate to skill after 3 weeks
  - ❌ Never review weekly → ✅ Weekly reviews daily, monthly reviews weekly

| Cadence | File |
|---------|------|
| Daily | `threads/reflections/daily/YYYYMMDD.md` |
| Weekly | `threads/reflections/weekly/YYYY-WNN.md` |
| Monthly | `threads/reflections/monthly/YYYYMM.md` |
