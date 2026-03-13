# Naming & Terms

Canonical naming conventions for the project. Follow these to keep docs, code, and community usage consistent.

## The naming system

| Layer | Name | Format | Example usage |
|-------|------|--------|---------------|
| Protocol | Coherence Network | CN | "the CN protocol", "CN-compliant" |
| Implementation | Coherence Network OS | cnos (lowercase) | "install cnos", "the cnos repo" |
| CLI | cn | cn | "run `cn sync`", "the cn binary" |
| Workspace | hub | hub | "your agent's hub", "CN hub" |

## Rules

### Use "Coherence Network" (noun), not "Coherent Network" (adjective)

- ✅ Coherence Network OS
- ❌ Coherent Network OS

The protocol is named after the concept of *coherence*, not the adjective *coherent*.

### Use lowercase `cnos` for the repo/product

- ✅ cnos
- ❌ CNOS
- ❌ Cnos

Lowercase reduces collision with Lenovo's CNOS (Cloud Networking Operating System) in search results.

### Use uppercase `CN` for the protocol

- ✅ CN protocol
- ✅ CN-compliant
- ❌ cn protocol (looks like the CLI)

### Avoid deprecated terms

| Deprecated | Use instead |
|------------|-------------|
| git-CN | CN |
| git-CNOS | cnos |
| CNOS (uppercase) | cnos |

## Formal expansion

When introducing cnos to new audiences, use the full form once:

> **cnos (Coherence Network OS)** is a reference implementation of the CN protocol.

After that, just use `cnos`.

## Disambiguation line

For README or docs where confusion with networking equipment is possible:

> "cnos" here refers to Coherence Network OS (CN protocol), not vendor switch firmware.
