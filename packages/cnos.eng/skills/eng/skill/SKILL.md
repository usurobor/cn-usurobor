---
name: skill
description: Write coherent skills. Use when creating, rewriting, classifying, or reviewing any artifact under src/agent/skills/.
triggers:
  - creating a new skill
  - rewriting an old skill
  - deciding whether an artifact is really a skill
  - normalizing a skill to the meta-skill standard
---

# Skill

## Core Principle

Coherent skill: a skill teaches repeatable judgment in one domain through a domain-specific coherence formula, unfolded into necessary sections, enforced by imperative rules, and demonstrated by its own structure.

A skill is not a pile of advice. A skill is not a lookup page. A skill is not a runbook with a nicer title.

If the formula is generic, the artifact is not ready. If the artifact is really a runbook or reference, reclassify it instead of forcing skill form onto it.

## Algorithm

1. Define — classify the artifact, name the domain formula, the parts, the governing question, and the failure mode.
2. Unfold — organize the skill so each section serves the formula in a necessary order.
3. Rules — write imperative rules with stable IDs and contrastive ❌/✅ examples.
4. Verify — check that the skill itself obeys the structure it teaches.

---

## 1. Define

### 1.0. Classify the artifact first

Before writing or rewriting, decide what kind of artifact this is.

A true skill:

- teaches repeatable judgment in a domain
- has a domain-specific coherence formula
- benefits from Define → Unfold → Rules

A runbook:

- is mostly ordered operational steps
- depends on sequence and preconditions more than judgment

A reference:

- is lookup-oriented
- mainly holds commands, conventions, templates, APIs, or examples

A deprecated / merged artifact:

- is too small to stand alone
- belongs inside another skill or reference

- ❌ Force every low-quality artifact into skill form
- ✅ Reclassify first, then rewrite only the true skills

### 1.1. Identify the parts

Ask:

- what are the parts in this domain?
- what must stay distinct?
- what must fit together?

- ❌ Skip straight to bullet rules
- ✅ "Reflection has: observation, interpretation, output"
- ✅ "Design has: problem, constraints, impact graph, proposal, acceptance criteria"

### 1.2. Articulate how they fit

State the coherence formula in one sentence. The formula must explain:

- how the parts serve the whole
- what makes the domain coherent
- what would be lost if one part were missing

- ❌ "Coherent writing: follow best practices"
- ✅ "Coherent writing: nothing can be removed without loss"
- ❌ "Coherent review: be thorough"
- ✅ "Coherent review: terms, pointer, and exit all resolve to the same gap"

### 1.3. Name the governing question

Every skill should answer one governing question. Use a sentence like:

> This skill teaches how to...

- ❌ One skill mixing several domains
- ✅ One skill with one governing question

Examples:

- "This skill teaches how to design a change before implementing it."
- "This skill teaches how to review a change against its declared contract."
- "This skill teaches how to write so the reader understands the point on the first pass."

### 1.4. Name the failure mode

A good skill names what incoherence looks like in its domain.

- ❌ Generic: "doing it wrong"
- ✅ Specific: "Reflection fails via motivated reasoning"
- ✅ Specific: "Design fails via incomplete impact tracing"
- ✅ Specific: "Writing fails through clutter and drift"

If you cannot name the failure mode, the formula is probably still vague.

---

## 2. Unfold

### 2.1. One skill, one domain

Do not let one skill do several jobs.

- ❌ A skill that mixes theory, operations, and style guidance
- ✅ A skill that owns one domain and points to adjacent skills when needed

### 2.2. Order sections by dependency

Sections should build on one another. Good progressions:

- small → large
- simple → complex
- gather → process → act
- observe → interpret → decide → act

- ❌ Random ordering of tips
- ✅ Each section depends on the one before it

### 2.3. High alpha — each bullet stands on its own

Each bullet should be locally coherent. The reader should not need to leave the bullet to understand the rule.

- ❌ "Cut filler (see appendix for examples)"
- ✅ "Cut filler: ❌ 'In order to' → ✅ 'To'"

### 2.4. High beta — sections serve the whole

Each section should answer a necessary sub-question.

- ❌ Section exists because it sounds related
- ✅ Section exists because the formula needs it

Ask:

- if I remove this section, what necessary understanding disappears?

### 2.5. Keep examples small and contrastive

Examples should show one failure and one fix.

- ❌ One giant before/after example with many unrelated changes
- ✅ One bad line and one corrected line
- ✅ One incoherent behavior and the coherent version of the same situation

### 2.6. Use output formats only when the skill produces recurring artifacts

If the skill regularly produces:

- issue specs
- design docs
- self-coherence reports
- review requests

then provide a stable output format.

If it does not, do not force a template into the skill.

- ❌ Add output templates to every skill
- ✅ Add them only when the artifact recurs and benefits from structure

---

## 3. Rules

### 3.1. Start with the formula

Put the domain-specific coherence formula near the top.

- ❌ Three paragraphs of setup before the principle appears
- ✅ "Coherent design: every decision traces to a named incoherence..."

### 3.2. State what the skill is

Name the skill positively and concretely.

- ❌ "This is not just a checklist"
- ✅ "This skill teaches how to..."

### 3.3. Write imperative rules

Each rule should start with a verb.

- ❌ "Filler phrases are bad"
- ✅ "Cut filler phrases"
- ❌ "Impact graphs are important"
- ✅ "Trace the impact graph"

### 3.4. Add one line of context only when it helps

Rules may have one short line explaining why they matter or when they apply.

- ❌ Three sentences of background before the rule starts
- ✅ "Vague observations do not produce action."

### 3.5. Pair ❌ and ✅ on the same failure

The fix must answer the same situation as the failure.

- ❌ Failure example about one thing, fix example about something else
- ✅ Same situation, corrected

### 3.6. Keep IDs stable

Use numbered IDs such as:

- 1.2.
- 2.4.
- 3.7.

Do not renumber casually. Add new items at the end of a section when possible.

- ❌ "See above"
- ✅ "See 2.3."

### 3.7. Keep authority explicit

If the skill depends on another surface, say so directly.

- ✅ "Canonical doc governs on disagreement."
- ✅ "This is a reference profile, not the method."
- ✅ "This skill is the executable summary."

Do not make the reader infer authority from tone.

### 3.8. Say stable facts once, then point to them

If a stable fact belongs elsewhere, point to it. Do not duplicate it across many skills.

- ❌ Restate the same authority rule in multiple places with slight drift
- ✅ Name the owning document once and point to it

### 3.9. Make the skill demonstrate its own formula

A coherent skill should obey its own rules.

- ❌ A writing skill that rambles
- ❌ A design skill with no impact graph
- ❌ A review skill with no clear verdict structure
- ✅ The skill itself is the first proof that the formula works

### 3.10. Do not force skill form onto the wrong artifact

If the artifact is really a runbook or reference, reclassify it.

- ❌ Add fake coherence language to a command cheat sheet
- ✅ Keep lookup docs declarative and let skills teach judgment

### 3.11. Sync source and packaged copies

If you edit anything under `src/agent/skills/`, keep packaged copies in sync.

- ❌ Update only the source skill and leave the packaged copy stale
- ✅ Run the build/sync path before claiming the change is complete

---

## 4. Verify

### 4.1. File-level check

Ask:

- what is the one governing question?
- is this really a skill?
- what is the domain-specific coherence formula?
- what is the named failure mode?

### 4.2. Structure check

Ask:

- does each section serve the formula?
- are sections ordered by dependency?
- does each paragraph make one move?

### 4.3. Rule check

Ask:

- does each rule start with a verb?
- does each rule have a real ❌/✅ pair?
- are examples small and contrastive?
- are IDs stable?

### 4.4. Self-demonstration check

Ask:

- does the skill itself obey the writing, design, and coherence standards it teaches?

If not, it is not done.

---

## 5. Final Test

A skill is coherent when:

- the artifact is correctly classified
- the governing question is singular
- the formula is domain-specific
- the failure mode is named
- sections unfold in a necessary order
- rules are imperative
- examples show one failure and one fix
- authority is explicit
- the skill demonstrates its own formula

If a formula is generic, sharpen it. If a section does not serve the whole, cut it. If the artifact is not really a skill, reclassify it.
