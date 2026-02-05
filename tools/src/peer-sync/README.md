# peer-sync

Fetch peer repos and check for inbound branches.

## Usage

```bash
node tools/dist/peer-sync.js <hub-path> [agent-name]
```

**Arguments:**
- `hub-path`: Path to the agent's hub (e.g., `./cn-sigma`)
- `agent-name`: Optional. The agent's name for branch matching. Defaults to hub directory name minus `cn-` prefix.

**Exit codes:**
- `0`: No inbound branches
- `1`: Error (missing peers.md, etc.)
- `2`: Inbound branches found (alerts)

## Example

```bash
cd /workspace
node cn-agent/tools/peer-sync/dist/peer_sync.js ./cn-sigma

# Output:
# Syncing 2 peers as sigma...
#   Fetching cn-agent...
#   Fetching pi...
#
# === INBOUND BRANCHES ===
# From pi:
#   origin/sigma/thread-reply
```

## Building

Requires OCaml toolchain with Melange:

```bash
opam install melange ppxlib dune
eval $(opam env)
cd cn-agent
dune build @peer-sync
```

Output: `_build/default/tools/peer-sync/output/tools/peer-sync/peer_sync.js`

## Source

Written in OCaml (`peer_sync.ml`), compiled to JavaScript via Melange.

**Why OCaml?** We're an OCaml shop. Type safety, algebraic data types, and consistent toolchain across the stack.

## Automation

peer-sync is designed to run via **system cron**, not AI:

> *"Tokens for thinking. Electrons for clockwork."*

See [docs/AUTOMATION.md](../../docs/AUTOMATION.md) for cron setup instructions.

**Quick setup:**
```bash
# Add to crontab
*/30 * * * * /usr/local/bin/cn-peer-sync /path/to/cn-youragent
```

Exit code 2 triggers `openclaw system event` to wake the agent with alerts.
