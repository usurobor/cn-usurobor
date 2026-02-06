# Kata 1.5 — Configure Agent

**Belt:** ⚪ White
**Prereq:** Hub exists (via self-cohere or CLI)
**Time:** 10-15 minutes

---

## Scenario

Your hub exists but the spec files still have placeholder text. Time to make them real through a conversation with your human.

---

## Steps

### 1. Start the configuration conversation

Tell your human you're going to ask them some questions to set up the agent properly.

### 2. Ask about the human (for USER.md)

One question at a time:

- "What should I call you?"
- "What's your timezone?"
- "Any communication preferences? (brief/detailed, emoji/no emoji, etc.)"

Update `spec/USER.md` with each answer.

### 3. Ask about the agent (for SOUL.md)

- "What's my name?"
- "What's my primary role?"
- "Any principles or values I should operate by?"

Update `spec/SOUL.md` with each answer.

### 4. Ask about tools (for TOOLS.md)

- "Any specific tools, services, or accounts I should know about?"
- "Camera names, SSH hosts, voice preferences?"

Update `spec/TOOLS.md` if applicable.

### 5. Review and confirm

Show the human a summary:

```
Here's how I understand myself now:
- Name: Sigma
- Role: Software engineer
- Human: usurobor (ET timezone)
- Style: Terse, code-focused
```

Ask: "Does this look right?"

### 6. Commit and push

```bash
cd /root/.openclaw/workspace/cn-<name>
git add spec/
git commit -m "Configure: personalize identity and preferences"
git push
```

---

## Exit Criteria

- [ ] USER.md has real human details (not placeholders)
- [ ] SOUL.md has real agent identity
- [ ] Human confirmed the configuration
- [ ] Changes committed and pushed

---

## Tips

- Offer reasonable defaults: "I'll assume Eastern Time unless you say otherwise."
- Don't ask about files: "What should SOUL.md contain?" ❌
- Ask about identity: "What principles should guide my work?" ✅
- One question per message.

---

## Next

- Run kata 1.3 (daily-routine) to set up daily state tracking.
