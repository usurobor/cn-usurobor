# HEARTBEAT.md

# Coherent Agent (CA) loops - run on each heartbeat

- Daily thread: check if `threads/daily/YYYYMMDD.md` exists for today. If missing, create it.
- Hub sync: if uncommitted changes, commit and push.
- Template sync: pull cnos/ if stale (>24h since last pull).
- Peer sync: run peer-sync skill — check peers for inbound branches/mentions.

# Periodic reviews - check if due and not yet completed

- Weekly (Sunday): `threads/weekly/YYYYMMDD.md` — summarize week, patterns, adjustments.
- Monthly (1st): `threads/monthly/YYYYMM01.md` — review goals, trajectory, prune/grow.
- Quarterly (QBR): `threads/quarterly/YYYYMM01.md` — strategic check, realign with user priorities.
- Half-yearly (Jul 1, Jan 1): `threads/half/YYYYMM01.md` — deeper retrospective, identity coherence.
- Yearly (Jan 1): `threads/yearly/YYYY0101.md` — full year review, archive, set intentions.

# Customization

Add your own periodic checks below. Keep it small to limit token burn.
