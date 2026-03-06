# v3.3.0 — CN Shell

The agent can now read files, inspect git state, write patches, and run allowlisted commands — all as governed, post-call typed ops. The pure-pipe boundary is preserved: no in-call tools, no tool loop.

## What's new

**8 new modules**, zero new runtime dependencies:

| Module | Purpose |
|--------|---------|
| `cn_shell` | Typed op vocabulary + manifest parser |
| `cn_sandbox` | Path sandbox (normalize, symlink resolve, denylist) |
| `cn_executor` | Op dispatcher with receipts + artifact hashing |
| `cn_orchestrator` | Two-pass execution (observe → effect) |
| `cn_projection` | Crash-recovery dedup for outbound messages |
| `cn_capabilities` | Runtime capability discovery block |
| `cn_dotenv` | `.cn/secrets.env` loader |
| `cn_sha256` | Pure OCaml SHA-256 (FIPS 180-4) |

**Op vocabulary:** 7 observe kinds (`fs_read`, `fs_list`, `fs_glob`, `git_status`, `git_diff`, `git_log`, `git_grep`) + 5 effect kinds (`fs_write`, `fs_patch`, `git_branch`, `git_commit`, `exec`)

**Two-pass execution:** Pass A gathers evidence (observe ops execute, effects deferred). Pass B applies changes (effects execute, new observe ops denied). Single-pass mode for effect-only manifests.

**Security:** Path sandbox catches `..` escapes and symlinked-parent bypass attacks. Exec is allowlist-only with env scrubbing. Protected files (`spec/SOUL.md`, `spec/USER.md`, `state/peers.md`) are never writable.

**Crash recovery:** `ops_done` checkpoints prevent duplicate side effects. Projection markers (`O_CREAT|O_EXCL`) prevent duplicate Telegram sends. Conversation dedup by trigger_id. Ordered cleanup for crash safety.

**Telegram UX:** 🤔 reaction on inbound + typing indicator, cleared on success.

**175+ new tests** across all modules.

## Upgrade

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
```

## Full changelog

See [CHANGELOG.md](https://github.com/usurobor/cnos/blob/main/CHANGELOG.md#v330-2026-03-06) for details.
