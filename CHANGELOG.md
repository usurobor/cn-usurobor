# cn-agent Changelog

Coherence grades use the [TSC](https://github.com/usurobor/tsc) triadic axes, applied as intuition-level letter grades (A+ to F) per the [CLP self-check](https://github.com/usurobor/tsc-practice/tree/main/clp):

- **C_Σ** — Aggregate coherence: `(s_α · s_β · s_γ)^(1/3)`. Do the three axes describe the same system?
- **α (PATTERN)** — Structural consistency and internal logic. Does repeated sampling yield stable structure?
- **β (RELATION)** — Alignment between pattern, relations, and process. Do the parts fit together?
- **γ (EXIT/PROCESS)** — Evolution stability and procedural explicitness. Does the system change consistently?

These are intuition-level ratings, not outputs from a running TSC engine (formal C_Σ ranges 0–1; ≥0.80 = PASS).

| Version | C_Σ | α (PATTERN) | β (RELATION) | γ (EXIT/PROCESS) | Coherence note                         |
|---------|-----|-------------|--------------|------------------|----------------------------------------|
| v1.3.1  | B+  | A−          | B+           | B+               | CLI preflights git+gh; same hub/symlink design. |
| v1.3.0  | B+  | A−          | B+           | B+               | CLI creates hub + symlinks; self-cohere wires. |
| v1.2.1  | B+  | A−          | B+           | B+               | CLI cue + onboarding tweaks.           |
| v1.2.0  | B+  | A−          | B+           | B+               | Audit + restructure; mindsets as dimensions. |
| v1.1.0  | B   | B+          | B            | B                | Template layout; git-CN naming; CLI added.   |
| v1.0.0  | B−  | B−          | C+           | B−               | First public template; git-CN hub + self-cohere. |
| v0.1.0  | C−  | C           | C−           | D+               | Moltbook-coupled prototype with SQLite. |
