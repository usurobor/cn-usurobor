# CDD — Topic Bundle

How cnos develops itself coherently.

**Version:** 3.15.0
**Status:** Draft
**Doc-Class:** topic-bundle
**Canonical-Path:** `docs/gamma/cdd/README.md`
**Owns:** the development method, its rationale, its reference workflow profile, and post-release assessment history
**Does-Not-Own:** runtime doctrine, feature design specs, release mechanics in detail

---

## Purpose

This bundle owns Coherence-Driven Development as a method.

Read this bundle when you need to know:

- how work is selected
- what artifacts a substantial change must produce
- what is mechanical vs judgment-bearing
- how release feeds back into assessment and the next cycle

---

## Reading Order

1. [`CDD.md`](./CDD.md) — canonical algorithm spec
2. [`RATIONALE.md`](./RATIONALE.md) — why the method takes this shape
3. [`AGILE-PROCESS.md`](./AGILE-PROCESS.md) — reference workflow profile for a small async team
4. epoch assessments — release-scale measurement history

---

## Document Map

| Document | Class | Description |
|----------|-------|-------------|
| [CDD.md](./CDD.md) | Canonical spec | Normative CDD algorithm: observe → select → execute → assess → close |
| [RATIONALE.md](./RATIONALE.md) | Companion rationale | Why CDD is closed-loop, artifact-driven, and not fully mechanical |
| [AGILE-PROCESS.md](./AGILE-PROCESS.md) | Reference profile | Small-team async workflow profile compatible with CDD |
| [POST-RELEASE-EPOCH-v3.12.md](./POST-RELEASE-EPOCH-v3.12.md) | Assessment | Epoch assessment: v3.12.0–v3.12.2 |
| [POST-RELEASE-EPOCH-v3.14.md](./POST-RELEASE-EPOCH-v3.14.md) | Assessment | Epoch assessment: v3.14.0–v3.14.5 |

---

## Related operational docs

- `src/agent/skills/ops/cdd/SKILL.md` — executable summary
- `src/agent/skills/ops/post-release/SKILL.md` — assessment procedure
- `src/agent/skills/eng/review/SKILL.md` — review protocol
- `src/agent/skills/eng/design/SKILL.md` — design protocol
- `src/agent/skills/release/SKILL.md` — release procedure

---

## Version History

| Version | Directory | Highlights |
|---------|-----------|------------|
| v3.14.6 | [3.14.6/](3.14.6/) | Epoch 2 addendum: v3.14.3–v3.14.5 coverage |
| v3.14.5 | [3.14.5/](3.14.5/) | Gamma root migration; AGILE-PROCESS joins the bundle |
| v3.14.4 | [3.14.4/](3.14.4/) | Beta reorg and freeze-semantics note |
