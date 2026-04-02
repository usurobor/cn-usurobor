# Automation: Daemon + Oneshot Setup

cnos uses a long-running daemon or manual oneshot invocations for automation. This follows the principle:

> *"Tokens for thinking. Electrons for clockwork."*

The daemon handles orchestration. The LLM handles response. Zero tokens wasted on routine checks.

---

## Two Modes (Unified Scheduler — v3.7.0)

Both modes run the **same protocol loop**: maintenance (sync, inbox, outbox,
update check, MCA review, cleanup) → queue drain → exit/loop. The only difference
is cadence.

| Mode | Entry point | Best for |
|------|-------------|----------|
| **Daemon** | `cn agent --daemon` (long-running) | Telegram-connected agents, or peer-only agents needing continuous sync |
| **Oneshot** | `cn agent` (manual or external timer) | Peer-based agents, minimal resource use, scripting |

The daemon is the recommended scheduler. It runs as a systemd service and handles
maintenance ticks, Telegram polling, and queue draining automatically.

The oneshot mode runs a single maintenance cycle and exits. It is useful for manual
runs, scripting, and environments where a long-running daemon is not practical.

> **Note (v3.27.1):** cnos no longer installs or manages OS crontabs. The daemon
> (systemd service) is the recommended continuous scheduler. Oneshot mode remains
> available for manual or externally-triggered runs.

The daemon no longer requires a Telegram token. A peer-only daemon runs maintenance
ticks on its configured interval without any external transport.

---

## Daemon Setup (Recommended)

The daemon runs the unified scheduler loop continuously. It has two activity sources:
- **Exteroception** (sensor-driven): Telegram poll (if token configured) → immediate drain after new work
- **Interoception** (self-driven): Periodic maintenance tick (sync, inbox, outbox, update, review, cleanup) → bounded drain

The daemon works with or without Telegram. A peer-only daemon (no `TELEGRAM_TOKEN`)
runs maintenance ticks on the configured `sync_interval_sec` interval.

### 1. Install cn

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
```

### 2. Configure

Set secrets via environment variables or `.cn/secrets.env` (auto-loaded by the runtime,
never committed — `.gitignore` excludes `.cn/secrets.env`):

```bash
# Option A: environment variables
export ANTHROPIC_KEY="sk-ant-..."
export TELEGRAM_TOKEN="123456:ABC..."

# Option B: .cn/secrets.env (KEY=VALUE, one per line)
echo 'ANTHROPIC_KEY=sk-ant-...' >> .cn/secrets.env
echo 'TELEGRAM_TOKEN=123456:ABC...' >> .cn/secrets.env
chmod 600 .cn/secrets.env
```

Optionally create `.cn/config.json` for non-secret settings:

```json
{
  "runtime": {
    "model": "claude-sonnet-4-6",
    "max_tokens": 4096,
    "poll_interval": 30,
    "allowed_users": [12345678],
    "scheduler": {
      "sync_interval_sec": 300,
      "review_interval_sec": 300,
      "daemon_drain_limit": 8
    }
  }
}
```

**Scheduler settings** (all optional, shown with defaults):

| Key | Default | Description |
|-----|---------|-------------|
| `sync_interval_sec` | 300 | Daemon slow-clock interval (seconds between maintenance ticks) |
| `review_interval_sec` | 300 | MCA review interval |
| `oneshot_drain_limit` | 1 | Max items to process per oneshot run |
| `daemon_drain_limit` | 8 | Max items to drain per daemon maintenance cycle |

All values are clamped to minimum 1.

### 3. Configure allowed users

In `.cn/config.json`, set `allowed_users` to the Telegram user IDs that may
interact with the agent. **An empty list denies all users** (secure default):

```json
{
  "runtime": {
    "allowed_users": [12345678, 87654321]
  }
}
```

### 4. Set up systemd service

```ini
[Unit]
Description=cn agent daemon
After=network.target

[Service]
Type=simple
User=cn
WorkingDirectory=/path/to/your-hub
Environment=ANTHROPIC_KEY=sk-ant-...
Environment=TELEGRAM_TOKEN=123456:ABC...
ExecStart=/usr/local/bin/cn agent --daemon
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Or use `cn setup` which offers to create the systemd unit automatically.

### 5. Verify

```bash
# Check service status
systemctl status cn-<agentname>

# Check logs
journalctl -u cn-<agentname> -f

# Check state projections
cat state/ready.json    # scheduler section shows last_sync_at, last_maintenance_status
```

### Daemon guarantees

- **Offset persistence:** Telegram update offset is persisted to `state/telegram.offset`.
  Restarts resume from where they left off (no replay storms).
- **Ack boundary:** Offset advances only after successful processing.
  If the LLM call fails, Telegram re-delivers the message on next poll.
- **Idempotent enqueue:** Duplicate messages are detected by trigger ID
  (in queue, in-flight state files, or logs).
- **Conversation dedup:** Recovery replays skip conversation append if
  the trigger_id is already present (prevents double-entries).
- **Projection dedup:** Telegram reply markers prevent double-sending
  on crash recovery.
- **Visual feedback:** Typing indicator + reaction on inbound message
  (bounded best-effort, non-fatal).

---

## Oneshot Mode

`cn agent` runs one full maintenance cycle + bounded queue drain under atomic lock:
1. Maintenance: sync peers, materialize inbox, flush outbox, update check, MCA review, cleanup
2. Drain queue: dequeue → pack context → call LLM → execute ops → archive (up to `oneshot_drain_limit`)
3. Exit
4. Recovery: handles crash at any point (resumes from correct step)

Oneshot is useful for:
- Manual runs (`cn agent` from a shell)
- External schedulers (systemd timers, task runners)
- Scripting and testing

```bash
# Manual test
cd /path/to/your-hub
cn agent
```

---

## How It Works (v3.7.0 Unified Scheduler)

```
┌──────────────────┐         ┌──────────────────┐
│  Oneshot          │    OR   │  Daemon loop     │
│  (manual/timer)   │         │  (long-running)  │
└────────┬─────────┘         └────────┬─────────┘
         │                             │
         ▼                             ▼
┌──────────────────────────────────────────────┐
│          Shared Maintenance Engine            │
│  (cn_maintenance.maintain_once):              │
│  1. Peer sync (fetch, inbox, outbox flush)    │
│  2. Update check (when idle)                  │
│  3. MCA review tick                           │
│  4. Stale state cleanup                       │
└────────────────────┬─────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────┐
│        Shared Queue Drain (drain_queue)       │
│  Repeats process_one until:                   │
│  - queue empty                                │
│  - drain limit reached                        │
│  - lock busy / error                          │
└────────────────────┬─────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────┐
│          process_one (per item)               │
│  Under atomic lock (state/agent.lock):        │
│  1. Queue inbox items                         │
│  2. Dequeue from state/queue/                 │
│  3. Pack context (identity, skills, caps,     │
│     conversation, message)                    │
│  4. Write state/input.md                      │
│  5. Call Claude API (body-only prompt)         │
│  6. Write state/output.md                     │
│  7. Archive to logs/ (before effects)         │
│  8. CN Shell: N-pass execute (observe →        │
│     effect, bounded bind loop) + receipts     │
│  9. Project to Telegram (idempotent)          │
│  10. Update conversation (dedup by trigger)   │
│  11. Cleanup state files + clear marker       │
└──────────────────────────────────────────────┘

Daemon adds:
┌──────────────────────┐
│  Exteroception       │ Telegram poll → enqueue → immediate drain
│  (sensor-driven)     │ (only when TELEGRAM_TOKEN configured)
├──────────────────────┤
│  Interoception       │ Periodic maintain_once → bounded drain
│  (self-driven timer) │ (always active, configurable interval)
└──────────────────────┘
```

---

## Other Modes

| Mode | Command | Use case |
|------|---------|----------|
| Single-shot | `cn agent --process` | Process one item and exit (for scripting) |
| Interactive | `cn agent --stdio` | REPL: type a message, get a response |

---

## Prerequisites

- Unix-like OS (Linux, macOS, WSL)
- systemd (recommended for daemon automation) or any external timer
- curl (for Claude API and Telegram API)
- `cn` native binary installed

Windows users: Use WSL or adapt to Task Scheduler.

---

*"If it's not in the repo, it didn't happen. If it doesn't need thinking, don't use tokens."*
