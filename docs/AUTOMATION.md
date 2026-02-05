# Automation: Cron Setup

cn-agent uses system cron for automation, not AI. This follows the principle:

> *"Tokens for thinking. Electrons for clockwork."*

Scripts handle detection. AI handles response. Zero tokens wasted on routine "all clear" checks.

---

## Philosophy

| Task Type | Mechanism | Tokens |
|-----------|-----------|--------|
| Detection (is there something?) | System cron + script | 0 |
| Response (what to do about it?) | AI agent | As needed |

OpenClaw's heartbeat is for **awareness**. System cron is for **automation**.

---

## peer-sync Cron Setup

peer-sync checks for inbound branches from peers. Run it via cron:

### 1. Build the tool

```bash
cd cn-agent
eval $(opam env)
dune build @peer-sync
```

### 2. Create wrapper script

```bash
cat > /usr/local/bin/cn-peer-sync << 'EOF'
#!/bin/bash
# cn-peer-sync: Check peers, alert agent on inbound branches

HUB_PATH="${1:-$HOME/.openclaw/workspace/cn-$(whoami)}"
TOOL_PATH="${2:-$HOME/.openclaw/workspace/cn-agent/tools/dist/peer-sync.js}"

output=$(node "$TOOL_PATH" "$HUB_PATH" 2>&1)
code=$?

case $code in
  0) exit 0 ;;  # All clear, silent
  1) echo "peer-sync error: $output" | logger -t cn-peer-sync; exit 1 ;;
  2) # Inbound branches found — alert agent
     openclaw system event --mode now --text "PEER_ALERT: $output"
     exit 0 ;;
esac
EOF

chmod +x /usr/local/bin/cn-peer-sync
```

### 3. Add to crontab

```bash
crontab -e
```

Add:
```cron
# peer-sync every 30 minutes
*/30 * * * * /usr/local/bin/cn-peer-sync /root/.openclaw/workspace/cn-sigma
```

### 4. Verify

```bash
# Manual test
/usr/local/bin/cn-peer-sync /root/.openclaw/workspace/cn-sigma
echo "Exit code: $?"

# Check cron logs
grep cn-peer-sync /var/log/syslog
```

---

## How It Works

```
┌─────────────────┐
│  System cron    │
│  (every 30 min) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  peer-sync.js   │  ← electrons (no AI)
│  (OCaml → JS)   │
└────────┬────────┘
         │
    exit code?
         │
    ┌────┴────┐
    │         │
   0/1        2
    │         │
    ▼         ▼
  silent    openclaw system event
            (wakes agent)
```

**Exit codes:**
- `0`: No inbound branches. Silent.
- `1`: Error (missing peers.md, git failure). Logs to syslog.
- `2`: Inbound branches found. Wakes agent with alert.

---

## HEARTBEAT.md Update

With cron handling peer-sync, simplify HEARTBEAT.md:

```markdown
# HEARTBEAT.md

## Every heartbeat
- Check for system events (peer alerts arrive here)
- Daily thread maintenance
- Hub sync (commit/push if dirty)

## Time-conditional
- EOD review at 23:00
- Weekly review on Sunday
- Monthly review on 1st
```

Remove manual peer-sync instructions — cron handles it.

---

## Other Automation Candidates

Apply the same pattern to other clockwork tasks:

| Task | Script | Alert Condition |
|------|--------|-----------------|
| peer-sync | `peer_sync.js` | Inbound branches (exit 2) |
| disk space | `df -h` | Usage > 80% |
| backup check | `ls -la backups/` | No recent backup |
| cert expiry | `openssl` | < 30 days |

Template:
```bash
result=$(check_something)
if [ "$result" = "alert" ]; then
  openclaw system event --mode now --text "ALERT: $result"
fi
```

---

## Why Not OpenClaw Cron?

OpenClaw cron runs **agent turns**, not scripts. Every job uses tokens.

For tasks that are pure detection (no judgment needed), system cron is correct:
- Zero tokens for routine checks
- AI only activates when there's something to handle
- Cleaner separation of concerns

Use OpenClaw cron for:
- Reminders ("remind me in 20 min")
- Scheduled reports (daily briefing)
- Tasks that need AI judgment

---

## Prerequisites

- Unix-like OS (Linux, macOS, WSL)
- System cron (`cron`, `crond`, or `launchd`)
- OpenClaw installed with `openclaw system event` available

Node.js and OCaml are installed by the setup process.

Windows users: Use WSL or adapt to Task Scheduler.

---

*"If it's not in the repo, it didn't happen. If it doesn't need thinking, don't use tokens."*
