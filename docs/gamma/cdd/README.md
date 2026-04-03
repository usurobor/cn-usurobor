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

1. [`OVERVIEW.md`](./OVERVIEW.md) — plain-language introduction: what CDD is, why it exists, what one cycle looks like
2. [`CDD.md`](./CDD.md) — canonical algorithm spec
3. [`RATIONALE.md`](./RATIONALE.md) — why the method takes this shape
4. epoch assessments — release-scale measurement history

---

## Document Map

| Document | Class | Description |
|----------|-------|-------------|
| [OVERVIEW.md](./OVERVIEW.md) | Introduction | Plain-language explanation of CDD for humans new to the method |
| [CDD.md](./CDD.md) | Canonical spec | Normative CDD algorithm: observe → select → execute → assess → close |
| [RATIONALE.md](./RATIONALE.md) | Companion rationale | Why CDD is closed-loop, artifact-driven, and not fully mechanical |
| [POST-RELEASE-EPOCH-v3.12.md](./POST-RELEASE-EPOCH-v3.12.md) | Assessment | Epoch assessment: v3.12.0–v3.12.2 |
| [POST-RELEASE-EPOCH-v3.14.md](./POST-RELEASE-EPOCH-v3.14.md) | Assessment | Epoch assessment: v3.14.0–v3.14.5 |

---

## Related operational docs

- `src/agent/skills/cdd/SKILL.md` — executable summary (skill)
- `src/agent/skills/cdd/design/SKILL.md` — design protocol (skill)
- `src/agent/skills/cdd/review/SKILL.md` — review protocol (skill)
- `src/agent/skills/cdd/release/SKILL.md` — release procedure (skill)
- `src/agent/skills/cdd/post-release/SKILL.md` — assessment procedure (skill)
- `src/agent/skills/cdd/plan/SKILL.md` — implementation plan production (runbook)
- `src/agent/skills/cdd/issue/SKILL.md` — issue writing (runbook)

---

## Version History

| Version | Directory | Highlights |
|---------|-----------|------------|
| v3.15.2 | [3.15.2/](3.15.2/) | CDD canonical rewrite (v3.15.0 method state), RATIONALE.md created, authority split resolved, review/release skill hardened, empty Telegram filter (#29) |
| v3.15.0 | [3.15.0/](3.15.0/) | Version coherence (#22): VERSION-first flow, stamp-versions.sh |
| v3.14.7 | [3.14.7/](3.14.7/) | Review pre-flight, scope enumeration, review quality metrics |
| v3.14.6 | [3.14.6/](3.14.6/) | Epoch 2 addendum: v3.14.3–v3.14.5 coverage |
| v3.14.5 | [3.14.5/](3.14.5/) | Gamma root migration; AGILE-PROCESS joins the bundle |
| v3.14.4 | [3.14.4/](3.14.4/) | Beta reorg and freeze-semantics note |
