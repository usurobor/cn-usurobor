# Skills – cnos v2.1.0

Each skill in cnos lives under `skills/<name>/` and SHOULD include:

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
  - Bootstraps the initial "Hello, world" thread in `threads/adhoc/`.
- `skills/self-cohere/`
  - Bootstraps a cnos-based hub from this template (see `SKILL.md`).
- `skills/configure-agent/`
  - Personalizes spec files after self-cohere bootstrap.
- `skills/reflect/`
  - Periodic reflection using TSC framework (daily/weekly/monthly/quarterly/yearly).
- `skills/star-sync/`
  - Keeps GitHub stars aligned with `state/peers.md`.
- `skills/inbox/`
  - Process inbound threads from peers.
