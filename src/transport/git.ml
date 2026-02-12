(** git.ml — Pure git operations

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
    Returns Option for operations that can fail.
*)

module Child_process = struct
  let exec_in ~cwd cmd =
    let full_cmd = Printf.sprintf "cd %s && %s" (Filename.quote cwd) cmd in
    try
      let ic = Unix.open_process_in full_cmd in
      let buf = Buffer.create 1024 in
      (try while true do Buffer.add_char buf (input_char ic) done
       with End_of_file -> ());
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> Some (Buffer.contents buf)
      | _ -> None
    with _ -> None
end

let split_lines s =
  s |> String.trim |> String.split_on_char '\n' |> List.filter (fun s -> String.length s > 0)

(* === Core Operations === *)

let fetch ~cwd =
  Child_process.exec_in ~cwd "git fetch origin" |> Option.is_some

let add_all ~cwd =
  Child_process.exec_in ~cwd "git add -A" |> Option.is_some

let commit ~cwd ~msg =
  let escaped = String.map (fun c -> if c = '"' then '\'' else c) msg in
  Child_process.exec_in ~cwd (Printf.sprintf "git commit -m \"%s\"" escaped) |> Option.is_some

let push ~cwd =
  Child_process.exec_in ~cwd "git push origin HEAD" |> Option.is_some

let push_branch ~cwd ~branch ~force =
  let force_flag = if force then "-f " else "" in
  Child_process.exec_in ~cwd (Printf.sprintf "git push %s-u origin %s" force_flag branch) |> Option.is_some

let pull_ff ~cwd =
  Child_process.exec_in ~cwd "git pull --ff-only" |> Option.is_some

(* === Branch Operations === *)

let current_branch ~cwd =
  Child_process.exec_in ~cwd "git branch --show-current"
  |> Option.map String.trim

let remote_branches ~cwd ~prefix =
  let cmd = Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" prefix in
  Child_process.exec_in ~cwd cmd
  |> Option.map split_lines
  |> Option.value ~default:[]

let checkout ~cwd ~branch =
  Child_process.exec_in ~cwd (Printf.sprintf "git checkout %s" branch) |> Option.is_some

let checkout_create ~cwd ~branch =
  Child_process.exec_in ~cwd (Printf.sprintf "git checkout -b %s 2>/dev/null || git checkout %s" branch branch) |> Option.is_some

let checkout_main ~cwd =
  Child_process.exec_in ~cwd "git checkout main 2>/dev/null || git checkout master" |> Option.is_some

let delete_local_branch ~cwd ~branch =
  Child_process.exec_in ~cwd (Printf.sprintf "git branch -D %s 2>/dev/null" branch) |> Option.is_some

(* === Query Operations === *)

let status_porcelain ~cwd =
  Child_process.exec_in ~cwd "git status --porcelain"
  |> Option.map String.trim
  |> Option.value ~default:""

let is_dirty ~cwd =
  status_porcelain ~cwd <> ""

let show ~cwd ~ref ~path =
  Child_process.exec_in ~cwd (Printf.sprintf "git show %s:%s" ref path)

let diff_files ~cwd ~base ~head =
  let cmd = Printf.sprintf "git diff %s...%s --name-only 2>/dev/null" base head in
  Child_process.exec_in ~cwd cmd
  |> Option.map split_lines
  |> Option.value ~default:[]

let rev_parse ~cwd ~ref =
  Child_process.exec_in ~cwd (Printf.sprintf "git rev-parse --short %s 2>/dev/null" ref)
  |> Option.map String.trim

let log_oneline ~cwd ~count =
  Child_process.exec_in ~cwd (Printf.sprintf "git log --oneline -%d" count)
  |> Option.map split_lines
  |> Option.value ~default:[]

(* === Repo Setup === *)

let init ~cwd =
  Child_process.exec_in ~cwd "git init -b main" |> Option.is_some

let clone ~url ~dest =
  Child_process.exec_in ~cwd:"." (Printf.sprintf "git clone %s %s" url dest) |> Option.is_some
