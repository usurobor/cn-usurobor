# system/

Infrastructure services that implement kernel protocols.

## Subdirectories

- **sync/** — Peer sync, star-sync
- **inbox/** — Message routing, materialization
- **threads/** — Thread lifecycle, archival
- **cli/** — cn CLI commands

## Rules

1. Implements kernel protocols
2. Can evolve without breaking protocol
3. Swappable implementations allowed
