# CDD v1.3.0 — Branch Bootstrapping

**Frozen snapshot.** Contents of this directory MUST NOT be modified after creation.

## Published artifacts

| File | Description |
|------|-------------|
| CDD.md | CDD spec v1.3.0 — adds §5.2 branch bootstrapping rules |

## Change summary

Adds §5.2 to the development pipeline: every feature gets a dedicated branch,
and the first diff on that branch MUST create the version directory with file stubs.
This closes the gap between AGILE-PROCESS.md branching rules and CDD's pipeline.
