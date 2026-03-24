# Skill Conformity Audit

All skills scored against the meta-skill at `src/agent/skills/skill/SKILL.md`.

## Scoring Criteria (each 0–2, max 14)

| Code | Criterion | What 2 means |
|------|-----------|---------------|
| C1 | **Define** | Coherence formula with parts, fit, and named failure mode (§1.1–1.3) |
| C2 | **Unfold** | High alpha (self-contained bullets) + high beta (sections build on each other) (§2.1–2.3) |
| C3 | **Rules** | All/most rules use `N.N. **Imperative** + ❌/✅` paired examples (§3) |
| C4 | **Imperative** | Rules start with verbs — "Cut", "Name", "Check" (§3.1) |
| C5 | **Domain** | Examples and rules specific to the skill's domain, not generic advice |
| C6 | **IDs** | Consistent numbered IDs in `N.N` format (§4.1–4.2) |
| C7 | **Self-Demo** | The skill itself follows the format it teaches |

---

## Results (descending by score)

| Rank | Skill | Path | C1 | C2 | C3 | C4 | C5 | C6 | C7 | Total | Notes |
|------|-------|------|----|----|----|----|----|----|----|-------|-------|
| 1 | reflect | agent/reflect/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Textbook conformity. Motivated-reasoning failure mode. Used as example in skill skill itself. |
| 2 | design | eng/design/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Full Define (1.1–1.3), 7 sections building from problem to ACs, impact-graph examples. |
| 3 | review | eng/review/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Issue-contract → diff → context → verdict progression. Finding taxonomy. |
| 4 | documenting | documenting/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Claim/source/verification formula. Style section eats its own dog food. |
| 5 | issue | pm/issue/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Symptoms/impact/acceptance formula. Define through after-handoff progression. |
| 6 | adhoc-thread | ops/adhoc-thread/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Trigger/type/content parts. Under-capture vs over-capture failure modes. |
| 7 | release | release/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Readiness/version/artifacts/deployment parts. Version-drift failure mode. |
| 8 | coding | eng/coding/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | "Unintended behavior is unrepresentable." Types → functions → modules → boundaries. |
| 9 | mca | agent/mca/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Smallest-intervention formula. Identify → scope → act → verify. |
| 10 | mci | agent/mci/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Smallest-learning formula. Identify → scope → capture → migrate. |
| 11 | coherent | agent/coherent/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Claims/sources/dependencies. Internal + external alignment. |
| 12 | cap | agent/cap/ | 2 | 2 | 2 | 2 | 2 | 2 | 2 | **14** | Gap → two paths → priority → loop. Named failure mode. |
| 13 | cbp | agent/cbp/ | 2 | 2 | 2 | 2 | 2 | 2 | 1 | **13** | Full content conformity. Top-level headers are PLUR not Define/Unfold/Rules — domain-native structure. |
| 14 | cdd | ops/cdd/ | 2 | 2 | 2 | 2 | 2 | 2 | 1 | **13** | Comprehensive and domain-specific. 660+ lines strains the high-alpha principle slightly. |
| 15 | eng/testing | eng/testing/ | 1 | 2 | 1 | 1 | 2 | 1 | 1 | **9** | Good domain specificity. Strategy → cram → unit → coverage. IDs inconsistent, mixed format. |
| 16 | functional | eng/functional/ | 1 | 2 | 1 | 1 | 2 | 1 | 1 | **9** | OCaml/FP specific. Code-block examples instead of ❌/✅. Mixed voice. |
| 17 | eng/ship | eng/ship/ | 1 | 2 | 2 | 1 | 2 | 0 | 1 | **9** | Strong domain content. Feature/bug-fix/versioning flows. No numbered IDs. |
| 18 | post-release | ops/post-release/ | 1 | 2 | 1 | 1 | 2 | 1 | 1 | **9** | Procedural skill. Anti-patterns at end. Missing formal Define. Partial IDs. |
| 19 | human-interaction | agent/human-interaction/ | 1 | 1 | 1 | 2 | 2 | 0 | 0 | **7** | Good imperative voice. Do/don't tables. No Define, no IDs, not skill format. |
| 20 | communicating | agent/communicating/ | 1 | 1 | 1 | 2 | 2 | 0 | 0 | **7** | Strong imperative voice. Intra-team/external specific. No coherence formula, no IDs. |
| 21 | agent-ops | agent/agent-ops/ | 0 | 1 | 1 | 1 | 2 | 0 | 0 | **5** | Reference doc with RACI section. Domain-specific. No formula, no IDs. |
| 22 | ca-conduct | agent/ca-conduct/ | 0 | 1 | 0 | 2 | 2 | 0 | 0 | **5** | PLUR conduct code. Strong imperative voice. Manifesto, not skill format. |
| 23 | inbox | ops/inbox/ | 1 | 1 | 0 | 1 | 2 | 0 | 0 | **5** | Actor-model semantics. Reference doc more than coherence-formula skill. |
| 24 | pm/ship | pm/ship/ | 0 | 1 | 1 | 1 | 2 | 0 | 0 | **5** | PM branch workflow. Rules table with why column. No formula, no IDs. |
| 25 | rca | eng/rca/ | 0 | 1 | 0 | 1 | 2 | 0 | 0 | **4** | Incident analysis. Process steps + anti-patterns. Arrow format not ❌/✅. |
| 26 | follow-up | pm/follow-up/ | 0 | 1 | 0 | 1 | 2 | 0 | 0 | **4** | PM cadence. Anti-pattern table. Procedural, not coherence-formula format. |
| 27 | ocaml | eng/ocaml/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | Strong OCaml reference (dune, FFI). Pure reference doc, no skill format at all. |
| 28 | ux-cli | eng/ux-cli/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | Terminal UX reference with color/symbol tables. Declarative, no skill structure. |
| 29 | tool-writing | eng/tool-writing/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | Bash tool conventions. Template-driven. No formula, declarative bullets. |
| 30 | testing (root) | testing/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | cnos testing. Minimal structure. Short reference doc. |
| 31 | peer | ops/peer/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | Peering protocol. TERMS/INPUTS/EFFECTS. Operational runbook. |
| 32 | self-cohere | agent/self-cohere/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | Hub-wiring runbook. Sequential steps. No formula, no examples. |
| 33 | configure-agent | agent/configure-agent/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | Agent personalization interview. No formula, no examples, no IDs. |
| 34 | onboarding | agent/onboarding/ | 0 | 1 | 0 | 0 | 2 | 0 | 0 | **3** | New-agent setup checklist. Procedural, no skill format. |
| 35 | coherence-test | agent/coherence-test/ | 0 | 1 | 0 | 0 | 1 | 0 | 0 | **2** | Quiz/exam format, not a skill. No formula, no IDs, no paired examples. |
| 36 | hello-world | agent/hello-world/ | 0 | 0 | 0 | 0 | 1 | 0 | 0 | **1** | Minimal stub (17 lines). TERMS/EFFECTS only. Defers to kata.md. |
| 37 | star-sync | ops/star-sync/ | 0 | 0 | 0 | 0 | 1 | 0 | 0 | **1** | Minimal operational spec (18 lines). TERMS/INPUTS/EFFECTS only. |

---

## Distribution

| Score Range | Count | % |
|-------------|-------|---|
| 14 (full) | 12 | 32% |
| 13 | 2 | 5% |
| 7–9 | 6 | 16% |
| 3–5 | 14 | 38% |
| 1–2 | 3 | 8% |

## Key Findings

1. **Bimodal distribution** — skills either fully conform (14/14) or largely don't (≤9). Almost nothing in between. The skill skill format was adopted deliberately where applied, not partially everywhere.

2. **Top tier (14/14)** — 12 skills demonstrate textbook conformity: Define with parts + fit + failure mode, Unfold with progressive sections, Rules with imperative voice and paired ❌/✅ examples, consistent numbered IDs.

3. **Biggest gap: operational runbooks** — skills like peer, star-sync, self-cohere, configure-agent, and hello-world are procedural "do X then Y" docs, not coherence-formula skills. They may benefit from the skill skill format, or they may be a different document type entirely.

4. **Reference docs vs skills** — ocaml, tool-writing, ux-cli, and root testing are reference material. Converting them to skill skill format would mean finding their coherence formula (what makes good OCaml code coherent? what makes a good CLI tool coherent?).

5. **Quick wins** — eng/ship (9/14), eng/testing (9/14), functional (9/14), and post-release (9/14) are closest to conformity and would need the least work to reach 14/14: add formal Define sections, switch to consistent N.N IDs, and convert examples to ❌/✅ format.
