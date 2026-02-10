# OCaml

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
match Fs.exists path with true -> Some x | false -> None
match xs with x :: _ -> x | [] -> default

(* avoid *)
let x = ref 0
for i = 0 to n do ... done
with _ -> None              (* use: exception Js.Exn.Error _ *)
List.hd xs                  (* use: match xs with x :: _ -> *)
Option.get opt              (* use: match opt with Some v -> *)
if Fs.exists path then ...  (* use: match on bool *)
```

## Build

```bash
eval $(opam env)
dune build @<tool>
npx esbuild _build/default/tools/src/<tool>/output/.../<tool>.js \
  --bundle --platform=node --outfile=dist/<tool>.js
```

## Checklist

See `checklists/ocaml.md` for review checklist with severities.
