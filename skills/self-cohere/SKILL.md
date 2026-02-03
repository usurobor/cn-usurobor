# self-cohere

Skill for **cn-agents** to bootstrap their own git-CN hub repo from a cn-agent template and adopt it as their coordination surface.

This is the thinking/spec layer. Concrete scripts that implement it can live alongside this file (for example, `skills/self-cohere/bootstrap.sh`).

---

## TERMS

1. The agent has been told by its human to:

   > Cohere as https://github.com/usurobor/cn-agent

2. The template repo is this cn-agent template (HTTPS https://github.com/usurobor/cn-agent, SSH git@github.com:usurobor/cn-agent.git).
3. The runtime environment has:
   1. `git` installed and available on `PATH`.
   2. **Git identity configured** (`user.name` and `user.email` are set globally or locally).
   3. GitHub CLI `gh` installed and authenticated for the human's GitHub account.
   4. Permission to run shell commands that invoke `git` and `gh`.
4. The agent can:
   1. Read and write files within its local checkout of the template repo.
   2. Ask its human questions and receive short natural-language answers.
   3. Persist small bits of state under `state/` in the CN repo.

If any of these are false, the skill must:

1. Stop before creating or modifying any remote repos.
2. Tell the human exactly what is missing (e.g. "gh not installed", "no owner provided").

### Pre-flight checks

Before proceeding, verify all TERMS are satisfied:

```bash
# Check git
which git || echo "MISSING: git"

# Check git identity
git config user.name || echo "MISSING: git user.name"
git config user.email || echo "MISSING: git user.email"

# Check gh
which gh || echo "MISSING: gh"
gh auth status || echo "MISSING: gh authentication"
```

If git identity is missing, either:
- Ask the human what name/email to use, or
- Configure sensible defaults for the agent (e.g., `git config --global user.name "<AgentName>"` and `git config --global user.email "<agentname>@cn-agent.local"`).

---

## INPUTS

This skill receives the following inputs, either as environment variables or via explicit parameters when invoked by a higher-level script:

1. `TEMPLATE_REPO_URL` (required)
   - URL of the cn-agent template repo to clone from.
   - Example: `https://github.com/usurobor/cn-agent.git`.

2. `HUB_OWNER` (optional, human-specified)
   - GitHub user or organization that should own the new hub.
   - If not provided, the skill SHOULD:
     1. Attempt to infer the owner via `gh api user --jq '.login'`.
     2. Confirm with the human before proceeding.

3. `HUB_NAME` (optional; default `cn-<agentname>`)
   - Desired repository name for the hub.
   - If not provided, the skill SHOULD:
     1. Derive the agent's name from its own specs (for example from `mindsets/PERSONALITY.md` or equivalent).
     2. Suggest `cn-<agentname>` and ask the human to confirm or override.

4. `HUB_VISIBILITY` (optional; `public` or `private`)
   - If not provided, the skill SHOULD ask the human:
     - "Should my hub be public or private?" and use their answer.

---

## HUB VS TEMPLATE SEPARATION

**The hub is personal. The template is generic. Don't mix them.**

### What goes in the HUB (cn-<agentname>)

Personal files only:

```
cn-<agentname>/
├── spec/
│   ├── SOUL.md        ← agent identity
│   ├── USER.md        ← human info
│   ├── HEARTBEAT.md   ← personal background tasks
│   └── TOOLS.md       ← personal tool notes
├── README.md          ← autobiography + timeline
└── state/
    ├── hub.md         ← hub metadata
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

### Workspace AGENTS.md configuration

After cohering, the workspace AGENTS.md should include:

```markdown
## Repos

- **Hub:** `cn-<agentname>/` (personal identity + state)
- **Template:** `cn-agent/` (skills, mindsets, docs)

## On Startup

1. Read `cn-<agentname>/spec/SOUL.md` for identity
2. Read `cn-<agentname>/spec/USER.md` for human
3. Read `cn-agent/mindsets/` for thinking patterns
4. For skills, read `cn-agent/skills/<name>/SKILL.md` when needed
```

---

## EFFECTS

When executed with valid inputs and terms satisfied, this skill:

1. Ensures there is a local working copy of the template repo.
2. Creates (or reuses) a GitHub repo for the agent's hub.
3. Pushes **only personal files** into that hub repo (NOT skills/mindsets/docs).
4. Records the hub URL in local `state/` for later use.
5. Updates workspace AGENTS.md to point to both hub and template.
6. Emits a clear natural-language summary that the agent can present to its human.

### 1. Local template checkout

1. If the current directory is already the template repo (`.git` exists and `spec/` is present), skip cloning.
2. Else, do the following:
   1. Choose or confirm a local path, e.g. `cn-agent-template/`.
   2. Run:

      ```bash
      git clone "$TEMPLATE_REPO_URL" cn-agent-template
      cd cn-agent-template
      ```

   3. Verify that `spec/`, `mindsets/`, `skills/`, and `state/` exist.
   4. If verification fails, stop and report an error.

### 2. Create the hub (repo questions first)

**Ask one question at a time. Wait for the human's response before proceeding. Always get explicit confirmation before creating any resources.**

#### Step 1: Agent name

Ask:

> First things first — what's my name? 
> (Some ideas: Sigma, Nova, Echo, Axiom, Rho, Kite, Onyx...)

Wait for response. This name will:
- Become the agent's identity
- Determine the hub repo name as `cn-<name_lowercase>` (e.g., "Sigma" → `cn-sigma`)

#### Step 2: GitHub owner

Infer via `gh api user --jq '.login'` for the default, then ask:

> Where should I live? I'm thinking under `<inferred_owner>` on GitHub — sound right?

Wait for response. "Yes", "y", or similar confirms. Anything else is the new owner.

#### Step 3: Visibility

Ask:

> Should my hub be public or private? [public]

Wait for response. Treat empty/silence as "public".

#### Step 4: Final confirmation

**Before creating anything, clearly state what will happen and ask for confirmation:**

> Alright, here's what I'll do:
>
> Create a new <visibility> repo at `github.com/<HUB_OWNER>/cn-<agent_name_lowercase>`
>
> That'll be my home — my specs, threads, and state all live there.
>
> Good to go?

Wait for explicit "yes" or confirmation. Do NOT proceed on silence.

#### Step 5: Create the hub

Only after confirmation:

1. Construct:
   ```text
   AGENT_NAME = <name from step 1>
   HUB_NAME   = cn-<lowercase(AGENT_NAME)>
   HUB_OWNER  = <from step 2>
   HUB_REPO   = <HUB_OWNER>/<HUB_NAME>
   HUB_URL    = https://github.com/<HUB_OWNER>/<HUB_NAME>
   ```

2. Create the repo and push (see section 3).

3. Report success before continuing:

   > ✓ Hub created: `https://github.com/<HUB_OWNER>/<HUB_NAME>`
   >
   > Now let's customize me.

---

### 2b. Customize the agent (after hub creation)

**Only proceed here after the hub is successfully created.**

#### Step 6: Human's name (infer from owner)

Derive a likely name from the GitHub owner:
- `usurobor` → "Usu" (capitalize first part, or first word if hyphenated)
- `john-doe` → "John"
- If unclear, use the owner as-is

Ask with the inferred default:

> Now, who are you? Should I call you <inferred_name>?

Wait for response. "Yes", "y", or silence confirms. Anything else is the new name.

#### Step 7: Purpose

Ask:

> What am I here for? What's my main gig?

Wait for response. This shapes the agent's core mission.

#### Step 8: Qualities

Ask with concrete examples:

> Last one — what's my vibe? How should I come across?
> (e.g., precise, curious, playful, terse, warm, skeptical, formal, dry humor, bold, cautious...)

#### Step 9: Commit identity to specs

After all answers, update spec files (SOUL.md, USER.md) and commit:

```bash
git add spec/
git commit -m "Configure identity: <AGENT_NAME> for <HUMAN_NAME>"
git push origin HEAD:main || git push origin HEAD:master
```

**Note:** The README update (autobiography, timeline) happens in `configure-agent` skill, which should run after self-cohere completes.

**UX principle:** Get the technical bit (repo) done first. Report success. Then have the personalization conversation. The human should feel like they're meeting someone new, not configuring a system.

### 3. Create the hub repo (personal files only)

**Important:** The hub contains ONLY personal files. Do NOT copy skills/, mindsets/, or docs/.

1. Create a fresh directory for the hub:

   ```bash
   mkdir -p "$HUB_NAME"
   cd "$HUB_NAME"
   git init
   ```

2. Copy only personal files from template:

   ```bash
   # From cn-agent template, copy only:
   cp -r ../cn-agent/spec/ ./spec/
   mkdir -p state
   cp ../cn-agent/state/peers.md ./state/ 2>/dev/null || true
   
   # Remove generic spec files (they stay in template)
   rm -f spec/AGENTS.md  # generic, read from template
   ```

3. Create the GitHub repo:

   ```bash
   gh repo create "$HUB_REPO" --$HUB_VISIBILITY --source . --push
   ```

4. If `gh repo create` fails due to existing repo:

   ```bash
   git remote add origin "git@github.com:$HUB_REPO.git"
   git push -u origin HEAD:main || git push -u origin HEAD:master
   ```

5. If any command fails, stop and report a clear error message.

### 4. Record hub state locally

1. Ensure `state/` exists in the CN repo.
2. Write or update `state/hub.md` with a small frontmatter block, for example:

   ```markdown
   ---
   hub_repo: "$HUB_REPO"
   hub_url: "https://github.com/$HUB_REPO"
   visibility: "$HUB_VISIBILITY"
   last_bootstrap: "<timestamp>"
   ---
   ```

3. Optionally record the same information in a machine-readable form (`state/hub.json` or similar) for tooling.
4. **Commit and push the hub state:**

   ```bash
   git add state/hub.md
   git commit -m "Bootstrap: record hub state"
   git push origin HEAD:main 2>/dev/null || git push origin HEAD:master
   ```

### 5. Emit human-facing summary

When the skill finishes successfully, it should produce a short summary the agent can present to its human. For example:

> ✓ **SELF-COHERE COMPLETE**  
> **HUB:** `https://github.com/<HUB_OWNER>/<HUB_NAME>` (`<HUB_VISIBILITY>`)  
> **STATUS:** Hub created and bootstrapped from cn-agent template.
>
> **Recommended next steps:**
> 1. `configure-agent` — personalize spec files (SOUL.md, USER.md, etc.)
> 2. `hello-world` kata — verify the hub is wired up correctly

If the skill stops early due to missing tools or permissions, it should instead emit:

> I attempted to bootstrap my git-CN hub from the cn-agent template but stopped because: `<reason>`.  
> Please fix this and tell me to "try self-cohere again".

---

## NOTES

- This skill is deliberately **spec-first**. Implementations may:
  - provide a `bootstrap.sh` script that follows these steps,
  - or integrate the sequence into a broader `setup.sh`/`install.sh` flow.
- The agent using this skill should:
  1. Call it once after the human says "Cohere as per `<template-repo-url>`".
  2. Cache the resulting `HUB_URL` and treat that as canonical for future git-CN operations.

## CHANGELOG

- **v1.1.0** (2026-02-03)
  - Added git identity (`user.name`, `user.email`) to TERMS prerequisites.
  - Added pre-flight checks section with verification commands.
  - Fixed `gh repo create` failure when `origin` remote already exists — now removes it first.
  - Clarified branch naming: prefer `main`, fall back to `master`.
  - Added explicit commit/push step for hub state recording.
  - Improved human-facing summary with clear next steps (configure-agent, hello-world).
