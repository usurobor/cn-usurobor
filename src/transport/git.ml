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

    All functions are thin wrappers over git CLI.
    Uses Cn_ffi.Child_process for shell execution.
    Returns Option for operations that can fail.
*)

let exec = Cn_ffi.Child_process.exec_in

let split_lines s =
  s |> String.trim |> String.split_on_char '\n' |> List.filter (fun s -> String.length s > 0)

(* === Core Operations === *)

let fetch ~cwd =
  exec ~cwd "git fetch origin" |> Option.is_some

let add_all ~cwd =
  exec ~cwd "git add -A" |> Option.is_some

let commit ~cwd ~msg =
  exec ~cwd (Printf.sprintf "git commit -m %s" (Filename.quote msg)) |> Option.is_some

let push ~cwd =
  exec ~cwd "git push origin HEAD" |> Option.is_some

let push_branch ~cwd ~branch ~force =
  let force_flag = if force then "-f " else "" in
  exec ~cwd (Printf.sprintf "git push %s-u origin %s" force_flag branch) |> Option.is_some

let pull_ff ~cwd =
  exec ~cwd "git pull --ff-only" |> Option.is_some

(* === Branch Operations === *)

let current_branch ~cwd =
  exec ~cwd "git branch --show-current"
  |> Option.map String.trim

let remote_branches ~cwd ~prefix =
  let cmd = Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" prefix in
  exec ~cwd cmd
  |> Option.map split_lines
  |> Option.value ~default:[]

let checkout ~cwd ~branch =
  exec ~cwd (Printf.sprintf "git checkout %s" branch) |> Option.is_some

let checkout_create ~cwd ~branch =
  exec ~cwd (Printf.sprintf "git checkout -b %s 2>/dev/null || git checkout %s" branch branch) |> Option.is_some

let checkout_main ~cwd =
  exec ~cwd "git checkout main 2>/dev/null || git checkout master" |> Option.is_some

let delete_local_branch ~cwd ~branch =
  exec ~cwd (Printf.sprintf "git branch -D %s 2>/dev/null" branch) |> Option.is_some

(* === Query Operations === *)

let status_porcelain ~cwd =
  exec ~cwd "git status --porcelain"
  |> Option.map String.trim
  |> Option.value ~default:""

let is_dirty ~cwd =
  status_porcelain ~cwd <> ""

let show ~cwd ~ref ~path =
  exec ~cwd (Printf.sprintf "git show %s:%s" ref path)

let diff_files ~cwd ~base ~head =
  let cmd = Printf.sprintf "git diff %s...%s --name-only 2>/dev/null" base head in
  exec ~cwd cmd
  |> Option.map split_lines
  |> Option.value ~default:[]

let rev_parse ~cwd ~ref =
  exec ~cwd (Printf.sprintf "git rev-parse --short %s 2>/dev/null" ref)
  |> Option.map String.trim

let log_oneline ~cwd ~count =
  exec ~cwd (Printf.sprintf "git log --oneline -%d" count)
  |> Option.map split_lines
  |> Option.value ~default:[]

(* === Repo Setup === *)

let init ~cwd =
  exec ~cwd "git init -b main" |> Option.is_some

let clone ~url ~dest =
  exec ~cwd:"." (Printf.sprintf "git clone %s %s" url dest) |> Option.is_some
