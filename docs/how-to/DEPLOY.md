# Deploy

Update a running cnos agent to a new version.

---

## Prerequisites

- A released version with binaries (see [BUILD-RELEASE.md](./BUILD-RELEASE.md))
- SSH access to the agent's host
- Knowledge of the agent's hub path and run mode (daemon or cron)

---

## Steps

### 1. Verify the release exists

```bash
gh release view vX.Y.Z -R usurobor/cnos
```

Confirm binary artifacts are attached (`cn-linux-x64`, `cn-macos-x64`, `cn-macos-arm64`).

### 2. Download the binary

The running daemon holds a file lock on the binary. Download to a temp path first, then replace atomically:

```bash
curl -fsSL -o /tmp/cn-new \
  "https://github.com/usurobor/cnos/releases/download/vX.Y.Z/cn-$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/')"
chmod +x /tmp/cn-new
mv /tmp/cn-new /usr/local/bin/cn
```

Alternatively, use the install script (downloads latest):

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
```

> **Note:** `cn update` has a known bug where the git-based source update path can overwrite a successful binary download. Use direct download instead.

### 3. Verify the binary

```bash
cn --version
```

### 4. Restart the agent

How you restart depends on the agent's run mode:

#### Daemon mode (`cn agent --daemon`)

```bash
# Stop
pkill -f "cn agent --daemon"

# Start
cd /path/to/hub
nohup cn agent --daemon > /var/log/cn-agent.log 2>&1 &

# Verify
ps aux | grep "cn agent" | grep -v grep
```

#### Cron mode

No restart needed — the next cron invocation picks up the new binary automatically.

#### Systemd

```bash
sudo systemctl restart cn-agent
sudo systemctl status cn-agent
```

### 5. Verify the agent is running

```bash
# Check version
cn --version

# Check process (daemon mode)
ps aux | grep "cn agent" | grep -v grep

# Check logs
tail -f /var/log/cn-agent.log
```

### 6. Run setup for new features (if needed)

Some releases add new hub structure (e.g., v3.4.0 added `.cn/vendor/`). Run setup to materialize:

```bash
cd /path/to/hub
cn setup
```

Check `cn doctor` for any missing structure:

```bash
cn doctor
```

---

## Quick deploy (one-liner)

For daemon-mode agents over SSH:

```bash
ssh user@host 'curl -fsSL -o /tmp/cn-new "https://github.com/usurobor/cnos/releases/download/vX.Y.Z/cn-linux-x64" && chmod +x /tmp/cn-new && mv /tmp/cn-new /usr/local/bin/cn && pkill -f "cn agent --daemon"; sleep 1; cd /path/to/hub && nohup cn agent --daemon > /var/log/cn-agent.log 2>&1 & sleep 2 && cn --version'
```

---

## Rollback

Same process, different version:

```bash
curl -fsSL -o /tmp/cn-old \
  "https://github.com/usurobor/cnos/releases/download/vPREVIOUS/cn-linux-x64"
chmod +x /tmp/cn-old
mv /tmp/cn-old /usr/local/bin/cn
pkill -f "cn agent --daemon"
cd /path/to/hub && nohup cn agent --daemon > /var/log/cn-agent.log 2>&1 &
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `curl: (23) Failure writing output` | Binary locked by running process | Download to `/tmp` first, then `mv` |
| `cn update` installs old version | Git source path overwrites binary | Use direct download, not `cn update` |
| Daemon not running after deploy | Forgot to restart | `pkill` + `nohup cn agent --daemon` |
| New features missing | Hub structure outdated | Run `cn setup` or `cn doctor` |
