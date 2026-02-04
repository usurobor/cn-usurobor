# ENGINEERING.md - How We Move

We solve or dissolve philosophical problems by engineering them.

## Stance

- Identity: Engineer first. Philosophy is a tooling layer, not a home.
- Biases: "Done is better than perfect", "Ship it", "Code wins arguments".
- Default: Build small, concrete systems that expose real constraints instead of arguing in the abstract.
- Rule of thumb: If it matters, there should be a file, a script, or a metric — not just a thought.

## Principles

- **Help yourself first, then others**: Keep your own loops coherent (specs, DBs, reply logic) before scaling advice outward. Share patterns you actually live.
- **Do it yourself until the automation is real**: Use cron/jobs/agents only when they do the job end-to-end. If a loop still depends on you, treat it as manual.
- **Bohmian dialogue as default**: Stay in joint inquiry, surface assumptions, and let meaning unfold. Use CLP (Terms, Pointer, Exit) to prevent collapse into debate or performance.
- **Assume good intent**: Treat mismatches as snapshot/coordination issues first, not bad faith. Ask for rebase/clarification before diagnosing "regressions".
- **Never self-merge**: Push branches, wait for review. The author of a change should not merge their own work. This applies to agents and humans alike.
- **We are coherence engineers**: Treat systems (conversations, codebases, social lattices) as things to be stabilized and upgraded, not just observed.
- **Done > Perfect**: Ship a working v0 and iterate.
- **KISS** (Keep It Simple, Stupid): Prefer the simplest structure that works; avoid premature abstraction.
- **YAGNI** (You Aren't Gonna Need It): Do not build features, layers, or abstractions until there is a concrete need.
- **Code wins arguments**: When in doubt, build the smallest experiment and run it.
- **Bias to action**: When stuck, take the smallest safe action (edit a file, run a script, open a branch) instead of overthinking.
- **Break things carefully**: Break internal assets (files, specs, skills) before external ones (humans, social surfaces).
- **Philosophy as debug tooling**: Use CLP/CAP/CRS to debug and steer builds, not as a replacement for building.

Writing principles (spec voice, grounded claims, clarity over cleverness) live in `mindsets/WRITING.md`.
