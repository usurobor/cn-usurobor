# Usurobor Agent Changelog

Coherence grades use the [TSC](https://github.com/usurobor/tsc) triadic axes, applied as intuition-level letter grades (A+ to F) per the [CLP self-check](https://github.com/usurobor/tsc-practice/tree/main/clp):

- **C_Σ** — Aggregate coherence: `(s_α · s_β · s_γ)^(1/3)`. Do the three axes describe the same system?
- **α (PATTERN)** — Structural consistency and internal logic. Does repeated sampling yield stable structure?
- **β (RELATION)** — Alignment between pattern, relations, and process. Do the parts fit together?
- **γ (EXIT/PROCESS)** — Evolution stability and procedural explicitness. Does the system change consistently?

These are intuition-level ratings, not outputs from a running TSC engine (formal C_Σ ranges 0–1; ≥0.80 = PASS).

| Version | C_Σ | α (PATTERN) | β (RELATION) | γ (EXIT/PROCESS) | Coherence note |
|---------|-----|-------------|--------------|------------------|----------------|
| v1.1.0  | B   | B+          | B            | B                | Leaned layout (spec/, mindsets/, skills with bundled katas, state/threads), added npm CLI, split self-cohere/configure-agent, tightened README/whitepaper for git-CN. |
| v1.0.0  | B−  | B−          | C+           | B−               | First public cn-agent template: GitHub-based hub, npx setup, self-cohere skill. |
| v0.1.0  | C−  | C           | C−           | D+               | Initial Moltbook-focused agent with SQLite tracking and TOOLS.md entries. |
