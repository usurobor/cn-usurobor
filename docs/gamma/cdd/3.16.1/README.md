# v3.16.1 — Daemon retry limit and dead-letter

**Issue:** #28
**Branch:** `claude/3.16.1-28-daemon-retry-limit`
**Mode:** MCA (bugfix — daemon retries failed triggers forever)
**Scope:** Retry limit with exponential backoff, dead-letter for permanently failed triggers, 4xx fail-fast, offset advancement after dead-lettering

## Frozen Artifacts

| Artifact | File | Status |
|----------|------|--------|
| Snapshot manifest | `README.md` (this file) | complete |
| Self-coherence report | `SELF-COHERENCE.md` | complete |
