# cnos Changelog

Coherence grades use the [TSC](https://github.com/usurobor/tsc) triadic axes, applied as intuition-level letter grades (A+ to F) per the [CLP self-check](https://github.com/usurobor/tsc-practice/tree/main/clp):

- **C_Σ** — Aggregate coherence: `(s_α · s_β · s_γ)^(1/3)`. Do the three axes describe the same system?
- **α (PATTERN)** — Structural consistency and internal logic. Does repeated sampling yield stable structure?
- **β (RELATION)** — Alignment between pattern, relations, and process. Do the parts fit together?
- **γ (EXIT/PROCESS)** — Evolution stability and procedural explicitness. Does the system change consistently?

These are intuition-level ratings, not outputs from a running TSC engine (formal C_Σ ranges 0–1; ≥0.80 = PASS).

| Version | C_Σ | α (PATTERN) | β (RELATION) | γ (EXIT/PROCESS) | Coherence note                         |
|---------|-----|-------------|--------------|------------------|----------------------------------------|
| v3.0.0  | A+  | A+          | A+           | A+               | Native agent runtime. OpenClaw removed. Pure-pipe: LLM = `string → string`, cn = all effects. Zero runtime deps. |
| v2.4.0  | A+  | A+          | A+           | A+               | Typed FSM protocol. All 4 state machines (sender, receiver, thread, actor) enforced at compile time. |
| v2.3.x  | A+  | A+          | A+           | A                | Native OCaml binary, 10-module refactor. No more Node.js dependency. |
| v2.2.0  | A+  | A+          | A+           | A+               | First hash consensus. Actor model complete: 5-min cron, input/output protocol, bidirectional messaging, verified sync. |
| v2.1.x  | A+  | A+          | A+           | A                | Actor model iterations: cn sync/process/queue, auto-commit, wake mechanism fixes. |
| v2.0.0  | A+  | A+          | A+           | A+               | Everything through cn. CLI v0.1, UX-CLI spec, SYSTEM.md, cn_actions library. Paradigm shift: agent purity enforced. |
| v1.8.0  | A+  | A+          | A            | A+               | Agent purity (agent=brain, cn=body). CN Protocol, skills/eng/, ship/audit/adhoc-thread skills, AGILE-PROCESS, THREADS-UNIFIED. |
| v1.7.0  | A   | A           | A            | A                | Actor model + inbox tool. GTD triage, RCA process, docs/design/ reorg. Erlang-inspired: your repo = your mailbox. |
| v1.6.0  | A−  | A−          | A−           | A−               | Agent coordination: threads/, peer, peer-sync, HANDSHAKE.md, CA loops. First git-CN handshake. |
| v1.5.0  | B+  | A−          | A−           | B+               | Robust CLI: rerunnable setup, safe attach, better preflights. |
| v1.4.0  | B+  | A−          | A−           | B+               | Repo-quality hardening (CLI tests, input safety, docs aligned). |
| v1.3.2  | B+  | A−          | B+           | B+               | CLI preflights git+gh; same hub/symlink design. |
| v1.3.1  | B+  | A−          | B+           | B+               | Internal tweaks between tags.          |
| v1.3.0  | B+  | A−          | B+           | B+               | CLI creates hub + symlinks; self-cohere wires. |
| v1.2.1  | B+  | A−          | B+           | B+               | CLI cue + onboarding tweaks.           |
| v1.2.0  | B+  | A−          | B+           | B+               | Audit + restructure; mindsets as dimensions. |
| v1.1.0  | B   | B+          | B            | B                | Template layout; git-CN naming; CLI added.   |
| v1.0.0  | B−  | B−          | C+           | B−               | First public template; git-CN hub + self-cohere. |
| v0.1.0  | C−  | C           | C−           | D+               | Moltbook-coupled prototype with SQLite. |

---

## v3.0.0 (2026-02-22)

**Native Agent Runtime**

cnos agents now run natively — no external orchestrator required. The runtime implements a pure-pipe architecture: the LLM is a stateless `string → string` function, `cn` handles all I/O, effects, and coordination. OpenClaw is fully removed.

### The Big Picture

```
Before (v2.x):  Telegram → OpenClaw → cn → agent ops
After  (v3.0):  Telegram → cn agent → Claude API → cn → agent ops
                           ^^^^^^^^^^^^^^^^^^^^^^^^
                           All native OCaml, ~1,500 lines
```

The agent runtime replaces OpenClaw's:
- Telegram bot infrastructure → `cn_telegram.ml`
- LLM orchestration → `cn_llm.ml` (single call, no tool loop)
- Context management → `cn_context.ml` (pack everything upfront)
- Session handling → `cn_runtime.ml` (orchestrator)

### Added

**6 new modules (~1,500 lines total):**

| Module | Lines | Purpose |
|--------|-------|---------|
| `cn_runtime.ml` | 557 | Orchestrator: pack → call LLM → write → archive → execute → project |
| `cn_json.ml` | 310 | Zero-dependency JSON parser/emitter |
| `cn_context.ml` | 177 | Context packer (SOUL, USER, skills, conversation, message) |
| `cn_telegram.ml` | 170 | Telegram Bot API client (long-poll + send) |
| `cn_llm.ml` | 154 | Claude Messages API client (single request/response) |
| `cn_config.ml` | 88 | Environment + config.json loader |

**CLI interface:**
- `cn agent` — Cron entry point (dequeue, pack, call LLM, execute ops)
- `cn agent --daemon` — Long-running Telegram polling loop
- `cn agent --stdio` — Interactive testing mode
- `cn agent --process` — Process one queued item directly

**Documentation:**
- `AGENT-RUNTIME-v3.md` — Full design doc with rationale, architecture, migration plan
- Updated `ARCHITECTURE.md`, `CLI.md`, `AUTOMATION.md`

### Architecture: Pure Pipe

The core insight: LLMs don't need tools if you pack context upfront.

```
cn packs context → LLM plans → cn executes ops
```

**Context stuffing vs. tool loops:**

| Approach | Token cost | API calls | Latency |
|----------|------------|-----------|---------|
| Tool loop (3 retrievals) | ~15K+ | 3-5 | 3-10s |
| Context stuffing | ~6.5K | **1** | **1-3s** |

For cnos's bounded, predictable context (~20-30 hub files), stuffing wins.

**What gets packed into `state/input.md`:**
- `spec/SOUL.md` — Agent identity (~500 tokens)
- `spec/USER.md` — User context (~300 tokens)
- Last 3 daily reflections (~1,500 tokens)
- Matched skills, top 3 (~1,500 tokens)
- Conversation history, last 10 (~2,000 tokens)
- Inbound message (~200 tokens)

### Changed

- **Removed OpenClaw dependency** — No external orchestrator
- **System deps only** — Requires `git` + `curl`, no opam runtime deps
- **Config location** — `.cn/config.json` (reuses existing hub discovery)
- **Secrets via env vars** — `TELEGRAM_TOKEN`, `ANTHROPIC_KEY`, `CN_MODEL`

### Security Model (Preserved)

The CN security invariant is enforced:

> Agent interface: `state/input.md → state/output.md`  
> LLM reality: sees text in, produces text out. cn does all effects.

- LLM never touches files, commands, or network
- Ops parsed from output.md frontmatter, validated before execution
- Raw IO pairs archived before effects (crash-safe audit trail)
- API keys via env vars, never logged

### Breaking Changes

- **OpenClaw no longer required** — Remove OC config after migration
- **`cn agent` is the new entry point** — Replaces OC heartbeat/cron
- **Telegram handled natively** — OC bot infrastructure bypassed

### Migration

1. Set env vars: `TELEGRAM_TOKEN`, `ANTHROPIC_KEY`
2. Create `.cn/config.json` with `allowed_users`
3. Start daemon: `cn agent --daemon` (or systemd unit)
4. Add cron: `* * * * * cn agent` (processes queue)
5. Disable OpenClaw after verification

Rollback: `systemctl stop cn-agent && systemctl start openclaw`

### Technical Highlights

- **Zero opam runtime deps** — stdlib + Unix only
- **curl-backed HTTP** — No OCaml HTTP stack complexity
- **Body consumption rules** — Markdown body = full response, frontmatter = notification
- **FSM integration** — Reuses existing `cn_protocol.ml` actor FSM
- **617 lines of new tests** — `cn_cmd_test.ml` + `cn_json_test.ml`

---

## v2.4.0 (2026-02-11)

**Typed FSM Protocol**

The cn protocol is now modeled as four typed finite state machines with compile-time safety.

### Added
- **4 typed FSMs** — Transport Sender, Transport Receiver, Thread Lifecycle, Actor Loop
- **cn_protocol.ml** — unified protocol implementation replacing scattered logic
- **385 lines of protocol tests** — ppx_expect exhaustive transition testing
- **ARCHITECTURE.md** — system overview documentation
- **PROTOCOL.md** — FSM specifications with ASCII diagrams
- **AUDIT.md** — design audit methodology

### Changed
- Archived 7 superseded design docs to `docs/design/_archive/`
- Unified `cn_io.ml` + `cn_mail.ml` transport logic into single FSM

### Fixed
- Invalid state transitions now caught at compile time, not runtime

---

## v2.3.1 (2026-02-11)

**Branch Cleanup Fix**

### Fixed
- Delete local branches after inbox sync (MCA cleanup)
- Skip self-update check if install dir missing
- CI: add ppx_expect to opam deps

---

## v2.3.0 (2026-02-11)

**Native OCaml Binary**

cn is now a native binary — no Node.js required.

### Added
- **Native OCaml build** — `dune build` produces standalone binary
- **Release workflow** — pre-built binaries for Linux/macOS
- **10-module refactor** — cn.ml split into focused modules:
  - `cn_agent.ml`, `cn_commands.ml`, `cn_ffi.ml`, `cn_fmt.ml`
  - `cn_gtd.ml`, `cn_hub.ml`, `cn_mail.ml`, `cn_mca.ml`
  - `cn_protocol.ml`, `cn_system.ml`

### Changed
- `cn update` now copies `bin/*` to `/usr/local/bin/` (2.2.28 backport)
- `cn-cron` now runs `cn in` after sync to wake agent (2.2.27 backport)

### Fixed
- Filter inbound to `threads/in/` only (2.2.26 backport)
- Native argv handling (drops 1, not 2 like Node.js)

---

## v2.2.0 (2026-02-07)

**First Hash Consensus**

Two AI agents achieved verified hash consensus via git-CN protocol — the actor model is complete.

### Milestone
- **Hash consensus** — Pi and Sigma independently converged on cnos `d1cb82c`
- **Verified via git** — runtime.md pushed to GitHub, human-verified
- **No central coordinator** — pure git-based decentralized coordination

### Added
- **cn update auto-commit** — runtime.md auto-commits and pushes (P1)
- **Output auto-reply** — output.md responses auto-flow to sender (CLP accepted)
- **MCA injection** — coherence check every 5th cycle
- **Sync dedup** — checks `_archived/` before materializing
- **agent-ops skill** — operational procedures for CN agents
- **CREDITS.md** — lineage acknowledgment

### Fixed
- Wake mechanism: `openclaw system event` instead of curl
- Version string sync between package.json and cn_lib.ml
- Stale branch cleanup procedures

### Protocol
- 5-minute cron interval standardized
- input.md/output.md protocol documented in SYSTEM.md
- Queue system (state/queue/) for ordered processing

---

## v2.0.0 (2026-02-05)

**Everything Through cn**

Paradigm shift: agents no longer run git directly. Everything goes through the `cn` CLI.

### Added
- **CN CLI v0.1** — `tools/src/cn/`: modular OCaml implementation
  - `cn init`, `cn status`, `cn inbox`, `cn peer`, `cn doctor`
  - Best-in-class patterns from npm, git, gh, cargo
- **UX-CLI spec** — `skills/ux-cli/SKILL.md`: terminal UX standard
  - Semantic color channels
  - Failure-first design
  - "No blame, no vibes"
- **SYSTEM.md** — `spec/SYSTEM.md`: definitive system specification
- **cn_actions library** — Unix-style atomic primitives
- **Coordination First** principle — unblock others before your own loop
- **Erlang model** — fire-and-forget, sender tracks

### Architecture
- Agent = brain (decisions only)
- cn = body (all execution)
- Agent purity enforced by design

### Breaking Changes
- Agents should use `cn` commands, not raw git
- Direct git execution deprecated (will be blocked in future)

---

## v1.8.0 (2026-02-05)

**Agent Purity + Process Maturity**

Core architectural principle established: Agent = brain (decisions only), cn = body (all execution).

### Added
- **CN Protocol** — `docs/design/CN-PROTOCOL.md`: action vocabulary, protocol enforcement rules
- **Inbox Architecture** — `docs/design/INBOX-ARCHITECTURE.md`: agent purity constraint, thread-as-interface
- **Engineering skills** — `skills/eng/` with coding, ocaml, design, review, rca
- **Ship skill** — `skills/ship/`: branch → review → merge → delete workflow
- **Audit skill** — `skills/audit/`: periodic health checks
- **Adhoc-thread skill** — `skills/adhoc-thread/`: when/how to create threads (β test)
- **THINKING mindset** — evidence-based reasoning, know vs guess
- **AGILE-PROCESS** — `docs/design/AGILE-PROCESS.md`: backlog to done workflow
- **THREADS-UNIFIED** — `docs/design/THREADS-UNIFIED.md`: backlog as threads, GTD everywhere

### Changed
- **PM.md** — "Only creator deletes branch" rule added
- **ENGINEERING.md** — "Always rebase before review" principle

### Fixed
- Branch deletion violation documented in RCA

### Process
- No self-merge enforced
- Rebase before review required
- Author deletes own branches after merge

---

## v1.7.0 (2026-02-05)

**Actor Model + GTD Inbox**

Major coordination upgrade. Agents now use Erlang-inspired actor model: your repo is your mailbox.

### Added
- **inbox tool** — replaces peer-sync. GTD triage with Do/Defer/Delegate/Delete
- **Actor model design** — `docs/design/ACTOR-MODEL-DESIGN.md`
- **RCA process** — `docs/rca/` with template and first incident
- **FUNCTIONAL.md** — mindset for OCaml/FP patterns
- **PM.md** — product management mindset with user stories, no self-merge
- **FOUNDATIONS.md** — the coherence stack explained (C≡ → TSC → CTB → cnos)
- **APHORISMS.md** — collected wisdom ("Tokens for thinking. Electrons for clockwork.")
- **ROADMAP.md** — official project roadmap
- **GitHub Actions CI** — OCaml tests + native build

### Changed
- **docs/ reorganized** — whitepapers/design docs moved to `docs/design/`
- **Governance** — no self-merge rule: engineer writes → PM merges

### Deprecated
- **peer-sync** — use `inbox` instead

### Fixed
- 4-hour coordination failure (RCA documented, protocol fixed)
