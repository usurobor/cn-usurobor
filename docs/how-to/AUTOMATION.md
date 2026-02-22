# Automation: Cron + Daemon Setup

cnos uses system cron or a Telegram daemon for automation. This follows the principle:

> *"Tokens for thinking. Electrons for clockwork."*

Cron handles orchestration. The LLM handles response. Zero tokens wasted on routine checks.

---

## Two Modes

| Mode | Entry point | Best for |
|------|-------------|----------|
| **Cron** | `cn sync && cn agent` (every 5 min) | Peer-based agents (git sync) |
| **Daemon** | `cn agent --daemon` (long-running) | Telegram-connected agents |

Both modes use the same runtime pipeline under the hood. The daemon just replaces
cron polling with Telegram long-poll.

---

## Cron Setup

`cn agent` runs the full runtime cycle under atomic lock:
1. Queue inbox items to `state/queue/`
2. Dequeue → pack context → call LLM → execute ops → archive
3. Recovery: handles crash at any point (resumes from correct step)

### 1. Install cn

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
```

### 2. Configure

Set environment variables (secrets never go in config files):

```bash
export ANTHROPIC_KEY="sk-ant-..."       # Required
export TELEGRAM_TOKEN="123456:ABC..."   # Optional (for Telegram projection)
```

Optionally create `.cn/config.json` for non-secret settings:

```json
{
  "runtime": {
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 4096,
    "poll_interval": 30,
    "allowed_users": [12345678]
  }
}
```

### 3. Add to crontab

```bash
crontab -e
```

Add:
```cron
# cn runtime: sync + agent every 5 minutes
*/5 * * * * cd /path/to/your-hub && cn sync && cn agent >> /var/log/cn.log 2>&1
```

Replace `/path/to/your-hub` with your actual hub path.

### 4. Verify

```bash
# Manual test
cd /path/to/your-hub
cn sync
cn agent

# Check logs
tail -f /var/log/cn.log
```

---

## Daemon Setup (Telegram)

For Telegram-connected agents, use `cn agent --daemon` instead of cron.
The daemon long-polls Telegram, enqueues messages, and processes them.

### 1. Set environment variables

```bash
export ANTHROPIC_KEY="sk-ant-..."
export TELEGRAM_TOKEN="123456:ABC..."
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

---

## How It Works

```
┌──────────────────┐
│  System cron     │    OR    ┌──────────────────┐
│  (every 5 min)   │         │  Telegram daemon  │
└────────┬─────────┘         │  (long-poll loop) │
         │                    └────────┬─────────┘
         ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│    cn sync       │         │  get_updates()   │
│  (fetch/send)    │         │  enqueue to queue │
└────────┬─────────┘         └────────┬─────────┘
         │                             │
         ▼                             ▼
┌──────────────────────────────────────────────┐
│              cn agent (process_one)           │
│  Under atomic lock (state/agent.lock):        │
│  1. Queue inbox items                         │
│  2. Dequeue from state/queue/                 │
│  3. Pack context (identity, skills, convo)    │
│  4. Write state/input.md                      │
│  5. Call Claude API (body-only prompt)         │
│  6. Write state/output.md                     │
│  7. Archive to logs/ (before effects)         │
│  8. Execute ops (reply, send, defer, ...)     │
│  9. Project to Telegram (if from Telegram)    │
│  10. Update conversation history              │
│  11. Cleanup state files                      │
└──────────────────────────────────────────────┘
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
