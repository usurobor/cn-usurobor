> **ARCHIVED** — Superseded by [FSM-PROTOCOL.md](../FSM-PROTOCOL.md) and [ARCHITECTURE.md](../../ARCHITECTURE.md).
> See [AUDIT.md](../AUDIT.md) for details. Preserved for historical reference.

# CN-ACTIONS: Unix-Style Action Library

**Status:** Draft  
**Author:** Sigma  
**Date:** 2026-02-05

## Design Moment

**Unix philosophy.** Each action does one job and does it well.

- Small, sharp tools
- One input → one effect
- Composable by caller
- No hidden conditionals
- Fails or succeeds, nothing in between

## Core Principle

The action library is a set of **atomic primitives**. The agent (or higher-level tool) composes them. The library never decides—it executes.

```
Agent (brain)          Action Library (body)
     │                        │
     │  [Checkout; Merge]     │
     └───────────────────────►│
                              │ executes sequentially
                              │ stops on first failure
                              ▼
                           effects
```

## Action Catalog

### Git Actions
| Action | Input | Effect |
|--------|-------|--------|
| `Checkout` | branch | `git checkout <branch>` |
| `Merge` | branch | `git merge <branch>` |
| `Rebase` | branch | `git rebase <branch>` |
| `Push` | remote, branch | `git push <remote> <branch>` |
| `Fetch` | remote | `git fetch <remote>` |
| `Pull` | remote, branch | `git pull <remote> <branch>` |
| `Branch_create` | branch | `git checkout -b <branch>` |
| `Branch_delete` | branch | `git branch -d <branch>` |
| `Remote_delete` | remote, branch | `git push <remote> --delete <branch>` |

### File Actions
| Action | Input | Effect |
|--------|-------|--------|
| `File_write` | path, content | Write content to path (create/overwrite) |
| `File_append` | path, content | Append content to path |
| `File_move` | src, dst | Move file from src to dst |
| `File_copy` | src, dst | Copy file from src to dst |
| `File_delete` | path | Delete file at path |
| `Dir_create` | path | Create directory (mkdir -p) |

### Log Actions
| Action | Input | Effect |
|--------|-------|--------|
| `Log_append` | path, line | Append timestamped line to log |

## OCaml Types

```ocaml
type branch = string
type remote = string
type path = string
type content = string

type action =
  (* Git *)
  | Checkout of branch
  | Merge of branch
  | Rebase of branch
  | Push of remote * branch
  | Fetch of remote
  | Pull of remote * branch
  | Branch_create of branch
  | Branch_delete of branch
  | Remote_delete of remote * branch
  (* File *)
  | File_write of path * content
  | File_append of path * content
  | File_move of path * path
  | File_copy of path * path
  | File_delete of path
  | Dir_create of path
  (* Log *)
  | Log_append of path * string

type result = Ok | Error of string

val execute : action -> result
val execute_all : action list -> result  (* stops on first error *)
```

## Composition Examples

### Accept inbound branch
```ocaml
let accept branch = [
  Checkout "main";
  Merge branch;
  Push ("origin", "main");
  Branch_delete branch;
  Remote_delete ("origin", branch);
  Log_append ("logs/inbox.md", "accepted: " ^ branch);
]
```

### Reject inbound branch
```ocaml
let reject branch reason = [
  Branch_delete branch;
  Remote_delete ("origin", branch);
  Log_append ("logs/inbox.md", "rejected: " ^ branch ^ " (" ^ reason ^ ")");
]
```

### Defer inbound branch
```ocaml
let defer branch until = [
  Log_append ("logs/inbox.md", "deferred: " ^ branch ^ " until " ^ until);
]
(* No git actions — branch stays, just logged *)
```

## Constraints

1. **No conditionals inside actions.** If you need `if`, compose at caller level.
2. **No retries inside actions.** Caller decides retry policy.
3. **No batching inside actions.** `execute_all` is the only batching.
4. **Idempotent where possible.** `Dir_create` on existing dir = Ok.
5. **Atomic where possible.** `File_write` = write-to-temp + rename.

## Error Handling

Actions return `Ok | Error of string`. On error:
- Message describes what failed
- No partial state (action either fully succeeds or fully fails)
- Caller decides whether to continue, retry, or abort

## Audit Trail

Every action can be logged before execution:

```ocaml
let execute_logged log_path action =
  Log_append (log_path, action_to_string action) |> execute |> ignore;
  execute action
```

## Non-Goals

- **No rollback.** Git is the rollback mechanism.
- **No transactions.** Compose carefully; git reflog is your friend.
- **No remote API calls.** This is local git + filesystem only.

## Next Steps

1. Implement `cn_actions.ml` with execute function
2. Add to inbox tool as action backend
3. Test with mock executor
