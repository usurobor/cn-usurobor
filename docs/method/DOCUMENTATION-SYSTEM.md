# Documentation System

How the docs/ tree is organized and how documents evolve.

**Version:** 1.0.0
**Date:** 2026-03-13

---

## 1. Taxonomy

Each directory in docs/ has a defined role. Documents live where their role says they belong.

| Directory | Role | Question it answers |
|-----------|------|-------------------|
| (root) | Entry points | What is cnos? How do I read these docs? |
| `foundations/` | Why | Doctrine, values, meta-model, system thesis |
| `architecture/` | What | Structural specs, protocol, runtime, security, observability |
| `method/` | How it evolves | Development method, process, checklists, this document |
| `plans/` | Current intentions | Ephemeral: implementation plans for specific releases |
| `evidence/` | What happened | RCAs, audits, operational proof surfaces |
| `guides/` | How to do things | Task-oriented procedures for operators and contributors |
| `reference/` | Lookup | Stable terminology, naming conventions, schemas |

### Root-level documents

- **THESIS.md** — the one answer to "what is cnos?" Always the entry point.
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

When adding a new document, ask:

1. **Does it define what cnos is or why?** → `foundations/`
2. **Does it specify structure, protocol, or runtime behavior?** → `architecture/`
3. **Does it define how the system evolves or how work is done?** → `method/`
4. **Is it scoped to a specific release or bounded effort?** → `plans/`
5. **Does it record what happened in operation?** → `evidence/`
6. **Is it a step-by-step procedure?** → `guides/`
7. **Is it stable lookup material?** → `reference/`

If it doesn't fit, the taxonomy may need to evolve — but add the category explicitly here before creating a new directory.

---

## 5. Relationship to the coherence loop

The docs tree is α — the articulated substance of the system. Its structure should support CMP (forming the most coherent picture).

The reading order for CMP maps to the taxonomy:

1. `THESIS.md` — what is this system?
2. `foundations/` — why does it exist?
3. `architecture/` — how is it built?
4. `method/` — how does it change?
5. `evidence/` — what happened last time?
6. `plans/` — what is it doing now?

This is the MCP formation sequence. If a document disrupts this reading order — if a reader has to jump categories to form a coherent picture — the document is probably in the wrong place.
