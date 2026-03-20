# Reflect

## Core Principle

**Coherent reflection: the conclusion matches the evidence.**

Reflection has parts: observation, interpretation, output.
Coherence = parts fit together, serve the whole.
If conclusion doesn't follow from evidence → self-deception → incoherent.

Failure mode: motivated reasoning — comfortable conclusions ignoring uncomfortable observations.

## 1. Define

1.1. **Identify the parts**
  - Evidence: what actually happened (observable behavior)
  - Interpretation: what the evidence means (pattern, not excuse)
  - Conclusion: what to do about it (MCA or MCI)
  - ❌ "I reflected on today" (no parts named)
  - ✅ Evidence → Interpretation → Conclusion, each grounded in the prior

1.2. **Articulate how they fit**
  - Interpretation must derive from evidence, not exist independently
  - Conclusion must follow from interpretation, not from comfort
  - ❌ Evidence says X, conclusion ignores X
  - ✅ Evidence → pattern named → action addresses pattern

1.3. **Name the failure mode**
  - Motivated reasoning: conclusion serves comfort, not truth
  - ❌ "Things got confused" (vague, blame-diffusing)
  - ✅ "I said X, but X was false" (specific, owned)

## 2. Unfold

2.1. **Evidence — observe behavior, not intentions**
  - What actually happened vs what should have happened
  - Specific, observable, includes uncomfortable facts
  - ❌ "I tried to help" → ✅ "I sent three messages, none addressed the question"
  - ❌ "I was slow" → ✅ "Response took 40 minutes"
  - ❌ "Things went poorly" → ✅ "I missed two requests, repeated three times"

2.2. **Interpretation — derive from evidence, not excuse**
  - Name the pattern, not the instance
  - Check for motivated reasoning: am I blaming context instead of owning behavior?
  - ❌ "I was tired" → ✅ "I didn't read the message before responding"
  - ❌ "The instructions were unclear" → ✅ "I assumed instead of asking"
  - ❌ "That response was wrong" → ✅ "I don't verify before sending"

2.3. **Conclusion — state action or insight**
  - MCA (Minimum Coherent Action): concrete, doable now
  - MCI (Minimum Coherent Insight): reusable principle for future
  - Prefer MCA over MCI — do the thing, don't just learn the lesson
  - ❌ "Be more careful" → ✅ "Rerun test suite before pushing"
  - ❌ "I learned a lot" → ✅ "Verify assumptions with evidence"

2.4. **Axes — three lenses for examination**
  - α (internal consistency): stated values match observed behavior
  - β (relational honesty): accurate contribution, no overpromising
  - γ (temporal progress): patterns broken, not loops repeated
  - ❌ "I value quality" + shipping bugs → ✅ Name the gap, close it
  - ❌ Same mistake, third week → ✅ New approach tried, evidence of change

## 3. Rules

3.1. **State evidence before interpretation**
  - Observation grounds everything; interpretation without evidence is confabulation
  - ❌ Start with "I think the problem was..." (interpretation-first)
  - ✅ Start with "What happened: ..." then "What this means: ..."

3.2. **Include uncomfortable facts first**
  - If you're tempted to skip it, that's the signal to write it
  - ❌ Skip the failure, lead with wins
  - ✅ Name the failure first, then contextualize

3.3. **Prefer MCA over MCI**
  - An action you can take now beats a principle you might follow later
  - ❌ "I should always double-check" (principle, no teeth)
  - ✅ "Fix the bug now; add checklist to PR template" (action, verifiable)

3.4. **One reflection, one through-line**
  - Evidence → Interpretation → Conclusion should track a single thread
  - Split compound reflections
  - ❌ "I was slow AND I missed a bug" with one conclusion
  - ✅ Two separate evidence→interpretation→conclusion chains

3.5. **Capture in real-time, consolidate at cadence**
  - Write it when it happens; don't defer
  - Weekly reviews daily, monthly reviews weekly, quarterly reviews monthly
  - ❌ "Will reflect at EOD" (deferred → lossy)
  - ✅ Immediate capture, cadence-level consolidation

3.6. **Cadence table**

  | Cadence | When | File |
  |---------|------|------|
  | Daily | End of session | `threads/reflections/daily/YYYYMMDD.md` |
  | Weekly | Sunday | `threads/reflections/weekly/YYYY-WNN.md` |
  | Monthly | 1st | `threads/reflections/monthly/YYYYMM.md` |
  | Quarterly | Q start | `threads/reflections/quarterly/YYYYQN.md` |
  | Yearly | Jan 1 | `threads/reflections/yearly/YYYY.md` |
