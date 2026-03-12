# Automation: Cron + Daemon Setup

cnos uses system cron or a long-running daemon for automation. This follows the principle:

> *"Tokens for thinking. Electrons for clockwork."*

Cron handles orchestration. The LLM handles response. Zero tokens wasted on routine checks.

---

## Two Modes (Unified Scheduler — v3.7.0)

Both schedulers run the **same protocol loop**: maintenance (sync, inbox, outbox,
update check, MCA review, cleanup) → queue drain → exit/loop. The only difference
is cadence.

| Mode | Entry point | Best for |
|------|-------------|----------|
| **Oneshot** | `cn agent` (via cron/timer) | Peer-based agents, minimal resource use |
| **Daemon** | `cn agent --daemon` (long-running) | Telegram-connected agents, or peer-only agents needing faster sync |

The daemon no longer requires a Telegram token. A peer-only daemon runs maintenance
ticks on its configured interval without any external transport.

---

## Cron / Oneshot Setup

`cn agent` runs one full maintenance cycle + bounded queue drain under atomic lock:
1. Maintenance: sync peers, materialize inbox, flush outbox, update check, MCA review, cleanup
2. Drain queue: dequeue → pack context → call LLM → execute ops → archive (up to `oneshot_drain_limit`)
3. Exit
4. Recovery: handles crash at any point (resumes from correct step)

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
      "oneshot_drain_limit": 1,
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

### 3. Add to crontab

```bash
crontab -e
```

Add:
```cron
# cn runtime: agent every 5 minutes (maintenance + drain built-in)
*/5 * * * * cd /path/to/your-hub && cn agent >> /var/log/cn.log 2>&1
```

Replace `/path/to/your-hub` with your actual hub path.

> **Note (v3.7.0):** `cn agent` now includes maintenance (sync, inbox, outbox)
> automatically. A separate `cn sync` before `cn agent` is no longer required
> but remains available as a standalone command.

### 4. Verify

```bash
# Manual test
cd /path/to/your-hub
cn agent

# Check logs
tail -f /var/log/cn.log

# Check state projections
cat state/ready.json    # scheduler section shows last_sync_at, last_maintenance_status
```

---

## Daemon Setup

The daemon runs the unified scheduler loop continuously. It supports two clocks:
- **Fast clock:** Telegram poll (if token configured) → immediate drain after new work
- **Slow clock:** Periodic maintenance tick (sync, inbox, outbox, update, review, cleanup) → bounded drain

The daemon works with or without Telegram. A peer-only daemon (no `TELEGRAM_TOKEN`)
runs maintenance ticks on the configured `sync_interval_sec` interval.

### 1. Set environment variables

```bash
export ANTHROPIC_KEY="sk-ant-..."
export TELEGRAM_TOKEN="123456:ABC..."   # optional — daemon works without it
```

### 2. Configure allowed users

In `.cn/config.json`, set `allowed_users` to the Telegram user IDs that may
interact with the agent. **An empty list denies all users** (secure default):

```json
{
  "runtime": {
    "allowed_users": [12345678, 87654321]
  }
}
```

### 3. Run the daemon

```bash
cd /path/to/your-hub
cn agent --daemon
```

Or via systemd:

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

## How It Works (v3.7.0 Unified Scheduler)

```
┌──────────────────┐         ┌──────────────────┐
│  System cron     │    OR   │  Daemon loop     │
│  (every 5 min)   │         │  (long-running)  │
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
│  8. CN Shell: two-pass execute (observe →     │
│     effect) + write receipts                  │
│  9. Project to Telegram (idempotent)          │
│  10. Update conversation (dedup by trigger)   │
│  11. Cleanup state files + clear marker       │
└──────────────────────────────────────────────┘

Daemon adds:
┌──────────────────┐
│  Fast clock      │ Telegram poll → enqueue → immediate drain
│  Slow clock      │ Periodic maintain_once → bounded drain
└──────────────────┘
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
- System cron or systemd (for automation)
- curl (for Claude API and Telegram API)
- `cn` native binary installed

Windows users: Use WSL or adapt to Task Scheduler.

---

*"If it's not in the repo, it didn't happen. If it doesn't need thinking, don't use tokens."*
