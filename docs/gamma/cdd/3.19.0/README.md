## v3.19.0 — Package System Substrate: integrity, doctor depth, Runtime Contract truth

**Issue:** #113 (AC5-AC7)
**Branch:** claude/3.19.0-113-integrity-doctor-rc
**Mode:** MCA
**Active skills:** eng/ocaml, eng/testing, eng/coding

### Gap

The package system has honest lockfiles and path-consistent restore (v3.18.0), but:
- Integrity is modeled without enforcement — lockfile entries carry `integrity = None`, restore never verifies
- Doctor checks presence without consistency — no lockfile-vs-installed validation, no integrity checks, no drift detection
- Runtime Contract package truth is incomplete — surfaces name/version/counts but not source/rev/integrity

### Coherence contract

- **α target:** integrity is computed, stored, and verified — one hash truth from lock through install
- **β target:** doctor validates the full package system chain (desired → resolved → installed), not just file presence
- **γ target:** Runtime Contract exposes authoritative package truth so the agent's self-model matches installed reality

### Acceptance criteria (this cycle)

| AC | Description | Evidence |
|----|-------------|----------|
| AC5 | Integrity is generated and verified | Lock entries carry sha256 hash; restore verifies; tampered package rejected |
| AC6 | Doctor validates package-system truth | desired vs resolved, installed vs lockfile, integrity, metadata validity |
| AC7 | Runtime Contract wake-time package truth is complete and authoritative | Package info includes source, rev, integrity; agent sees full lock state |

### Deferred (not this cycle)

| AC | Description | Rationale |
|----|-------------|-----------|
| AC1 | Package publication/retrieval coherently Git-native | Already met by existing Git fetch |
| AC2 | Desired/resolved state explicit and deterministic | Already met by deps.json/deps.lock.json |
| AC3 | Restore installs full package content | Shipped in v3.18.0 |
| AC4 | Third-party handling explicit | Shipped in v3.18.0 |
| AC8 | Extensions/bundles sit above substrate without redesign | Validated by existing extension architecture |

### Deliverables

- `src/cmd/cn_deps.ml` — integrity hash computation in lock generation, verification in restore
- `src/cmd/cn_deps.ml` — doctor depth: lockfile-vs-installed consistency checks
- `src/cmd/cn_runtime_contract.ml` — package truth expansion (source, rev, integrity)
- `test/cmd/cn_deps_test.ml` — integrity generation, verification, tamper detection tests
- `test/cmd/cn_system_test.ml` or inline — doctor validation tests
- `docs/gamma/cdd/3.19.0/SELF-COHERENCE.md` — self-coherence report
