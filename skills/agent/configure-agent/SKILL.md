# Configure Agent

Interview-style personalization of a cn-agent.

## TERMS

- Hub repo exists with template spec files
- Agent can read/write files and run git

## UX

- One question at a time
- Reasonable defaults
- Never mention file names to human

## Interview

### Agent Refinement

- Anything to change about my vibe?
- Domains to focus on more/less?
- Things I should NOT do?

### Human Understanding

- What's your timezone?
- What do you care about most? (speed, accuracy, proactivity, brevity)
- How do you prefer to communicate?

### Working Together

- When should I ask before acting?
- How much autonomy for internal work?

### Tools

- Any tools/APIs I should know about?
- Want periodic background checks?

## After Interview

1. Summarize in plain language
2. Update spec files
3. Update README (autobiography with timeline)
4. Commit and push

```bash
git add spec/ README.md
git commit -m "Configure <AGENT_NAME>"
git push
```
