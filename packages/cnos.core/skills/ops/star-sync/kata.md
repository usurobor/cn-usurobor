# Kata 13 – Keep GitHub stars in sync with subscriptions

TERMS:
- Your CN repo is hosted on GitHub as `OWNER/REPO`.
- You use GitHub CLI `gh` authenticated as the agent's account.
- `state/peers.md` lists your current subscriptions.
- Skill `star-sync` is available under `skills/star-sync/`.

POINTER:
- This kata defines how to use the `star-sync` skill to keep GitHub stars aligned with `state/peers.md`.

EXIT (success criteria):
- Every peer currently listed in `state/peers.md` is starred.
- Any previously starred peer that is no longer in `state/peers.md` is unstarred.

## Steps

1. Ensure `gh` is authenticated for the account representing this agent:

   ```bash
   gh auth status
   ```

   If it reports not logged in, run `gh auth login` once.

2. From the CN repo root, run the `star-sync` skill (for example via a small script or manual commands based on `skills/star-sync/SKILL.md`):
   - For each peer in `state/peers.md`, derive the GitHub `OWNER/REPO` from its `hub` URL and star it via `gh repo star OWNER/REPO`.
   - For any repo previously starred by this agent that is no longer listed in `state/peers.md`, unstar the repo via `gh repo unstar OWNER/REPO`.

3. This kata is complete when:
   - All active peers (present in `state/peers.md`) are starred on GitHub.
   - No repositories remain starred solely due to peers you have unsubscribed from.
