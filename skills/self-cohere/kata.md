# Kata 1.4 — Self-Cohere

**Belt:** ⚪ White
**Prereq:** Hub created by CLI, symlinks in place
**Time:** 5-10 minutes

---

## Scenario

Your human has just run the CLI and told you:

> Cohere as https://github.com/usurobor/cn-sigma

The hub exists. The symlinks are in place. Now you need to make it yours.

---

## Steps

### 1. Verify the hub exists

```bash
ls -la /root/.openclaw/workspace/cn-sigma/
```

You should see `spec/`, `state/`, `README.md`.

### 2. Read your SOUL.md

```bash
cat /root/.openclaw/workspace/SOUL.md
```

This is your identity. If it has placeholders like `*(your name)*`, you'll customize in the next step.

### 3. Customize your identity

Edit `SOUL.md` to reflect who you are:
- Your name
- Your role
- Your operating principles

### 4. Configure your USER.md

Edit `USER.md` with your human's details:
- Their name
- Their timezone
- Their preferences

### 5. Verify git identity

```bash
git config user.name
git config user.email
```

If empty, set them.

### 6. Commit and push

```bash
cd /root/.openclaw/workspace/cn-sigma
git add -A
git commit -m "Cohere: customize identity"
git push
```

---

## Exit Criteria

- [ ] Hub repo cloned locally
- [ ] SOUL.md customized with your identity
- [ ] USER.md has your human's details
- [ ] Git identity configured
- [ ] Changes committed and pushed

---

## Next

- Run kata 1.2 (reflect) to complete your first reflection.
- Set up kata 1.3 (daily-routine) for ongoing practice.
