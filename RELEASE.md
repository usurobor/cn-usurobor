# RELEASE.md

## Outcome

Coherence delta: C_Σ A- (`α A`, `β A`, `γ B+`) · **Level:** `L6`

Legacy fallback paths in src/ systematically audited and eliminated. 29 findings classified — 7 removed (dead code), 7 justified keeps (fail-closed), 15 silent exception swallows converted to warning-logged fallbacks. Zero bare `with _ ->` remains in any touched file. CDD bundle fully normalized. Design docs landed for thread event model and hub placement models.

## Why it matters

Silent fallback paths mask real failures. `run_inbound` was 120+ lines of dead code reachable only through a deprecated CLI path. Flat hub-path loaders could silently load skills into the wrong namespace. 15 `with _ ->` sites swallowed I/O errors — permission failures, missing directories, corrupt state — returning empty defaults with no diagnostic trace. Converting these to logged warnings preserves graceful degradation while making failures visible.

## Fixed

- **Legacy path audit** (#152): 29-row audit table covering all touched src/cmd files. 7 dead-code paths removed (~185 lines), 15 silent swallows converted to `Printf.eprintf` warnings, 7 legitimate patterns justified as fail-closed keeps.

## Added

- **Thread event model design** (#153): `docs/alpha/protocol/THREAD-EVENT-MODEL.md` v1.0.1 — canonical ID vs locator split, parent-linked publication, Git-first transport-flexible.
- **Hub placement models design** (#156): `docs/alpha/HUB-PLACEMENT-MODELS.md` — split `hub_root`/`workspace_root` for sandboxed agents, nested clone as default backend.
- **Implementation plans**: thread event model (`docs/gamma/cdd/3.32.0/PLAN-thread-event-model.md`), hub placement models (`docs/gamma/cdd/3.33.0/PLAN-hub-placement-models.md`).

## Changed

- **CDD bundle normalization**: all 7 skill artifacts have `artifact_class`, `kata_surface`, `governing_question`. Descriptions sharpened. Kata sections expanded to Scenario/Task/Verification/Common failures format. Package copies synced.

## Removed

- **`run_inbound`**, **`feed_next_input`**, **`wake_agent`** from `cn_agent.ml` — dead since v3.27, no CLI path reached them.
- **`hub_flat_mindsets_path`**, **`hub_flat_skills_path`** + loader blocks from `cn_assets.ml` — package namespace is the only layout since v3.25.

## Validation

- Deployed to Pi (`143.198.14.19`), validated `cn --version` reports 3.32.0.
- `cn deps restore` completes, skills load from package namespace only.
- `cn sync` succeeds — no regression in peer transport.

## Known Issues

- 21 `with _ ->` sites remain in 7 untouched src/cmd files — standard defensive I/O, not legacy fallback. Documented in audit scope section.
- #155 — `cn deps restore` shallow-fetch fallback for sandboxed environments.
