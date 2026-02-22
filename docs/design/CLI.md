# CN CLI Reference

**Status:** Current
**Date:** 2026-02-22
**Author:** usurobor (aka Axiom)
**Contributors:** Sigma  

---

## Design Principle

**Agent = brain. cn = body.**

Agent thinks and decides. `cn` senses and executes. The agent never touches git, filesystem, or network directly. Everything goes through `cn`.

## Usage

```
cn <command> [options]
```

## Commands

### Agent Decisions (GTD)

The five GTD operations on threads:

```
cn delete <thread>           Discard thread
cn defer <thread> [until]    Postpone thread
cn delegate <thread> <peer>  Forward thread to peer
cn do <thread>               Claim/start thread → threads/doing/
cn done <thread>             Complete thread → threads/archived/
```

Plus direct communication:

```
cn reply <thread> <message>  Append reply to thread
cn send <peer> <message>     Send message to peer (or self)
```

### Agent Output (Structured)

For agent-to-cn structured responses (used by actor loop):

```
cn out do reply --message <msg>
cn out do send --to <peer> --message <msg>
cn out do surface --desc <desc>
cn out do noop --reason <reason>          Reason must be ≥10 chars, non-trivial
cn out do commit --artifact <path>
cn out defer --reason <reason>
cn out delegate --to <peer>
cn out delete --reason <reason>
```

### Agent Runtime

```
cn agent                     Run one cycle: dequeue → LLM → execute (cron mode)
cn agent --process           Single-shot: process one queued item and exit
cn agent --daemon            Telegram long-poll loop (requires TELEGRAM_TOKEN)
cn agent --stdio             Interactive REPL (stdin → LLM → stdout)
```

### Orchestration

```
cn sync                      Fetch inbound + send outbound
cn next                      Get next inbox item (with cadence priority)
cn read <thread>             Display thread content
cn inbox [check]             List inbound branches / materialized threads
cn inbox process             Materialize inbound branches as threads
cn inbox flush               Execute queued agent decisions
cn outbox [check]            List outbound threads
cn outbox flush              Push outbox threads to peers
cn queue [list]              Show task queue
cn queue clear               Empty task queue
cn mca [list]                List managed concern aggregations
cn mca add <description>     Surface MCA for community pickup
```

### Thread Creation

```
cn adhoc <title>             Create adhoc thread in threads/adhoc/
cn daily                     Create/show daily reflection
cn weekly                    Create/show weekly reflection
```

### Hub Management

```
cn init [name]               Create new hub
cn setup                     System setup (logrotate + cron) — run with sudo
cn status                    Show hub state
cn doctor                    Health check
cn update                    Update cn to latest version
cn commit [message]          Stage + commit
cn push                      Push to origin
cn save [message]            Commit + push (shorthand)
cn peer [list]               List peers
cn peer add <name> <url>     Add peer
cn peer remove <name>        Remove peer
cn peer sync                 Fetch all peer repos
```

### Aliases

```
i = inbox    o = outbox    s = status    d = doctor
in = agent
```

### Flags

```
--help, -h       Show help
--version, -V    Show version
--json           Machine-readable output
--quiet, -q      Minimal output
--dry-run        Show what would happen
--verbose, -v    Detailed output
```

## Command Types (Implementation)

From `cn_lib.ml` — exhaustive variant, compiler warns on missing cases:

```ocaml
type command =
  | Help | Version | Status | Doctor
  | Init of string option
  | Inbox of Inbox.cmd         (* Check | Process | Flush *)
  | Outbox of Outbox.cmd       (* Check | Flush *)
  | Peer of Peer.cmd           (* List | Add | Remove | Sync *)
  | Queue of Queue.cmd         (* List | Clear *)
  | Mca of Mca.cmd             (* List | Add *)
  | Sync | Next
  | Read of string
  | Reply of string * string
  | Send of string * string
  | Gtd of Gtd.cmd             (* Delete | Defer | Delegate | Do | Done *)
  | Out of Out.gtd             (* Structured agent output *)
  | Commit of string option
  | Push
  | Save of string option
  | Agent of Agent.mode        (* Cron | Process | Daemon | Stdio *)
  | Update | Setup
  | Adhoc of string
  | Daily | Weekly
```

## Dispatch

`cn.ml` is ~100 lines of pure routing. It:

1. Parses flags (`--dry-run`, `--json`, etc.)
2. Parses command (string list → `command option`)
3. Finds hub (`Cn_hub.find_hub_path`)
4. Routes to module (`Cn_mail.inbox_check`, `Cn_runtime.run_cron`, etc.)

Commands that work without a hub: `help`, `version`, `init`, `update`.
All others require being inside a hub directory.

`Agent` mode loads config (`Cn_config.load`) before dispatch to the runtime.

## Directory Structure

`cn init` creates:

```
cn-<name>/
 +-- .cn/
 |    +-- config.json
 +-- threads/
 |    +-- in/
 |    +-- mail/
 |    |    +-- inbox/
 |    |    +-- outbox/
 |    |    +-- sent/
 |    +-- doing/
 |    +-- deferred/
 |    +-- archived/
 |    +-- adhoc/
 |    +-- reflections/
 |         +-- daily/
 |         +-- weekly/
 +-- state/
 |    +-- peers.md
 |    +-- runtime.md
 |    +-- queue/
 |    +-- mca/
 |    +-- agent.lock
 |    +-- conversation.json
 |    +-- telegram.offset
 +-- logs/
 |    +-- input/
 |    +-- output/
 +-- spec/
```

See [ARCHITECTURE.md](../ARCHITECTURE.md) for full directory layout details.

## Implementation

```
src/
 +-- cli/
 |    +-- cn.ml              CLI dispatch
 +-- lib/
 |    +-- cn_lib.ml          Types, parsing, help text (pure)
 |    +-- cn_json.ml         JSON parser/emitter (pure, zero-dep)
 +-- protocol/
 |    +-- cn_protocol.ml     Typed FSMs
 |    +-- cn_protocol.mli    Interface
 +-- ffi/
 |    +-- cn_ffi.ml          System bindings
 +-- transport/
 |    +-- cn_io.ml           Protocol I/O
 |    +-- git.ml             Raw git operations
 |    +-- inbox_lib.ml       Inbox utilities
 +-- cmd/
      +-- cn_runtime.ml      Agent runtime orchestrator (dequeue → LLM → execute)
      +-- cn_context.ml      Context packer (skills, conversation, artifacts)
      +-- cn_llm.ml          Claude API client (curl-backed)
      +-- cn_telegram.ml     Telegram Bot API client
      +-- cn_config.ml       Config loader (env vars + .cn/config.json)
      +-- cn_agent.ml        Queue, input/output, op execution
      +-- cn_mail.ml         Inbox/outbox transport
      +-- cn_gtd.ml          GTD commands + thread creation
      +-- cn_mca.ml          MCA commands
      +-- cn_commands.ml     Peer + git commands
      +-- cn_system.ml       Init, setup, update, status, doctor
      +-- cn_hub.ml          Hub discovery, paths
      +-- cn_fmt.ml          Output formatting
```

### Build

```bash
dune build src/cli/cn.exe   # Native OCaml binary
```

Installed to `/usr/local/bin/cn`.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

## Non-Goals

- No GUI (terminal only)
- No network services (git is the transport)
- No cloud dependencies (works offline)
