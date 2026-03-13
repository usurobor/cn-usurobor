(** git.ml — Raw git operations

    DESIGN: This module contains ONLY raw git operations.
    No CN protocol knowledge. No business logic.

    Layering (deliberate):
      cn.ml → cn_io.ml → git.ml
              ↑           ↑
              CN semantics │
                          raw git

    Why separate?
    - Testable: can mock git.ml for cn_io tests
    - Portable: git.ml works for any git workflow
    - Clear: CN protocol lives in cn_io, not here

    Execution:
    - Core sync operations (fetch, add, commit, push) use argv-style
      execution via Process.exec_args for safety and error propagation.
    - Branch/query operations use shell execution via Child_process.exec_in
      for convenience (pipelines, redirects). These are read-only or
      developer-workflow operations where shell is acceptable.
*)

(* Shell-based execution — used by branch/query operations *)
let exec = Cn_ffi.Child_process.exec_in

(* Argv-style execution — used by core sync operations.
   Returns (exit_code, output). No shell involved. *)
let exec_argv ~cwd args =
  Cn_ffi.Process.exec_args ~prog:"git"
    ~args:("-C" :: cwd :: args) ()

let split_lines s =
  s |> String.trim |> String.split_on_char '\n' |> List.filter (fun s -> String.length s > 0)

(* === Core Sync Operations (argv-style, result-returning) === *)

(** Fetch from origin. Returns Ok output or Error (code, output). *)
let fetch_r ~cwd =
  match exec_argv ~cwd ["fetch"; "origin"] with
  | (0, out) -> Ok out
  | (code, out) -> Error (code, out)

(** Stage all changes. Returns Ok output or Error (code, output). *)
let add_all_r ~cwd =
  match exec_argv ~cwd ["add"; "-A"] with
  | (0, out) -> Ok out
  | (code, out) -> Error (code, out)

(** Commit with message. Returns Ok output or Error (code, output). *)
let commit_r ~cwd ~msg =
  match exec_argv ~cwd ["commit"; "-m"; msg] with
  | (0, out) -> Ok out
  | (code, out) -> Error (code, out)

(** Commit with --allow-empty. Returns Ok output or Error (code, output). *)
let commit_allow_empty_r ~cwd ~msg =
  match exec_argv ~cwd ["commit"; "--allow-empty"; "-m"; msg] with
  | (0, out) -> Ok out
  | (code, out) -> Error (code, out)

(** Push HEAD to origin. Returns Ok output or Error (code, output). *)
let push_r ~cwd =
  match exec_argv ~cwd ["push"; "origin"; "HEAD"] with
  | (0, out) -> Ok out
  | (code, out) -> Error (code, out)

(* === Legacy boolean API (used by existing callers) === *)

let fetch ~cwd =
  exec ~cwd "git fetch origin" |> Option.is_some

let add_all ~cwd =
  exec ~cwd "git add -A" |> Option.is_some

let commit ~cwd ~msg =
  exec ~cwd (Printf.sprintf "git commit -m %s" (Filename.quote msg)) |> Option.is_some

let commit_allow_empty ~cwd ~msg =
  exec ~cwd (Printf.sprintf "git commit --allow-empty -m %s" (Filename.quote msg)) |> Option.is_some

let push ~cwd =
  exec ~cwd "git push origin HEAD" |> Option.is_some

let push_branch ~cwd ~branch ~force =
  let force_flag = if force then "-f " else "" in
  exec ~cwd (Printf.sprintf "git push %s-u origin %s" force_flag (Filename.quote branch)) |> Option.is_some

let pull_ff ~cwd =
  exec ~cwd "git pull --ff-only" |> Option.is_some

(* === Branch Operations === *)

let current_branch ~cwd =
  exec ~cwd "git branch --show-current"
  |> Option.map String.trim

let remote_branches ~cwd ~prefix =
  let cmd = Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" (Filename.quote prefix) in
  exec ~cwd cmd
  |> Option.map split_lines
  |> Option.value ~default:[]

let checkout ~cwd ~branch =
  exec ~cwd (Printf.sprintf "git checkout %s" (Filename.quote branch)) |> Option.is_some

let checkout_create ~cwd ~branch =
  let bq = Filename.quote branch in
  exec ~cwd (Printf.sprintf "git checkout -b %s 2>/dev/null || git checkout %s" bq bq) |> Option.is_some

let checkout_main ~cwd =
  exec ~cwd "git checkout main 2>/dev/null || git checkout master" |> Option.is_some

let delete_local_branch ~cwd ~branch =
  exec ~cwd (Printf.sprintf "git branch -D %s 2>/dev/null" (Filename.quote branch)) |> Option.is_some

(* === Query Operations === *)

let status_porcelain ~cwd =
  exec ~cwd "git status --porcelain"
  |> Option.map String.trim
  |> Option.value ~default:""

let is_dirty ~cwd =
  status_porcelain ~cwd <> ""

let show ~cwd ~ref ~path =
  exec ~cwd (Printf.sprintf "git show %s" (Filename.quote (ref ^ ":" ^ path)))

let diff_files ~cwd ~base ~head =
  let cmd = Printf.sprintf "git diff %s...%s --name-only 2>/dev/null" (Filename.quote base) (Filename.quote head) in
  exec ~cwd cmd
  |> Option.map split_lines
  |> Option.value ~default:[]

let rev_parse ~cwd ~ref =
  exec ~cwd (Printf.sprintf "git rev-parse --short %s 2>/dev/null" (Filename.quote ref))
  |> Option.map String.trim

let log_oneline ~cwd ~count =
  exec ~cwd (Printf.sprintf "git log --oneline -%d" count)
  |> Option.map split_lines
  |> Option.value ~default:[]

(* === Repo Setup === *)

let init ~cwd =
  exec ~cwd "git init -b main" |> Option.is_some

let clone ~url ~dest =
  exec ~cwd:"." (Printf.sprintf "git clone %s %s" (Filename.quote url) (Filename.quote dest)) |> Option.is_some
