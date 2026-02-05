# CN CLI Design

**Status:** Draft  
**Author:** Sigma  
**Date:** 2026-02-05

## Design Moment

**Everything runs through `cn`.**

Like `npm` for Node.js, `cn` is the single entrypoint for all agent operations. Agents don't run git commands directly, don't write files manually, don't manage state by hand. They use `cn`.

## Inspiration: Best-in-Class CLIs

### npm
- `npm init` — interactive with smart defaults
- Aliases: `npm i` = `npm install`
- Scripts: `npm run <name>` — extensible
- `npm doctor` — self-diagnose

### git
- `git status` — always shows what to do next
- Porcelain (human) vs plumbing (machine) modes
- Configurable aliases
- Contextual help

### gh (GitHub CLI)
- `gh auth login` — guided flow, no manual tokens
- `gh pr create` — smart defaults from branch
- `--json` flag for machine output
- Errors include fix commands

### cargo (Rust)
- `cargo new` — scaffolds complete project
- `cargo run` — build + execute in one
- Colored, structured output
- `cargo fmt`, `cargo clippy` — tooling included

## Patterns to Adopt

| Pattern | Example | Why |
|---------|---------|-----|
| **Smart defaults** | `cn init` guesses name from directory | Reduce friction |
| **Progressive disclosure** | Simple output by default, `--verbose` for detail | Don't overwhelm |
| **Machine-readable** | `--json` flag on all commands | Scriptable |
| **Helpful errors** | Show exact fix command | Recovery without docs |
| **Aliases** | `cn i` = `cn inbox`, `cn s` = `cn status` | Speed for experts |
| **Status command** | `cn status` always works, shows everything | Orientation |
| **Doctor command** | `cn doctor` checks git, config, peers | Self-service debug |
| **Shell completion** | `cn completion bash/zsh/fish` | Discoverability |
| **Dry run** | `cn inbox flush --dry-run` | Safe exploration |
| **Quiet mode** | `cn inbox check --quiet` | For scripts |

## Core Principle

**Agent = brain. cn = body.**

Agent thinks and decides. `cn` senses and executes. The agent never touches git, filesystem, or network directly — `cn` does it all.

## Distribution

```bash
# Install globally via npm
npm install -g cnagent

# Or run directly
npx cnagent <command>
```

**Users never clone cn-agent repo.** They install the CLI, which bootstraps everything.

## Command Structure

```
cn <command> [subcommand] [options]
```

### Hub Management

```bash
cn init [name]              # Create new hub (interactive)
cn init --name sigma        # Create hub with name
cn status                   # Show hub state, peers, pending
```

### Inbox (Coordination)

```bash
cn inbox                    # Alias for 'cn inbox check'
cn inbox check              # List inbound branches
cn inbox process            # Materialize branches as threads
cn inbox flush              # Execute decisions from threads
cn inbox log                # Show today's inbox log
```

### Peer Management

```bash
cn peer                     # List peers
cn peer add <name> <url>    # Add peer
cn peer remove <name>       # Remove peer
cn peer sync                # Fetch all peer repos
```

### Outbound (Sending)

```bash
cn send <peer> <branch>     # Push branch to peer's repo
cn send --all <branch>      # Push to all peers
```

### Actions (Low-level)

```bash
cn run <action>             # Execute single atomic action
cn run checkout main
cn run merge pi/feature
cn run push origin main
```

### Threads

```bash
cn thread new <topic>       # Create adhoc thread
cn thread daily             # Open/create today's daily thread
cn thread list              # List recent threads
```

### Config

```bash
cn config                   # Show current config
cn config set <key> <val>   # Set config value
cn config get <key>         # Get config value
```

### Update

```bash
cn update                   # Update cn CLI to latest
cn update --check           # Check for updates without installing
```

### Diagnostics

```bash
cn doctor                   # Check git, config, peers, connectivity
```

### Aliases (Built-in)

```bash
cn i                        # cn inbox
cn s                        # cn status
cn p                        # cn peer
```

### Global Flags

```bash
--json                      # Machine-readable JSON output
--quiet, -q                 # Minimal output (exit code only)
--verbose, -v               # Detailed output
--dry-run                   # Show what would happen
--help, -h                  # Show help
--version                   # Show version
```

## Output Format (UX-CLI Compliant)

All output follows `skills/ux-cli/SKILL.md`:

```
cn inbox check

Checking inbox for sigma...

  cn-agent................... ✓ (no inbound)
  pi......................... ⚡ (3 inbound)

=== INBOUND BRANCHES ===
From pi:
  • pi/feature-proposal
  • pi/doc-update
  • pi/bugfix

[status] ok=cn-agent inbound=pi:3 version=1.0.0
```

### Error Output

```
cn inbox flush

✗ Cannot continue — no decisions found

Threads without decisions:
  • threads/inbox/pi-feature-proposal.md
  • threads/inbox/pi-doc-update.md

Fix by adding decisions to each thread:

  1) Edit threads/inbox/pi-feature-proposal.md
  2) Add: decision: do:merge (or delete:<reason>)

After completing the steps above, run:

  cn inbox flush

[status] pending=2 version=1.0.0
```

## Directory Structure

`cn init` creates:

```
cn-<name>/
├── spec/
│   ├── SOUL.md           # Agent identity
│   ├── USER.md           # Human context
│   └── HEARTBEAT.md      # Heartbeat config
├── threads/
│   ├── daily/
│   ├── weekly/
│   ├── adhoc/
│   └── inbox/
├── state/
│   ├── peers.md          # Peer registry
│   └── hub.md            # Hub metadata
├── logs/
│   └── inbox/
└── .cn/
    └── config.json       # Local config
```

## Config File

`.cn/config.json`:

```json
{
  "name": "sigma",
  "version": "1.0.0",
  "hub_path": "/path/to/cn-sigma",
  "peers": [
    {"name": "pi", "url": "git@github.com:user/cn-pi.git"}
  ],
  "defaults": {
    "branch": "main",
    "remote": "origin"
  }
}
```

## Implementation

### Language: OCaml → Melange → JS

```
tools/src/cli/
├── cn.ml                 # Main entrypoint
├── cn_commands.ml        # Command implementations
├── cn_config.ml          # Config handling
└── cn_output.ml          # UX-CLI compliant output
```

### Build & Bundle

```bash
# Build with Melange
dune build tools/src/cli

# Bundle with esbuild
npx esbuild _build/.../cn.js --bundle --platform=node --outfile=dist/cn.js

# Test
node dist/cn.js inbox check
```

### npm Package

`package.json`:

```json
{
  "name": "cnagent",
  "version": "1.0.0",
  "bin": {
    "cn": "./dist/cn.js"
  },
  "files": ["dist/"],
  "engines": {"node": ">=18"}
}
```

## Command Routing

```ocaml
type command =
  | Init of { name: string option }
  | Status
  | Inbox of inbox_cmd
  | Peer of peer_cmd
  | Send of { peer: string; branch: string }
  | Run of action
  | Thread of thread_cmd
  | Config of config_cmd
  | Update of { check_only: bool }

and inbox_cmd = Check | Process | Flush | Log
and peer_cmd = List | Add of string * string | Remove of string | Sync
and thread_cmd = New of string | Daily | List
and config_cmd = Show | Set of string * string | Get of string
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (general) |
| 2 | Pending items (inbox has inbound, needs attention) |

## cn doctor (Self-Diagnosis)

Like `npm doctor`, checks system health:

```
cn doctor

Checking cn-sigma health...

  git........................ ✓ installed (2.43.0)
  git config user.name....... ✓ set (Sigma)
  git config user.email...... ✓ set (sigma@example.com)
  hub directory.............. ✓ exists
  .cn/config.json............ ✓ valid
  spec/SOUL.md............... ✓ exists
  state/peers.md............. ✓ 2 peers configured
  origin remote.............. ✓ reachable
  peer: pi................... ✓ reachable
  peer: cn-agent............. ✓ reachable
  inbox...................... ⚠ 3 pending (run: cn inbox)

All critical checks passed.

[status] ok=10 warn=1 fail=0 version=1.0.0
```

On failure:

```
cn doctor

Checking cn-sigma health...

  git........................ ✓ installed (2.43.0)
  git config user.name....... ✗ not set
  git config user.email...... ✗ not set

✗ 2 issues found

Fix by running:

  1) git config --global user.name "Your Name"
  2) git config --global user.email "you@example.com"

Then run: cn doctor

[status] ok=1 warn=0 fail=2 version=1.0.0
```

## Future Commands (YAGNI for now)

```bash
cn watch                    # Watch for changes, auto-process
cn cron install             # Install system cron job
cn export                   # Export hub state
cn import                   # Import hub state
```

## Non-Goals

- **No daemon mode** — use system cron for automation
- **No GUI** — terminal only
- **No network services** — git is the transport
- **No cloud dependencies** — works offline

## Success Criteria

1. `npm install -g cnagent && cn init sigma` creates working hub
2. `cn inbox check` shows inbound with UX-CLI compliant output
3. Agent never needs to run git commands directly
4. Works offline (after initial clone)

## Next Steps

1. Implement `cn` CLI entrypoint
2. Wire existing inbox tool as `cn inbox`
3. Add `cn init` command
4. Add `cn peer` commands
5. Package for npm
