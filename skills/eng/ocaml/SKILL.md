# ocaml

Write OCaml tools for cn-agent. Compile via Melange, bundle with esbuild.

## Toolchain

```bash
opam switch create cn-agent 4.14.1
opam install dune melange melange.ppx ppx_expect
```

## Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Types | `snake_case` | `triage_entry` |
| Constructors | `PascalCase` | `Delete`, `Reason` |
| Modules | `PascalCase` | `Inbox_lib` |
| Functions | `snake_case` | `triage_of_string` |
| Files | `snake_case` | `inbox_lib.ml` |

### Variant Naming

When multiple types share constructor names, use modules for scoping:

```ocaml
(* Clean: module-scoped variants *)
module Inbox = struct
  type cmd = Check | Process | Flush
end

module Outbox = struct
  type cmd = Check | Flush
end

(* Usage *)
| Inbox Inbox.Check -> ...
| Outbox Outbox.Flush -> ...
```

Rules:
1. **Use modules** for related command groups
2. **Clean constructor names** inside modules (no prefixes)
3. **Qualify at use site**: `Module.Constructor`

## Structure

```
tools/src/<tool>/
├── <tool>.ml        # CLI with FFI
├── <tool>_lib.ml    # Pure functions
└── dune

tools/test/<tool>/
├── <tool>_test.ml   # ppx_expect tests
└── dune

dist/<tool>.js       # Bundled output
```

## Dune

```dune
; Library
(library
 (name inbox_lib)
 (modules inbox_lib)
 (modes :standard melange))

; CLI
(melange.emit
 (target output)
 (alias inbox)
 (modules inbox)
 (libraries inbox_lib)
 (module_systems commonjs)
 (preprocess (pps melange.ppx)))
```

## FFI

```ocaml
module Fs = struct
  external exists_sync : string -> bool = "existsSync" [@@mel.module "fs"]
  external read_file_sync : string -> string -> string = "readFileSync" [@@mel.module "fs"]
end
```

## Patterns

```ocaml
(* prefer *)
input |> parse |> validate |> output
match result with Ok x -> x | Error e -> handle e
List.fold_left (+) 0 items

(* avoid *)
let x = ref 0
for i = 0 to n do ... done
raise Not_found
```

## Build

```bash
eval $(opam env)
dune build @<tool>
npx esbuild _build/default/tools/src/<tool>/output/.../<tool>.js \
  --bundle --platform=node --outfile=dist/<tool>.js
```

## Comments

### Module-level docs

Every `.ml` file starts with `(** ... *)` (double-star = ocamldoc):

```ocaml
(** cn_lib.ml — Core CN library (pure, no I/O)
    
    DESIGN: This is the "lib" in Unix convention — the core library
    that everything else depends on.
    
    Layering (deliberate):
      cn.ml     → CLI wiring
      cn_io.ml  → Protocol I/O (side effects)
      cn_lib.ml → Types, parsing (THIS FILE - pure)
      git.ml    → Raw git operations
    
    Why pure?
    - Fully testable with ppx_expect
    - No mocking needed
*)
```

Include:
- **File name** — first line
- **DESIGN** — why this module exists, architectural role
- **Layering** — where it fits in the stack
- **Why** — rationale for key decisions

### Function docs

Document non-obvious functions:

```ocaml
(** [parse_command args] converts CLI args to a command.
    Returns [None] if args don't match any known command.
    
    Examples:
    - ["sync"] → Some Sync
    - ["inbox"; "check"] → Some (Inbox Check)
    - ["garbage"] → None *)
val parse_command : string list -> command option
```

### When NOT to comment

```ocaml
(* Bad: comments that repeat the code *)
let add x y = x + y  (* adds x and y *)

(* Bad: obvious from types *)
let is_empty lst = lst = []

(* Good: non-obvious behavior *)
let normalize path =
  (* Strip trailing slash to match git behavior *)
  if String.ends_with ~suffix:"/" path
  then String.sub path 0 (String.length path - 1)
  else path
```

### Inline comments

Use `(* ... *)` sparingly for:
- Non-obvious logic
- Workarounds with context
- TODOs with tickets

```ocaml
let run_sync hub_path name =
  (* Fetch before checking inbox — order matters *)
  let _ = Git.fetch ~cwd:hub_path in
  inbox_check hub_path name;
  (* TODO: batch outbox flush for efficiency *)
  outbox_flush hub_path name
```

### Design decisions

Document architectural choices in module headers, not inline:

```ocaml
(** git.ml — Pure git operations
    
    DESIGN: This module contains ONLY raw git operations.
    No CN protocol knowledge. No business logic.
    
    Why separate?
    - Testable: can mock git.ml for cn_io tests
    - Portable: git.ml works for any git workflow
    - Clear: CN protocol lives in cn_io, not here
*)
```

## Checklist

- [ ] Pure functions in `_lib.ml`
- [ ] FFI in main `.ml` only
- [ ] ppx_expect tests
- [ ] No `ref`, no loops, no exceptions for control flow
- [ ] Bundled `.js` committed
- [ ] Module-level `(** ... *)` with DESIGN rationale
- [ ] Non-obvious functions documented
