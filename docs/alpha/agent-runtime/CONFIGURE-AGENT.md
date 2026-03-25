# Configure Agent

**Version:** 1.0.0
**Status:** Draft
**Doc-Class:** canonical-spec
**Canonical-Path:** docs/alpha/agent-runtime/CONFIGURE-AGENT.md
**Owns:** configuration mode, constitutive-self installation, operator interview flow, confirmation protocol, promotion rules
**Does-Not-Own:** general onboarding, runtime contract schema, memory system, release process

---

## 0. Purpose

This document defines how a coherent agent is installed and configured for one hub and one operator.

The goal is not to generate a persona. The goal is to install a stable constitutive self and a stable operator relationship.

The output of configuration is:

- spec/SOUL.md — who the agent is
- spec/USER.md — who the operator is and how they want to work
- one confirmed commit recording the installation or reconfiguration

---

## 1. Problem

cnos already loads spec/SOUL.md and spec/USER.md as the first identity surfaces at wake. The runtime contract also classifies those files as constitutive_self. That means they are not ordinary working files. They are identity substrate.

A coherent system cannot treat constitutive identity as something the agent silently rewrites during normal work. So configuration must be explicit.

---

## 2. Decision

Introduce configuration mode.

### 2.1 Outside configuration mode

The agent may:

- read spec/SOUL.md
- read spec/USER.md
- propose changes
- explain why a change is needed

The agent may not:

- silently rewrite constitutive files
- treat temporary conversation preferences as identity changes

### 2.2 Inside configuration mode

The agent may:

- interview the operator
- draft proposed changes
- summarize them in plain language
- apply them only after explicit confirmation

### 2.3 Confirmation rule

No change to spec/SOUL.md or spec/USER.md is applied without one of:

- explicit operator approval in the current session
- an explicit operator-defined auto-apply rule already recorded in spec/USER.md

Default is approval required.

---

## 3. File ownership

### 3.1 spec/SOUL.md

Owns the agent's stable orientation:

- name
- role
- core drive
- truth / honesty invariants
- conduct invariants
- ambiguity tie-breaks
- continuity / self-change rule

This file should change rarely.

### 3.2 spec/USER.md

Owns the operator relationship:

- who the operator is
- timezone / locale
- communication style
- update preferences
- autonomy boundaries
- external-action gates
- domains to focus on / avoid
- durable operator preferences

This file may change more often.

---

## 4. Promotion rules

Not everything learned becomes constitutive self.

### 4.1 Transient

Store only in working state or conversation context.

Examples:
- one-off phrasing preference
- session-local plan
- temporary urgency

### 4.2 Durable operator preference

Promote to spec/USER.md.

Examples:
- prefers concise updates
- wants confirmation before external actions
- wants weekly check-ins
- dislikes speculative answers

### 4.3 Constitutive agent change

Promote to spec/SOUL.md, but only with explicit proposal and confirmation.

Examples:
- truthfulness rule needs correction
- default autonomy stance is wrong
- the agent's tie-break logic causes repeated failures

### 4.4 Rule

Do not promote transient convenience into identity.

---

## 5. Installation flow

### 5.1 Fresh install

1. Hub is cloned or opened
2. Existing spec/SOUL.md and spec/USER.md are read
3. If they are missing, template defaults are used
4. Agent enters configuration mode
5. Operator interview runs
6. Agent drafts proposed SOUL.md and USER.md
7. Agent summarizes the proposed configuration in plain language
8. Operator confirms or edits
9. Agent writes files
10. Agent commits configuration
11. Agent exits configuration mode
12. Normal heartbeat begins

### 5.2 Reconfiguration

1. Triggered explicitly by operator, or
2. Triggered by repeated mismatch evidence

In reconfiguration:
- current files are treated as baseline
- the agent proposes a diff, not a blank rewrite
- the operator confirms before application

---

## 6. Interview protocol

The agent asks one question at a time in plain language.

The interview must cover:

### 6.1 Operator understanding

- who the operator is
- what matters most: speed, accuracy, proactivity, brevity, caution
- timezone / locale if relevant

### 6.2 Communication

- concise or detailed
- direct or softened
- proactive updates or only on request
- preferred escalation style

### 6.3 Autonomy

- when to ask before acting
- when internal work may proceed without approval
- whether external actions always require confirmation

### 6.4 Focus

- domains to emphasize
- domains to avoid
- things the agent should not do

### 6.5 Tools

- APIs / tools to know about
- whether periodic checks are wanted

The interview should avoid mentioning file names to the operator unless the operator asks.

---

## 7. Confirmation protocol

Before writing anything, the agent must produce:

1. plain-language summary
2. proposed changes grouped as:
   - agent identity changes
   - operator preference changes
3. explicit approval prompt

Accepted confirmation forms:
- "apply"
- "apply with these edits: …"
- "do not apply"

No ambiguous acceptance.

---

## 8. Required outputs

A successful configuration produces:

- updated spec/SOUL.md
- updated spec/USER.md
- optional plain-language summary artifact in state/ or thread history
- one commit recording the change

Recommended commit message:

```text
Configure agent for <operator-or-hub>
```

---

## 9. Repeated-mismatch protocol

If repeated evidence shows the current soul or user profile is wrong:

1. name the mismatch
2. cite repeated evidence
3. propose the change explicitly
4. request confirmation
5. apply only after approval

Constitutive self evolves through evidence, not drift.

---

## 10. Non-goals

This spec does not:

- define the entire onboarding sequence
- define memory retention in general
- turn the agent into a theatrical persona
- allow silent identity mutation during normal work
