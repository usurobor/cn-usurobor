# OCaml

Write native OCaml for cnos. Compiled to native binaries via dune.

## Core Principle

**Write OCaml that the compiler helps you maintain.** Use the type system to prevent bugs at definition time, not at every use site. Prefer disambiguation at the type level over annotation at the call site.

---

## 1. Define

### 1.1 Identify the parts

- Types — the primary safety mechanism. Design them so the compiler resolves ambiguity without help.
- Modules — organize by purity boundary (pure lib vs I/O cmd vs FFI).
- Tests — ppx_expect inline tests. Expect-test output is the specification.
- Build — dune. Native binary. No bytecode in production.

### 1.2 Articulate how they fit

Types define the domain. Modules enforce the purity boundary: `cn_lib` is pure, `cn_ffi` does I/O, `cn_cmd` wires them. Tests verify behavior through expect-test snapshots. The build compiles everything to a single native binary.

  - ❌ Put I/O in a pure parsing module
  - ✅ Parse returns `(value, string) result`; caller does I/O

### 1.3 Name the failure mode

OCaml code fails through **type ambiguity** and **purity leaks**:
- Two record types sharing field names cause cascading disambiguation errors across every use site
- Exceptions used for control flow instead of Result types
- Mutable state leaking outside a localized scope

  - ❌ `type a = { kind: string; ... }` and `type b = { kind: string; ... }` in the same module → annotate every access
  - ✅ `type a = { op_kind: string; ... }` and `type b = { backend_kind: string; ... }` → no annotations needed

---

## 2. Unfold

### 2.1 Type design

**Disambiguate at definition, not at use.**

When two record types share a field name in the same module, every access requires a type annotation. The cost multiplies across every function that touches either type. Instead, use distinct field names.

```ocaml
(* ❌ creates disambiguation burden *)
type extension_op = { kind : string; op_class : string }
type backend = { kind : string; command : string list }
(* every fun op -> op.kind needs (op : extension_op) annotation *)

(* ✅ no disambiguation needed *)
type extension_op = { op_kind : string; op_class : string }
type backend = { backend_kind : string; command : string list }
```

If overlapping names are unavoidable (e.g. interfacing with external schemas), annotate **all** access sites at definition time — not incrementally as the compiler complains.

### 2.2 Naming conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Types | `snake_case` | `triage_entry` |
| Constructors | `PascalCase` | `Delete`, `Reason` |
| Modules | `PascalCase` | `Inbox_lib` |
| Functions | `snake_case` | `triage_of_string` |
| Files | `snake_case` | `inbox_lib.ml` |

### 2.3 Module structure

```
src/
  cli/       → dispatch (~100 lines)
  lib/       → pure types, parsing, no I/O
  protocol/  → typed FSMs (pure)
  ffi/       → system bindings (Unix + stdlib)
  cmd/       → business logic, wires lib + ffi
  transport/ → I/O adapters (git, inbox, network)

test/
  cmd/       → ppx_expect tests per module
  lib/       → ppx_expect tests for pure logic
  protocol/  → ppx_expect tests for FSMs
```

### 2.4 Dune

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

; Tests (ppx_expect)
(library
 (name cn_extension_test)
 (modules cn_extension_test)
 (libraries cn_cmd cn_ffi cn_lib unix)
 (inline_tests)
 (preprocess (pps ppx_expect)))
```

### 2.5 Patterns

```ocaml
(* Pipeline style *)
input |> parse |> validate |> output

(* Result-based parsing — no exceptions for expected failures *)
let parse s : (value, string) result =
  ... Ok v | Error (Printf.sprintf "expected X at pos %d" pos)

(* Pattern match over if/else *)
match result with Ok x -> x | Error e -> handle e
match xs with x :: _ -> x | [] -> default

(* filter_map — filter + map in one pass *)
List.filter_map extract items

(* Localized mutable state — API surface is pure *)
type state = { src: string; mutable pos: int }
let parse s = let st = { src = s; pos = 0 } in parse_value st

(* RAII cleanup *)
Fun.protect ~finally:(fun () -> close_in_noerr ic) (fun () ->
  really_input_string ic (in_channel_length ic))

(* Atomic file locking *)
let fd = Unix.openfile path [O_WRONLY; O_CREAT; O_EXCL] 0o644 in
Fun.protect ~finally:(fun () -> Unix.close fd) (fun () -> ...)

(* Safe subprocess — no shell injection *)
let code, output =
  exec_args ~prog:"curl" ~args:["--config"; "-"]
    ~stdin_data:config ()

(* Qualify constructors in bare bindings *)
❌ let status = if bad then Degraded else Ok_
✅ let status : Cn_trace.status = if bad then Degraded else Ok_

(* Inside labeled args, inference works *)
Cn_trace.gemit ~status:(if bad then Degraded else Ok_)  (* ok *)
```

### 2.6 Anti-patterns

```ocaml
(* ❌ avoid *)
let x = ref 0                  (* mutable state outside local scope *)
for i = 0 to n do ... done     (* imperative loop *)
with _ -> None                  (* swallow all exceptions *)
List.hd xs                      (* partial — use match *)
Option.get opt                  (* partial — use match *)
raise Parse_error               (* use Result.error *)
```

### 2.7 FFI (native system bindings)

```ocaml
(* cn_ffi.ml — I/O lives here, nowhere else *)
module Fs = struct
  let exists path = Sys.file_exists path
  let read path = In_channel.with_open_text path In_channel.input_all
  let write path content =
    Out_channel.with_open_text path (fun oc ->
      Out_channel.output_string oc content)
end
```

### 2.8 Build

```bash
eval $(opam env)
dune build src/cli/cn.exe    # compile
dune runtest                  # run all expect tests
```

**Always run `dune build` before pushing.** If the toolchain is unavailable (e.g. sandboxed CI-only environment), annotate all record field accesses at definition time — do not rely on incremental CI feedback.

---

## 3. Rules

### 3.1 Type safety rule

Disambiguate record field names at the type definition. If two types in the same module share a field name, rename the fields to be distinct. Do not create a recurring annotation burden.

### 3.2 Purity boundary rule

`lib/` and `protocol/` modules must be pure — no I/O, no Unix, no Sys. I/O lives in `ffi/`. Business logic in `cmd/` wires pure and impure.

### 3.3 Error handling rule

Use `Result` types for expected failures. Reserve exceptions for truly unexpected conditions. Never `with _ ->`.

### 3.4 Test rule

Every module gets ppx_expect inline tests. The expect-test output is the behavioral contract. If the output changes, the test fails — review the diff.

### 3.5 Build-before-push rule

Run `dune build` locally before pushing. If the toolchain is not available, treat type disambiguation as a project-wide audit: grep for all access sites of overlapping field names and annotate them in one pass.

### 3.6 Toolchain

```bash
opam switch create cnos 4.14.1
opam install dune ppx_expect ppxlib mdx
```
