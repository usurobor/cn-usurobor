# OCaml

Write native OCaml for cnos. Compiled to native binaries via dune.

## Core Principle

**Write OCaml that the compiler helps you maintain.** Use the type system to prevent bugs at definition time, not at every use site. Prefer disambiguation at the type level over annotation at the call site.

---

## 1. Define

### 1.1 Identify the parts

- Types — the primary safety mechanism. Design them so the compiler resolves ambiguity without help.
- Modules — organize by purity boundary (pure lib vs I/O cmd vs FFI).
- Fallbacks — every fallback/compatibility path is a policy decision, not a convenience.
- Tests — ppx_expect inline tests. Expect-test output is the specification.
- Build — dune. Native binary. No bytecode in production.

### 1.2 Articulate how they fit

Types define the domain. Modules enforce the purity boundary: `cn_lib` is pure, `cn_ffi` does I/O, `cn_cmd` wires them. Fallbacks express what the system does when reality is missing, stale, or malformed. They must be explicit, bounded, and visible — not silent. Tests verify behavior through expect-test snapshots. The build compiles everything to a single native binary.

  - ❌ Put I/O in a pure parsing module
  - ✅ Parse returns `(value, string) result`; caller does I/O

### 1.3 Name the failure mode

OCaml code fails through **type ambiguity**, **purity leaks**, and **silent fallback**:
- Two record types sharing field names cause cascading disambiguation errors across every use site
- Exceptions used for control flow instead of Result types
- Mutable state leaking outside a localized scope
- Compatibility paths that silently swallow failure and fabricate an "empty" state
- Readers/scans that turn missing or unreadable into `[]` / `None` without logging or classification

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

### 2.6 Fallback and compatibility discipline

Every fallback path is a policy choice. Silent fallback is a bug unless explicitly justified.

#### 2.6.1 Remove

Default disposition. If the path exists only for backward compatibility and the migration grace period has passed, delete it.

  - ❌ "Keep for safety"
  - ✅ "Package namespace is the only layout since v3.25. Flat loaders deleted."

#### 2.6.2 Convert

If "empty/skip" is the safe semantic outcome but the original `with _ ->` swallows all exceptions silently, convert to log + fallback:

```ocaml
(* ✅ tolerated but explicit *)
let collect_files_sorted dir =
  try Sys.readdir dir |> Array.to_list |> List.sort String.compare
  with Sys_error e ->
    log_warn (Printf.sprintf "collect_files_sorted %s: %s" dir e);
    []
```

Use this form only when "skip/empty" is a deliberately safe outcome.

#### 2.6.3 Keep

Keep a compatibility path only if all are true:

- it protects a real still-live transition or bootstrapping condition
- it is fail-closed or explicitly logged
- it has a reason in code comments or design docs
- it has an expiry or follow-up issue where appropriate

  - ❌ "Keep for safety"
  - ✅ "Keep until all peers use packet refs; reject loudly on ambiguity"

#### 2.6.4 Resource discovery rule

Any function that resolves binaries, config files, package contents, transport roots, or thread/event stores must either:

- validate existence and return `Result`
- or log a tolerated absence explicitly

Never construct a path and defer discovery of absence to a later opaque exec/IO failure.

#### 2.6.5 Audit rule

When you touch one fallback path class, audit the sibling surfaces in the same module/family.

Examples:
- if you convert one `with _ -> []`, grep for the others
- if you remove one compatibility helper, audit the other helpers in that layer
- if one reader now validates existence, check the parallel readers/scanners too

This is the same logic as type-disambiguation-at-definition: fix the class, not one symptom.

### 2.7 Anti-patterns

```ocaml
(* ❌ avoid *)
let x = ref 0                  (* mutable state outside local scope *)
for i = 0 to n do ... done     (* imperative loop *)
with _ -> None                  (* swallow all exceptions *)
with _ -> []                    (* fabricate empty state *)
with _ -> ""                    (* fabricate content *)
List.hd xs                      (* partial — use match *)
Option.get opt                  (* partial — use match *)
raise Parse_error               (* use Result.error *)
(* compatibility shim with no reason / expiry *)
let resolve_legacy = current_path
```

### 2.8 FFI (native system bindings)

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

### 2.9 Build

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

When overlapping names are unavoidable, annotate **all** access sites in one pass — not incrementally as the compiler complains across files.

### 3.2 Purity boundary rule

`lib/` and `protocol/` modules must be pure — no I/O, no Unix, no Sys. I/O lives in `ffi/`. Business logic in `cmd/` wires pure and impure.

### 3.3 Error and fallback rule

Use `Result` types for expected failures. Reserve exceptions for truly unexpected conditions. Never `with _ ->`.

Silent fallback is forbidden unless "empty/skip" is explicitly the safe semantic outcome. If a fallback is tolerated, it must be:
- intentional
- logged or made visible
- and justified as keep rather than accidental residue

Functions that resolve or construct paths to external resources (binaries, config files, package contents) should validate existence or return `Result` — don't construct a path and return it bare, deferring discovery of missing resources to the caller's opaque exec/IO failure.

  - ❌ `let resolve name = Path.join dir name` (caller gets `ENOENT` from exec)
  - ✅ `let resolve name = let p = Path.join dir name in if exists p then Ok p else Error (sprintf "not found: %s" p)`

### 3.4 Compatibility-path rule

Every compatibility path must be explicitly classified:
- **remove** — delete it
- **convert** — log + fallback
- **keep** — justify, make fail-closed or operator-visible, record expiry/follow-up

Do not leave ambiguous legacy behavior in place.

### 3.5 Test rule

Every module gets ppx_expect inline tests. The expect-test output is the behavioral contract. If the output changes, the test fails — review the diff.

Every module gets ppx_expect inline tests. The expect-test output is the behavioral contract. If the output changes, the test fails — review the diff.

For fallback conversions, test both:
- the positive path
- the degraded / missing / malformed path

  - ❌ only test success
  - ✅ test success and the explicit failure/fallback behavior

### 3.6 Build-before-push rule

Run `dune build` locally before pushing. If the toolchain is not available, treat type disambiguation as a project-wide audit: grep for all access sites of overlapping field names and annotate them in one pass.

If you changed fallback/compatibility behavior, perform the same class-wide audit:
- grep for sibling `with _ ->`
- grep for silent `[]` / `None` fabrication
- grep for parallel resolver/scanner paths

### 3.7 Mechanical fallback smell list

Treat these as review smells that require justification or conversion:

- `with _ -> []`
- `with _ -> None`
- `with _ -> ""`
- swallowing `Sys_error`
- swallowing directory-read failures
- compatibility aliases with no comment or expiry
- returning constructed external paths without checking existence

### 3.8 Toolchain

```bash
opam switch create cnos 4.14.1
opam install dune ppx_expect ppxlib mdx
```
