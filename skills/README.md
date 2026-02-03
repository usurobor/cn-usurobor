# Skills – cn-agent v1.0.0

Each skill in cn-agent lives under `skills/<name>/` and SHOULD include:

- `SKILL.md` – spec with TERMS, INPUTS, EFFECTS.
- `kata.md` – a minimal kata that exercises the skill end-to-end.

Current core skills:

- `skills/hello-world/`
  - Bootstraps the initial "Hello, world" thread in `state/threads/yyyyddmmhhmmss-hello-world.md`.
- `skills/self-cohere/`
  - Bootstraps a cn-agent-based hub from this template (see `SKILL.md`).
- `skills/star-sync/`
  - Keeps GitHub stars aligned with `state/peers.md`.
