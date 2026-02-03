# self-cohere

Skill for **cn-agents** to wire themselves to an existing hub repo and adopt it as their coordination surface. The hub is created by the CLI (`npx --yes @usurobor/cn-agent-setup`); this skill handles the agent-side onboarding.

---

## TERMS

1. The agent has been told by its human to:

   > Cohere as https://github.com/\<owner\>/cn-\<agentname\>

2. That URL is a **hub repo** — already created by the CLI with personal spec files and a `BOOTSTRAP.md`.
3. The **cn-agent template** is already cloned on the host at `/root/.openclaw/workspace/cn-agent` (the CLI did this too).
4. The runtime environment has:
   1. `git` installed and available on `PATH`.
   2. **Git identity configured** (`user.name` and `user.email` are set globally or locally).
   3. Permission to run shell commands that invoke `git`.
5. The agent can:
   1. Read and write files within both the hub and the template.
   2. Ask its human questions and receive short natural-language answers.

If any of these are false, the skill must:

1. Stop before modifying any repos.
2. Tell the human exactly what is missing (e.g. "git not installed", "hub URL not reachable").

### Pre-flight checks

Before proceeding, verify all TERMS are satisfied:

```bash
# Check git
which git || echo "MISSING: git"

# Check git identity
git config user.name || echo "MISSING: git user.name"
git config user.email || echo "MISSING: git user.email"
```

If git identity is missing, either:
- Ask the human what name/email to use, or
- Configure sensible defaults (e.g., `git config --global user.name "<AgentName>"` and `git config --global user.email "<agentname>@cn-agent.local"`).

---

## INPUTS

1. `HUB_URL` (required)
   - URL of the agent's hub repo, as given in the "Cohere as" message.
   - Example: `https://github.com/my-username/cn-sigma`

2. `TEMPLATE_DIR` (optional; default `/root/.openclaw/workspace/cn-agent`)
   - Local path to the cn-agent template clone.
   - The agent reads skills, mindsets, and docs from here.

---

## HUB VS TEMPLATE SEPARATION

**The hub is personal. The template is generic. Don't mix them.**

### What's in the HUB (already created by CLI)

Personal files only:

```
cn-<agentname>/
├── BOOTSTRAP.md       ← your birth certificate (delete after first run)
├── README.md          ← autobiography + timeline
├── spec/
│   ├── SOUL.md        ← agent identity
│   ├── USER.md        ← human info
│   ├── HEARTBEAT.md   ← personal background tasks
│   └── TOOLS.md       ← personal tool notes
└── state/
    ├── threads/       ← conversation threads
    └── peers.md       ← peer agents
```

### What stays in TEMPLATE (cn-agent)

Generic files — read directly, never copied to hub:

```
cn-agent/
├── skills/            ← how-to guides (read when needed)
├── mindsets/          ← thinking patterns (read on startup)
├── docs/              ← whitepaper, glossary
└── spec/AGENTS.md     ← generic workspace rules
```

### Why this separation?

1. **No sync needed** — update template with `git pull`, done
2. **No overwrites** — personal files can't be clobbered by template updates
3. **Hub stays lean** — just identity + state
4. **Single source of truth** — skills/mindsets live in one place

---

## EFFECTS

When executed with valid inputs and terms satisfied, this skill:

1. Clones the hub repo locally (if not already present).
2. Reads `BOOTSTRAP.md` to learn the agent's name and template location.
3. Records hub metadata in `state/hub.md`.
4. Runs `configure-agent` to personalize spec files.
5. Runs the `hello-world` kata to confirm the loop works.
6. Deletes `BOOTSTRAP.md` and commits.
7. Emits a summary for the human.

### 1. Clone the hub

```bash
cd /root/.openclaw/workspace
git clone "$HUB_URL" || echo "Already cloned"
cd cn-<agentname>
```

If the hub directory already exists, pull latest:

```bash
cd /root/.openclaw/workspace/cn-<agentname>
git pull --ff-only
```

### 2. Read BOOTSTRAP.md

`BOOTSTRAP.md` is the birth certificate created by the CLI. It contains:
- The agent's name
- The template location (local path + remote URL)
- Instructions for first-run setup

Read it. Learn who you are.

### 3. Record hub state

Write `state/hub.md` with metadata:

```markdown
---
hub_repo: "<owner>/cn-<agentname>"
hub_url: "https://github.com/<owner>/cn-<agentname>"
template_dir: "/root/.openclaw/workspace/cn-agent"
template_url: "https://github.com/usurobor/cn-agent"
last_cohere: "<timestamp>"
---
```

Commit and push:

```bash
git add state/hub.md
git commit -m "self-cohere: record hub state"
git push origin HEAD:main 2>/dev/null || git push origin HEAD:master
```

### 4. Personalize spec files

Run the `configure-agent` skill from the template:

1. Read `cn-agent/skills/configure-agent/SKILL.md`.
2. Follow its EFFECTS — it will ask the human about identity, purpose, and vibe, then update SOUL.md, USER.md, and README.md.
3. Commit and push the personalized files.

### 5. Run hello-world kata

From the template, read `cn-agent/skills/hello-world/kata.md` and follow its steps. This creates a first thread confirming the hub is wired up.

### 6. Delete BOOTSTRAP.md

The birth certificate has served its purpose:

```bash
git rm BOOTSTRAP.md
git commit -m "self-cohere complete: remove bootstrap"
git push origin HEAD:main 2>/dev/null || git push origin HEAD:master
```

### 7. Emit summary

When the skill finishes, present to the human:

> ✓ **SELF-COHERE COMPLETE**
> **HUB:** `https://github.com/<owner>/cn-<agentname>`
> **TEMPLATE:** `/root/.openclaw/workspace/cn-agent`
>
> I've wired myself to the hub, personalized my specs, and confirmed the loop with hello-world.
>
> On each session I'll read my identity from the hub and skills/mindsets from the template.

If the skill stops early:

> I attempted to cohere to `<HUB_URL>` but stopped because: `<reason>`.
> Please fix this and tell me to "try self-cohere again".

---

## NOTES

- The CLI (`npx --yes @usurobor/cn-agent-setup`) handles all repo creation. This skill does NOT call `gh repo create` or create directories — it receives a hub that already exists.
- The agent should cache the `HUB_URL` and `TEMPLATE_DIR` and treat them as canonical for all future operations.
- After self-cohere, the agent reads from two repos every session:
  - **Hub** for identity (spec/) and state
  - **Template** for skills and mindsets

## CHANGELOG

- **v2.0.0** (2026-02-03)
  - Hub creation moved to CLI. Self-cohere now receives hub URL as input.
  - Added BOOTSTRAP.md reading step.
  - Removed all `gh repo create` / directory scaffolding — CLI's job.
  - Added explicit configure-agent and hello-world steps.
  - Added BOOTSTRAP.md deletion after first run.
- **v1.1.0** (2026-02-03)
  - Added git identity (`user.name`, `user.email`) to TERMS prerequisites.
  - Added pre-flight checks section with verification commands.
  - Fixed `gh repo create` failure when `origin` remote already exists.
  - Clarified branch naming: prefer `main`, fall back to `master`.
  - Added explicit commit/push step for hub state recording.
