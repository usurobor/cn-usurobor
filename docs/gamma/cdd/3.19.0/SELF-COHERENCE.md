## Self-Coherence Report — v3.19.0

**Issue:** #113 AC5-AC7
**Mode:** MCA
**Active skills:** eng/ocaml, eng/testing, eng/coding
**Self-review date:** 2026-03-26

---

### Triad Scores

| Axis | Score | Rationale |
|------|-------|-----------|
| α (PATTERN) | B+ | Integrity hash uses OCaml stdlib Digest (md5) — deterministic, no external deps. Tree-hash design (sorted paths + content hashes → combined hash) is structurally clean. Doctor validates the full desired→resolved→installed chain. Runtime Contract type expanded with provenance fields. Integrity prefix "md5:" allows future algorithm migration. |
| β (RELATION) | B+ | All three ACs connect: lock generation → integrity hash → restore verification → doctor validation → Runtime Contract exposure. Single hash truth flows from lock through install to agent self-model. Doctor now checks manifest↔lockfile↔installed consistency, metadata validity, integrity, and stale installs. |
| γ (EXIT/PROCESS) | B | Skills declared and applied: eng/ocaml (Digest stdlib, nested match parens, type expansion), eng/testing (invariant-named tests I6-I8, negative/tamper cases), eng/coding (minimal changes, no scope creep). No OCaml toolchain means mechanical findings are likely. |

### AC Evidence

| AC | Claim | Evidence |
|----|-------|----------|
| AC5 | Integrity generated and verified | `compute_integrity` computes md5 tree hash. `lockfile_for_manifest` populates integrity field from local package source. `restore_one` verifies after install (both paths) and on already-installed check. `verify_integrity` returns Error on mismatch — tampered packages rejected and removed. Tests: I6 (deterministic, format, differs on change, None for missing), I7 (passes correct, fails wrong, skips None), I8 (lock generation includes integrity). |
| AC6 | Doctor validates package-system truth | `cn_deps.doctor` expanded: manifest parseable, lockfile parseable, manifest→lockfile presence, lockfile→installed presence, cn.package.json validity and name consistency, integrity verification, stale install detection (installed but not in lockfile). `cn_system.run_doctor` integrates via new "package system" check. |
| AC7 | Runtime Contract package truth complete | `package_info` type expanded with `source`, `rev`, `integrity` fields. `gather` reads lockfile for provenance. Markdown renders integrity when present. JSON includes source, rev, and conditional integrity. Tests: gather provenance from lockfile, to_json includes source/rev/integrity. |

### Findings (Self-Review)

| # | Type | Finding | Resolution |
|---|------|---------|------------|
| 1 | Mechanical | Nested match in `verify_integrity` needs parentheses | Fixed — added `( ... )` around inner match |
| 2 | Judgment | Used `Str.regexp_string` in test — unnecessary dependency | Replaced with inline `has_sub` helper, removed `str` from dune deps |
| 3 | Judgment | md5 is weak for adversarial tampering | Acceptable for drift detection. Prefix "md5:" allows future algorithm migration. Package system is local-only (no registry), so adversarial tampering is not the threat model. |
| 4 | Mechanical | `collect_files_sorted` shares structure with test helper `collect_files` | Different modules, slightly different signatures. Not worth abstracting for two uses. |

### Active Skill Compliance

- **eng/ocaml:** Digest is stdlib (no new deps). Nested match guarded with parens. Type change propagated through all three layers (gather/render/to_json). No unused variables.
- **eng/testing:** Invariant-named tests (I6-I8). Negative cases (tamper detection, missing dir). Determinism verified (same content → same hash). Format assertion (md5: prefix).
- **eng/coding:** Minimal footprint — 3 new functions in cn_deps.ml (compute_integrity, verify_integrity, collect_files_sorted), 1 type expansion in cn_runtime_contract.ml, 1 doctor deepening, 1 cn_system.ml integration. No scope creep.

### Known Gaps

1. **No OCaml toolchain** — cannot verify compilation or run tests locally. Mechanical findings likely in first review round.
2. **Doctor test coverage** — doctor depth tested implicitly through cn_deps_test invariants, but no dedicated doctor-specific test with a mock hub (would require significant scaffolding).
3. **md5 algorithm** — adequate for drift detection, not for adversarial integrity. Future: migrate to sha256 when crypto library is added to deps.
