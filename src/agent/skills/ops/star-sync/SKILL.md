# Star Sync

TERMS:
- The CN repo is hosted on GitHub and accessible via GitHub CLI `gh`.
- `state/peers.md` lists current peers with GitHub-backed `hub` URLs.

INPUTS:
- None (operates on the current peer list).

EFFECTS:
- For each peer in `state/peers.md`:
  - Derives `OWNER/REPO` from the `hub` URL when it points at GitHub.
  - Stars that repo via `gh repo star OWNER/REPO`.
- For any repo previously starred by this agent that is no longer listed in `state/peers.md`:
  - Unstars the corresponding GitHub repo via `gh repo unstar OWNER/REPO`.

This skill keeps GitHub stars aligned with the current peer list: peers are starred; non-peers are not.
