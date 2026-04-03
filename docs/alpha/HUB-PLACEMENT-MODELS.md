# Hub Placement Models

## Standalone and Attached Hubs for Sandboxed Agents

**Issue:** #156
**Version:** 1.0.0
**Mode:** MCA
**Active Skills:** design, architecture-evolution, process-economics, writing

## Problem

Sandboxed agents (Claude Code, Codespaces, CI runners, foreign repo sessions) operate inside a single project checkout and often cannot maintain a standalone hub elsewhere on disk.

The current cnos model assumes one root is doing two jobs at once:

- **hub root** — where cnos keeps:
  - `.cn/config.json`
  - `.cn/secrets.env`
  - `state/`
  - `threads/`
  - `spec/`
  - `.cn/vendor/`
- **workspace root** — where the agent performs:
  - filesystem reads/lists/globs
  - git status/diff/commit
  - local code/doc edits

That assumption is coherent for standalone agents with their own repo/home. It is not coherent for injected/sandboxed agents operating inside some other project repo.

### Named incoherence

The current system implicitly equates:

> hub root = workspace root

This causes three classes of problem in the sandboxed use case:

1. **Project pollution** — placing full hub state directly in the project repo pollutes project history with:
   - sync state
   - inbox materialization
   - reflections
   - package installs
   - runtime logs/state

2. **Remote confusion** — the agent's durable home and the project repo are not the same remote — cnos needs to push hub state to the hub remote, not the project remote

3. **Root ambiguity** — the current discovery model finds a hub root, but not a distinct workspace root — that means execution still wants to operate against the same root that stores the hub

### Why the raw submodule proposal is not enough

A Git submodule at `.cn/` is a useful implementation technique, but it is not the real architecture. The real architecture question is:

> How does cnos model a hub that is attached to, but not identical with, the workspace repo?

If that is not answered first, "submodule support" becomes a narrow patch rather than a coherent placement model.

---

## Constraints

### Existing contracts

- Git remains the canonical substrate for cnos state and sync
- runtime wake-time truth comes from local installed state and Runtime Contract
- hub discovery currently identifies a single hub root
- sandboxed/project repo workflows must not require a second unrelated top-level checkout

### What cannot change

- standalone hub mode remains valid and must continue to work
- the project repo must not become the canonical durable home of the agent by accident
- the runtime must continue to wake from local truth, not from network lookups
- cnos state, memory, and package installs must remain clearly separated from project artifacts

### Abstraction level

This is a placement model design. It sits above:

- raw Git clone/submodule mechanics

and below:

- runtime execution
- package installs
- sync
- doctor
- Runtime Contract

### Challenged assumption

The challenged assumption is:

> "One root can serve as both the hub root and the workspace root."

This change replaces it with:

> cnos has two explicit roots: `hub_root` and `workspace_root`.

---

## Impact Graph

### Downstream consumers

- hub discovery (`cn_hub`)
- executor root resolution for filesystem and git operations
- package installs / vendor roots
- sync / peer remotes
- Runtime Contract workspace/body/medium surfaces
- doctor validation
- setup/init flows
- documentation for sandboxed workflows

### Upstream producers

- placement manifest
- standalone init / attached init commands
- optional Git backend implementation (nested clone / submodule)
- operator configuration

### Copies and authority

- **placement manifest** is authoritative for root separation
- **hub repo** remains authoritative for:
  - state
  - threads
  - spec
  - vendor/packages
- **workspace repo** remains authoritative for the code/docs/tree being worked on
- submodule status or local clone state is never itself the canonical semantic model

---

## Proposal

## 1. Core Decision

Introduce Hub Placement Models with two explicit roots:

- `hub_root`
- `workspace_root`

### Supported placement modes

1. **Standalone** — current model — `hub_root` = `workspace_root`
2. **Attached** — sandboxed/injected model — `hub_root` != `workspace_root`

In attached mode, the hub is mounted into or alongside the project workspace, but remains a distinct repo and a distinct canonical root.

---

## 2. Placement Manifest

Add a placement manifest, for example:

```
.cn/placement.json
```

Example:

```json
{
  "schema": "cn.hub_placement.v1",
  "mode": "attached",
  "hub_root": ".cn/hub",
  "workspace_root": ".",
  "backend": {
    "kind": "nested_clone",
    "remote": "git@github.com:me/agent-home.git"
  }
}
```

### Rules

- `mode` = `"standalone"` may omit or collapse roots
- `mode` = `"attached"` must specify distinct roots
- all path resolution after discovery must go through this manifest
- the manifest is local placement truth, not agent cognition truth

---

## 3. Attached Hub Backends

The architectural concept is **attached hub**. Submodule is only one backend.

### 3.1 Nested clone (default)

Mounted at: `.cn/hub/`

**Why default:**

- independent history and remote
- no parent-repo gitlink churn
- fewer superproject dirty-state surprises
- better fit for high-churn hub state

### 3.2 Git submodule (optional backend)

Mounted at: `.cn/hub/`

**Why optional:**

- reproducible/project-tracked mount
- useful where the parent repo explicitly wants to pin the hub checkout

**Tradeoff:**

- submodule pointer churn in the parent repo
- awkward for high-churn hub state

### 3.3 External path / mount (future)

Possible later, but not required in v1.

---

## 4. Root Semantics

### 4.1 hub_root

The hub root owns:

- `.cn/config.json`
- `.cn/secrets.env`
- `state/`
- `threads/`
- `spec/`
- `.cn/vendor/`

### 4.2 workspace_root

The workspace root owns:

- project source tree
- local git worktree under active engineering
- ordinary file operations and git operations on the target repo

### 4.3 Rule

The runtime must stop assuming one root for both concerns. Every path-sensitive operation must explicitly choose:

- `hub_root`
- or `workspace_root`

---

## 5. Execution Model

### 5.1 Workspace-targeted operations

These should run against `workspace_root`:

- `fs_read`
- `fs_list`
- `fs_glob`
- `git_status`
- `git_diff`
- `git_log`
- `git_grep`
- `git_commit`
- code/doc edits

### 5.2 Hub-targeted operations

These should run against `hub_root`:

- inbox materialization
- sync state
- reflections
- spec
- package install roots
- peer config
- cnos-local logs/state/traceability

### 5.3 Rule

Root selection must be explicit in the executor/runtime, not inferred ad hoc from the current working directory.

---

## 6. Runtime Contract Impact

The Runtime Contract should surface attached placement explicitly.

### Identity / cognition

No semantic change: the agent still learns who it is and what packages/overrides are installed.

### Body

Should expose that the hub is attached and where the private body lives.

### Medium

Should distinguish:

- `workspace_root`
- `hub_root`
- and classify them by relation to self:
  - `private_body`
  - `work_medium`

Example body:

```yaml
placement:
  mode: attached
  hub_root: .cn/hub
medium:
  workspace:
    root: .
  zones:
    private_body:
      - ".cn/hub/**"
    work_medium:
      - "src/**"
      - "docs/**"
```

---

## 7. Package System Impact

In attached mode:

- installs still go to:
  - `hub_root/.cn/vendor/packages/...`
  - not to the project repo's own top-level `.cn/vendor` unless that is inside `hub_root`

This preserves:

- externalized memory/state
- package truth in the hub
- no contamination of project repo state with agent substrate

---

## 8. Sync and Remote Semantics

### Rule

`cn sync` in attached mode must push/pull hub state against the hub remote, not the project remote.

This means:

- hub remote is resolved from attached-hub backend metadata
- project remote remains irrelevant to hub sync unless explicitly configured otherwise

This is one of the strongest reasons to model attached hubs explicitly rather than hacking submodule behavior into existing sync semantics.

---

## 9. Doctor Semantics

Doctor must validate placement as a first-class concern.

### Standalone mode checks

- current hub checks unchanged

### Attached mode checks

- placement manifest parses
- hub root exists
- workspace root exists
- hub repo is valid
- backend (nested clone / submodule) is coherent
- hub remote is configured
- vendor/packages resolve under hub root
- workspace operations resolve under workspace root

---

## 10. Why This Is the Most Coherent Model

This design preserves the strongest existing cnos properties:

- Git-first durable home
- local wake-time truth
- externalized memory/state
- no project-history pollution
- no agent confusion about where it lives vs what it works on

It also makes the sandboxed use case natural: **the agent is attached to a repo, not collapsed into it.**

That is the right abstraction.

---

## Leverage

This design makes future work easier by:

- supporting sandboxed / injected agent use cases cleanly
- preserving a portable external hub across many projects
- enabling optional project-tracked attached hubs via submodule without making submodule the architecture
- clarifying root semantics for executor/runtime/package/install logic
- giving Runtime Contract a cleaner body/medium story

---

## Negative Leverage

This design adds:

- one new placement layer
- explicit root selection throughout runtime/executor
- doctor/setup complexity
- more path resolution rules
- migration work for assumptions baked into current single-root code

It also forces a decision on:

- backend defaults
- how much the project repo should know about attached hub identity
- how much attached placement is surfaced to the agent vs only operator/runtime

---

## Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Put full hub state directly in project repo | Simple path model | Pollutes project history, wrong remote, wrong permissions | Rejected |
| Make `.cn/` itself the whole hub model | Feels compact | Still leaves hub_root/workspace_root implicit, weak for runtime semantics | Rejected |
| Use git submodule as the architecture | Familiar Git mechanism | Too implementation-specific, poor default for high-churn hub state | Rejected as primary model |
| Attached hub model with backends | Explicit roots, flexible implementation, preserves Git-first truth | More runtime/path complexity | **Selected** |

---

## Process Cost / Automation Boundary

### Human judgment remains for

- choosing standalone vs attached placement
- choosing backend (nested clone vs submodule)
- project policy around tracking attached hub state

### Mechanical work should be automated

- placement manifest generation
- backend initialization
- path resolution
- doctor checks
- workspace/hub root routing in execution
- gitignore/submodule ignore hints

---

## Non-goals

This design does not:

- change the default standalone hub model
- make submodule mandatory
- solve every CI/submodule quirk
- redesign package or sync protocols
- support arbitrary many workspaces per hub in v1

---

## File Changes

### Create

- `docs/alpha/HUB-PLACEMENT-MODELS.md`
- placement manifest schema
- placement resolver module

### Edit

- hub discovery/path resolution code
- executor root resolution
- Runtime Contract
- package/deps root logic where needed
- doctor
- setup/init docs and commands

---

## Acceptance Criteria

- [ ] cnos supports two explicit placement modes: standalone and attached
- [ ] attached mode has explicit `hub_root` and `workspace_root`
- [ ] nested clone works as the default attached backend
- [ ] submodule works as an optional attached backend
- [ ] runtime operations target `workspace_root` where appropriate
- [ ] hub state, memory, packages, and sync target `hub_root`
- [ ] `cn sync` pushes hub state to the hub remote, not the project remote
- [ ] `cn doctor` validates attached placement
- [ ] Runtime Contract exposes attached placement coherently
- [ ] project repo history is not polluted by ordinary hub state changes

---

## Known Debt

- multi-workspace attachments deferred
- CI-specific backend quirks deferred
- migration of old single-root assumptions needs implementation sequencing
