# Refactoring Plan: Splitting `cn.ml` into 10 Focused Modules

## Current State

`cn.ml` is 2,084 lines — the CLI wiring layer for a Melange/Node.js application. It mixes
FFI bindings, output formatting, hub discovery, mail transport, GTD lifecycle, queue
management, agent I/O, thread creation, peer management, system setup, and the main
dispatch loop — all in one file.

The existing layering is sound:

```
cn.ml      → CLI wiring (2,084 lines — THIS is the problem)
cn_io.ml   → Protocol I/O (204 lines — clean, focused)
cn_lib.ml  → Pure types & parsing (610 lines — tested, pure)
git.ml     → Raw git operations (109 lines — minimal)
```

## Design Principles

1. **One concern per module.** Each new module owns a single domain (mail, GTD, queue, etc.).
2. **Preserve the pure/effectful boundary.** `cn_lib.ml` stays pure. New modules handle
   effects but are grouped by domain, not by "pure vs effectful."
3. **Shared FFI in one place.** The Node.js FFI bindings (`Fs`, `Path`, `Child_process`,
   `Yaml`, `Json`, `Process`, `Str`) are duplicated across `cn.ml` and `cn_io.ml` today.
   Extract them into a single `cn_ffi.ml` module that everything uses.
4. **Shared helpers together.** Output formatting (colors, symbols), time helpers, dry-run
   mode, hub discovery, and path constants form a small shared "context" module.
5. **Thin dispatch in cn.ml.** After extraction, `cn.ml` becomes ~100 lines: parse args,
   find hub, dispatch to the right module's `run_*` function.
6. **No .mli files yet.** The codebase doesn't use them. Add them later once interfaces
   stabilize.
7. **Merge where there's domain affinity, not just because things are small.** Don't create
   grab-bag modules. Merge when modules share a domain model or when one is pure
   infrastructure for the other.

## Why 10 Modules (Not 14 or 8)

### Why not 14

The 14-module plan's domain analysis was correct, but over-fragmented:

- `cn_queue` (80 lines) is just FIFO infrastructure for agent — absorb it.
- `cn_threads` (thread creation) and `cn_gtd` (thread lifecycle) are the same domain — merge.
- `cn_peers` and `cn_git_cmd` are both small leaf commands with no shared primitives — merge.
- `cn_init` is hub bootstrapping, `cn_system` is hub maintenance — same lifecycle theme, merge.

### Why not 8

The 8-module proposal merged too aggressively:

- **MCA is a domain, not agent plumbing.** It has user-facing commands (`cn mca add`,
  `cn mca list`), its own state directory (`state/mca/`), and its own review cycle.
  Burying it inside `cn_agent` makes it invisible as a first-class concept.

- **`find_thread` creates a dependency inversion.** GTD owns `find_thread`, which is called
  by `execute_op` in agent (line 893). If GTD merges into a `cn_commands` grab-bag, then
  `cn_agent` depends on `cn_commands` — orchestration depending on the user-command layer.
  That inverts the natural dependency direction. GTD must sit *below* agent in the graph.

- **"All user commands" is a weak grouping.** GTD (thread state transitions), peers (peer
  list management), and git commands (commit/push) share no domain model. Merging them
  creates a mini-monolith.

## Proposed Module Structure

```
cn_ffi.ml       (~70 lines)  — Node.js FFI bindings (Fs, Path, Process, Child_process, Yaml, Json, Str)
cn_fmt.ml       (~60 lines)  — Output formatting (colors, symbols, ok/fail/warn/info)
cn_hub.ml       (~100 lines) — Hub discovery, path constants, timestamp helpers, load_peers, shared utilities
cn_mail.ml      (~350 lines) — Branch ops, orphan detection, inbox (check/process/flush), outbox (check/flush/send)
cn_gtd.ml       (~220 lines) — Thread lifecycle (find/delete/defer/delegate/do/done) + thread creation (adhoc/daily/weekly)
cn_agent.ml     (~300 lines) — Agent I/O, queue FIFO, execute_op, archive, wake, run_out, run_inbound
cn_mca.ml       (~120 lines) — Managed Concern Aggregation: add, list, count, cycle, queue_mca_review
cn_commands.ml  (~160 lines) — Peers (list/add/remove/sync) + git commands (commit/push/send/reply)
cn_system.ml    (~240 lines) — Setup, update, self-update, runtime, cron, hub initialization (init)
cn.ml           (~100 lines) — Main: parse args, find hub, dispatch
```

**Total: 10 modules instead of 1.** Each under 350 lines. The average is ~170 lines.

## Dependency Graph

```
cn_ffi          (leaf — no project deps, only Melange externals)
  ↑
cn_fmt          (depends on: cn_ffi)
  ↑
cn_hub          (depends on: cn_ffi, cn_fmt, cn_lib)
  ↑
  ├── cn_mail       (depends on: cn_ffi, cn_fmt, cn_hub, cn_lib)
  ├── cn_gtd        (depends on: cn_ffi, cn_fmt, cn_hub, cn_lib)
  ├── cn_mca        (depends on: cn_ffi, cn_fmt, cn_hub, cn_lib)
  ├── cn_commands   (depends on: cn_ffi, cn_fmt, cn_hub, cn_lib)
  ├── cn_system     (depends on: cn_ffi, cn_fmt, cn_hub, cn_lib)
  └── cn_agent      (depends on: cn_ffi, cn_fmt, cn_hub, cn_lib, cn_gtd, cn_mca, cn_mail)
        ↑
        cn.ml       (depends on: all of the above — thin dispatch)
```

Key property: **cn_agent depends on cn_gtd** (for `find_thread`), **not** the reverse.
`cn_commands` is a leaf — nothing depends on it except `cn.ml` dispatch.

## Module Details

### 1. `cn_ffi.ml` — Node.js FFI Bindings (~70 lines)

Extract verbatim from `cn.ml` lines 37–98. Also consolidate the duplicate `Fs`/`Path`
bindings from `cn_io.ml` lines 28–46 into this single source. Both files currently
declare their own `Fs.exists`, `Fs.read`, etc.

```ocaml
(* cn_ffi.ml — Node.js FFI bindings (Melange externals) *)
module Process = struct ... end     (* argv, cwd, exit, env *)
module Fs = struct ... end          (* exists, read, write, append, unlink, readdir, mkdir_p, ensure_dir *)
module Path = struct ... end        (* join, dirname, basename, basename_ext *)
module Yaml = struct ... end        (* parse, stringify *)
module Child_process = struct ... end  (* exec_in, exec *)
module Json = struct ... end        (* stringify *)
module Str = struct ... end         (* from_code_point *)
```

`cn_io.ml` and `git.ml` can be updated to use `Cn_ffi.Fs` / `Cn_ffi.Path` instead of
their own copies, or they can keep their own minimal bindings if you want those libraries
to remain self-contained (a deliberate trade-off).

### 2. `cn_fmt.ml` — Output Formatting (~60 lines)

Lines 101–123 + dry-run mode (126–137) + `now_iso`.

```ocaml
(* cn_fmt.ml — Terminal output formatting *)
val check : string
val cross : string
val warning : string
val now_iso : unit -> string
val no_color : bool
val green : string -> string
val red : string -> string
val yellow : string -> string
val cyan : string -> string
val dim : string -> string
val ok : string -> string
val fail : string -> string
val warn : string -> string
val info : string -> string
val dry_run_mode : bool ref
val would : string -> bool
val dry_run_banner : unit -> unit
```

### 3. `cn_hub.ml` — Hub Context & Path Constants (~100 lines)

Lines 141–200 + `load_peers` (162–166) + `is_md_file`, `split_lines`, `slugify` (170–177)
\+ path constants (181–187) + timestamp helpers (191–200) + `log_action` (154–158).

```ocaml
(* cn_hub.ml — Hub discovery, paths, and shared utilities *)
val find_hub_path : string -> string option
val log_action : string -> string -> string -> unit
val load_peers : string -> Cn_lib.peer_info list
val is_md_file : string -> bool
val split_lines : string -> string list
val slugify : string -> string
val threads_in : string -> string
val threads_mail_inbox : string -> string
val threads_mail_outbox : string -> string
val threads_mail_sent : string -> string
val threads_reflections_daily : string -> string
val threads_reflections_weekly : string -> string
val threads_adhoc : string -> string
val timestamp_slug : unit -> string
val make_thread_filename : string -> string
```

### 4. `cn_mail.ml` — Mail Transport (~350 lines)

Lines 202–529 + `inbox_flush` (1821–1866). This is the largest extracted module
because mail transport is a cohesive domain: branch operations, orphan detection,
materialization, and send/flush are tightly coupled.

```ocaml
(* cn_mail.ml — Inbox/outbox mail transport *)
(* Branch operations *)
val delete_remote_branch : string -> string -> bool
val is_orphan_branch : string -> string -> bool
val get_branch_author : string -> string -> string
val reject_orphan_branch : string -> string -> string -> unit
val parse_rejected_branch : string -> string option
val cleanup_rejected_branch : string -> string -> bool
val process_rejection_cleanup : string -> string -> unit

(* Inbox *)
type branch_info = { peer: string; branch: string }
val get_inbound_branches : string -> string -> branch_info list
val inbox_check : string -> string -> unit
val materialize_branch : ...
val inbox_process : string -> unit
val inbox_flush : string -> string -> unit

(* Outbox *)
val outbox_check : string -> unit
val send_thread : ...
val outbox_flush : string -> string -> unit

(* Next item helper *)
val get_next_inbox_item : string -> (string * string * string * string) option
val run_next : string -> unit
```

### 5. `cn_gtd.ml` — Thread Operations (~220 lines)

**Merged from:** cn_gtd (14-plan) + cn_threads (14-plan).

Thread lifecycle (lines 558–680) + thread creation (lines 1277–1377).
These share a domain: GTD manages thread state transitions, threads creates new threads.
Together they cover the full thread lifecycle from birth to archive.

```ocaml
(* cn_gtd.ml — Thread lifecycle and creation *)

(* Finding *)
val find_thread : string -> string -> string option

(* GTD state transitions *)
val gtd_delete : string -> string -> unit
val gtd_defer : string -> string -> string option -> unit
val gtd_delegate : string -> string -> string -> string -> unit
val gtd_do : string -> string -> unit
val gtd_done : string -> string -> unit

(* Reading / listing *)
val run_read : string -> string -> unit
val run_inbox_list : string -> unit
val run_outbox_list : string -> unit

(* Thread creation *)
val run_adhoc : string -> string -> unit
val run_daily : string -> unit
val run_weekly : string -> unit
```

### 6. `cn_agent.ml` — Agent I/O & Queue (~300 lines)

**Merged from:** cn_agent (14-plan) + cn_queue (14-plan).

Agent I/O (lines 873–1030, 1091–1115, 1381–1497, 1584–1642) + queue FIFO
(lines 828–870, 1034–1088, 1186–1209).

Queue is 80 lines of FIFO infrastructure used primarily by agent (`feed_next_input`,
`queue_inbox_items`) and MCA (`queue_mca_review`). It's agent plumbing, not a domain.

```ocaml
(* cn_agent.ml — Agent I/O, queue, and execution *)

(* Queue FIFO *)
val queue_dir : string -> string
val queue_add : string -> string -> string -> string -> string
val queue_pop : string -> string option
val queue_count : string -> int
val queue_list : string -> string list
val queue_inbox_items : string -> int
val feed_next_input : string -> bool
val run_queue_list : string -> unit
val run_queue_clear : string -> unit

(* Agent I/O *)
val input_path : string -> string
val output_path : string -> string
val get_file_id : string -> string option
val execute_op : string -> string -> string -> Cn_lib.agent_op -> unit
val archive_io_pair : string -> string -> bool
val shell_escape : string -> string
val wake_agent : string -> unit
val auto_save : string -> string -> unit
val run_out : string -> string -> Cn_lib.Out.gtd -> unit
val run_inbound : string -> string -> unit
```

### 7. `cn_mca.ml` — Managed Concerns (~120 lines)

Lines 889 (mca_dir) + 1211–1275 (run_mca_add, run_mca_list) + 1499–1582
(mca_cycle, mca_count, queue_mca_review).

MCA stays separate because it's a first-class domain: it has user-facing commands
(`cn mca add`, `cn mca list`), its own state directory (`state/mca/`), and its own
review cycle. It depends on `Cn_agent.queue_add` for review injection.

```ocaml
(* cn_mca.ml — Managed Concern Aggregation *)
val mca_dir : string -> string
val mca_count : string -> int
val run_mca_add : string -> string -> string -> unit
val run_mca_list : string -> unit
val mca_review_interval : int
val get_mca_cycle : string -> int
val increment_mca_cycle : string -> int
val queue_mca_review : string -> string -> unit
```

### 8. `cn_commands.ml` — Peer & Git Commands (~160 lines)

**Merged from:** cn_peers (14-plan) + cn_git_cmd (14-plan).

Peers (lines 1747–1817) + git commands (lines 682–751). Both are small, leaf-level
user commands with no shared primitives. Nothing depends on them except dispatch.

```ocaml
(* cn_commands.ml — Leaf user commands: peers + git *)

(* Peer management *)
val format_peers_md : Cn_lib.peer_info list -> string
val run_peer_list : string -> unit
val run_peer_add : string -> string -> string -> unit
val run_peer_remove : string -> string -> unit
val run_peer_sync : string -> unit

(* Git commands *)
val run_commit : string -> string -> string option -> unit
val run_push : string -> unit
val run_send : string -> string -> string -> unit
val run_reply : string -> string -> string -> unit
```

### 9. `cn_system.ml` — System Lifecycle (~240 lines)

**Merged from:** cn_system (14-plan) + cn_init (14-plan).

System setup/updates (lines 1118–1165, 1868–2005) + hub initialization (lines 1644–1745).
Init already calls `update_runtime` from system. Both are "hub lifecycle" — one creates
hubs, the other maintains them.

```ocaml
(* cn_system.ml — System setup, updates, and hub initialization *)
val update_runtime : string -> unit
val run_setup : string -> unit
val update_cron : string -> unit
val run_update : unit -> unit
val run_update_with_cron : string -> unit
val self_update_check : unit -> unit
val run_init : string option -> unit
```

### 10. `cn.ml` — Thin Dispatch (~100 lines)

What remains: `open` the modules, parse args, find hub, match command → call the
right module.

```ocaml
(* cn.ml — CLI entrypoint, thin dispatch *)
open Cn_lib

let () =
  Cn_system.self_update_check ();
  let args = Cn_ffi.Process.argv |> Array.to_list |> drop 2 in
  let flags, cmd_args = parse_flags args in
  Cn_fmt.dry_run_mode := flags.dry_run;
  if flags.dry_run then Cn_fmt.dry_run_banner ();
  match parse_command cmd_args with
  | None -> ...
  | Some Help -> ...
  | Some Version -> ...
  | Some Update -> ...
  | Some (Init name) -> Cn_system.run_init name
  | Some cmd ->
      match Cn_hub.find_hub_path (Cn_ffi.Process.cwd ()) with
      | None -> ...
      | Some hub_path ->
          let name = derive_name hub_path in
          match cmd with
          | Status -> Cn_system.run_status hub_path name
          | Inbox Inbox.Check -> Cn_mail.inbox_check hub_path name
          | Gtd (Gtd.Delete t) -> Cn_gtd.gtd_delete hub_path t
          | Mca (Mca.Add desc) -> Cn_mca.run_mca_add hub_path name desc
          | Peer (Peer.List) -> Cn_commands.run_peer_list hub_path
          (* ... etc ... *)
```

## Dune Build Configuration

Replace the single `(melange.emit (modules cn) ...)` with a library wrapping all
extracted modules, plus the thin `cn` entrypoint:

```scheme
; Shared FFI
(library
 (name cn_ffi)
 (modules cn_ffi)
 (modes melange)
 (preprocess (pps melange.ppx)))

; CN command modules (all share cn_ffi, cn_lib)
(library
 (name cn_cmd)
 (modules cn_fmt cn_hub cn_mail cn_gtd cn_agent cn_mca
          cn_commands cn_system)
 (libraries cn_ffi cn_lib inbox_lib git cn_io)
 (modes melange)
 (preprocess (pps melange.ppx)))

; CLI entrypoint
(melange.emit
 (target output)
 (alias cn)
 (modules cn)
 (libraries cn_cmd cn_ffi cn_lib inbox_lib git cn_io)
 (module_systems commonjs)
 (preprocess (pps melange.ppx)))
```

## Execution Order

Phase 1 — Foundation:
1. Create `cn_ffi.ml` (extract FFI bindings)
2. Create `cn_fmt.ml` (extract formatting + dry-run)
3. Create `cn_hub.ml` (extract hub discovery + path constants + shared helpers)

Phase 2 — Domain modules (can be done in parallel):
4. Create `cn_gtd.ml` (merge thread lifecycle + thread creation)
5. Create `cn_mail.ml` (extract mail transport)
6. Create `cn_mca.ml` (extract managed concerns)
7. Create `cn_commands.ml` (merge peers + git commands)

Phase 3 — Orchestration:
8. Create `cn_agent.ml` (merge agent I/O + queue)
9. Create `cn_system.ml` (merge system + init)

Phase 4 — Finalize:
10. Slim `cn.ml` down to thin dispatch
11. Update `dune` build config
12. Build and verify

## Key OCaml Patterns Used

- **Module as namespace**: Each file is a module. No nested `module M = struct ... end`
  inside these files — keep it flat.
- **Open sparingly**: Each module does `open Cn_lib` (for types) and references
  `Cn_ffi.Fs`, `Cn_fmt.ok`, `Cn_hub.load_peers` explicitly. No cascading opens.
- **Labeled arguments**: Preserve the existing `~cwd`, `~hub` convention.
- **Option over exceptions**: Maintained throughout — all fallible ops return `option`.
- **Records for context**: If passing `hub_path` + `name` everywhere gets tedious,
  introduce `type ctx = { hub: string; name: string }` in `cn_hub.ml` later.
  Don't over-engineer it upfront.
