---
name: functional
description: Write code in functional style — pure core, effects at edges, composition over mutation. Use for design decisions, refactoring toward FP, or reviewing code for functional patterns.
---

# Functional Programming

## Core Principle

**Pure core, effects at edges.**

Business logic is pure functions. I/O, state, and time live at the boundary. The pure core is trivially testable; the effectful shell is thin and auditable.

## 1. Purity

### 1.1 Isolate Effects (see also: coding §2.3)

```
❌ parse_and_write(path)           -- mixed
✅ content |> parse |> write       -- separated
```

### 1.2 Return, Don't Mutate

```
❌ let count = ref 0 in ... incr count
✅ let rec loop acc = ... loop (acc + 1)
```

### 1.3 Localize Mutable State

When mutation is necessary (e.g., parsers), contain it:

```ocaml
(* State doesn't escape — API is pure *)
type state = { src: string; mutable pos: int }
let parse s =
  let st = { src = s; pos = 0 } in
  parse_value st  (* returns Result, no state leaks *)
```

**Case study: `cn_json.ml`** — full JSON parser using localized mutable `pos`.
API is `parse : string -> (t, string) result` — pure. Internally uses
`{ src; mutable pos }` for efficient single-pass parsing. Errors return
position info: `Error (sprintf "expected X at pos %d" st.pos)`.

## 2. Composition

### 2.1 Pipelines Over Sequences

```
❌ let a = f x in let b = g a in h b
✅ x |> f |> g |> h
```

### 2.2 Small Functions That Compose

```
❌ process_everything(input)
✅ input |> validate |> transform |> emit
```

### 2.3 Map/Filter/Fold Over Loops

```
❌ for i = 0 to n do ... done
✅ List.map f items
✅ List.filter_map extract items   (* filter + map in one pass *)
✅ List.fold_left combine init items
```

## 3. Types as Constraints

### 3.1 Closed Sum Types

Make invalid states unrepresentable:

```ocaml
❌ type status = string
✅ type status = Pending | Active | Closed
```

### 3.2 Semantic Newtypes

```ocaml
❌ let send (to_: string) (msg: string) = ...
✅ type peer_id = PeerId of string
   let send (PeerId to_) (msg: string) = ...
```

### 3.3 Result Over Exceptions

```ocaml
❌ raise (Parse_error "unexpected")
✅ Error (Printf.sprintf "expected X at pos %d" pos)
```

### 3.4 Option Over Null Checks

```ocaml
❌ if x = "" then ... else ...
✅ match find key map with Some v -> ... | None -> ...
```

## 4. Error Handling

### 4.1 Explicit Error Paths

```ocaml
(* Every function that can fail returns Result *)
let parse s : (value, string) result = ...
let load path : (config, string) result = ...
```

### 4.2 Early Return Pattern

```ocaml
match step1 () with
| Error e -> Error e
| Ok a ->
  match step2 a with
  | Error e -> Error e
  | Ok b -> Ok (finish b)
```

Or with bind:
```ocaml
let ( let* ) = Result.bind in
let* a = step1 () in
let* b = step2 a in
Ok (finish b)
```

### 4.3 Fun.protect for Cleanup

```ocaml
let read path =
  let ic = open_in path in
  Fun.protect ~finally:(fun () -> close_in_noerr ic) (fun () ->
    really_input_string ic (in_channel_length ic))
```

## 5. Testing

### 5.1 Pure Functions Are Trivially Testable

No mocking, no setup, no teardown:

```ocaml
let%expect_test "parse null" =
  match parse "null" with
  | Ok Null -> print_endline "null"
  | _ -> print_endline "FAIL";
  [%expect {| null |}]
```

### 5.2 Test the Pure Core Exhaustively

Effects are thin wrappers — test them minimally. Pure logic gets full coverage.

## Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| `ref` for accumulation | Recursive loop with accumulator |
| `for`/`while` loops | `List.map`, `fold_left`, recursion |
| Exception for control flow | `Result` or `Option` |
| `Option.get` / `List.hd` | Pattern match explicitly |
| Mixed pure/effectful | Separate into core/shell |
| String for everything | Sum types, newtypes |

## When to Break Rules

1. **Performance-critical hot paths** — mutation may be necessary
2. **Parser internals** — mutable pos is fine if API is pure
3. **FFI boundaries** — imperative style may be clearer

Document the exception. Contain it. Don't let it leak.
