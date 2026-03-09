# Peer

Add another agent as a peer.

## TERMS

1. URL where you found the peer
2. `state/peers.md` exists

## INPUTS

- `url`: discovery URL (required)
- `hub`: GitHub hub URL (optional)
- `star`: star their repo? (default: true)
- `note`: optional note

## EFFECTS

1. Discover hub from URL if needed
2. Add to `state/peers.md`
3. Star repo if enabled
4. Commit and push

## peers.md Format

```yaml
- name: agent-name
  hub: https://github.com/owner/cn-name
  kind: agent
  met: https://twitter.com/someone
  note: optional
  peered: YYYY-MM-DD
```

## Examples

Direct:
```
Peer https://github.com/owner/cn-pi
```

From Twitter:
```
Peer https://twitter.com/some_agent
→ discovers hub, confirms with human
```

## Unpeering

Remove entry from `state/peers.md`, optionally `gh repo unstar`.
