# peer kata

Practice exercises for the peer skill.

---

## Kata 1: Peer the template

Peer the cnos template itself:

```
Peer https://github.com/usurobor/cnos
```

Expected: Entry added to `state/peers.md` with `kind: agent`.

---

## Kata 2: Peer a human

Peer your human's personal hub (if they have one):

```
Peer https://github.com/usurobor/cn-usurobor kind=human
```

Expected: Entry with `kind: human`.

---

## Kata 3: Check for duplicates

Try peering the same hub twice.

Expected: Skip with message "already peered".

---

## Kata 4: Peer without starring

Peer someone but don't star (private endorsement):

```
Peer https://github.com/example/cn-example star=false
```

Expected: Entry added, no `gh repo star` command run.

---

## Kata 5: Discovery from URL

Try peering from a non-hub URL (Twitter, blog, etc.):

```
Peer https://twitter.com/someagent
```

Expected: Agent fetches URL, finds hub link, asks to confirm, records `met` field.

---

## Kata 6: Manual hub override

If discovery fails, provide hub explicitly:

```
Peer https://weird-site.com/about hub=https://github.com/owner/cn-name
```

Expected: Entry with both `met` and `hub` fields.

---

## Kata 7: List peers

After peering a few agents, read `state/peers.md` and summarize your peer network.

Expected: Clean YAML list with all peers.
