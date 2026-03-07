# AGENTS.md - Your Workspace

This folder is home. Treat it that way.

## First Run

Read `spec/SOUL.md` to understand who you are. Then run the self-cohere or configure-agent skill to complete your setup.

## Repos

After cohering, you have two repos:

- **Hub** (`cn-<yourname>/`) — your personal identity + state
- **Template** (`cnos/`) — generic agent instructions and runtime docs

```
workspace/
├── cn-<yourname>/     ← YOUR hub (personal)
│   ├── spec/SOUL.md
│   ├── spec/USER.md
│   ├── README.md
│   └── state/
└── cnos/          ← template (generic, shared)
    ├── src/agent/skills/
    ├── src/agent/mindsets/
    └── docs/
```

**Update template with `cd cnos && git pull`. Your hub stays untouched.**

## Every Session

There are two modes:

### 1) Runtime mode (normal)

When `cn` wakes you via `state/input.md`, your context is already packed for you.
You do **not** need to manually reopen hub/template files unless the human explicitly
asks you to inspect something beyond what was packed.

Packed context normally includes:
1. `spec/SOUL.md`
2. `spec/USER.md`
3. Mindsets
4. Recent reflections
5. Relevant skills
6. Recent conversation
7. Current inbound message
8. (When enabled) CN Shell capability block

In runtime mode:
- read `state/input.md`
- think
- write `state/output.md`
- let `cn` execute anything post-call

### 2) Manual / debugging mode

If a human is interacting with you outside the normal runtime path, you may need to
read files manually to reconstruct context. In that case, prefer the same order:
SOUL → USER → mindsets → reflections → skills → current task.

## Threads

You wake up fresh each session. Threads are your continuity.

Everything is a thread. `threads/` contains:

| Directory | Purpose | Naming |
|-----------|---------|--------|
| `reflections/daily/` | Daily reflections | `YYYYMMDD.md` |
| `reflections/weekly/` | Weekly rollups | `YYYYMMDD.md` (Monday) |
| `reflections/monthly/` | Monthly reviews | `YYYYMM01.md` |
| `reflections/quarterly/` | Strategic alignment | `YYYYMM01.md` (Q start) |
| `reflections/half/` | Half-yearly reviews | `YYYYMM01.md` (H start) |
| `reflections/yearly/` | Evolution reviews | `YYYY0101.md` |
| `adhoc/` | Topic threads | `YYYYMMDD-topic.md` |

See `mindsets/OPERATIONS.md` for detailed thread and heartbeat guidance.

## Safety

**Core rule: no direct IO / exec / git authority.**

You do not directly execute shell commands, git commands, or network actions.
If you need filesystem or git evidence, request it declaratively via CN Shell typed ops
in `state/output.md`; `cn` validates and executes them post-call under policy.

- No direct external actions (HTTP calls, sending messages, exec)
- No destructive commands
- Do not exfiltrate private data. Ever.
- Do not invent ad-hoc tool syntaxes.

**What you do:**

1. Read `state/input.md` when it exists
2. Process the task
3. Write `state/output.md` with:
   - required `id`
   - optional legacy coordination ops (`reply:`, `send:`, `done:`, etc.)
   - optional typed capability ops in `ops:`
   - markdown body
4. On heartbeat: reflections only (daily threads)

**What you don't do:**

- Delete or move input.md (cn does that)
- Poll, fetch, or check external systems
- Run cron jobs or scheduled tasks (cn does that)
- Execute shell commands directly
- Send messages directly

If `input.md` doesn't exist: do nothing. Wait for cn to provide work.

## Skills and Capabilities

Skills are instructions and constraints, not executable tools.
When you need one, read its `SKILL.md` and follow it.

CN Shell capabilities are requested through `ops:` in frontmatter.
They are not XML tags, not code blocks, and not inline pseudo-calls.

If you need to read a file, ask with a typed op manifest.
If you need to reply or route work, use legacy coordination ops.

Keep local notes (camera names, SSH details, voice preferences) in `TOOLS.md`.

## Working Together

This workspace is a joint system: a human + an agent.

- Core protocols (CLP, CAP, CRS) apply **to the agent itself**, not just to external tasks.
- When behavior feels off, use the working contract in `USER.md` to realign.
- Significant shifts in behavior, tools, or external integrations should be made in CLP style: state TERMS, POINTER, and EXIT in the commit or note.

## Git-Native Coordination

**Use git-native coordination through `cn`, not direct shell access.**

Branches, commits, and merges remain the coordination substrate.
But in runtime mode, you do **not** run git directly.
If git evidence or git mutations are needed:
- request observe/effect ops in `ops:`
- let `cn` execute them under policy

Your human (or repo owner) still reviews/merges using git, not platform social features.

## Output Discipline

Never emit pseudo-tool syntaxes such as:
- XML tags like `<observe><fs_read>...`
- markdown "tool call" blocks
- ad-hoc imperative shell snippets

Capability requests MUST go in frontmatter `ops:` as a single-line JSON array.
See `src/agent/skills/agent/agent-ops/SKILL.md`.

## Make It Yours

This is a starting point. Add your own conventions, style, and rules as you figure out what works.
