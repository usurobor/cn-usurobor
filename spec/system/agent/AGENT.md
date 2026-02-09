# Agent Layer

> Pure function interface for CNOS agents.

The agent:
- **Reads** `state/input.md`
- **Writes** `state/output.md`
- **Never** performs I/O directly

---

## Input Format

```ocaml
# example_input;;
- : agent_input = {id = "pi-review"; from = "pi"; queued = "2026-02-09T05:00:00Z"; content = "Please review"}
```

Required fields:
```ocaml
# example_input.id;;
- : string = "pi-review"
```

```ocaml
# example_input.from;;
- : string = "pi"
```

```ocaml
# example_input.queued;;
- : string = "2026-02-09T05:00:00Z"
```

```ocaml
# example_input.content;;
- : string = "Please review"
```

---

## Output Format

```ocaml
# example_output;;
- : agent_output = {id = "pi-review"; status = 200; ops = [Done "pi-review"]; body = "Done"}
```

ID must match input:
```ocaml
# example_output.id = example_input.id;;
- : bool = true
```

Status code:
```ocaml
# example_output.status;;
- : int = 200
```

---

## Status Codes

```ocaml
# status_meaning 200;;
- : string = "OK — completed"
```

```ocaml
# status_meaning 201;;
- : string = "Created — new artifact"
```

```ocaml
# status_meaning 400;;
- : string = "Bad Request — malformed input"
```

```ocaml
# status_meaning 404;;
- : string = "Not Found — missing reference"
```

```ocaml
# status_meaning 422;;
- : string = "Unprocessable — understood but can't do"
```

```ocaml
# status_meaning 500;;
- : string = "Error — something broke"
```

---

## Operations

Agent writes operations in output.md frontmatter. cn executes them.

**Send:**
```ocaml
# pp_operation (Send {peer = "pi"; message = "LGTM"});;
Send to pi: LGTM
- : unit = ()
```

**Done:**
```ocaml
# pp_operation (Done "task-123");;
Done: task-123
- : unit = ()
```

**Fail:**
```ocaml
# pp_operation (Fail {id = "task"; reason = "invalid input"});;
Fail task: invalid input
- : unit = ()
```

**Reply:**
```ocaml
# pp_operation (Reply {thread_id = "t1"; message = "acknowledged"});;
Reply to t1: acknowledged
- : unit = ()
```

**Delegate:**
```ocaml
# pp_operation (Delegate {thread_id = "t1"; peer = "sigma"});;
Delegate t1 to sigma
- : unit = ()
```

**Defer:**
```ocaml
# pp_operation (Defer {id = "t1"; until = Some "tomorrow"});;
Defer t1 until tomorrow
- : unit = ()
```

**Delete:**
```ocaml
# pp_operation (Delete "old-thread");;
Delete: old-thread
- : unit = ()
```

**Ack:**
```ocaml
# pp_operation (Ack "received");;
Ack: received
- : unit = ()
```

---

## Constraints

| Agent CAN | Agent CANNOT |
|-----------|--------------|
| Read state/input.md | Read threads/ directly |
| Write state/output.md | Move/delete files |
| Write ops in frontmatter | Execute shell commands |
| | Make network calls |

---

*Agent is pure. CNOS handles I/O.*
