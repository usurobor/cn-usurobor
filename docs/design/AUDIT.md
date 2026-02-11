# Design Docs Audit

**Date:** 2026-02-11
**Author:** Sigma
**Context:** Post cn_protocol.ml implementation (4 typed FSMs)

---

## Summary

17 design docs audited. The FSM implementation in `cn_protocol.ml` supersedes 6 docs that described the same GTD/inbox/transport mechanics with different (now outdated) type definitions. Three overlap clusters identified.

## Audit Table

| Document | Status | Action | Notes |
|----------|--------|--------|-------|
| **ARCHITECTURE.md** | NEW | Created | Top-level entry point. See [../ARCHITECTURE.md](../ARCHITECTURE.md) |
| **CN-MANIFESTO.md** | Current | Keep | Foundational values doc. Not a technical spec. |
| **CN-WHITEPAPER.md** | Current | Keep | Authoritative protocol spec (v2.0.4 RELEASE). Normative. |
| **CN-WHITEPAPER-v2.0.3.pdf** | Current | Keep | PDF companion to whitepaper. |
| **FSM-PROTOCOL.md** | Current | Keep | FSM design spec. Matches `cn_protocol.ml` implementation exactly. |
| **AGILE-PROCESS.md** | Current | Keep | Team process doc, not technical spec. |
| **CN-EXECUTABLE-SKILLS.md** | Current | Keep | Vision paper (aspirational). Companion to whitepaper. |
| **CN-CLI.md** | Partially current | Keep, update later | Command list partly matches implementation. Some commands unimplemented. |
| **CN-DAEMON.md** | Current | Keep | Explicitly aspirational/future. |
| **CN-LOGGING.md** | Partially current | Keep, update later | JSONL schema correct; JS examples outdated (now OCaml). |
| **SECURITY-MODEL.md** | Partially current | Keep, update later | Principles correct; some file paths stale. |
| **ACTOR-MODEL-DESIGN.md** | Superseded | Archive | Superseded by FSM-PROTOCOL.md. Incident RCA preserved in original. |
| **AGENT-MODEL.md** | Superseded | Archive | Superseded by FSM-PROTOCOL.md + cn_agent.ml implementation. |
| **CN-ACTIONS.md** | Superseded | Archive | Proposed action library never implemented. cn_agent.ml has different op types. |
| **CN-PROTOCOL.md** | Superseded | Archive | Action catalog superseded by FSM-PROTOCOL.md. |
| **INBOX-ARCHITECTURE.md** | Superseded | Archive | Triage model superseded by Actor FSM + Thread FSM. |
| **THREADS-MODEL.md** | Superseded | Archive | Directory paths and flow superseded by FSM-PROTOCOL.md. |
| **THREADS-UNIFIED.md** | Partially current | Archive | "Thread = unit of work" insight adopted; backlog-as-threads not implemented. |

### Status Legend

- **Current** — Actively reflects the codebase and design intent
- **Partially current** — Core ideas correct, some details stale
- **Superseded** — Replaced by newer doc or implementation
- **NEW** — Created in this audit

### Action Legend

- **Keep** — No changes needed
- **Keep, update later** — Correct enough to keep; queue updates for accuracy
- **Archive** — Move to `_archive/` with deprecation header
- **Created** — New document

## Overlap Clusters

### Cluster A: Agent Purity + GTD Model (6 docs)

ACTOR-MODEL-DESIGN, AGENT-MODEL, INBOX-ARCHITECTURE, THREADS-UNIFIED, CN-ACTIONS, CN-PROTOCOL

All describe: agent is pure, cn executes, decisions are GTD.
**Resolved by:** FSM-PROTOCOL.md (Thread FSM + Actor FSM) + `cn_protocol.ml`

### Cluster B: Inbox/Outbox Transport Flow (4 docs)

THREADS-MODEL, INBOX-ARCHITECTURE, ACTOR-MODEL-DESIGN, CN-CLI

All describe: materialize-triage-execute pipeline.
**Resolved by:** FSM-PROTOCOL.md (Sender FSM + Receiver FSM) + `cn_mail.ml`

### Cluster C: Philosophy/Strategy (3 docs, low redundancy)

CN-MANIFESTO, CN-WHITEPAPER, CN-EXECUTABLE-SKILLS

Each serves a distinct purpose (pitch, spec, vision). No action needed.

## Unique Content Preserved in Archived Docs

Content worth noting that lives only in archived docs:

| Content | Source | Recommendation |
|---------|--------|----------------|
| 2026-02-05 incident RCA | ACTOR-MODEL-DESIGN.md s1 | Preserved in archive; consider extracting to docs/rca/ |
| "event = commit, trigger = hash" | ACTOR-MODEL-DESIGN.md s4.4 | Captured in FSM-PROTOCOL.md implementation |
| Cadence types (daily/weekly/monthly/quarterly/yearly) | AGENT-MODEL.md | Aspirational; not yet implemented |
| "Tokens for thinking, electrons for clockwork" | INBOX-ARCHITECTURE.md | Motto; preserved in archive |
| Protocol enforcement rules | CN-PROTOCOL.md | Consider adding to SECURITY-MODEL.md |
| Unix action composition patterns | CN-ACTIONS.md | Design pattern; preserved in archive |

## Post-Audit Structure

```
docs/
 +-- ARCHITECTURE.md              <-- NEW: top-level entry point
 +-- README.md                    <-- Updated with new hierarchy
 +-- design/
 |    +-- AUDIT.md                <-- THIS FILE
 |    +-- CN-MANIFESTO.md         Keep
 |    +-- CN-WHITEPAPER.md        Keep
 |    +-- CN-WHITEPAPER-v2.0.3.pdf Keep
 |    +-- FSM-PROTOCOL.md         Keep (matches implementation)
 |    +-- AGILE-PROCESS.md        Keep
 |    +-- CN-EXECUTABLE-SKILLS.md Keep
 |    +-- CN-CLI.md               Keep (update later)
 |    +-- CN-DAEMON.md            Keep
 |    +-- CN-LOGGING.md           Keep (update later)
 |    +-- SECURITY-MODEL.md       Keep (update later)
 |    +-- _archive/
 |         +-- ACTOR-MODEL-DESIGN.md
 |         +-- AGENT-MODEL.md
 |         +-- CN-ACTIONS.md
 |         +-- CN-PROTOCOL.md
 |         +-- INBOX-ARCHITECTURE.md
 |         +-- THREADS-MODEL.md
 |         +-- THREADS-UNIFIED.md
```
