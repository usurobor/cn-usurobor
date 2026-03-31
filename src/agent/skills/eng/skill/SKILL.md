---
name: skill
description: Write coherent skills. Use when creating, rewriting, classifying, or reviewing any artifact under src/agent/skills/.
artifact_class: skill
kata_surface: embedded
governing_question: How do we write, classify, and verify coherent skills?
triggers:
  - creating a new skill
  - rewriting an old skill
  - deciding whether an artifact is really a skill
  - normalizing a skill to the meta-skill standard
---

# Skill

## Core Principle

**Coherent skill: a true skill teaches repeatable judgment in one domain through a domain-specific coherence formula, unfolded into necessary sections, enforced by imperative rules, and made trainable through a kata surface.**

A skill is not a pile of advice. A skill is not a lookup page. A skill is not a runbook with a nicer title.

If the formula is generic, the artifact is not ready. If the artifact is really a runbook or reference, reclassify it instead of forcing skill form onto it.

## Algorithm

1. Define — classify the artifact, name the domain formula, the governing question, the parts, and the failure mode.
2. Unfold — organize the artifact so each section serves the formula in a necessary order.
3. Rules — write imperative rules with stable IDs and contrastive ❌/✅ examples.
4. Verify — check that the artifact, its classification, and its kata surface all match.

---

## 1. Define

### 1.0. Classify the artifact first

Every artifact under `src/agent/skills/` must declare its class. Valid classes:

- **skill** — teaches repeatable judgment in a domain
- **runbook** — teaches ordered operational steps
- **reference** — provides lookup-oriented material
- **deprecated** — superseded, merged, or no longer authoritative

Use these tests:

A skill:

- has a domain-specific coherence formula
- teaches judgment, not just sequence
- benefits from Define → Unfold → Rules
- should expose a kata surface

A runbook:

- is mainly ordered steps
- depends on sequence and preconditions
- may have a drill or checklist, but does not need a coherence formula

A reference:

- is mainly conventions, APIs, commands, templates, or examples
- is lookup-oriented
- should be declarative, not artificially "skill-shaped"

A deprecated artifact:

- is superseded
- belongs inside another artifact
- should not silently remain live

- ❌ Force every low-scoring artifact into skill form
- ✅ Reclassify first, then rewrite only true skills

### 1.1. Identify the parts

Ask:

- what are the parts in this domain?
- what must stay distinct?
- what must fit together?

- ❌ Skip straight to bullet rules
- ✅ "Review has: contract, evidence, verdict"
- ✅ "Writing has: document, section, paragraph, sentence, word"

### 1.2. Articulate how they fit

State the coherence formula in one sentence. The formula must explain:

- how the parts serve the whole
- what makes the domain coherent
- what is lost if one part is missing

- ❌ "Coherent writing: follow best practices"
- ✅ "Coherent writing moves understanding forward with the minimum text required"
- ❌ "Coherent review: be thorough"
- ✅ "Coherent review resolves terms, pointer, and exit to the same gap"

### 1.3. Name the governing question

Every true skill should answer one governing question. Use a sentence like:

> This skill teaches how to...

- ❌ One artifact teaching two or three domains at once
- ✅ "This skill teaches how to design a change before implementing it"
- ✅ "This skill teaches how to review a change against its declared contract"

### 1.4. Name the failure mode

A good skill names what incoherence looks like in its domain.

- ❌ Generic: "doing it wrong"
- ✅ Specific: "Design fails through incomplete impact tracing"
- ✅ Specific: "Writing fails through clutter and drift"
- ✅ Specific: "Review fails when evidence and verdict drift apart"

If you cannot name the failure mode, the formula is probably still vague.

---

## 2. Unfold

### 2.1. One skill, one domain

Do not let one skill do several jobs.

- ❌ A skill that mixes theory, operations, and style guidance
- ✅ A skill that owns one domain and points to adjacent artifacts when needed

### 2.2. Order sections by dependency

Sections should build on one another. Common progressions:

- small → large
- simple → complex
- gather → process → act
- observe → interpret → decide → act

- ❌ Random ordering of advice
- ✅ Each section depends on the one before it

### 2.3. Make the artifact demonstrate its own formula

A coherent skill should obey its own rules.

- ❌ A writing skill that rambles
- ❌ A design skill with no impact graph
- ❌ A review skill with no clear verdict structure
- ✅ The artifact itself is the first proof that the formula works

### 2.4. Provide a kata surface for every true skill

A true skill must be kata-compatible. Allowed values:

- **embedded** — the skill contains its own kata section
- **external** — the skill points to a sibling kata file
- **none** — allowed only for runbook, reference, or deprecated artifacts

A kata surface must define:

- scenario
- task
- governing skills
- inputs
- expected artifacts
- verification
- common failures
- reflection

- ❌ A true skill with no practice surface
- ✅ A skill with an embedded or external kata that proves it can be exercised

### 2.5. Use output formats only when the artifact produces recurring outputs

If the artifact regularly produces:

- design docs
- review requests
- self-coherence reports
- release notes

provide a stable output format.

Do not force templates into artifacts that do not need them.

- ❌ Add output templates to every artifact
- ✅ Add them only when the artifact produces recurring structured outputs

---

## 3. Rules

### 3.1. Require frontmatter

Every artifact should declare what it is. Minimum frontmatter:

- `name`
- `description`
- `artifact_class`
- `kata_surface`
- `governing_question`

- ❌ Leave classification implicit
- ✅ Make the artifact say what it is

### 3.2. State what the artifact is

Name the artifact positively and concretely.

- ❌ "This is not just a checklist"
- ✅ "This skill teaches how to..."
- ✅ "This runbook explains how to..."
- ✅ "This reference lists..."

### 3.3. Write imperative rules

Each rule should start with a verb.

- ❌ "Impact graphs are important"
- ✅ "Trace the impact graph"
- ❌ "Filler phrases are bad"
- ✅ "Cut filler phrases"

### 3.4. Add one line of context only when it helps

A rule may have one short line explaining why it matters or when it applies.

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

Do not renumber casually.

- ❌ "See above"
- ✅ "See 2.3."

### 3.7. Keep authority explicit

If the artifact depends on another surface, say so directly.

- ✅ "Canonical doc governs on disagreement."
- ✅ "This is a reference profile, not the method."
- ✅ "This skill is the executable summary."

Do not make the reader infer authority from tone.

### 3.8. Say stable facts once, then point to them

Stable facts should have one home. State them once. Elsewhere, point back.

- ❌ Restate the same authority rule in multiple artifacts with slight drift
- ✅ Name the owning artifact once and point to it

### 3.9. Do not force skill form onto the wrong artifact

If the artifact is really a runbook or reference, reclassify it.

- ❌ Add fake coherence language to a command cheat sheet
- ✅ Keep lookup docs declarative and let skills teach judgment

### 3.10. Sync source and packaged copies

If you edit anything under `src/agent/skills/`, keep packaged copies in sync.

- ❌ Update only the source artifact and leave the packaged copy stale
- ✅ Run the build/sync path before claiming the change is complete

---

## 4. Verify

### 4.1. Classification check

Ask:

- is this really a skill?
- if not, should it be runbook, reference, or deprecated?

### 4.2. Formula check

Ask:

- is the formula domain-specific?
- is the failure mode named?
- does the artifact answer one governing question?

### 4.3. Structure check

Ask:

- does each section serve the formula?
- are sections ordered by dependency?
- does the artifact obey the rules it teaches?

### 4.4. Kata check

Ask:

- does every true skill expose a kata surface?
- is the kata embedded or external?
- does the kata define scenario, task, governing skills, inputs, expected artifacts, verification, failures, and reflection?

### 4.5. Corpus check

Ask:

- is frontmatter present?
- is the artifact class explicit?
- is the package copy synced if needed?

---

## 5. Final Test

An artifact is coherent when:

- its class is explicit
- its governing question is singular
- its formula is domain-specific
- its failure mode is named
- its sections unfold in a necessary order
- its rules are imperative
- its examples show one failure and one fix
- its authority is explicit
- every true skill has a kata surface
- it demonstrates its own formula

If the formula is generic, sharpen it. If the artifact is not a skill, reclassify it. If the skill cannot be practiced, add a kata surface.
