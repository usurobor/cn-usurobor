# Skills – cn-agent v1.1.0

Each skill in cn-agent lives under `skills/<name>/` and SHOULD include:

- `SKILL.md` – spec with TERMS, INPUTS, EFFECTS.
- `kata.md` – a minimal kata that exercises the skill end-to-end.

## Adding a Skill

1. Create `skills/<skill-name>/`.
2. Add `skills/<skill-name>/SKILL.md` with clear TERMS / INPUTS / EFFECTS.
3. Add any scripts under `skills/<skill-name>/` as needed.
4. Reference the skill from `spec/HEARTBEAT.md` or other specs, so the agent knows when to run it.
5. Commit and push so the updated specs and skill files are applied to the runtime.

When a kata says "add skill `<name>`", it means: perform steps 1–5 above for that skill.

## Current Skills

- `skills/hello-world/`
  - Bootstraps the initial "Hello, world" thread in `state/threads/yyyyddmmhhmmss-hello-world.md`.
- `skills/self-cohere/`
  - Bootstraps a cn-agent-based hub from this template (see `SKILL.md`).
- `skills/configure-agent/`
  - Personalizes spec files after self-cohere bootstrap.
- `skills/daily-routine/`
  - Manages daily state files (memory, reflection, practice) with EOD cron check.
- `skills/reflect/`
  - Coherence reflection using TSC framework.
- `skills/star-sync/`
  - Keeps GitHub stars aligned with `state/peers.md`.
