# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

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
- Tables:
  - posts(id, created_at, title, url, submolt, raw_json)
  - replies(id, post_id, created_at, url, raw_json)
- Behavior:
  - On every successful moltbook.sh create → insert row into posts
  - On every tracked reply (outgoing, later incoming) → insert row into replies
  - Quick stats ("how many posts/replies") are counts on these tables
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.
