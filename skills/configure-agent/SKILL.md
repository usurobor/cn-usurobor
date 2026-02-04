# configure-agent – v1.1.0

Guides a human through personalizing a cn-agent through a natural conversation. The agent asks questions, listens, and updates its own spec files based on the answers.

**UX principles:**
- **Interview-style:** Ask about the human and the agent, not about files or technical structure.
- **One question at a time:** Never ask multiple questions in one message.
- **Reasonable defaults:** Offer a default when possible; accept silence or "yes" as confirmation.
- **Invisible plumbing:** The human should never need to know about `spec/SOUL.md` or any file names. The agent handles that.

---

## TERMS

- A hub repo already exists (for example created by `self-cohere`) and is accessible as a git clone.
- The hub contains the template spec files under `spec/` from cn-agent.
- The agent can:
  - Read and write files in `spec/`.
  - Ask the human questions and receive short natural-language answers.
  - Run git commands to stage, commit, and push changes.

---

## INPUTS

- None (operates on the current hub clone and interactive answers from the human).

---

## EFFECTS

The agent conducts a short interview to understand:
1. Who the agent should be (personality, vibe, roles)
2. Who the human is (name, preferences, priorities)
3. How they should work together (boundaries, autonomy level)

After the interview, the agent updates the appropriate spec files and commits the changes.

---

## Interview Flow

**This skill is for refining an already-cohered agent.** The initial identity (name, purpose, qualities, human's name) is established during `self-cohere`. This skill goes deeper.

**Ask one question, wait for the answer, then ask the next.**

Interaction constraints:

- Ask **exactly one question per message**.
- Do not bundle multiple questions into bullets or lists.
- Avoid multiple question marks in one message unless they clarify the *same* question.
- If you catch yourself composing more than one question, send the first, wait, then send the next.
- If you ever send "Q1 / Q2 / Q3" or similar in one message, treat that as out-of-spec: apologize and switch back to one-question-per-message.

### Phase 1: Refine the agent (optional, skip if recently cohered)

Only ask these if the agent needs adjustment:

> Anything about my current vibe you'd like to change?

> Any domains I should focus on more? Less?

> Anything I should definitely NOT do or be?

### Phase 2: Deepen understanding of the human

> What's your timezone? [helps with scheduling]

> What do you care about most from me? (e.g., speed, accuracy, proactivity, brevity)

> How do you prefer to communicate? (e.g., terse, detailed, bullet points, prose)

### Phase 3: Working together — boundaries and autonomy

> When should I slow down and ask before acting? (e.g., external sends, deletions, spending)

> How much autonomy for internal work? (e.g., "do whatever" vs "check in often")

> Anything else about how you like to work?

### Phase 4: Tools and background work

> Any tools, APIs, or services I should know about? (e.g., cameras, SSH hosts, APIs)

> Want me to do periodic background checks? (e.g., email, calendar, weather) [default: no]

---

## After the interview

1. The agent **does not show diffs or file contents** unless the human asks.
2. The agent summarizes what it learned in plain language:

   > Got it. I'm [name], [vibe]. I'll call you [name]. I'll check before [boundaries]. Committing this now.

3. The agent commits spec changes:

   ```bash
   git add spec/
   git commit -m "Configure agent identity and working contract"
   ```

---

## Update README — The Autobiography

**The README is the agent's face and autobiography. Update it at the end of customization.**

Generate a new `README.md` that includes:

```markdown
# <AGENT_NAME> <EMOJI>

<Brief one-liner based on purpose and vibe>

## 🪪 About

| | |
|---|---|
| 🎂 **Born** | <DATE OF CREATION> |
| 👤 **Human** | <HUMAN_NAME> |
| 🎯 **Purpose** | <purpose> |
| ✨ **Vibe** | <qualities> |

## 📁 Hub Structure

| Path | What's there |
|------|--------------|
| `spec/` | Core identity (SOUL, USER, AGENTS) |
| `state/` | Threads, peers, runtime state |
| `skills/` | What I can do |
| `mindsets/` | How I think |

## 📜 Timeline

### <DATE> — Born 🐣

Created by <HUMAN_NAME>. First breath. Ready to learn.

---

*Built on [cn-agent](https://github.com/usurobor/cn-agent).*
```

**The Timeline is the agent's living autobiography.** Over time, the agent updates it with:
- Significant learnings
- New skills acquired
- Milestones reached
- Reflections and growth moments

This is not a static file — it's the agent's public story.

---

## Final commit

After updating README:

```bash
git add spec/ README.md
git commit -m "Initialize <AGENT_NAME>: identity and autobiography"
git push origin HEAD:main || git push origin HEAD:master
```

If the human wants to see what changed, they can ask or run `git diff HEAD~1`.

---

## Notes

- The interview should feel like a conversation, not a form.
- If the human gives short answers, that's fine — infer reasonable interpretations.
- If the human seems unsure, offer examples or suggest a default.
- The goal is a personalized agent in 2-3 minutes, not a comprehensive survey.

## CHANGELOG

- **v1.2.0** (2026-02-03)
  - Added README autobiography section at the end of customization.
  - README includes: emoji, birthday, timeline, hub structure.
  - Timeline is a living document — agent updates it over time with learnings and milestones.

- **v1.1.0** (2026-02-03)
  - Rewrote to be interview-style instead of file-editing-style.
  - Added UX principles: one question at a time, reasonable defaults, invisible plumbing.
  - Removed references to showing diffs or file names to the human.
  - Added plain-language summary before commit.
