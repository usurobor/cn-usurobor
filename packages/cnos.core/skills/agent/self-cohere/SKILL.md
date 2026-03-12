# Self Cohere

Wire agent to its hub and verify cognitive readiness.

## TERMS

1. Hub exists as a git repo (created by `cn init`)
2. Cognitive packages installed locally via `cn setup` (in `.cn/vendor/packages/`)
3. Identity files present: `spec/SOUL.md`, `spec/USER.md`
4. Git installed and identity configured

## Pre-flight

```bash
which git
git config user.name
git config user.email
ls spec/SOUL.md spec/USER.md
ls .cn/vendor/packages/
```

## Structure

```
hub/
├── spec/
│   ├── SOUL.md          (agent identity)
│   └── USER.md          (operator identity)
├── .cn/
│   ├── config.env       (hub configuration)
│   └── vendor/
│       └── packages/    (installed cognitive packages)
│           └── cnos.core/
│               ├── doctrine/
│               ├── mindsets/
│               └── skills/
├── threads/             (reflections, conversations)
└── state/               (runtime state, receipts)
```

Cognition is local. Everything the agent needs is installed in the hub — no external checkout required.

## Steps

1. Verify hub structure (spec/, .cn/, threads/, state/)
2. Learn identity from `spec/SOUL.md`
3. Verify installed packages in `.cn/vendor/packages/`
4. Record metadata in `state/hub.md`
5. Run `configure-agent` skill
6. Run `hello-world` kata
7. Emit summary

## Output

```
✓ SELF-COHERE COMPLETE
HUB: <hub-path>
IDENTITY: <agent-name>
PACKAGES: <installed-package-list>
```
