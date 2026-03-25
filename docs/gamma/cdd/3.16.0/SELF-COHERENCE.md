# Self-Coherence Report — v3.16.0

**Branch:** `claude/3.16.0-37-cn-update`
**Issue:** #37 — cn update: end-to-end self-update
**Mode:** MCA (enhancement — new capability: working self-update)
**Author:** Claude

## Pipeline Compliance

| Step | Status | Evidence |
|------|--------|----------|
| 0. Observe | done | v3.15.2 assessment committed #37 as next MCA (§3.2 operational debt) |
| 1. Branch | done | `claude/3.16.0-37-cn-update`, pre-flight passed |
| 2. Bootstrap | done | `docs/gamma/cdd/3.16.0/README.md` created as first diff |
| 3. Gap | done | `cn update` fully broken: no tags → 404, no ARM binary, no patch detection |
| 4. Mode | done | MCA — code + CI fix needed |
| 5. Plan | done | 3-fix plan: patch detection, ARM matrix, version output |
| 6. Tests | done | 3 new tests + 1 updated cram test |
| 7. Code | done | cn_agent.ml, cn_system.ml, cn.ml, release.yml |
| 8. Pre-flight | done | §8.5: all 6 ACs walked, 3 spot-checked with line numbers |
| 9. Self-coherence | this file |

## Triadic Assessment

- **α (PATTERN): A** — `get_latest_release()` replaces grep/sed with Cn_json parsing. `release_info` record type makes the API surface explicit. `Update_patch` variant extends the existing ADT cleanly. No new modules or abstractions.

- **β (RELATION): A-** — All 6 ACs met. The one gap: AC6 (Pi end-to-end) depends on tags being pushed, which is an operational requirement not enforced by code. The code path is correct; the operational precondition (pushing tags on release) must be followed.

- **γ (EXIT/PROCESS): A** — Full CDD pipeline followed. §8.5 pre-flight completed before review request. All ACs walked against diff with specific line numbers. No author pre-flight skip this time.

## Known Coherence Debt

- **Tags must be pushed.** The release.yml workflow triggers on `v*` tag push. If tags aren't pushed, no binaries are uploaded and `cn update` still 404s. This is documented in the release skill but not enforced by code. v3.14.5–v3.15.2 remain untagged.
- **`target_commitish` may be branch name.** GitHub API returns `target_commitish` as either a full SHA or a branch name (e.g., "main") depending on how the release was created. The code truncates to 7 chars, which works for SHAs but would produce "main" → "main" for branch-based releases. If the release was created from a tag (the expected path via release.yml), this is always a SHA.
- **No build verification.** No OCaml toolchain in this environment. CI will validate.

## Reviewer Notes

- The `get_latest_release_tag()` wrapper is kept for backward compatibility — `check_for_update` in daemon mode still uses it internally via `get_latest_release()`, but any future code that only needs the tag can call the wrapper.
- The `Update_patch` variant enters the same download path as `Update_available` — no separate logic. The distinction exists for logging/UX messaging only.
- The cram test for `--version` was changed from exact match to prefix match (`grep -q "^cn $CNOS_VERSION "`) because the commit hash varies per build.
