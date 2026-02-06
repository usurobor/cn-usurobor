(** cn_lib: Pure functions for cn CLI (no FFI, testable).
    Reuses types from Inbox_lib where possible. *)

(* Re-export inbox types for convenience *)
type triage = Inbox_lib.triage =
  | Delete of Inbox_lib.reason
  | Defer of Inbox_lib.reason
  | Delegate of Inbox_lib.actor
  | Do of Inbox_lib.action

(* === CLI Commands === *)

type inbox_cmd = Inbox_check | Inbox_process | Inbox_flush
type outbox_cmd = Outbox_check | Outbox_flush
type peer_cmd = List | Add of string * string | Remove of string | Sync

(* GTD verbs - agent-facing *)
type gtd_cmd =
  | GtdDelete of string               (* thread id *)
  | GtdDefer of string * string option (* thread id, until *)
  | GtdDelegate of string * string    (* thread id, peer *)
  | GtdDo of string                   (* thread id *)
  | GtdDone of string                 (* thread id *)

type command =
  | Help
  | Version
  | Status
  | Doctor
  | Init of string option
  | Inbox of inbox_cmd
  | Outbox of outbox_cmd
  | Peer of peer_cmd
  | Sync
  | Next                              (* get next inbox item *)
  | Read of string                    (* read thread *)
  | Reply of string * string          (* thread, message *)
  | Send of string * string           (* peer, message *)
  | Gtd of gtd_cmd
  | Commit of string option           (* message *)
  | Push
  | Save of string option             (* message *)
  | Process                           (* actor loop: inbox -> input.md -> wake *)

let string_of_command = function
  | Help -> "help"
  | Version -> "version"
  | Status -> "status"
  | Doctor -> "doctor"
  | Init name -> "init" ^ (match name with Some n -> " " ^ n | None -> "")
  | Inbox Inbox_check -> "inbox check"
  | Inbox Inbox_process -> "inbox process"
  | Inbox Inbox_flush -> "inbox flush"
  | Outbox Outbox_check -> "outbox check"
  | Outbox Outbox_flush -> "outbox flush"
  | Peer List -> "peer list"
  | Peer (Add (n, _)) -> "peer add " ^ n
  | Peer (Remove n) -> "peer remove " ^ n
  | Peer Sync -> "peer sync"
  | Sync -> "sync"
  | Next -> "next"
  | Read t -> "read " ^ t
  | Reply (t, _) -> "reply " ^ t
  | Send (p, _) -> "send " ^ p
  | Gtd (GtdDelete t) -> "delete " ^ t
  | Gtd (GtdDefer (t, _)) -> "defer " ^ t
  | Gtd (GtdDelegate (t, p)) -> "delegate " ^ t ^ " " ^ p
  | Gtd (GtdDo t) -> "do " ^ t
  | Gtd (GtdDone t) -> "done " ^ t
  | Commit msg -> "commit" ^ (match msg with Some m -> " " ^ m | None -> "")
  | Push -> "push"
  | Save msg -> "save" ^ (match msg with Some m -> " " ^ m | None -> "")
  | Process -> "process"

(* === Aliases === *)

let expand_alias = function
  | "i" -> "inbox"
  | "o" -> "outbox"
  | "s" -> "status"
  | "d" -> "doctor"
  | "p" -> "peer"
  | other -> other

(* === Command parsing === *)

let parse_inbox_cmd = function
  | [] | ["check"] -> Some Inbox_check
  | ["process"] -> Some Inbox_process
  | ["flush"] -> Some Inbox_flush
  | _ -> None

let parse_outbox_cmd = function
  | [] | ["check"] -> Some Outbox_check
  | ["flush"] -> Some Outbox_flush
  | _ -> None

let parse_peer_cmd = function
  | [] | ["list"] -> Some List
  | ["add"; name; url] -> Some (Add (name, url))
  | ["remove"; name] -> Some (Remove name)
  | ["sync"] -> Some Sync
  | _ -> None

let rec parse_command args =
  match args with
  | [] | ["help"] | ["-h"] | ["--help"] -> Some Help
  | ["--version"] | ["-V"] -> Some Version
  | ["status"] -> Some Status
  | ["doctor"] -> Some Doctor
  | "init" :: rest -> Some (Init (match rest with [n] -> Some n | _ -> None))
  | "inbox" :: rest -> parse_inbox_cmd rest |> Option.map (fun c -> Inbox c)
  | "outbox" :: rest -> parse_outbox_cmd rest |> Option.map (fun c -> Outbox c)
  | "peer" :: rest -> parse_peer_cmd rest |> Option.map (fun c -> Peer c)
  | ["sync"] -> Some Sync
  | ["next"] -> Some Next
  | ["process"] -> Some Process
  | "read" :: [t] -> Some (Read t)
  | "reply" :: t :: rest -> Some (Reply (t, String.concat " " rest))
  | "send" :: p :: rest -> Some (Send (p, String.concat " " rest))
  | "delete" :: [t] -> Some (Gtd (GtdDelete t))
  | "defer" :: t :: rest -> 
      Some (Gtd (GtdDefer (t, match rest with [u] -> Some u | _ -> None)))
  | "delegate" :: [t; p] -> Some (Gtd (GtdDelegate (t, p)))
  | "do" :: [t] -> Some (Gtd (GtdDo t))
  | "done" :: [t] -> Some (Gtd (GtdDone t))
  | "commit" :: rest -> Some (Commit (match rest with [] -> None | _ -> Some (String.concat " " rest)))
  | ["push"] -> Some Push
  | "save" :: rest -> Some (Save (match rest with [] -> None | _ -> Some (String.concat " " rest)))
  | [alias] ->
      let expanded = expand_alias alias in
      if expanded <> alias then parse_command [expanded] else None
  | _ -> None

(* === Flags === *)

type flags = {
  json: bool;
  quiet: bool;
  verbose: bool;
  dry_run: bool;
}

let default_flags = { json = false; quiet = false; verbose = false; dry_run = false }

let parse_flags args =
  let rec go flags remaining = function
    | [] -> (flags, List.rev remaining)
    | "--json" :: rest -> go { flags with json = true } remaining rest
    | "-q" :: rest | "--quiet" :: rest -> go { flags with quiet = true } remaining rest
    | "-v" :: rest | "--verbose" :: rest -> go { flags with verbose = true } remaining rest
    | "--dry-run" :: rest -> go { flags with dry_run = true } remaining rest
    | arg :: rest -> go flags (arg :: remaining) rest
  in
  go default_flags [] args

(* === Hub detection === *)

(* Derive agent name from hub path: /path/to/cn-sigma -> sigma *)
let derive_name hub_path =
  hub_path
  |> String.split_on_char '/'
  |> List.rev
  |> function
    | base :: _ ->
        if String.length base > 3 && String.sub base 0 3 = "cn-"
        then String.sub base 3 (String.length base - 3)
        else base
    | [] -> "agent"

(* === Frontmatter parsing === *)

let parse_frontmatter content =
  let lines = String.split_on_char '\n' content in
  match lines with
  | "---" :: rest ->
      let rec collect acc = function
        | "---" :: _ -> List.rev acc
        | line :: rest -> collect (line :: acc) rest
        | [] -> List.rev acc
      in
      let yaml_lines = collect [] rest in
      yaml_lines |> List.filter_map (fun line ->
        match String.split_on_char ':' line with
        | key :: rest when List.length rest > 0 ->
            Some (String.trim key, String.trim (String.concat ":" rest))
        | _ -> None
      )
  | _ -> []

let update_frontmatter content updates =
  let meta = parse_frontmatter content in
  let updated_meta = 
    List.fold_left (fun acc (k, v) ->
      (k, v) :: List.filter (fun (k', _) -> k' <> k) acc
    ) meta updates
  in
  let body = 
    let lines = String.split_on_char '\n' content in
    match lines with
    | "---" :: rest ->
        let rec skip_fm = function
          | "---" :: rest -> rest
          | _ :: rest -> skip_fm rest
          | [] -> []
        in
        String.concat "\n" (skip_fm rest)
    | _ -> content
  in
  let fm = String.concat "\n" (List.map (fun (k, v) -> k ^ ": " ^ v) updated_meta) in
  "---\n" ^ fm ^ "\n---\n" ^ body

(* === Peers parsing === *)

type peer_info = {
  name: string;
  hub: string option;
  clone: string option;
  kind: string option;
}

let parse_peers_md content =
  let lines = String.split_on_char '\n' content in
  let rec parse_block current peers = function
    | [] -> 
        (match current with Some p -> p :: peers | None -> peers) |> List.rev
    | line :: rest ->
        let trimmed = String.trim line in
        if String.length trimmed > 8 && String.sub trimmed 0 8 = "- name: " then
          let name = String.sub trimmed 8 (String.length trimmed - 8) in
          let new_peer = { name; hub = None; clone = None; kind = None } in
          let peers' = match current with Some p -> p :: peers | None -> peers in
          parse_block (Some new_peer) peers' rest
        else
          let updated = match current with
            | Some p ->
                if String.length trimmed > 5 && String.sub trimmed 0 5 = "hub: " then
                  Some { p with hub = Some (String.sub trimmed 5 (String.length trimmed - 5)) }
                else if String.length trimmed > 7 && String.sub trimmed 0 7 = "clone: " then
                  Some { p with clone = Some (String.sub trimmed 7 (String.length trimmed - 7)) }
                else if String.length trimmed > 6 && String.sub trimmed 0 6 = "kind: " then
                  Some { p with kind = Some (String.sub trimmed 6 (String.length trimmed - 6)) }
                else current
            | None -> None
          in
          parse_block updated peers rest
  in
  parse_block None [] lines

(* === Thread operations === *)

type cadence = Inbox | Outbox | Daily | Weekly | Monthly | Quarterly | Yearly | Adhoc | Doing | Deferred | Unknown

let cadence_of_path path =
  if String.length path > 0 then
    let parts = String.split_on_char '/' path in
    List.find_map (function
      | "inbox" -> Some Inbox
      | "outbox" -> Some Outbox
      | "daily" -> Some Daily
      | "weekly" -> Some Weekly
      | "monthly" -> Some Monthly
      | "quarterly" -> Some Quarterly
      | "yearly" -> Some Yearly
      | "adhoc" -> Some Adhoc
      | "doing" -> Some Doing
      | "deferred" -> Some Deferred
      | _ -> None
    ) parts |> Option.value ~default:Unknown
  else Unknown

let string_of_cadence = function
  | Inbox -> "inbox"
  | Outbox -> "outbox"
  | Daily -> "daily"
  | Weekly -> "weekly"
  | Monthly -> "monthly"
  | Quarterly -> "quarterly"
  | Yearly -> "yearly"
  | Adhoc -> "adhoc"
  | Doing -> "doing"
  | Deferred -> "deferred"
  | Unknown -> "unknown"

(* === Output formatting === *)

let no_color = 
  (* Will be overridden in cn.ml based on env *)
  false

let color code s = 
  if no_color then s
  else Printf.sprintf "\027[%sm%s\027[0m" code s

let green s = color "32" s
let red s = color "31" s  
let yellow s = color "33" s
let cyan s = color "36" s
let magenta s = color "35" s
let dim s = color "2" s

let ok msg = green "✓ " ^ msg
let fail msg = red "✗ " ^ msg
let warn msg = yellow "⚠ " ^ msg
let info msg = cyan msg

(* === Help text === *)

let help_text = {|cn - Coherent Network agent CLI

Usage: cn <command> [options]

Commands:
  # Agent decisions (output)
  delete <thread>     GTD: discard
  defer <thread>      GTD: postpone
  delegate <t> <peer> GTD: forward
  do <thread>         GTD: claim/start
  done <thread>       GTD: complete → archive
  reply <thread> <msg> Append to thread
  send <peer> <msg>   Message to peer (or self)
  
  # cn operations (orchestrator)
  next                Get next inbox item (with cadence)
  sync                Fetch inbound + send outbound
  inbox               List inbox (cn internal)
  outbox              List outbox (cn internal)
  read <thread>       Read thread with cadence
  process             Actor loop (inbox → input.md → OC wake)
  
  # Hub management
  init [name]         Create new hub
  status              Show hub state
  commit [msg]        Stage + commit
  push                Push to origin
  save [msg]          Commit + push
  peer                Manage peers
  doctor              Health check

Aliases:
  i = inbox, o = outbox, s = status, d = doctor

Flags:
  --help, -h          Show help
  --version, -V       Show version
  --json              Machine-readable output
  --quiet, -q         Minimal output
  --dry-run           Show what would happen

Examples:
  cn init sigma       Create hub named 'sigma'
  cn inbox check      List inbound branches
  cn doctor           Check system health
  cn process          Run actor loop
|}

let version = "2.1.0"
