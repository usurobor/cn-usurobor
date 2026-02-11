(** cn_hub.ml — Hub discovery, path constants, and shared utilities

    Hub detection, path helpers, peer loading, timestamped naming.
    Shared infrastructure used by all domain modules. *)

open Cn_lib

(* === Hub Detection === *)

let rec find_hub_path dir =
  match dir with
  | "/" -> None
  | _ ->
      let has_yaml = Cn_ffi.Fs.exists (Cn_ffi.Path.join dir ".cn/config.yaml") in
      let has_json = Cn_ffi.Fs.exists (Cn_ffi.Path.join dir ".cn/config.json") in
      let has_peers = Cn_ffi.Fs.exists (Cn_ffi.Path.join dir "state/peers.md") in
      match has_yaml || has_json || has_peers with
      | true -> Some dir
      | false -> find_hub_path (Cn_ffi.Path.dirname dir)

(* === Logging === *)

let log_action _hub_path _action _details =
  (* Removed: hub log redundant with system log + logs/runs/
     System log: /var/log/cn-YYYYMMDD.log (cron stdout)
     Audit trail: logs/runs/ (input + output + meta) *)
  ()

(* === Peers === *)

let load_peers hub_path =
  let peers_path = Cn_ffi.Path.join hub_path "state/peers.md" in
  match Cn_ffi.Fs.exists peers_path with
  | true -> parse_peers_md (Cn_ffi.Fs.read peers_path)
  | false -> []

(* === Helpers === *)

let is_md_file = ends_with ~suffix:".md"
let split_lines s = String.split_on_char '\n' s |> List.filter non_empty

let slugify s =
  s
  |> Js.String.toLowerCase
  |> Js.String.replaceByRe ~regexp:[%mel.re "/[^a-z0-9]+/g"] ~replacement:"-"
  |> Js.String.replaceByRe ~regexp:[%mel.re "/^-|-$/g"] ~replacement:""

(* === Path Constants (v2 structure) === *)

let threads_in hub = Cn_ffi.Path.join hub "threads/in"
let threads_mail_inbox hub = Cn_ffi.Path.join hub "threads/mail/inbox"
let threads_mail_outbox hub = Cn_ffi.Path.join hub "threads/mail/outbox"
let threads_mail_sent hub = Cn_ffi.Path.join hub "threads/mail/sent"
let threads_reflections_daily hub = Cn_ffi.Path.join hub "threads/reflections/daily"
let threads_reflections_weekly hub = Cn_ffi.Path.join hub "threads/reflections/weekly"
let threads_adhoc hub = Cn_ffi.Path.join hub "threads/adhoc"
let mca_dir hub = Cn_ffi.Path.join hub "state/mca"

(* === Timestamped Naming === *)

let timestamp_slug () =
  let iso = Cn_fmt.now_iso () in
  let date = String.sub iso 0 10 |> String.split_on_char '-' |> String.concat "" in
  let time = String.sub iso 11 8 |> String.split_on_char ':' |> String.concat "" in
  Printf.sprintf "%s-%s" date time

let make_thread_filename slug =
  Printf.sprintf "%s-%s.md" (timestamp_slug ()) slug
