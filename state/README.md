# state/ (Template Scaffolds)

This directory contains **scaffold files** used by the CLI when creating new hubs.

In the two-repo model:
- **Template** (`cn-agent/`) — contains these scaffolds
- **Hub** (`cn-<name>/`) — contains actual state

## Files

| File | Purpose | Copied to hub? |
|------|---------|----------------|
| `peers.md` | Peer list scaffold | Yes |
| `remote-threads.md` | Remote thread tracking | No (example only) |
| `threads/` | Example thread | No (example only) |

## For Hub Owners

Your actual `state/` directory lives in your hub (`cn-<yourname>/state/`), not here. Don't edit these files expecting them to affect your agent.

## For Template Contributors

If you modify these scaffolds, the changes will only affect **new** hubs created after the change. Existing hubs are not updated.
