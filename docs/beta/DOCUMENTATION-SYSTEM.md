# Documentation System

How the docs/ tree is organized and how documents evolve.

**Version:** 1.0.0
**Date:** 2026-03-13

---

## 1. Taxonomy

The docs tree unfolds along the three ontological axes of coherence. Each document has a dominant axis.

| Directory | Axis | Question it answers |
|-----------|------|-------------------|
| (root) | The whole | What is cnos? (`THESIS.md`) How to read these docs? (`README.md`) |
| `alpha/` | **Pattern** | What has been articulated? Doctrine, specs, definitions, protocol. |
| `beta/` | **Relation** | Do the parts reveal one system? System overview, vocabulary, guides, evidence. |
| `gamma/` | **Evolution** | How does it change? Method, plans, checklists. |

### Root-level documents

- **THESIS.md** — the whole, above the triad. Always the entry point.
- **README.md** — reading guide and navigation for the docs tree.

---

## 2. Document classes

### Canonical documents

Evolve in place. Never forked into versioned copies.

- Keep a version in the header
- Accumulate patch notes or version history internally
- Remain the single source of truth for their scope

Examples: THESIS.md, COHERENCE-SYSTEM.md, CAA.md, AGENT-RUNTIME.md, TRACEABILITY.md, CDD.md.

### Episodic documents

Capture a specific coherence delta. Scoped to a release, incident, or bounded effort.

- Live in `plans/` or `evidence/`
- Filename encodes the scope (e.g., `PLAN-v3.6.0.md`, `2026-02-07-wake-failure.md`)
- May reference canonical docs but never duplicate them

### Reference documents

Stable lookup material. Updated when terminology or conventions change, not per release.

Examples: GLOSSARY.md, NAMING.md.

---

## 3. Versioning rules

### When to version-bump a canonical doc

| Change | Version bump |
|--------|-------------|
| Wording, examples, typos | Patch (e.g., 1.0.0 → 1.0.1) |
| New section, additive capability | Minor (e.g., 1.0.0 → 1.1.0) |
| Scope change, structural rewrite, removed sections | Major (e.g., 1.0.0 → 2.0.0) |

### Supersession

When a canonical document is fully replaced:
2. The new document carries its own version starting at 1.0.0

Do not maintain parallel "v1" and "v2" files in active directories.

---

## 4. Placement rules

When adding a new document, ask: **what is its dominant ontological character?**

1. **Does it articulate substance?** (doctrine, spec, definition, protocol) → `alpha/`
2. **Does it define relation?** (how parts connect, vocabulary, operator connection, model↔reality evidence) → `beta/`
3. **Does it govern movement?** (method, process, plans, gates) → `gamma/`

Within each axis:
- `β/guides/` — task-oriented procedures (operator ↔ system relation)
- `β/evidence/` — audits, RCAs (model ↔ reality relation)
- `γ/plans/` — ephemeral implementation plans
- `γ/checklists/` — release gate verification

If it doesn't fit any axis, the taxonomy may need to evolve — but update this document before creating new structure.

---

## 5. Relationship to the coherence loop

The docs tree is itself an articulation of coherence. Its structure is triadic: α (pattern), β (relation), γ (evolution).

The reading order for CMP:

1. `THESIS.md` — the whole
2. `alpha/` — what has been articulated?
3. `beta/` — do the parts cohere?
4. `gamma/` — how does it move?

This is the MCP formation sequence. If a document disrupts this order — if a reader must cross axes to form a coherent picture — the document is probably on the wrong axis.
