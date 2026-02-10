# Self Cohere

Wire agent to an existing hub repo.

## TERMS

1. Hub URL provided: `https://github.com/<owner>/cn-<agentname>`
2. Template at `/root/.openclaw/workspace/cn-agent`
3. Symlinks exist in workspace root (created by CLI)
4. Git installed and identity configured

## Pre-flight

```bash
which git
git config user.name
git config user.email
ls -la /root/.openclaw/workspace/SOUL.md
```

## Structure

```
workspace/
├── SOUL.md      → cn-<name>/spec/SOUL.md (hub)
├── USER.md      → cn-<name>/spec/USER.md (hub)
├── AGENTS.md    → cn-agent/spec/AGENTS.md (template)
├── cn-<name>/   (hub: identity + state)
└── cn-agent/    (template: skills + mindsets)
```

Hub = personal. Template = generic. Don't mix.

## Steps

1. Clone hub (or pull if exists)
2. Learn identity from symlinked SOUL.md
3. Record metadata in `state/hub.md`
4. Run `configure-agent` skill
5. Run `hello-world` kata
6. Emit summary

## Output

```
✓ SELF-COHERE COMPLETE
HUB: https://github.com/<owner>/cn-<agentname>
TEMPLATE: /root/.openclaw/workspace/cn-agent
```
