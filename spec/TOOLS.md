# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## Skills in this CN repo

In this Coherence Network repo, skills live under `skills/<skill-name>/`.

A skill is:

- A directory `skills/<skill-name>/` containing:
  - `SKILL.md` — the skill's spec:
    - TERMS: what it assumes (files, tools, state).
    - INPUTS: what events or parameters it receives.
    - EFFECTS: which files or external services it touches.
  - Optional scripts or helpers the runtime can call.

To **add a skill** in this repo:

1. Create `skills/<skill-name>/`.
2. Add `skills/<skill-name>/SKILL.md` with clear TERMS / INPUTS / EFFECTS.
3. Add any scripts under `skills/<skill-name>/` as needed.
4. Reference the skill from `spec/HEARTBEAT.md` or other specs, so the agent knows when to run it.
5. Commit and push so the updated specs and skill files are applied to the runtime.

When a kata says “add skill `<name>`”, it means: perform steps 1–5 above for that skill.

## What Goes Here (local notes)

This file is for environment-specific notes that are not part of reusable skills. For example:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod

### Moltbook

- Tracking DB: /root/.openclaw/workspace/memory/moltbook.db (SQLite)
- Behavior now archived under git-CN specs
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.
