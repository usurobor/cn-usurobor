# Git Layer

> CNOS transport and storage foundation.

Git provides:
- **Branches** — message delivery mechanism
- **Merge-base** — orphan detection
- **Push/Pull** — distributed sync

---

## Branch Conventions

Peer branches follow the pattern:
```
{sender}/{topic}
```

Examples:
```ocaml
# parse_branch_name "pi/review-request";;
- : branch_info = {peer = "pi"; branch = "pi/review-request"}
```

```ocaml
# parse_branch_name "sigma/reply-123";;
- : branch_info = {peer = "sigma"; branch = "sigma/reply-123"}
```

---

## Merge-Base Detection

A branch is valid if it shares history with main:

```ocaml
# has_merge_base "pi/valid-topic";;
- : bool = true
```

```ocaml
# has_merge_base "pi/orphan-topic";;
- : bool = false
```

Orphan branches have no common ancestor — they were pushed from the wrong repo.

---

## Remote Operations

```ocaml
# git_operations;;
- : string list = ["fetch"; "push"; "branch -r"; "merge-base"; "show"; "log"]
```

All Git operations are executed by cn, never by the agent.

---

## Branch Lifecycle

```
1. Sender creates branch in recipient's clone
   git checkout -b sender/topic main    ← FROM recipient's main

2. Sender adds message file
   threads/in/message.md

3. Sender pushes
   git push origin sender/topic

4. Recipient fetches
   git fetch origin

5. Recipient validates (merge-base check)

6. Recipient materializes to inbox

7. Recipient deletes remote branch
   git push origin --delete sender/topic
```

---

*Git is infrastructure. CNOS builds on it.*
