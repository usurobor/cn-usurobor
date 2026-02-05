# FUNCTIONAL — Think in Transformations

Write code that describes *what*, not *how*. Data flows through pure functions. State is explicit. Side effects are contained.

---

## Core Principles

### 1. Pattern Matching Over Conditionals

**Avoid:**
```ocaml
let describe x =
  if x = 0 then "zero"
  else if x > 0 then "positive"
  else "negative"
```

**Prefer:**
```ocaml
let describe = function
  | 0 -> "zero"
  | n when n > 0 -> "positive"
  | _ -> "negative"
```

Pattern matching is exhaustive — the compiler catches missing cases.

---

### 2. Pipelines Over Sequences

**Avoid:**
```ocaml
let result = 
  let trimmed = String.trim input in
  let lines = String.split_on_char '\n' trimmed in
  let filtered = List.filter non_empty lines in
  List.map process filtered
```

**Prefer:**
```ocaml
let result =
  input
  |> String.trim
  |> String.split_on_char '\n'
  |> List.filter non_empty
  |> List.map process
```

Data flows left to right. Each step is a transformation.

---

### 3. Immutable Over Mutable

**Avoid:**
```ocaml
let results = ref [] in
List.iter (fun x ->
  if predicate x then
    results := x :: !results
) items;
!results
```

**Prefer:**
```ocaml
items |> List.filter predicate
```

If you see `ref`, pause. There's usually a functional way.

---

### 4. Option/Result Over Null/Exceptions

**Avoid:**
```ocaml
let find_user id =
  try 
    let user = db_lookup id in
    user
  with Not_found -> null  (* or raise *)
```

**Prefer:**
```ocaml
let find_user id : user option =
  match db_lookup id with
  | user -> Some user
  | exception Not_found -> None
```

Encode failure in the type. The caller *must* handle it.

---

### 5. Types That Prevent Invalid States

**Avoid:**
```ocaml
type user = {
  name: string;
  email: string;        (* might be empty *)
  verified: bool;       (* might be inconsistent *)
}
```

**Prefer:**
```ocaml
type email = Unverified of string | Verified of string
type user = { name: string; email: email }
```

If `email` is `Verified`, it's verified. No boolean to check.

---

### 6. Small Functions That Compose

**Avoid:**
```ocaml
let process_file path =
  let content = read_file path in
  let lines = String.split_on_char '\n' content in
  let result = ref [] in
  for i = 0 to List.length lines - 1 do
    let line = List.nth lines i in
    if String.length line > 0 then begin
      let trimmed = String.trim line in
      if String.get trimmed 0 = '#' then
        result := (parse_header trimmed) :: !result
    end
  done;
  List.rev !result
```

**Prefer:**
```ocaml
let is_header s = 
  String.length s > 0 && String.get s 0 = '#'

let process_file path =
  path
  |> read_file
  |> String.split_on_char '\n'
  |> List.map String.trim
  |> List.filter is_header
  |> List.map parse_header
```

Each function does one thing. Composition does the rest.

---

### 7. Recursion Over Loops

**Avoid:**
```ocaml
let sum items =
  let total = ref 0 in
  for i = 0 to List.length items - 1 do
    total := !total + List.nth items i
  done;
  !total
```

**Prefer:**
```ocaml
let rec sum = function
  | [] -> 0
  | x :: xs -> x + sum xs

(* Or use fold: *)
let sum items = List.fold_left (+) 0 items
```

Loops mutate. Recursion transforms.

---

### 8. Fold Over Manual Accumulation

**Avoid:**
```ocaml
let counts = Hashtbl.create 10 in
List.iter (fun word ->
  let count = try Hashtbl.find counts word with Not_found -> 0 in
  Hashtbl.replace counts word (count + 1)
) words;
counts
```

**Prefer:**
```ocaml
let count_words words =
  words |> List.fold_left (fun acc word ->
    let count = Option.value ~default:0 (Map.find_opt word acc) in
    Map.add word (count + 1) acc
  ) Map.empty
```

Fold is the universal iterator. Master it.

---

### 9. Explicit Effects

**Avoid:**
```ocaml
let process item =
  print_endline ("Processing: " ^ item);  (* hidden side effect *)
  let result = transform item in
  save_to_db result;                       (* hidden side effect *)
  result
```

**Prefer:**
```ocaml
type 'a effect = Log of string | Save of 'a | Pure of 'a

let process item =
  [Log ("Processing: " ^ item); 
   Save (transform item)]
```

Make effects visible. Execution happens at the boundary.

---

### 10. Total Functions

**Avoid:**
```ocaml
let head = function
  | x :: _ -> x
  | [] -> failwith "empty list"  (* partial: crashes on [] *)
```

**Prefer:**
```ocaml
let head = function
  | x :: _ -> Some x
  | [] -> None
```

Total functions handle all inputs. Partial functions lie about their type.

---

## Red Flags

When you see these, refactor:

| Smell | Alternative |
|-------|-------------|
| `ref` | Fold, recursion, or pipeline |
| `for`/`while` | `List.map`, `List.fold`, recursion |
| `if`/`else` chains | Pattern matching |
| `try`/`with` for control flow | Option/Result types |
| Mutable fields | Immutable records + copy |
| `null`/`None` checks everywhere | Option.map, Option.bind |
| Deeply nested code | Pipeline, extract functions |

---

## The Functional Mindset

> "A program is a transformation of data, not a sequence of commands."

Think:
- **Inputs → Outputs** (not step 1, step 2, step 3)
- **What, not how** (declare the transformation, not the procedure)
- **Values, not variables** (data doesn't change; you make new data)
- **Composition, not inheritance** (small functions that combine)

---

## Why This Matters

Functional code is:
- **Testable** — pure functions, same input = same output
- **Composable** — small pieces combine into larger pieces  
- **Verifiable** — types catch errors at compile time
- **Parallelizable** — no shared mutable state
- **Readable** — data flow is explicit

Imperative code hides state transitions. Functional code makes them visible.

---

*"The purpose of abstraction is not to be vague, but to create a new semantic level in which one can be absolutely precise."* — Dijkstra
