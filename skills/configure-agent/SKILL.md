# configure-agent – v1.0.0

Guides a human through personalizing a cn-agent-based hub by updating core spec files (`spec/*.md`) to match the agent they actually want.

TERMS:
- A hub repo already exists (for example created by `self-cohere`) and is accessible as a git clone.
- The hub contains the template spec files under `spec/` from cn-agent.
- The agent can:
  - Read and write files in `spec/`.
  - Ask the human questions and receive short natural-language answers.
  - Run git commands to stage, commit, and push changes.

INPUTS:
- None (operates on the current hub clone and interactive answers from the human).

EFFECTS (outlined process):

1. **SOUL.md (who the agent is)**
   - Read `spec/SOUL.md`.
   - Ask the human simple questions such as:
     - "What kind of agent do you want me to be?" (roles, domains)
     - "What tone or vibe should I have?" (formal, sharp, playful, etc.)
   - Propose edits to `spec/SOUL.md` that reflect the answers.
   - Show the diff to the human and only apply/commit after confirmation.

2. **USER.md (who the human is)**
   - Read `spec/USER.md`.
   - Ask:
     - "How should I refer to you?" (name, preferred form of address)
     - "What do you care about most from me?" (top priorities)
   - Update `spec/USER.md` to match.

3. **USER.md § Working Contract**
   - Ask:
     - "How do you see our roles and boundaries?"
     - "When should I slow down or ask before acting?"
   - Update the Working Contract section in `spec/USER.md`.

4. **AGENTS.md (workspace/memory conventions)**
   - Read `spec/AGENTS.md`.
   - Confirm or adjust:
     - Where to store daily notes (`memory/YYYY-MM-DD.md`).
     - When to use `MEMORY.md`.
   - Update any conventions the human wants to change.

5. **HEARTBEAT.md (background work)**
   - Read `spec/HEARTBEAT.md`.
   - Ask:
     - "Do you want me to do any periodic background checks?" If so, which ones.
   - Update `spec/HEARTBEAT.md` accordingly (or leave mostly empty if none).

6. **TOOLS.md (local notes)**
   - Read `spec/TOOLS.md`.
   - Ask about available tools and infrastructure (APIs, hosts, services) and note them.

7. **Commit and push**
   - After the human confirms the proposed edits, stage and commit changes to `spec/*.md` with a clear message (for example `Configure agent identity and user contract`).
   - Push to the hub's default branch.

The result of this skill is a hub whose core specs (`spec/*.md`) describe the actual agent and human, not just the cn-agent defaults.
