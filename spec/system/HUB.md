# Hub Layer

> Local filesystem structure for CNOS.

The hub defines:
- **Thread locations** — where messages live
- **State files** — input.md, output.md, queue/
- **Naming convention** — timestamped filenames
- **Logging** — audit trail

---

## Directory Structure

```
hub/
├── state/
│   ├── input.md
│   ├── output.md
│   ├── queue/
│   └── peers.md
├── threads/
│   ├── in/
│   ├── mail/{inbox,outbox,sent}/
│   ├── reflections/{daily,weekly,monthly}/
│   └── adhoc/
└── logs/
```

---

## Thread Paths

```ocaml
# thread_path In "incoming";;
- : string = "threads/in/incoming.md"
```

```ocaml
# thread_path Mail_inbox "from-pi";;
- : string = "threads/mail/inbox/from-pi.md"
```

```ocaml
# thread_path Mail_outbox "to-sigma";;
- : string = "threads/mail/outbox/to-sigma.md"
```

```ocaml
# thread_path Mail_sent "delivered";;
- : string = "threads/mail/sent/delivered.md"
```

```ocaml
# thread_path Reflections_daily "20260209";;
- : string = "threads/reflections/daily/20260209.md"
```

```ocaml
# thread_path Reflections_weekly "2026-W06";;
- : string = "threads/reflections/weekly/2026-W06.md"
```

```ocaml
# thread_path Adhoc "scratch";;
- : string = "threads/adhoc/scratch.md"
```

---

## Naming Convention

All threads use timestamped names:

```
YYYYMMDD-HHMMSS-{slug}.md
```

```ocaml
# timestamp_filename "pi-review";;
- : string = "20260209-120000-pi-review.md"
```

```ocaml
# timestamp_filename "rejected-orphan";;
- : string = "20260209-120000-rejected-orphan.md"
```

Benefits:
- Sorts chronologically
- No collisions
- Clear audit trail

---

## State Files

**input.md** — delivered by cn, one at a time:
```ocaml
# state_path "input.md";;
- : string = "state/input.md"
```

**output.md** — written by agent:
```ocaml
# state_path "output.md";;
- : string = "state/output.md"
```

**queue/** — pending items:
```ocaml
# state_path "queue";;
- : string = "state/queue"
```

---

## Log Paths

```ocaml
# log_path "cn.log";;
- : string = "logs/cn.log"
```

```ocaml
# log_path "input/archived.md";;
- : string = "logs/input/archived.md"
```

---

*Hub is local structure. Protocol is distributed.*
