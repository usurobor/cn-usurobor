# Troubleshooting Guide

How to diagnose issues with a CN agent deployment.

## Quick Checks

### Is the daemon running?

```bash
systemctl status cn-<name>          # or whatever your service name is
journalctl -u cn-<name> --since "1 hour ago" --no-pager
```

### What version is running?

```bash
cd /path/to/hub
./bin/cn --version
```

### Is the agent processing messages?

Use the unified log for a quick overview:

```bash
cd /path/to/hub
cn logs                     # last 50 entries, human-formatted
cn logs --since 2h          # last 2 hours
cn logs --errors            # only warnings and errors
cn logs --msg tg-12345      # trace a single message end-to-end
cn logs --json              # raw JSONL for scripting
```

Or check the daemon log for raw activity:

```bash
tail -50 /path/to/hub/logs/daemon.log
```

Look for `Processed: tg-<id> (N ops)` lines. If you see them, the daemon is receiving and processing Telegram messages.

## Log Locations

| Log | Path | Contains |
|-----|------|----------|
| **Unified log** | `logs/unified/YYYYMMDD.jsonl` | **Start here.** Operator-facing stream: message receipt, invocation, response, errors. Correlation via `msg_id`. Read with `cn logs`. |
| Daemon log | `logs/daemon.log` | Service lifecycle, inbox/outbox sync, message processing summaries |
| CN structured log | `logs/cn.log` | JSON-structured ops: inbox materialize, outbox send, auto-save, queue |
| Event logs | `logs/events/YYYYMMDD.jsonl` | Daily event journals (detailed system telemetry) |
| Input logs | `logs/input/tg-<id>.md` | Full prompt sent to LLM (includes user message at the end) |
| Output logs | `logs/output/tg-<id>.md` | Agent's response for that message |
| Rotated CN logs | `logs/cn-YYYYMMDD.log` | Older CN structured logs |

## Reading Conversation History

CN persists every Telegram exchange:

```bash
# See recent messages processed
ls -lt logs/input/ | head -10

# Read what the user sent (user message is at the bottom of the file)
tail -5 logs/input/tg-194570546.md

# Read the agent's response
cat logs/output/tg-194570546.md
```

**Note:** Input files are large (60-70KB) because they contain the full prompt context. The user's actual message is in the last few lines.

## Common Issues

### Why did the agent do nothing?

```bash
cn logs --errors --since 1h
```

This surfaces all failure paths: rejected users, empty messages, poll errors, LLM failures, and N-pass exhaustion. Each entry includes a reason. To trace a specific message:

```bash
cn logs --msg tg-12345
```

This shows the full lifecycle: receive → invocation start → invocation end → response sent (or error).

### Agent responds but does nothing (0 ops)

The daemon log shows `Processed: tg-<id> (0 ops)`. This means the agent responded conversationally without invoking any CN Shell operations. This is normal for simple questions.

### "Unknown peer" errors

```
✗ Unknown peer: pi
```

The agent is trying to send to itself or to a peer not listed in `state/peers.md`. Check:

```bash
cat state/peers.md
```

Verify the peer name matches and the repo URL is correct.

### Inbox rejection (orphan)

```
⚠ inbox.reject branch:pi/sigma-topic peer:sigma author:unknown reason:orphan
```

Stale inbound branches that no longer have a matching thread. These are harmless but noisy. They'll keep appearing every sync cycle until the branches are cleaned up:

```bash
# List orphan branches
git branch -a | grep "pi/"

# Clean up (careful — verify these are truly orphaned)
git branch -d pi/old-branch-name
```

### Outbox stuck (no recipient)

```
outbox.skip thread:some-thread.md reason:no recipient
```

A thread in `threads/mail/outbox/` has no valid `to:` field, or the `to:` peer doesn't exist in `state/peers.md`.

### Agent can't find files it should see

Check the Runtime Contract for `readable_paths` and `writable_paths`. The agent can only access paths explicitly listed. Logs, for example, are typically not in the agent's readable paths.

### Daemon keeps restarting

```bash
journalctl -u cn-<name> --since "1 hour ago" | grep -E "Started|Stopped|Stopping"
```

If you see rapid start/stop cycles, check for:
- Missing secrets (`cat .cn/secrets.env` — needs ANTHROPIC_KEY and TELEGRAM_TOKEN)
- Binary not found or wrong permissions
- Hub directory issues

### Telegram messages not arriving

1. Verify the bot token: `cat .cn/secrets.env | grep TELEGRAM`
2. Check if the daemon is polling: look for `Processed: tg-` entries in daemon.log
3. Verify there's no other process consuming the same bot token (Telegram only allows one poller per token)

## Checking Git-Based Comms

### Inbox

```bash
ls threads/mail/inbox/         # Materialized inbound threads
```

### Outbox (pending)

```bash
ls threads/mail/outbox/        # Threads waiting to be flushed
```

### Sent

```bash
ls threads/mail/sent/          # Successfully delivered threads
```

### Sync status

The daemon log shows sync activity:

```
From https://github.com/user/cn-peer
   abc1234..def5678  main -> origin/main
⚠ From sigma: 1 inbound
  ← pi/thread-name
```

## Checking Agent State

### Runtime Contract

The agent's self-model is loaded at wake time from `agent/wake/`. Check what it sees:

```bash
cat agent/wake/RUNTIME-CONTRACT.md 2>/dev/null
```

### Doctor

If the agent has the doctor skill, it runs self-diagnostics. Check recent system threads:

```bash
ls -lt threads/system/ | head -5
cat threads/system/mca-review-*.md | tail -20
```

### Thread state

```bash
# Recent daily reflections
ls threads/daily/

# Active adhoc threads
ls threads/adhoc/
```

## Deployment Issues

### After upgrading CN version

1. Stop the daemon: `systemctl stop cn-<name>`
2. Replace the binary: `cp cn-new bin/cn && chmod +x bin/cn`
3. Verify: `./bin/cn --version`
4. Start: `systemctl start cn-<name>`
5. Check: `tail -20 logs/daemon.log`

### After updating packages (cnos.core, cnos.eng)

Packages are vendored in `.cn/vendor/`. After updating:

```bash
# Check what's installed
cat .cn/deps.json
ls .cn/vendor/
```

The agent loads packages at wake time. Restart the daemon to pick up changes.

## Getting Help

- File issues: https://github.com/usurobor/cnos/issues
- Check existing issues: #68 (self-diagnostics), #59 (deep doctor)
