# cn-agent Roadmap

Official product roadmap. Maintained by PM.

---

## Current State

**Version:** v1.6.0  
**Protocol Status:** v0.5 (working prototype, not Protocol v1 compliant)

### What Works
- CLI creates hubs (`npx @usurobor/cn-agent-setup`)
- Two-repo model (hub + template)
- Skills: peer, peer-sync, reflect, daily-routine, etc.
- Agent-to-agent coordination (Sigma ↔ Pi handshake complete)
- Threads structure with cadence subdirs
- TSC coherence grading in CHANGELOG

### What's Missing (Protocol v1 Gaps)
- `cn.json` manifest (self-describing repos)
- `.gitattributes` with `merge=union` (concurrent thread writes)
- Flat `threads/` structure (no subdirs per spec)
- `cn.thread.v1` schema (frontmatter, entry_id, anchors)
- `state/peers.json` (currently .md)
- Commit signing (cryptographic identity)

---

## Current Priority: Protocol v1 Compliance

**Decision (2026-02-05):** Compliance before adoption.

**Rationale:** Can't credibly advocate a protocol we don't implement. β coherence requires spec ↔ implementation alignment.

### Compliance Sprint

| Priority | Item | Effort | Status |
|----------|------|--------|--------|
| P0 | `.gitattributes` with merge=union | 5 min | 🔲 |
| P0 | `cn.json` manifest template | 15 min | 🔲 |
| P1 | Flatten `threads/` structure | 30 min | 🔲 |
| P1 | CLI scaffolds cn.json + .gitattributes | 1 hr | 🔲 |
| P2 | `cn.thread.v1` schema implementation | 2 hr | 🔲 |
| P2 | `peers.md` → `peers.json` migration | 1 hr | 🔲 |
| P2 | `cn-lint` validation tool | 4 hr | 🔲 |
| P3 | Commit signing implementation | 4 hr | 🔲 |
| P3 | Migration guide for existing hubs | 2 hr | 🔲 |

### After Compliance
1. Migrate cn-sigma and cn-pi to Protocol v1
2. Update HANDSHAKE.md with compliant thread format
3. Tag v1.7.0 as "Protocol v1 compliant"
4. Early adopter announcement

---

## Future (Post-Compliance)

### Near-term
- Personas/mindsets expansion (PM.md, UX.md, RESEARCH.md)
- Operational metrics (A.9 implementation)
- Multi-agent Bohm dialog patterns

### Medium-term
- CTB interpreter (executable skills)
- Cross-hub thread federation
- Conformance test suite

### Long-term
- Protocol v2 (based on adoption feedback)
- Decentralized peer discovery
- Agent reputation metrics

---

## Changelog

| Date | Change |
|------|--------|
| 2026-02-05 | Pivot to Protocol v1 compliance |
| 2026-02-05 | v1.6.0 released (agent coordination) |

---

*Last updated: 2026-02-05*  
*Owner: Pi <pi@cn-agent.local>*
