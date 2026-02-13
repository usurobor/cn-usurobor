# Kata 2.1: Keep GitHub stars in sync with subscriptions

## Belt
🟡 Yellow (Iteration)

## Objective
Sync your GitHub stars with the repos listed in `state/peers.md`.

## Prerequisites
- GitHub CLI (`gh`) authenticated
- `state/peers.md` with hub URLs

## Steps

1. **Check current stars**
   ```bash
   gh api user/starred --paginate -q '.[].full_name'
   ```

2. **Run star-sync**
   ```bash
   cn star-sync
   ```
   Or manually:
   - Read each hub URL from `state/peers.md`
   - Extract owner/repo
   - Star if not already starred

3. **Verify**
   ```bash
   gh api user/starred --paginate -q '.[].full_name' | grep cn-
   ```

## Success Criteria
- All peer repos are starred
- No errors during sync

## Time
~5 minutes
