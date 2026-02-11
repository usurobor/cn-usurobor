# OCaml

Write native OCaml tools for cnos. Compiled to native binaries via dune.

## Toolchain

```bash
opam switch create cnos 4.14.1
opam install dune ppx_expect ppxlib mdx
```

## Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Types | `snake_case` | `triage_entry` |
| Constructors | `PascalCase` | `Delete`, `Reason` |
| Modules | `PascalCase` | `Inbox_lib` |
| Functions | `snake_case` | `triage_of_string` |
| Files | `snake_case` | `inbox_lib.ml` |

## Structure

```
tools/src/cn/
 +-- cn.ml              Dispatch (~100 lines)
 +-- cn_lib.ml          Types, parsing (pure)
 +-- cn_protocol.ml     4 typed FSMs (pure)
 +-- cn_ffi.ml          System bindings (Unix + stdlib)
 +-- cn_agent.ml        Agent loop, queue
 +-- cn_mail.ml         Inbox/outbox transport
 +-- ...

tools/test/cn/
 +-- cn_test.ml         ppx_expect tests
 +-- dune
```

## Dune

```dune
; Pure library (no I/O)
(library
 (name cn_lib)
 (modules cn_lib)
 (libraries inbox_lib))

; Native binary
(executable
 (name cn)
 (public_name cn)
 (modules cn)
 (libraries cn_cmd cn_ffi cn_lib inbox_lib git cn_io))
```

## FFI (Native)

```ocaml
(* cn_ffi.ml — native system bindings *)
module Fs = struct
  let exists path = Sys.file_exists path
  let read path = In_channel.with_open_text path In_channel.input_all
  let write path content = Out_channel.with_open_text path (fun oc -> Out_channel.output_string oc content)
end
```

## Patterns

```ocaml
(* prefer *)
input |> parse |> validate |> output
match result with Ok x -> x | Error e -> handle e
List.fold_left (+) 0 items
match Cn_ffi.Fs.exists path with true -> Some x | false -> None
match xs with x :: _ -> x | [] -> default

(* avoid *)
let x = ref 0
for i = 0 to n do ... done
with _ -> None
List.hd xs                  (* use: match xs with x :: _ -> *)
Option.get opt              (* use: match opt with Some v -> *)
if condition then ...       (* use: match on bool *)
```

## Build

```bash
eval $(opam env)
dune build tools/src/cn/cn.exe
dune runtest
```

## Checklist

See `checklists/ocaml.md` for review checklist with severities.
