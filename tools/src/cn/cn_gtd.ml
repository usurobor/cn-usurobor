(** cn_gtd.ml — Thread lifecycle and creation

    Thread finding, GTD state transitions (delete/defer/delegate/do/done),
    thread reading/listing, and thread creation (adhoc/daily/weekly).

    Merged from: cn_gtd + cn_threads in the 14-module plan. *)

open Cn_lib

(* === Thread Finding === *)

let find_thread hub_path thread_id =
  let locations = [
    "in"; "mail/inbox"; "mail/outbox"; "mail/sent";
    "doing"; "deferred"; "adhoc";
    "reflections/daily"; "reflections/weekly"; "reflections/monthly"
  ] in
  match String.contains thread_id '/' with
  | true ->
      let path = Cn_ffi.Path.join hub_path (Printf.sprintf "threads/%s.md" thread_id) in
      (match Cn_ffi.Fs.exists path with true -> Some path | false -> None)
  | false ->
      locations |> List.find_map (fun loc ->
        let path = Cn_ffi.Path.join hub_path (Printf.sprintf "threads/%s/%s.md" loc thread_id) in
        match Cn_ffi.Fs.exists path with true -> Some path | false -> None)

(* === GTD State Transitions === *)

let gtd_delete hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (Cn_fmt.fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      Cn_ffi.Fs.unlink path;
      Cn_hub.log_action hub_path "gtd.delete" thread_id;
      print_endline (Cn_fmt.ok (Printf.sprintf "Deleted: %s" thread_id))

let gtd_defer hub_path thread_id until =
  match find_thread hub_path thread_id with
  | None -> print_endline (Cn_fmt.fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let deferred_dir = Cn_ffi.Path.join hub_path "threads/deferred" in
      Cn_ffi.Fs.ensure_dir deferred_dir;
      let content = Cn_ffi.Fs.read path in
      let until_str = Option.value until ~default:"unspecified" in
      Cn_ffi.Fs.write (Cn_ffi.Path.join deferred_dir (Cn_ffi.Path.basename path))
        (update_frontmatter content [("deferred", Cn_fmt.now_iso ()); ("until", until_str)]);
      Cn_ffi.Fs.unlink path;
      Cn_hub.log_action hub_path "gtd.defer" (Printf.sprintf "%s until:%s" thread_id until_str);
      let suffix = match until with Some u -> " until " ^ u | None -> "" in
      print_endline (Cn_fmt.ok (Printf.sprintf "Deferred: %s%s" thread_id suffix))

let gtd_delegate hub_path name thread_id peer =
  match find_thread hub_path thread_id with
  | None -> print_endline (Cn_fmt.fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
      Cn_ffi.Fs.ensure_dir outbox_dir;
      let content = Cn_ffi.Fs.read path in
      Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir (Cn_ffi.Path.basename path))
        (update_frontmatter content [("to", peer); ("delegated", Cn_fmt.now_iso ()); ("delegated-by", name)]);
      Cn_ffi.Fs.unlink path;
      Cn_hub.log_action hub_path "gtd.delegate" (Printf.sprintf "%s to:%s" thread_id peer);
      print_endline (Cn_fmt.ok (Printf.sprintf "Delegated to %s: %s" peer thread_id));
      print_endline (Cn_fmt.info "Run \"cn sync\" to send")

let gtd_do hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (Cn_fmt.fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let doing_dir = Cn_ffi.Path.join hub_path "threads/doing" in
      Cn_ffi.Fs.ensure_dir doing_dir;
      let content = Cn_ffi.Fs.read path in
      Cn_ffi.Fs.write (Cn_ffi.Path.join doing_dir (Cn_ffi.Path.basename path))
        (update_frontmatter content [("started", Cn_fmt.now_iso ())]);
      Cn_ffi.Fs.unlink path;
      Cn_hub.log_action hub_path "gtd.do" thread_id;
      print_endline (Cn_fmt.ok (Printf.sprintf "Started: %s" thread_id))

let gtd_done hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (Cn_fmt.fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let archived_dir = Cn_ffi.Path.join hub_path "threads/archived" in
      Cn_ffi.Fs.ensure_dir archived_dir;
      let content = Cn_ffi.Fs.read path in
      Cn_ffi.Fs.write (Cn_ffi.Path.join archived_dir (Cn_ffi.Path.basename path))
        (update_frontmatter content [("completed", Cn_fmt.now_iso ())]);
      Cn_ffi.Fs.unlink path;
      Cn_hub.log_action hub_path "gtd.done" thread_id;
      print_endline (Cn_fmt.ok (Printf.sprintf "Completed: %s → archived" thread_id))

(* === Read Thread === *)

let run_read hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (Cn_fmt.fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let content = Cn_ffi.Fs.read path in
      let cadence = cadence_of_path path |> string_of_cadence in
      let meta = parse_frontmatter content in
      Printf.printf "[cadence: %s]\n" cadence;
      meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
        |> Option.iter (Printf.printf "[from: %s]\n");
      meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None)
        |> Option.iter (Printf.printf "[to: %s]\n");
      print_endline "";
      print_endline content

(* === Inbox/Outbox List === *)

let run_inbox_list hub_path =
  let inbox_dir = Cn_hub.threads_mail_inbox hub_path in
  if not (Cn_ffi.Fs.exists inbox_dir) then print_endline "(empty)"
  else
    match Cn_ffi.Fs.readdir inbox_dir |> List.filter Cn_hub.is_md_file with
    | [] -> print_endline "(empty)"
    | ts -> ts |> List.iter (fun f ->
        let id = Cn_ffi.Path.basename_ext f ".md" in
        let meta = Cn_ffi.Fs.read (Cn_ffi.Path.join inbox_dir f) |> parse_frontmatter in
        let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
          |> Option.value ~default:"unknown" in
        Printf.printf "%s/%s\n" from id)

let run_outbox_list hub_path =
  let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
  if not (Cn_ffi.Fs.exists outbox_dir) then print_endline "(empty)"
  else
    match Cn_ffi.Fs.readdir outbox_dir |> List.filter Cn_hub.is_md_file with
    | [] -> print_endline "(empty)"
    | ts -> ts |> List.iter (fun f ->
        let id = Cn_ffi.Path.basename_ext f ".md" in
        let meta = Cn_ffi.Fs.read (Cn_ffi.Path.join outbox_dir f) |> parse_frontmatter in
        let to_peer = meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None)
          |> Option.value ~default:"unknown" in
        Printf.printf "→ %s  \"%s\"\n" to_peer id)

(* === Thread Creation === *)

let run_adhoc hub_path title =
  let dir = Cn_hub.threads_adhoc hub_path in
  Cn_ffi.Fs.ensure_dir dir;

  let ts = Cn_fmt.now_iso () in
  let date = String.sub ts 0 10 in
  let time = String.sub ts 11 8 |> Js.String.replaceByRe ~regexp:[%mel.re "/:/g"] ~replacement:"" in
  let slug =
    title
    |> Js.String.slice ~start:0 ~end_:40
    |> Js.String.toLowerCase
    |> Js.String.replaceByRe ~regexp:[%mel.re "/[^a-z0-9]+/g"] ~replacement:"-"
    |> Js.String.replaceByRe ~regexp:[%mel.re "/^-|-$/g"] ~replacement:""
  in
  let file_name = Printf.sprintf "%s-%s-%s.md" (Js.String.replaceByRe ~regexp:[%mel.re "/-/g"] ~replacement:"" date) time slug in
  let file_path = Cn_ffi.Path.join dir file_name in

  let content = Printf.sprintf {|---
created: %s
type: adhoc
---

# %s

|} ts title in

  Cn_ffi.Fs.write file_path content;
  print_endline (Cn_fmt.ok (Printf.sprintf "Created: %s" file_path))

let run_daily hub_path =
  let dir = Cn_hub.threads_reflections_daily hub_path in
  Cn_ffi.Fs.ensure_dir dir;

  let today = String.sub (Cn_fmt.now_iso ()) 0 10 |> Js.String.replaceByRe ~regexp:[%mel.re "/-/g"] ~replacement:"" in
  let file_name = Printf.sprintf "%s.md" today in
  let file_path = Cn_ffi.Path.join dir file_name in

  if Cn_ffi.Fs.exists file_path then begin
    print_endline (Cn_fmt.info (Printf.sprintf "Daily exists: %s" file_path));
    let content = Cn_ffi.Fs.read file_path in
    print_endline content
  end else begin
    let ts = Cn_fmt.now_iso () in
    let content = Printf.sprintf {|---
date: %s
type: daily
---

# Daily Reflection

## Done

## In Progress

## Blocked

## α (What did I do?)

## β (What would I do differently?)

## γ (What did I learn?)
|} ts in
    Cn_ffi.Fs.write file_path content;
    print_endline (Cn_fmt.ok (Printf.sprintf "Created: %s" file_path))
  end

let run_weekly hub_path =
  let dir = Cn_hub.threads_reflections_weekly hub_path in
  Cn_ffi.Fs.ensure_dir dir;

  let ts = Cn_fmt.now_iso () in
  let year = String.sub ts 0 4 in
  let file_name = Printf.sprintf "%s-W%02d.md" year ((int_of_string (String.sub ts 5 2)) / 4 + 1) in
  let file_path = Cn_ffi.Path.join dir file_name in

  if Cn_ffi.Fs.exists file_path then begin
    print_endline (Cn_fmt.info (Printf.sprintf "Weekly exists: %s" file_path));
    let content = Cn_ffi.Fs.read file_path in
    print_endline content
  end else begin
    let content = Printf.sprintf {|---
date: %s
type: weekly
---

# Weekly Reflection

## Summary

## Key Accomplishments

## Challenges

## Next Week Focus
|} ts in
    Cn_ffi.Fs.write file_path content;
    print_endline (Cn_fmt.ok (Printf.sprintf "Created: %s" file_path))
  end
