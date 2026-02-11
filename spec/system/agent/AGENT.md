# Agent Layer

> Pure function interface for CNOS agents.

The agent:
- **Receives** input via `cn input` (cn reads state/input.md)
- **Outputs** decisions via `cn out` (cn writes state/output.md)
- **Never** accesses filesystem directly

---

## Hard Rule: Agent ↔ cn Only

```ocaml
(* Agent's ENTIRE interface — nothing else exposed *)
# agent_interface;;
- : string list = ["cn input"; "cn out"]
```
```mdx-error
Unknown directive `agent_interface'.
Line 1, characters 5-6:
Error: Syntax error
```

Agent CANNOT:
```ocaml
# agent_cannot;;
- : string list =
["access filesystem"; "execute commands"; "call APIs"; "list inbox";
 "choose processing order"]
```

Agent CAN ONLY:
```ocaml
# agent_can_only;;
- : string list = ["call cn input"; "call cn out"]
```

---

## Input: cn input

Agent calls `cn input` to receive the current item:

```ocaml
# cn_input_returns;;
- : input_item =
{id = "abc123"; from = "pi"; content = "Please review"; cadence = Inbox}
```

Required fields:
```ocaml
# cn_input_returns.id;;
- : string = "abc123"
```

```ocaml
# cn_input_returns.from;;
- : string = "pi"
```

```ocaml
# cn_input_returns.content;;
- : string = "Please review"
```

Cadence types:
```ocaml
# all_cadences;;
- : cadence list = [Inbox; Daily; Weekly; Monthly; Quarterly; Yearly; Adhoc]
```

---

## Output: cn out

Agent outputs decisions via `cn out <gtd> [op]`.

**Only 4 GTD options:**
```ocaml
# gtd_options;;
- : string list = ["do"; "defer"; "delegate"; "delete"]
```

### Do — complete with operation

```ocaml
# parse_cn_out "cn out do reply --message \"LGTM\"";;
- : gtd = Do (Reply {message = "LGTM"})
```

```ocaml
# parse_cn_out "cn out do send --to pi --message \"hello\"";;
- : gtd = Do (Send {to_ = "pi"; message = "hello"; body = None})
```

```ocaml
# parse_cn_out "cn out do send --to pi --message \"summary\" --body \"full response\"";;
- : gtd =
Do (Send {to_ = "pi"; message = "summary"; body = Some "full response"})
```

```ocaml
# parse_cn_out "cn out do noop --reason \"acknowledged\"";;
- : gtd = Do (Noop {reason = "acknowledged"})
```

### Defer — postpone

```ocaml
# parse_cn_out "cn out defer --reason \"waiting on review\"";;
- : gtd = Defer {reason = "waiting on review"}
```

### Delegate — forward to peer

```ocaml
# parse_cn_out "cn out delegate --to pi";;
- : gtd = Delegate {to_ = "pi"}
```

### Delete — discard

```ocaml
# parse_cn_out "cn out delete --reason \"duplicate\"";;
- : gtd = Delete {reason = "duplicate"}
```

---

## Operations (for Do)

```ocaml
# all_operations;;
- : string list = ["reply"; "send"; "noop"; "ack"; "surface"; "commit"]
```

| Operation | Parameters | Description |
|-----------|------------|-------------|
| reply | --message | Append to current thread |
| send | --to --message [--body] | Send to peer |
| noop | --reason | Acknowledge, no action |
| ack | --reason | Explicit acknowledgment |
| surface | --desc | Surface MCA for community |
| commit | --artifact | Reference artifact hash |

---

## Type Definitions

```ocaml
# type_op;;
- : string =
"type op = Reply of {message: string} | Send of {to_: string; message: string; body: string option} | Noop of {reason: string} | Ack of {reason: string} | Surface of {desc: string} | Commit of {artifact: string}"
```

```ocaml
# type_gtd;;
- : string =
"type gtd = Do of op | Defer of {reason: string} | Delegate of {to_: string} | Delete of {reason: string}"
```

---

## Constraints

| Agent CAN | Agent CANNOT |
|-----------|--------------|
| Call `cn input` | Read state/input.md directly |
| Call `cn out` | Write state/output.md directly |
| | Access threads/ directly |
| | Move/delete files |
| | Execute shell commands |
| | Make network calls |

---

## Automatic Notification

When agent responds to input from a peer, cn automatically notifies the input creator:

```ocaml
# auto_notify;;
- : bool = true
```

Flow:
```
Pi sends input → Sigma calls cn out <gtd> → cn notifies Pi
```

---

*Agent thinks. cn acts.*
