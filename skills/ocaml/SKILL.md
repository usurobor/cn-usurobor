# ocaml

Write OCaml tools for cn-agent. Compile to JavaScript via Melange, bundle with esbuild.

---

## TERMS

1. OCaml toolchain installed (opam, dune, Melange)
2. Working in cn-agent repo
3. Follow accepted conventions

---

## Toolchain

```bash
# Setup (one-time)
opam switch create cn-agent 4.14.1
opam install dune melange melange.ppx ppx_expect

# Verify
ocaml --version    # 4.14.1
dune --version     # 3.x
```

---

## Conventions

**Follow accepted OCaml conventions — don't invent.**

| Thing | Convention | Example |
|-------|-----------|---------|
| Type names | `snake_case` | `triage_entry` |
| Constructors | `PascalCase` | `Delete`, `Reason` |
| Modules | `PascalCase` | `Inbox_lib` |
| Functions | `snake_case` | `triage_of_string` |
| Files | `snake_case` | `inbox_lib.ml` |

### Wrapper Types (for type safety)

```ocaml
(* Semantic wrapper types *)
type reason = Reason of string
type actor = Actor of string

(* Usage — compiler prevents mixing *)
let x = Delete (Reason "stale")     (* ✓ *)
let y = Delete (Actor "pi")         (* ✗ type error *)
```

### Variant Types (for exhaustive matching)

```ocaml
type command =
  | Check
  | Process
  | Flush

let run cmd = match cmd with
  | Check -> ...
  | Process -> ...
  | Flush -> ...
  (* compiler warns if case missing *)
```

---

## Project Structure

```
tools/
├── src/
│   └── <tool>/
│       ├── <tool>.ml        # CLI with Node.js bindings
│       ├── <tool>_lib.ml    # Pure functions (testable)
│       └── dune
├── test/
│   └── <tool>/
│       ├── <tool>_test.ml   # ppx_expect tests
│       └── dune
└── dist/
    └── <tool>.js            # Bundled output (committed)
```

---

## Dune Config

### Library (pure, testable)

```dune
(library
 (name inbox_lib)
 (modules inbox_lib)
 (modes :standard melange))
```

### CLI (Melange → JS)

```dune
(melange.emit
 (target output)
 (alias inbox)
 (modules inbox)
 (libraries inbox_lib)
 (module_systems commonjs)
 (preprocess (pps melange.ppx)))
```

### Tests (ppx_expect)

```dune
(library
 (name inbox_test)
 (libraries inbox_lib)
 (inline_tests)
 (preprocess (pps ppx_expect)))
```

---

## Node.js Bindings

```ocaml
module Process = struct
  external cwd : unit -> string = "cwd" [@@mel.module "process"]
  external argv : string array = "argv" [@@mel.module "process"]
  external exit : int -> unit = "exit" [@@mel.module "process"]
end

module Fs = struct
  external read_file_sync : string -> encoding:string -> string = 
    "readFileSync" [@@mel.module "fs"]
  external exists_sync : string -> bool = 
    "existsSync" [@@mel.module "fs"]
end

module Path = struct
  external join : string -> string -> string = "join" [@@mel.module "path"]
  external dirname : string -> string = "dirname" [@@mel.module "path"]
end
```

---

## Testing (ppx_expect)

```ocaml
let%expect_test "parse valid input" =
  ["check"; "process"; "flush"]
  |> List.iter (fun s ->
    match command_of_string s with
    | Some c -> print_endline (string_of_command c)
    | None -> print_endline "NONE");
  [%expect {|
    check
    process
    flush
  |}]
```

Run tests:
```bash
dune runtest
```

---

## Build & Bundle

```bash
# Build
eval $(opam env --switch=cn-agent)
dune build @<tool>

# Bundle (single file, no deps)
npx esbuild _build/default/tools/src/<tool>/output/tools/src/<tool>/<tool>.js \
  --bundle --platform=node --outfile=tools/dist/<tool>.js

# Test the bundle
node tools/dist/<tool>.js --help
```

---

## Functional Patterns

### Prefer

```ocaml
(* Pipelines *)
input |> parse |> validate |> transform |> output

(* Pattern matching *)
match result with
| Ok x -> handle_success x
| Error e -> handle_error e

(* Option chaining *)
value |> Option.map transform |> Option.value ~default:fallback

(* Immutable data *)
let new_record = { old_record with field = new_value }
```

### Avoid

```ocaml
(* Mutable refs *)
let counter = ref 0   (* avoid *)

(* Imperative loops *)
for i = 0 to n do ... done   (* use List.iter or recursion *)

(* Exceptions for control flow *)
raise Not_found   (* use Option or Result *)
```

---

## Checklist

- [ ] Types defined with semantic wrappers where appropriate
- [ ] All variants handled (no wildcard `_` matches)
- [ ] Pure functions in `_lib.ml` (testable without FFI)
- [ ] FFI bindings in main `.ml` only
- [ ] ppx_expect tests for all parsing/formatting
- [ ] Bundled `.js` committed to `tools/dist/`
- [ ] README in tool directory

---

## NOTES

- "If it compiles, it works" — leverage the type system
- Pure functions are easier to test than effectful ones
- Melange output is CommonJS by default
- Bundle size ~600-700KB typical (includes runtime)
- See `tools/src/inbox/` for reference implementation
