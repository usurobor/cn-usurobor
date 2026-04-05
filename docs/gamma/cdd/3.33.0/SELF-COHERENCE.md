## Self-Coherence Report -- v3.33.0

**Issue:** #158 -- Redesign install.sh to match tsc v0.3.0 installer pattern

### Alpha (type-level clarity)

Shell script -- no type system. Structural clarity assessed instead:

- Every variable is named, scoped, and used exactly once or in a clear pipeline
- `TMPFILE` has a clear lifecycle: empty -> mktemp -> download target -> mv (cleared) or cleanup (deleted)
- `fail()` takes cause as $1, rest as detail lines -- consistent calling convention
- Color variables: RED/GREEN/YELLOW/RESET, gated by NO_COLOR/TTY check
- Platform detection: two independent case blocks (OS, ARCH) -> single TARGET string

**Alpha score: A** -- Clean variable naming, single-responsibility functions, no ambiguous state.

### Beta (authority surface agreement)

| Surface | Before | After | Agreement |
|---------|--------|-------|-----------|
| install.sh structure | Flat script, no helpers | UX helpers + cleanup trap + structured sections | yes |
| Download path | Direct to `${BIN_DIR}/cn` | Temp file + atomic `mv` | yes |
| Error format | "Error: ..." (non-actionable) | cause -> fix -> rerun (every fail site) | yes |
| Platform detection | Separate OS/ARCH cases, silent fallthrough possible | Explicit fail with build-from-source for unknown OS or ARCH | yes |
| Color/TTY | Not handled | NO_COLOR + non-TTY detection | yes |
| Symbol language | None | checkmark/warning/x consistent with tsc | yes |
| Verification | `cn --version` at end | Same (preserved) | yes |
| README.md | Documents tsc pattern port | Matches actual code structure | yes |

**Beta score: A** -- All surfaces agree. No stale references.

### Gamma (cycle economics)

- Lines before: 80 (install.sh)
- Lines after: 155 (install.sh)
- Net: +75 lines (all new UX/safety infrastructure)
- Every added line serves an AC: cleanup trap (AC4), size check (AC2), actionable errors (AC3), color gating (AC5), platform rejection (AC6), symbols (AC7)
- No dead code added

### Pointers

| What | Where |
|------|-------|
| Installer | install.sh |
| tsc reference | https://github.com/usurobor/tsc/blob/main/install.sh |
| CDD bootstrap | docs/gamma/cdd/3.33.0/README.md |

### Triadic Coherence Check

1. **Does every AC have corresponding code?**
   - AC1: mktemp + mv (lines ~108-110, ~133-143)
   - AC2: wc -c + MIN_SIZE comparison (lines ~115-130)
   - AC3: every fail() call has cause + fix + rerun (7 call sites)
   - AC4: trap cleanup EXIT INT TERM (line ~44)
   - AC5: NO_COLOR / TTY check (lines ~23-27)
   - AC6: OS and ARCH case blocks with explicit fail (lines ~64-90)
   - AC7: ok() uses checkmark (line ~31)
   - AC8: `${BIN_DIR}/${BINARY_NAME} --version` (last line)

2. **Does the cnos installer match the tsc pattern structurally?** Yes. Same section order, same function signatures, same error format. Only differences are binary name, repo, platform matrix, and build-from-source instructions.

3. **Are there any silent failure paths?** No. Every error calls `fail()` which exits with code 1. The `|| true` after release fetch is deliberate -- the empty-check on $LATEST catches the failure and calls fail(). The `2>/dev/null` on mv is deliberate -- the mv failure is caught and reported with actionable fix.

### Exit Criteria

- [x] AC1: Atomic install (temp file + mv)
- [x] AC2: Size check (< 1 MB rejected)
- [x] AC3: Actionable errors (7 fail sites, all cause -> fix -> rerun)
- [x] AC4: Cleanup trap (EXIT + INT + TERM)
- [x] AC5: NO_COLOR + non-TTY detection
- [x] AC6: Explicit platform rejection with build-from-source
- [x] AC7: Checkmark/warning/x symbols
- [x] AC8: cn --version verification
