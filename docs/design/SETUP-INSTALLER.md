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
| Telegram bot token | No | `.cn/secrets.env` | guided flow (see below) |
| Allowed Telegram user IDs | No | `.cn/config.json` | auto-detected or manual (see below) |
| Model | No | `.cn/config.json` | selected from live API list (see below) |
| max_tokens | No | `.cn/config.json` | default: 8192; clamp >= 1 |
| poll_interval | No | `.cn/config.json` | default: 1; clamp >= 1 |
| poll_timeout | No | `.cn/config.json` | default: 30; clamp >= 0 |

#### Model selection

After the API key is entered (or loaded from existing secrets),
`cn setup` calls `GET /v1/models` to fetch the live model list.
The API returns models sorted most-recent-first with `id`, `display_name`,
and `created_at`.

Behavior:

- **Online**: present a numbered list of available models.
  Default selection: the first model whose `id` contains `sonnet`
  (cost-effective for an always-on daemon). User can pick any model,
  including Opus.
- **Offline / error**: fall back to hardcoded default
  `claude-sonnet-4-5-20250929` and print a note.
- **Re-run**: show current model with `[current-model-id]` prompt;
  Enter keeps it.

Example output:

```
  Available models:
    1. claude-opus-4-6           (Claude Opus 4.6)
    2. claude-sonnet-4-5-20250929 (Claude Sonnet 4.5)  ← default
    3. claude-haiku-4-5-20251001  (Claude Haiku 4.5)
    ...
  Model [2]:
```

This reuses the same API call that Step 4 uses for key validation —
if the call succeeds, the key is valid and we have the model list.
If it fails with 401/403, we know the key is bad before writing anything.

#### Telegram setup (guided)

Telegram integration is optional. The flow walks users through bot
creation, token validation, and **automatic user-ID detection** — no
more asking users to look up their numeric Telegram ID.

**Phase 1 — Enable Telegram?**

```
  Enable Telegram integration? [Y/n]
```

- `n` → skip all Telegram prompts, write no token or user IDs.
- `y` / Enter → continue.
- **Re-run with existing token**: skip this prompt, go straight to
  Phase 2 (show masked token, let user change or keep it).

**Phase 2 — Token acquisition**

```
  Do you have a bot token? [Y/n]
```

If **no**, print step-by-step BotFather instructions inline:

```
  To create a Telegram bot:
    1. Open https://t.me/BotFather
    2. Send /newbot
    3. Choose a name and username
    4. Copy the token BotFather gives you

  Telegram bot token:
```

If **yes** (or re-run):

```
  Telegram bot token [123…DEF]:
```

**Phase 3 — Token validation**

Immediately call `GET https://api.telegram.org/bot<TOKEN>/getMe`.

- `ok: true` → print bot info and continue:
  ```
    ✓ Bot: My CN Bot (@my_cn_bot)
  ```
- `ok: false` / `401` → warn and offer retry or skip:
  ```
    ✗ Token invalid.
    Re-enter token, or press Enter to skip Telegram:
  ```
- Network error → warn "could not validate" and continue
  (user IDs prompt still shown so they can configure offline).

**Phase 4 — Allowed users (auto-detect)**

If the token is valid, offer automatic user-ID detection:

```
  Who should be allowed to talk to this bot?

    1. Auto-detect (send /start to @my_cn_bot, then press Enter)
    2. Enter user IDs manually
    3. Skip (deny all — configure later)
  [1]:
```

**Option 1 — Auto-detect** (default):

1. Print instruction:
   ```
     → Send /start to @my_cn_bot in Telegram, then press Enter.
   ```
2. User presses Enter.
3. Call `GET https://api.telegram.org/bot<TOKEN>/getUpdates`.
4. Collect unique `from.id` + `from.first_name` from all messages.
5. If users found, present them for confirmation:
   ```
     Detected users:
       1. Alice (ID: 498316684)  ✓
       2. Bob   (ID: 123456789)  ✓
     Allow these users? [Y/n]
   ```
   - `Y` → save all detected IDs.
   - `n` → fall back to manual entry.
6. If no messages found:
   ```
     No messages found. Make sure you sent /start to @my_cn_bot.
     Retry? [Y/n]
   ```
   - `Y` → repeat from sub-step 2.
   - `n` → fall back to manual entry.

**Option 2 — Manual entry**:

```
  Allowed Telegram user IDs (comma-separated): 498316684, 123456789
```

Parsed as before: comma-separated → JSON array of ints.
Invalid input (non-numeric) → warn and re-prompt.

**Option 3 — Skip**:

Write `"allowed_users": []` (deny all). Print:

```
  ⚠ No users allowed. Edit .cn/config.json to add user IDs later.
```

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
Both keys are now validated **inline during Step 1**:

- **Anthropic**: validated when fetching the model list
  (`GET /v1/models`; 200 = valid, 401/403 = warn).
- **Telegram**: validated immediately after token entry
  (`GET /bot<TOKEN>/getMe`; ok = valid, else warn + offer retry/skip).

Step 4 only runs validation for keys that were **not yet checked**
(e.g. loaded from existing `secrets.env` on re-run without changes).
If both were already validated inline, this step is a no-op.

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
  ✓ API key valid — fetching models...

  Available models:
    1. claude-opus-4-6             (Claude Opus 4.6)
    2. claude-sonnet-4-5-20250929  (Claude Sonnet 4.5)  ← default
    3. claude-haiku-4-5-20251001   (Claude Haiku 4.5)
  Model [2]:

  Enable Telegram integration? [Y/n] y
  Do you have a bot token? [Y/n] y
  Telegram bot token: 123456:ABCDEF
  ✓ Bot: My CN Bot (@my_cn_bot)

  Who should be allowed to talk to this bot?
    1. Auto-detect (send /start to @my_cn_bot, then press Enter)
    2. Enter user IDs manually
    3. Skip (deny all — configure later)
  [1]:

  → Send /start to @my_cn_bot in Telegram, then press Enter.

  Detected users:
    1. Alice (ID: 498316684)  ✓
  Allow these users? [Y/n] y

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
  ✓ API key valid — fetching models...

  Available models:
    1. claude-opus-4-6             (Claude Opus 4.6)
    2. claude-sonnet-4-5-20250929  (Claude Sonnet 4.5)  ← current
    3. claude-haiku-4-5-20251001   (Claude Haiku 4.5)
  Model [2]:

  Telegram bot token [123…DEF]:
  ✓ Bot: My CN Bot (@my_cn_bot)

  Allowed users: Alice (498316684)
  Change allowed users? [y/N]

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
