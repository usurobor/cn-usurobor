# Agile Process for cnos

**Version:** 1.1.0
**Status:** Draft
**Doc-Class:** reference-profile
**Canonical-Path:** `docs/gamma/cdd/AGILE-PROCESS.md`
**Owns:** one small-team async workflow profile compatible with CDD
**Does-Not-Own:** the canonical CDD algorithm

---

## Scope note

This document is a reference workflow profile for a small async agent team. CDD is normative. This document is one valid implementation profile of CDD.

It is optimized for:

- async collaboration
- Git-native work-in-progress
- minimal ceremony for a very small team

If another team keeps the CDD artifact contract, gate, assessment, and closure logic intact, it may use a different workflow profile.

---

## Overview

This profile assumes:

- work is selected through CDD
- branches carry the work
- review happens before merge
- release and assessment still follow CDD

What this document adds is a lightweight team-state model.

---

## Workflow states

```text
Backlog → Claimed → In Progress → Review → Done
```

| State | Where it lives | Who owns it |
|-------|----------------|-------------|
| Backlog | backlog surface | PM / coordinator |
| Claimed | branch exists | engineer / agent |
| In Progress | commits on branch | engineer / agent |
| Review | branch pushed, review requested | reviewer + author |
| Done | merged to main | system |

---

## Priority bands

Use a simple priority structure:

- P0 — unblockers
- P1 — operational reliability
- P2 — protocol / contract compliance
- P3 — features

CDD selection still governs what work should start. This profile only constrains how queued work is organized.

---

## Relationship to CDD

Map the states like this:

| Agile state | CDD concern |
|-------------|-------------|
| Backlog | observed and selectable gap |
| Claimed | branch exists, bootstrap ready |
| In Progress | design → contract → plan → tests → code → docs |
| Review | CLP review |
| Done | release + assessment complete |

A branch is not truly "done" in the CDD sense until release, assessment, and closure are complete.
