# Skills

How the skill corpus is organized.

## Purpose

This directory contains more than one kind of artifact. Not every artifact here is a skill.

The corpus uses one directory axis for domain and one metadata axis for artifact class.

### Domain directories

Current directories group artifacts by domain:

- agent/ — foundational coherent-agent behavior
- eng/ — engineering practice
- ops/ — operational / hub-facing practice
- cdd/ — development method
- release/ — release procedure
- testing/ — testing-related artifacts

These folders do not tell you whether an artifact is a skill, runbook, or reference. That is handled by frontmatter.

---

## Artifact classes

Every artifact under src/agent/skills/ should declare:

- artifact_class: skill | runbook | reference | deprecated
- kata_surface: embedded | external | none
- governing_question: ...

### Skill

A skill teaches repeatable judgment in one domain.

A true skill:

- has a domain-specific coherence formula
- follows the meta-skill
- exposes a kata surface

### Runbook

A runbook teaches ordered operational steps. It may have a drill or checklist. It does not need a coherence formula.

### Reference

A reference artifact is lookup-oriented. Use it for:

- commands
- conventions
- templates
- APIs
- examples
- style guides

### Deprecated

A deprecated artifact is superseded, merged, or no longer authoritative. Do not leave deprecated artifacts ambiguous.

---

## Kata compatibility

Every true skill must be kata-compatible. That means the artifact must expose a kata surface:

- kata_surface: embedded — the skill contains its own kata section
- kata_surface: external — the skill points to a sibling kata.md
- kata_surface: none — allowed only for runbook, reference, or deprecated artifacts

A kata should define:

- scenario
- task
- governing skills
- inputs
- expected artifacts
- verification
- common failures
- reflection

The goal is not ceremony. The goal is practice and evidence.

---

## Current migration rule

Older artifacts may still reflect the previous corpus model. That older model included:

- TERMS / INPUTS / EFFECTS
- mandatory sibling kata.md
- flatter skill descriptions

The current standard is the meta-skill in:

```text
src/agent/skills/eng/skill/SKILL.md
```

When rewriting an artifact:

1. classify it first
2. rewrite only if it is a true skill
3. add or preserve a kata surface if it remains a skill

---

## Adding a new artifact

**Step 1** — choose the domain folder

Put the artifact in the domain it belongs to:

- agent
- eng
- ops
- cdd
- release
- testing

**Step 2** — classify it

Choose one:

- skill
- runbook
- reference
- deprecated

**Step 3** — add frontmatter

Minimum frontmatter:

```yaml
---
name: <artifact-name>
description: <one-sentence purpose>
artifact_class: skill
kata_surface: embedded
governing_question: <one sentence>
---
```

Adjust artifact_class and kata_surface to match reality.

**Step 4** — follow the right standard

- skill → follow eng/skill/SKILL.md
- runbook → ordered steps, explicit preconditions, verification
- reference → declarative lookup structure
- deprecated → state replacement and status clearly

**Step 5** — sync package copies

If the artifact ships through packaged skills, sync the packaged copy before claiming the change is complete.

---

## Current priority

The corpus is in transition. The highest-value work is:

1. classify existing artifacts correctly
2. rewrite true skills to the meta-skill standard
3. reclassify references and runbooks instead of forcing skill form onto them
4. make kata surfaces explicit for every true skill

---

## Canonical authority

The canonical skill standard is:

```text
src/agent/skills/eng/skill/SKILL.md
```

If this README and the meta-skill disagree, the meta-skill governs.
