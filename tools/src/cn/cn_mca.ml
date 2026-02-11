(** cn_mca.ml — Managed Concern Aggregation

    MCA surfacing, listing, review cycle.
    First-class domain with user-facing commands (cn mca add/list)
    and its own state directory (state/mca/).

    Note: prepare_mca_review returns data for the caller to queue,
    avoiding a circular dependency with cn_agent. *)

open Cn_lib

(* === MCA Operations === *)

let run_mca_add hub_path name description =
  let dir = Cn_hub.mca_dir hub_path in
  Cn_ffi.Fs.ensure_dir dir;

  let ts = Cn_fmt.now_iso () |> Js.String.replaceByRe ~regexp:[%mel.re "/[:.]/g"] ~replacement:"-" in
  let slug =
    description
    |> Js.String.slice ~start:0 ~end_:40
    |> Js.String.toLowerCase
    |> Js.String.replaceByRe ~regexp:[%mel.re "/[^a-z0-9]+/g"] ~replacement:"-"
    |> Js.String.replaceByRe ~regexp:[%mel.re "/^-|-$/g"] ~replacement:""
  in
  let file_name = Printf.sprintf "%s-%s.md" ts slug in
  let file_path = Cn_ffi.Path.join dir file_name in

  let content = Printf.sprintf {|---
id: %s
surfaced-by: %s
created: %s
status: open
---

# MCA

%s
|} slug name (Cn_fmt.now_iso ()) description in

  Cn_ffi.Fs.write file_path content;
  Cn_hub.log_action hub_path "mca.add" (Printf.sprintf "id:%s desc:%s" slug description);
  print_endline (Cn_fmt.ok (Printf.sprintf "MCA surfaced: %s" description))

let run_mca_list hub_path =
  let dir = Cn_hub.mca_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then print_endline "(no MCAs)"
  else
    let items = Cn_ffi.Fs.readdir dir |> List.filter Cn_hub.is_md_file |> List.sort String.compare in
    match items with
    | [] -> print_endline "(no MCAs)"
    | _ ->
        print_endline (Cn_fmt.info (Printf.sprintf "Open MCAs: %d" (List.length items)));
        items |> List.iter (fun file ->
          let file_path = Cn_ffi.Path.join dir file in
          let content = Cn_ffi.Fs.read file_path in
          let meta = parse_frontmatter content in
          let id = meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)
            |> Option.value ~default:"?" in
          let by = meta |> List.find_map (fun (k, v) -> if k = "surfaced-by" then Some v else None)
            |> Option.value ~default:"?" in
          let lines = String.split_on_char '\n' content in
          let rec skip_frontmatter in_fm = function
            | [] -> []
            | "---" :: rest when not in_fm -> skip_frontmatter true rest
            | "---" :: rest when in_fm -> rest
            | _ :: rest when in_fm -> skip_frontmatter in_fm rest
            | rest -> rest
          in
          let body_lines = skip_frontmatter false lines in
          let desc = body_lines |> List.find_opt (fun l ->
            let t = String.trim l in t <> "" && not (starts_with ~prefix:"#" t))
            |> Option.value ~default:"(no description)" in
          print_endline (Printf.sprintf "  [%s] %s (by %s)" id (String.trim desc) by))

(* === MCA Review Cycle === *)

let mca_cycle_path hub_path = Cn_ffi.Path.join hub_path "state/.mca-cycle"
let mca_review_interval = 5

let get_mca_cycle hub_path =
  let path = mca_cycle_path hub_path in
  if Cn_ffi.Fs.exists path then
    int_of_string_opt (String.trim (Cn_ffi.Fs.read path)) |> Option.value ~default:0
  else 0

let increment_mca_cycle hub_path =
  let current = get_mca_cycle hub_path in
  let next = current + 1 in
  Cn_ffi.Fs.write (mca_cycle_path hub_path) (string_of_int next);
  next

let mca_count hub_path =
  let dir = Cn_hub.mca_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then 0
  else Cn_ffi.Fs.readdir dir |> List.filter Cn_hub.is_md_file |> List.length

(* Prepare MCA review: builds the review body, commits the event file,
   and returns (trigger, body, count) for the caller to queue.
   This avoids a circular dependency with cn_agent (which owns queue_add). *)
type review_event = {
  trigger: string;
  body: string;
  count: int;
}

let prepare_mca_review hub_path name =
  let dir = Cn_hub.mca_dir hub_path in
  let mcas = Cn_ffi.Fs.readdir dir |> List.filter Cn_hub.is_md_file |> List.sort String.compare in
  let mca_list = mcas |> List.map (fun file ->
    let content = Cn_ffi.Fs.read (Cn_ffi.Path.join dir file) in
    let meta = parse_frontmatter content in
    let id = meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)
      |> Option.value ~default:"?" in
    let by = meta |> List.find_map (fun (k, v) -> if k = "surfaced-by" then Some v else None)
      |> Option.value ~default:"?" in
    let lines = String.split_on_char '\n' content in
    let rec skip_fm in_fm = function
      | [] -> []
      | "---" :: rest when not in_fm -> skip_fm true rest
      | "---" :: rest when in_fm -> rest
      | _ :: rest when in_fm -> skip_fm in_fm rest
      | rest -> rest
    in
    let body_lines = skip_fm false lines in
    let desc = body_lines |> List.find_opt (fun l ->
      let t = String.trim l in t <> "" && not (starts_with ~prefix:"#" t))
      |> Option.value ~default:"(no description)" in
    Printf.sprintf "- [%s] %s (by %s)" id (String.trim desc) by
  ) |> String.concat "\n" in

  let ts = Cn_fmt.now_iso () |> Js.String.replaceByRe ~regexp:[%mel.re "/[:.]/g"] ~replacement:"-" in
  let event_file = Printf.sprintf "threads/system/mca-review-%s.md" ts in
  let body = Printf.sprintf {|---
type: mca-review
created: %s
---

# MCA Review

Review the MCA queue below. Identify the highest priority MCA with:
- Lowest cost to complete
- Highest probability of success

If you can do it now, do it. Otherwise, explain why not.

## Open MCAs

%s
|} (Cn_fmt.now_iso ()) mca_list in

  (* Commit first — all events are git commits *)
  let system_dir = Cn_ffi.Path.join hub_path "threads/system" in
  Cn_ffi.Fs.ensure_dir system_dir;
  Cn_ffi.Fs.write (Cn_ffi.Path.join hub_path event_file) body;
  let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git add '%s'" event_file) in
  let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git commit -m '%s: system event mca-review'" name) in

  let trigger =
    Cn_ffi.Child_process.exec_in ~cwd:hub_path "git rev-parse HEAD"
    |> Option.map String.trim
    |> Option.value ~default:(Printf.sprintf "mca-review-%s" ts) in

  { trigger; body; count = List.length mcas }
