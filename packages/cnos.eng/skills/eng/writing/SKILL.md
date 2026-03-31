---
name: writing
description: Write so the reader understands the point on the first pass. Use for docs, issues, specs, READMEs, essays, reviews, and status updates.
triggers:
  - drafting new docs
  - rewriting unclear docs
  - fixing repetition across files
  - tightening README / architecture / quickstart splits
  - reducing clutter without losing meaning
---

# Writing

## Core Principle

Coherent writing moves understanding forward with the minimum text required.

Nothing can be removed without loss. Nothing should be repeated without gain. Each file should answer one governing question.

If a document argues with itself, it usually has too many jobs, repeats stable facts, or explains what something is not instead of what it is.

## Algorithm

1. Define — name the governing question, the reader, the stable facts, and the failure mode.
2. Unfold — organize from document → section → paragraph → sentence → word.
3. Rules — state imperative rules with direct ❌/✅ examples and revise in that same order.

---

## 1. Define

### 1.1. Identify the parts

A coherent text has five levels:

- Document — one governing question
- Section — one sub-question
- Paragraph — one move
- Sentence — one main claim
- Word — one job

- ❌ Start at the sentence level and hope the document works
- ✅ Name the document's job first, then make every lower level serve it

### 1.2. Articulate how they fit

The document sets the question. Each section answers part of it. Each paragraph advances one step. Each sentence makes one move. Each word earns its place.

- ❌ One file explains purpose, architecture, roadmap, and usage at once
- ✅ One file answers one question and points elsewhere for the rest

### 1.3. Name the governing question

State the file's job in one sentence beginning with:

> This document explains...

If you need two different governing sentences, you probably have two files.

- ❌ "This document explains the repo, the architecture, how to run it, and the roadmap"
- ✅ "This document explains how the repo is organized"
- ✅ "This guide explains the current runnable path"

### 1.4. Name the stable facts

Stable facts are the facts that should be stated once, then pointed to elsewhere.

Examples:

- what the repo is
- where authority lives
- what config is live
- what the current implementation is
- what path is canonical

- ❌ Restate the same stable fact in README, ARCHITECTURE, and QUICKSTART
- ✅ Give the fact one home and link or point to it from other files

### 1.5. Name the failure mode

Writing fails through clutter and drift. Typical signs:

- the file has two jobs
- the point appears late
- the same fact appears in multiple files
- transitions compensate for weak logic
- abstractions replace specifics
- the reader must infer authority or scope

- ❌ "This repo is not X, not Y, not Z"
- ✅ "This repo is X"

---

## 2. Unfold

### 2.1. Document

Start with the point. The first sentence should orient the reader immediately. The first paragraph should commit to the file's job.

- ❌ Three paragraphs of setup before the point appears
- ✅ "TSC is a theory, a target model, and a verifier for triadic coherence."
- ✅ "This guide explains the current runnable path."

### 2.2. Section

Each section should answer one sub-question only. Name sections by what they do, not by vague themes.

- ❌ "Additional Notes"
- ❌ "Overview and Miscellaneous"
- ✅ "Targets"
- ✅ "Implementation"
- ✅ "Generated state"

If a section answers a different question, move it to another file.

### 2.3. Paragraph

One paragraph, one move. A paragraph may:

- state a claim
- explain a mechanism
- compare two options
- give one example
- close one implication

It should not do several unrelated things because they are nearby in your head.

- ❌ One paragraph defines the repo, explains the current CLI, and previews future implementation plans
- ✅ One paragraph for current implementation, one for future direction

### 2.4. Sentence

Lead with the point. Put stable context first. Put the new or important information at the end.

- ❌ "The current executable path is the Python implementation under reference/python/."
- ✅ "Python runs the current CLI."
- ❌ "The target model lives in project.tsc and targets/."
- ✅ "`project.tsc` is the live config. targets/ defines the named-target model."

### 2.5. Word

Every word must do new work. Prefer:

- short words over long words
- plain words over jargon
- active verbs over abstract nouns
- concrete nouns over vague labels

- ❌ "utilize"
- ✅ "use"
- ❌ "current executable implementation"
- ✅ "current implementation"
- ❌ "named target declarations"
- ✅ "targets"

---

## 3. Rules

### 3.1. State what it is

Define the thing positively. Use contrast only when the distinction is truly load-bearing.

- ❌ "This is not a platform, not a chat UI, not a product surface"
- ✅ "This is a protocol"
- ✅ "This is the current runnable path"
- ✅ "This is the canonical spec"

### 3.2. One file, one governing question

Do not let one file do several jobs.

- ❌ README also doing architecture, roadmap, quickstart, and manifesto
- ✅ README gives identity, map, and pointers
- ✅ ARCHITECTURE owns structure and authority
- ✅ QUICKSTART owns the runnable path

### 3.3. Say a fact once, then point to it

Stable facts should have one home.

- ❌ "Python is the current implementation" stated in three files with slightly different wording
- ✅ State it once clearly; elsewhere point to the file that owns it

### 3.4. Front-load the point

The first sentence must orient. The second may qualify. The third may expand.

- ❌ "It is important to understand the broader context before..."
- ✅ "This document explains how the repo is organized."

### 3.5. Cut throat-clearing

Remove self-introduction, permission slips, and commentary on the act of writing.

- ❌ "It is worth noting that..."
- ❌ "This section describes..."
- ✅ say the thing

### 3.6. Cut filler transitions

Use transitions only when they add logic:

- But for contrast
- So for consequence
- Because for cause
- Then for sequence

- ❌ "Additionally, furthermore, moreover"
- ✅ next sentence or next paragraph

### 3.7. Prefer active voice when agency matters

- ❌ "The file was updated by the user"
- ✅ "The user updated the file"

Use passive only when the actor is irrelevant or unknown.

### 3.8. Replace abstractions with specifics

Do not write "better," "clean," "robust," or "flexible" without evidence.

- ❌ "This design is cleaner"
- ✅ "This removes one duplicate source of truth"
- ❌ "The system is fast"
- ✅ "The response arrives in under 50 ms"

### 3.9. Replace opinion with source or reason

- ❌ "This is the best approach"
- ✅ "This matches the current runtime contract"
- ✅ "This removes two dead links and one duplicate fact"

### 3.10. Keep stable context before new information

Readers follow best when the sentence starts from what they already know and ends on what matters.

- ❌ "In the target model declared by the repo, project.tsc..."
- ✅ "`project.tsc` is the live config."

### 3.11. Use lists only when they reveal structure

Use a list when:

- order matters
- the items are parallel
- scanning helps

- ❌ Three bullets that are really one sentence
- ✅ Three bullets naming three distinct categories

### 3.12. Keep examples small and contrastive

Show one mistake and one fix.

- ❌ One giant before/after block with five changes at once
- ✅ One bad line and one better line

### 3.13. Keep authority explicit

If a document depends on another document, say so directly.

- ❌ Let the reader infer which file governs
- ✅ "Theory is canonical."
- ✅ "`project.tsc` is the live config."
- ✅ "This file is a guide, not the spec."

### 3.14. Brevity is earned, not chopped

Shorter is better only when meaning survives.

Cut:

- repetition
- filler
- duplicate facts
- vague intensifiers
- decorative contrast

Do not cut:

- distinctions that prevent error
- definitions that carry authority
- examples that disambiguate a rule

- ❌ Remove the only sentence that explains which file governs
- ✅ Remove the second and third restatement of it

### 3.15. End when the point is delivered

The ending should close the document's job. It should not restart the argument.

- ❌ Final paragraph that restates the whole file in softer language
- ✅ Final line that closes the last open question

---

## 4. Revision Pass

Revise in this order.

### 4.1. File pass

- What is the one governing question?
- Does every section serve it?
- Which stable facts belong here, and which belong elsewhere?

### 4.2. Section pass

- Does each section answer one sub-question?
- Can any section be cut, merged, or moved?

### 4.3. Paragraph pass

- One move per paragraph?
- Any paragraph doing two jobs?

### 4.4. Sentence pass

- Point first?
- Stable context before new information?
- Active voice where agency matters?

### 4.5. Word pass

- Can this word be cut?
- Can this phrase be shorter?
- Can this abstraction be made concrete?

---

## 5. Final Test

A text is coherent when:

- the reader knows what the file is for by the first sentence
- each section answers one question
- each paragraph makes one move
- each sentence lands its point early
- each word does new work
- no stable fact is duplicated without gain

If a word, sentence, paragraph, or section can be removed without loss, remove it.

If a fact appears twice, choose one home and point to it.

If the file has two jobs, split it.
