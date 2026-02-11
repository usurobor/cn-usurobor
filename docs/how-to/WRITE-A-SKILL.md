# Write a Skill

How to add a new skill to cnos.

---

## Reading order

1. **[WRITING.md](../../mindsets/WRITING.md)** — the voice. Coherent writing: nothing can be removed without loss. Read this first so every sentence you write passes the test.
2. **[skills/skill/SKILL.md](../../skills/skill/SKILL.md)** — the structure. Three-step algorithm: Define (coherence formula), Unfold (sections with high alpha/beta), Rules (imperative + examples).
3. **[skills/README.md](../../skills/README.md)** — the mechanics. Where to put files, what to name them, how to register the skill.

---

## Steps

1. Read all three docs above.
2. Create `skills/<name>/`.
3. Write `SKILL.md` following the algorithm in `skills/skill/SKILL.md`.
4. Write `kata.md` — a minimal exercise that runs the skill end-to-end. See [DOJO.md](../tutorials/DOJO.md) for kata format.
5. Reference the skill from a spec (e.g. `spec/HEARTBEAT.md`) so the agent knows when to invoke it.
6. Commit and push.

---

## Examples

| Skill | Why it's a good model |
|-------|----------------------|
| [skills/skill/SKILL.md](../../skills/skill/SKILL.md) | Teaches the format using the format |
| [skills/eng/coding/SKILL.md](../../skills/eng/coding/SKILL.md) | Full-size skill with numbered rules, examples, process section |
| [skills/agent/hello-world/SKILL.md](../../skills/agent/hello-world/SKILL.md) | Minimal skill — shows the floor |
