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
2. Read existing spec/SOUL.md
3. Read existing spec/USER.md
4. If either file is missing, copy template defaults from `cnos/spec/SOUL.md` and `cnos/spec/USER.md` into the hub's `spec/` directory. Identity must be materialized in the hub before first normal wake — the runtime packer has no fallback.
5. Record hub metadata
6. Decide mode:
   - existing configured agent — both files present and populated
   - fresh install — one or both files were missing or defaulted
   - reconfiguration needed — files exist but mismatch evidence is present
7. Run configure-agent
8. Emit plain summary of resulting identity state

## Output

```
✓ SELF-COHERE COMPLETE
  HUB:  <hub-url>
  SOUL: configured|defaulted|missing
  USER: configured|defaulted|missing
  MODE: existing|fresh-install|reconfiguration
```

Status meanings:
- **configured** — file exists with operator-confirmed content
- **defaulted** — file was missing, template materialized into hub
- **missing** — file could not be created (error state)
