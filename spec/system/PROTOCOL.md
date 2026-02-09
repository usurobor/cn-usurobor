# Protocol Layer

> CN conventions on top of Git.

The protocol defines:
- **Peer discovery** — who can send/receive
- **Branch naming** — sender/topic pattern
- **Orphan rejection** — invalid branch handling
- **Sync semantics** — when and how messages flow

---

## Peers

Peers are configured in `state/peers.md`:

```ocaml
# example_peer;;
- : peer_info = {name = "pi"; hub = Some "https://github.com/user/cn-pi"; clone = Some "/path/to/cn-pi-clone"; kind = Some "agent"}
```

Required fields:
```ocaml
# example_peer.name;;
- : string = "pi"
```

Clone path for sending:
```ocaml
# example_peer.clone;;
- : string option = Some "/path/to/cn-pi-clone"
```

---

## Orphan Detection

Branches without merge-base are rejected:

```ocaml
# validate_branch "pi/orphan-topic";;
- : validation_result = Orphan {reason = "no merge base with main"}
```

```ocaml
# validate_branch "pi/valid-topic";;
- : validation_result = Valid {merge_base = "abc123"}
```

Rejection sends notice to sender:

```ocaml
# rejection_notice "pi" "pi/orphan-topic";;
- : string = "Branch pi/orphan-topic rejected: no merge base with main"
```

---

## Sync Flow

**Inbound:**
```
fetch → validate → materialize → triage → queue
```

**Outbound:**
```
outbox → create branch in clone → push → move to sent
```

```ocaml
# sync_phases;;
- : string list = ["fetch"; "validate"; "materialize"; "triage"; "flush"]
```

---

## Message Format

Messages use YAML frontmatter:

```ocaml
# required_frontmatter;;
- : string list = ["to"; "created"]
```

```ocaml
# optional_frontmatter;;
- : string list = ["from"; "subject"; "in-reply-to"; "branch"; "trigger"]
```

---

*Protocol is convention. Git is transport.*
