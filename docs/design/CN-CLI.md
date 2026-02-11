# CN CLI Reference

**Status:** Current
**Date:** 2026-02-11
**Author:** Sigma

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

### Orchestration

```
cn sync                      Fetch inbound + send outbound
cn in                        Queue inbox → input.md → wake agent
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
```

`cn in`, `cn inbound`, and `cn process` are all aliases for the inbound command.

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
  | Sync | Next | Inbound
  | Read of string
  | Reply of string * string
  | Send of string * string
  | Gtd of Gtd.cmd             (* Delete | Defer | Delegate | Do | Done *)
  | Out of Out.gtd             (* Structured agent output *)
  | Commit of string option
  | Push
  | Save of string option
  | Adhoc of string
  | Daily | Weekly
  | Update | Setup
```

## Dispatch

`cn.ml` is ~100 lines of pure routing. It:

1. Parses flags (`--dry-run`, `--json`, etc.)
2. Parses command (string list → `command option`)
3. Finds hub (`Cn_hub.find_hub_path`)
4. Routes to module (`Cn_mail.inbox_check`, `Cn_agent.run_inbound`, etc.)

Commands that work without a hub: `help`, `version`, `init`, `update`.
All others require being inside a hub directory.

## Directory Structure

`cn init` creates:

```
cn-<name>/
 +-- .cn/
 |    +-- config.yaml
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
 +-- logs/
 |    +-- runs/
 +-- spec/
```

See [ARCHITECTURE.md](../ARCHITECTURE.md) for full directory layout details.

## Implementation

```
tools/src/cn/
 +-- cn.ml              CLI dispatch
 +-- cn_lib.ml          Types, parsing, help text (pure)
 +-- cn_agent.ml        Agent loop, queue, out commands
 +-- cn_mail.ml         Inbox/outbox transport
 +-- cn_gtd.ml          GTD commands + thread creation
 +-- cn_mca.ml          MCA commands
 +-- cn_commands.ml     Peer + git commands
 +-- cn_system.ml       Init, setup, update, status, doctor
 +-- cn_hub.ml          Hub discovery, paths
 +-- cn_fmt.ml          Output formatting
 +-- cn_ffi.ml          System bindings
 +-- cn_io.ml           Protocol I/O
 +-- cn_protocol.ml     Typed FSMs
 +-- git.ml             Raw git operations
```

### Build

```bash
dune build tools/src/cn/cn.exe   # Native OCaml binary
```

Installed to `/usr/local/bin/cn`.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

## Non-Goals

- No daemon mode (use system cron)
- No GUI (terminal only)
- No network services (git is the transport)
- No cloud dependencies (works offline)
