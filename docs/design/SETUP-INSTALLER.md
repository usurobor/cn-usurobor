# cn setup & installer — Design Doc

**Status:** Draft
**Date:** 2026-02-23
**Owner:** usurobor (Axiom)
**Contributors:** Sigma

---

## 1. Problem

Today, users must manually:

- export API keys
- create `.cn/config.json`
- write systemd units (or cron scripts)
- wire everything together

There is no single idempotent command that takes a fresh machine from:

> "`cn` is on PATH"

to:

> "agent is configured, secrets are stored safely, and a daemon can run."

## 2. Goals

- **One command**: `cn setup` converges the hub into a runnable configuration.
- **Idempotent**: safe to re-run; converges state without nuking user edits.
- **Industry-standard secrets**:
  - no secrets in JSON
  - no secrets in install pipes
  - secrets stored in a dotenv-style file with `0600`
- **Minimal**:
  - zero new deps
  - no database
  - no global state
- **Portable**: works without systemd (still configures hub + prints next steps).

## 3. Non-goals

- Package manager distribution (apt/brew) — separate effort.
- Multi-hub global config (`~/.config/cnos/...`) — YAGNI.
- Fancy dotenv features (no interpolation / multiline / export).
- A GUI setup experience.

## 4. Terms

| Term | Definition |
|------|-----------|
| **Hub** | A repo directory containing `.cn/`. |
| **Install** | Placing the `cn` binary on PATH. |
| **Setup** | Configuring a hub: non-secrets, secrets, and optional service wiring. |
| **Secrets file** | `.cn/secrets.env` (gitignored, chmod 0600). |
| **Config file** | `.cn/config.json` (non-secrets only, under `runtime`). |

## 5. Architecture

### 5.1 Install vs Setup

Two distinct phases:

| Phase | Command | What it does | Root required |
|-------|---------|-------------|---------------|
| Install | `install.sh` | installs binary to PATH | **No** if BIN_DIR is writable; **Yes** if writing to system dirs |
| Setup | `cn setup` | writes config + secrets; optionally installs service | **No** for files; **Only** for system service install |

**Rule:** `install.sh` does only binary placement.
No secrets, no prompts, no config.

### 5.2 Artifacts created/managed by `cn setup`

| Artifact | Purpose | Contains secrets? | Idempotency rule |
|----------|---------|-------------------|------------------|
| `.cn/config.json` | runtime settings | No | merge under `runtime`, preserve unknown keys |
| `.cn/secrets.env` | API keys | Yes | rewrite normalized KEY=VALUE lines; chmod 0600 |
| `.gitignore` | prevent leaks | No | ensure one line: `.cn/secrets.env` |
| systemd unit (optional) | daemon wiring | No | rewrite only if content differs |

### 5.3 Secrets resolution (runtime contract)

When resolving a secret:

1. Environment variable (if set and non-empty) **wins**
2. `.cn/secrets.env` (hub-local) fallback
3. Missing → `Error` (for required secrets) or `None` (for optional)

This preserves env semantics for CI/override,
while enabling `cn setup` to "just work."

**Current code** (`Cn_config.load`): reads `ANTHROPIC_KEY`, `TELEGRAM_TOKEN`,
and `CN_MODEL` from env only. Patch A adds `.cn/secrets.env` as a fallback source.

### 5.4 Dotenv parser (minimal spec)

Accepted lines:

- blank → skip
- `# comment` → skip
- `KEY=VALUE`

Parsing rules:

- **Key**: trim whitespace; must match `[A-Z0-9_]+` (otherwise ignore + warn)
- **Value**: trim whitespace; strip ONE layer of surrounding `'` or `"` if present
- No `export` prefix
- No interpolation
- No multiline values
- No escape sequences (beyond outer quote stripping)

Edge cases:

- File missing → treat as empty
- File exists but unreadable → warn and treat as empty
- File permissions more permissive than `0600` → warn

### 5.5 Security

| Concern | Mitigation |
|---------|-----------|
| Secrets in git | `.cn/secrets.env` added to `.gitignore` by `cn setup` |
| File permissions | Created with 0600; warn at startup if more permissive |
| Secrets in config.json | Never. Model/users/settings only. |
| Secrets in install pipe | Never. `install.sh` handles binary only. |
| Git tracking check | `cn doctor` warns if `secrets.env` is tracked |

## 6. `cn setup` UX / Flow

`cn setup` is interactive by default. Pressing Enter keeps the existing value.

### Step 0: Preconditions

- Must run inside a hub directory (or accept `--hub PATH` later).
- Ensure `.cn/` exists.
- Create `.cn/config.json` if missing (`{}`).

### Step 1: Prompts (interactive)

| Prompt | Required | Stored in | Notes |
|--------|----------|-----------|-------|
| Anthropic API key | Yes | `.cn/secrets.env` | masked on re-run: `sk-ant-…abcd` |
| Telegram bot token | No | `.cn/secrets.env` | if unset, daemon runs without Telegram |
| Allowed Telegram user IDs | No | `.cn/config.json` | comma-separated → JSON array of **ints**; empty = deny all |
| Model | No | `.cn/config.json` | default: `claude-sonnet-4-5-20250929` |
| max_tokens | No | `.cn/config.json` | default: 8192; clamp >= 1 |
| poll_interval | No | `.cn/config.json` | default: 1; clamp >= 1 |
| poll_timeout | No | `.cn/config.json` | default: 30; clamp >= 0 |

### Step 2: Write secrets

Write `.cn/secrets.env` with normalized lines:

```dotenv
# CN secrets — do not commit (chmod 600)
ANTHROPIC_KEY="sk-ant-..."
TELEGRAM_TOKEN="123456:ABCDEF..."
```

Then:

- `chmod 0600`
- ensure `.gitignore` contains `.cn/secrets.env`

### Step 3: Write config

Write/update `.cn/config.json`:

```json
{
  "runtime": {
    "model": "claude-sonnet-4-5-20250929",
    "allowed_users": [498316684],
    "poll_interval": 1,
    "poll_timeout": 30,
    "max_tokens": 8192
  }
}
```

Merge strategy:

- parse existing JSON (error if invalid)
- update known keys under `runtime`
- preserve everything else

### Step 4: Validate keys (warn-only)

Validation is best-effort and never blocks setup.

**Anthropic:**

- `GET https://api.anthropic.com/v1/models`
- Headers: `x-api-key: <KEY>`, `anthropic-version: 2023-06-01`
- `200` → valid
- `401`/`403` → warn "invalid key"

**Telegram:**

- `GET https://api.telegram.org/bot<TOKEN>/getMe`
- `ok: true` → valid (print bot username)
- `ok: false` / `401` → warn "invalid token"

If offline or network error → warn "could not validate" and continue.

### Step 5: Optional systemd install

Prompt: `Install and start as a systemd service? [Y/n]`

If yes and systemd present:

- Prefer a **user service** if not root
  (writes into `~/.config/systemd/user/`)
- If root (or user agrees to sudo), install as a **system service**
  in `/etc/systemd/system/`

System service example (generated by `cn setup`, placeholders replaced):

```ini
[Unit]
Description=cn agent daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{USER}}
Group={{GROUP}}
WorkingDirectory={{HUB_PATH}}
EnvironmentFile={{HUB_PATH}}/.cn/secrets.env
ExecStart={{CN_PATH}} agent --daemon
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:

- `systemctl daemon-reload`
- `systemctl enable --now cn.service`
- show `systemctl status cn.service`

If user says no (or systemd missing), print:

- `Run cn agent --daemon in this hub`
- `Or schedule cn agent with cron/systemd timer`

## 7. User journey

First run:

```
$ curl -fsSL https://cnos.dev/install.sh | sh
  ✓ cn installed to /usr/local/bin/cn

$ cd my-project
$ cn setup
  CN Setup
  ────────
  Anthropic API key: sk-ant-api03-xxxxx
  Telegram bot token (optional): 123456:ABCDEF
  Allowed Telegram user IDs: 498316684
  Model [claude-sonnet-4-5-20250929]:

  Validating...
  ✓ Anthropic API key valid
  ✓ Telegram bot @my_cn_bot

  Writing .cn/secrets.env (0600)... ✓
  Writing .cn/config.json... ✓
  Updating .gitignore... ✓

  Install as systemd service? [Y/n] y
  Writing /etc/systemd/system/cn.service... ✓
  Starting cn.service... ✓

  Done. cn is running.
  View logs: journalctl -u cn -f
```

Re-run (idempotent):

```
$ cn setup
  CN Setup
  ────────
  Anthropic API key [sk-ant-…xxxx]:
  Telegram bot token [123…DEF]:
  Allowed Telegram user IDs [498316684]:
  Model [claude-sonnet-4-5-20250929]:

  Validating...
  ✓ Anthropic API key valid
  ✓ Telegram bot @my_cn_bot

  No changes detected. ✓
```

## 8. Acceptance criteria

After `install.sh` + `cn setup`:

- `.cn/config.json` exists and is valid JSON.
- `.cn/secrets.env` exists, chmod 0600, and is gitignored.
- `cn agent --daemon` starts and reads secrets without manual exports.
- Re-running `cn setup` with no changes prints "No changes detected"
  and does not rewrite files.

## 9. Implementation plan

| Patch | Scope | Depends on |
|-------|-------|-----------|
| **A** | Dotenv loader + secret precedence in `Cn_config.load` | — |
| **B** | `cn setup` interactive flow + atomic file writes | A |
| **C** | Key validation (Anthropic `/v1/models`, Telegram `getMe`) | B |
| **D** | Optional systemd unit generation + idempotent install | B |
| **E** | Tests (dotenv parsing, setup idempotency, config merge) | A+B |

## 10. Open questions

1. **User service vs system service by default?**
   User service (no sudo) is friendlier for dev machines;
   system service (server-first) is better for production.
2. **Unit naming:** `cn.service` assumes one hub per machine.
   If multi-hub appears, introduce `cn@.service` (template unit).
3. **Non-systemd platforms:** generate launchd plist later,
   or document manual run for now.
