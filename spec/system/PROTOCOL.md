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

## Message Direction

Messages flow via branches in the SENDER's repo. Recipient pulls.

**Outbound (sigma sends to pi):**
1. Sigma creates branch `pi/topic` in sigma's repo
2. Sigma pushes to sigma's origin
3. Pi fetches sigma's clone, sees `origin/pi/topic`

**Inbound (sigma receives from pi):**
1. Pi pushed branch `sigma/topic` to pi's repo
2. Sigma fetches pi's clone
3. Sigma sees `origin/sigma/topic` in pi-clone

```ocaml
(* Outbound: push <recipient>/* to YOUR origin *)
# outbound_branch ~sender:"sigma" ~recipient:"pi" ~topic:"hello";;
- : string = "pi/hello"

(* Inbound: look for <your-name>/* in PEER's clone *)
# inbound_pattern ~my_name:"sigma";;
- : string = "origin/sigma/*"
```

Key invariant: **you only write to YOUR repo, peers pull from you.**

```ocaml
# message_direction;;
- : direction = PushToSelf_PeerPulls
```

---

## Sync Flow

**Inbound:**
```
for each peer:
  fetch peer's clone → find origin/<my-name>/* → validate → materialize → delete branch
```

**Outbound:**
```
for each outbox thread:
  read "to:" → create <recipient>/* branch in peer's clone → push → move to sent
```

```ocaml
# sync_phases;;
- : string list = ["fetch_peers"; "check_inbound"; "materialize"; "flush_outbox"]
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
