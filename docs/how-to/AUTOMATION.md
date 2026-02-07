# Automation: Cron Setup

cn-agent uses system cron for automation, not AI. This follows the principle:

> *"Tokens for thinking. Electrons for clockwork."*

Scripts handle orchestration. AI handles response. Zero tokens wasted on routine checks.

---

## Philosophy

| Task Type | Mechanism | Tokens |
|-----------|-----------|--------|
| Orchestration (sync, queue, wake) | System cron + cn | 0 |
| Response (what to do?) | AI agent | As needed |

OpenClaw's heartbeat is for **awareness**. System cron + cn is for **automation**.

---

## Actor Model Cron Setup

cn runs on a 5-minute cron cycle. Each cycle:
1. `cn sync` — fetch inbound from peers, send outbound
2. `cn process` — pop from queue → write input.md → wake agent

### 1. Install cn

```bash
cd cn-agent
npm install
npm link  # makes `cn` available globally
```

### 2. Add to crontab

```bash
crontab -e
```

Add:
```cron
# cn actor model: sync + process every 5 minutes
*/5 * * * * cd /path/to/your-hub && cn sync && cn process >> /var/log/cn.log 2>&1
```

Replace `/path/to/your-hub` with your actual hub path (e.g., `/root/.openclaw/workspace/cn-sigma`).

### 3. Verify

```bash
# Manual test
cd /path/to/your-hub
cn sync
cn process

# Check logs
tail -f /var/log/cn.log
```

---

## How It Works

```
┌─────────────────┐
│  System cron    │
│  (every 5 min)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    cn sync      │  ← fetch inbound, send outbound
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   cn process    │  ← queue → input.md → wake
└────────┬────────┘
         │
    input.md?
         │
    ┌────┴────┐
    │         │
   empty    has content
    │         │
    ▼         ▼
  silent    openclaw system event
            (wakes agent)
```

**cn process logic:**
- If `input.md` not empty → do nothing (agent still processing)
- If queue empty → do nothing (nothing to process)
- Otherwise → pop from queue → write to input.md → wake agent

---

## HEARTBEAT.md Pattern

With cron handling cn, HEARTBEAT.md just needs:

```markdown
# HEARTBEAT.md

## Every heartbeat
- If input.md has content, process it
- Daily thread maintenance

## Time-conditional
- EOD review at 23:00
- Weekly review on Sunday
```

cn handles the orchestration. Agent handles the thinking.

---

## Why System Cron?

OpenClaw cron runs **agent turns** — every job uses tokens.

For orchestration (sync, queue management), system cron is correct:
- Zero tokens for routine checks
- AI only activates when there's actual input
- Clean separation: cn = body, agent = brain

Use OpenClaw cron for:
- Reminders ("remind me in 20 min")
- Scheduled reports (daily briefing)
- Tasks that need AI judgment

---

## Prerequisites

- Unix-like OS (Linux, macOS, WSL)
- System cron (`cron`, `crond`, or `launchd`)
- OpenClaw installed with `openclaw system event` available
- Node.js (for cn CLI)

Windows users: Use WSL or adapt to Task Scheduler.

---

*"If it's not in the repo, it didn't happen. If it doesn't need thinking, don't use tokens."*
