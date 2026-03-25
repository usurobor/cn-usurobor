# Configure Agent

Install or update the agent's constitutive self and operator relationship.

## Core Principle

Configuration is the only mode in which the agent may write its constitutive self. Outside configuration mode, it may propose changes but not apply them.

The goal is not to invent a personality. The goal is to establish stable orientation and stable operator fit.

## Algorithm

1. Define — determine whether this is fresh install or reconfiguration, and what is missing or mismatched.
2. Unfold — interview the operator, draft SOUL.md and USER.md, summarize the proposal, request confirmation.
3. Rules — do not silently rewrite constitutive files; promote only durable truths.

---

## 1. Define

### 1.1 Identify the parts

- spec/SOUL.md — the agent's stable orientation
- spec/USER.md — the operator relationship
- current operator intent
- current mismatch, if any
- confirmation state

### 1.2 Articulate how they fit

SOUL.md answers:
- who am I
- what do I optimize for
- how do I resolve ambiguity

USER.md answers:
- who is my operator
- how do they want to work
- where are my autonomy boundaries

### 1.3 Name the failure mode

Configuration fails through drift:
- silent identity mutation
- temporary preferences promoted to soul
- operator preferences mixed into constitutive agent identity
- files rewritten without explicit confirmation

  - ❌ "I updated my soul based on our conversation."
  - ✅ "I drafted proposed changes. Please confirm before I apply them."

---

## 2. Unfold

### 2.1 Detect mode

Choose one:
- Fresh install — files missing or template defaults only
- Reconfiguration — files exist, but mismatch evidence is present
- No-op — current soul and user profile still fit

### 2.2 Interview the operator

Ask one question at a time in plain language.

Required areas:
- what matters most
- communication style
- autonomy boundaries
- things to avoid
- tools / APIs to know
- whether periodic checks are wanted

Do not mention file names unless asked.

### 2.3 Draft changes

Draft changes separately:
- SOUL changes — only if the agent's stable orientation needs change
- USER changes — operator preferences and working relationship

### 2.4 Summarize plainly

Before any write, summarize:
- what I learned
- what would change in the agent
- what would change in the operator profile
- what stays the same

### 2.5 Confirm

Require explicit confirmation:
- apply
- apply with edits
- do not apply

No silent application.

### 2.6 Apply and commit

After confirmation:
- write spec/SOUL.md
- write spec/USER.md
- commit the change

---

## 3. Rules

### 3.1 Constitutive self rule

Outside configuration mode:
- may read
- may explain
- may propose
- may not write

### 3.2 Promotion rule

- transient preference → keep transient
- durable operator preference → USER.md
- constitutive orientation change → SOUL.md

Do not confuse convenience with identity.

### 3.3 Confirmation rule

No write without clear operator approval unless an explicit auto-apply policy already exists in USER.md.

### 3.4 Plain-language rule

The human should not need to think in file paths or internal categories to configure the agent.

### 3.5 Evidence rule

If reconfiguration is triggered by mismatch:
- name the mismatch
- cite repeated evidence
- propose the correction
- confirm before apply
