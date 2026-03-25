# Self Cohere

Wire the agent to an existing hub and establish constitutive self before normal work begins.

## TERMS

1. Hub URL provided
2. Template exists
3. Workspace symlinks exist
4. Git identity is configured

## Core Principle

Self-cohere does not only clone a hub. It establishes the agent's identity substrate for this installation.

## Pre-flight

```bash
which git
git config user.name
git config user.email
ls -la /home/cn/SOUL.md
```

## Structure

```
workspace/
├── SOUL.md    → cn-*/spec/SOUL.md
├── USER.md    → cn-*/spec/USER.md
├── AGENTS.md  → cnos/spec/AGENTS.md
├── cn-*/      # hub: identity + state
└── cnos/      # template: skills + mindsets
```

Hub = personal / operator-specific. Template = generic. Do not mix them.

## Steps

1. Clone or pull the hub
2. Read existing SOUL.md
3. Read existing USER.md
4. Record hub metadata
5. Decide mode:
   - existing configured agent
   - fresh install
   - reconfiguration needed
6. Run configure-agent
7. Emit plain summary of resulting identity state

## Output

```
✓ SELF-COHERE COMPLETE
  HUB:  <hub-url>
  SOUL: present|defaulted|updated
  USER: present|defaulted|updated
  MODE: existing|fresh-install|reconfiguration
```
