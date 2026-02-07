(** cn_lib: Pure functions for cn CLI.
    
    No FFI, fully testable. Follows FUNCTIONAL.md:
    - Pattern matching over conditionals
    - Pipelines over sequences
    - Total functions (no exceptions)
    - Semantic types *)

(* Re-export inbox types for convenience *)
type triage = Inbox_lib.triage =
  | Delete of Inbox_lib.reason
  | Defer of Inbox_lib.reason
  | Delegate of Inbox_lib.actor
  | Do of Inbox_lib.action

(* === String Helpers (total functions) === *)

let starts_with ~prefix s =
  let plen = String.length prefix in
  String.length s >= plen && String.sub s 0 plen = prefix

let strip_prefix ~prefix s =
  let plen = String.length prefix in
  if starts_with ~prefix s 
  then Some (String.sub s plen (String.length s - plen))
  else None

let ends_with ~suffix s =
  let slen = String.length suffix in
  let len = String.length s in
  len >= slen && String.sub s (len - slen) slen = suffix

let non_empty s = String.trim s <> ""

(* === CLI Commands (exhaustive variants) === *)

type inbox_cmd = Inbox_check | Inbox_process | Inbox_flush
type outbox_cmd = Outbox_check | Outbox_flush
type peer_cmd = Peer_list | Peer_add of string * string | Peer_remove of string | Peer_sync
type queue_cmd = Queue_list | Queue_clear

type gtd_cmd =
  | GtdDelete of string
  | GtdDefer of string * string option
  | GtdDelegate of string * string
  | GtdDo of string
  | GtdDone of string

type command =
  | Help
  | Version
  | Status
  | Doctor
  | Init of string option
  | Inbox of inbox_cmd
  | Outbox of outbox_cmd
  | Peer of peer_cmd
  | Queue of queue_cmd
  | Sync
  | Next
  | Read of string
  | Reply of string * string
  | Send of string * string
  | Gtd of gtd_cmd
  | Commit of string option
  | Push
  | Save of string option
  | Process
  | Update

(* Exhaustive - compiler warns on missing cases *)
let string_of_command = function
  | Help -> "help"
  | Version -> "version"
  | Status -> "status"
  | Doctor -> "doctor"
  | Init None -> "init"
  | Init (Some n) -> "init " ^ n
  | Inbox Inbox_check -> "inbox check"
  | Inbox Inbox_process -> "inbox process"
  | Inbox Inbox_flush -> "inbox flush"
  | Outbox Outbox_check -> "outbox check"
  | Outbox Outbox_flush -> "outbox flush"
  | Peer Peer_list -> "peer list"
  | Peer (Peer_add (n, _)) -> "peer add " ^ n
  | Peer (Peer_remove n) -> "peer remove " ^ n
  | Peer Peer_sync -> "peer sync"
  | Queue Queue_list -> "queue list"
  | Queue Queue_clear -> "queue clear"
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
  | Commit None -> "commit"
  | Commit (Some m) -> "commit " ^ m
  | Push -> "push"
  | Save None -> "save"
  | Save (Some m) -> "save " ^ m
  | Process -> "process"
  | Update -> "update"

(* === Alias Expansion === *)

let expand_alias = function
  | "i" -> "inbox"
  | "o" -> "outbox"
  | "s" -> "status"
  | "d" -> "doctor"
  | "p" -> "peer"
  | s -> s  (* identity for non-aliases *)

(* === Command Parsing (Option for totality) === *)

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
  | [] | ["list"] -> Some Peer_list
  | ["add"; name; url] -> Some (Peer_add (name, url))
  | ["remove"; name] -> Some (Peer_remove name)
  | ["sync"] -> Some Peer_sync
  | _ -> None

let parse_queue_cmd = function
  | [] | ["list"] -> Some Queue_list
  | ["clear"] -> Some Queue_clear
  | _ -> None

let parse_gtd_cmd = function
  | ["delete"; t] -> Some (GtdDelete t)
  | "defer" :: t :: rest -> Some (GtdDefer (t, List.nth_opt rest 0))
  | ["delegate"; t; p] -> Some (GtdDelegate (t, p))
  | ["do"; t] -> Some (GtdDo t)
  | ["done"; t] -> Some (GtdDone t)
  | _ -> None

let join_rest rest = match rest with [] -> None | _ -> Some (String.concat " " rest)

let rec parse_command = function
  | [] | ["help"] | ["-h"] | ["--help"] -> Some Help
  | ["--version"] | ["-V"] -> Some Version
  | ["status"] -> Some Status
  | ["doctor"] -> Some Doctor
  | ["init"] -> Some (Init None)
  | ["init"; n] -> Some (Init (Some n))
  | "inbox" :: rest -> parse_inbox_cmd rest |> Option.map (fun c -> Inbox c)
  | "outbox" :: rest -> parse_outbox_cmd rest |> Option.map (fun c -> Outbox c)
  | "peer" :: rest -> parse_peer_cmd rest |> Option.map (fun c -> Peer c)
  | "queue" :: rest -> parse_queue_cmd rest |> Option.map (fun c -> Queue c)
  | ["sync"] -> Some Sync
  | ["next"] -> Some Next
  | ["process"] -> Some Process
  | ["read"; t] -> Some (Read t)
  | "reply" :: t :: rest -> Some (Reply (t, String.concat " " rest))
  | "send" :: p :: rest -> Some (Send (p, String.concat " " rest))
  | "delete" :: rest -> parse_gtd_cmd ("delete" :: rest) |> Option.map (fun c -> Gtd c)
  | "defer" :: rest -> parse_gtd_cmd ("defer" :: rest) |> Option.map (fun c -> Gtd c)
  | "delegate" :: rest -> parse_gtd_cmd ("delegate" :: rest) |> Option.map (fun c -> Gtd c)
  | "do" :: rest -> parse_gtd_cmd ("do" :: rest) |> Option.map (fun c -> Gtd c)
  | "done" :: rest -> parse_gtd_cmd ("done" :: rest) |> Option.map (fun c -> Gtd c)
  | "commit" :: rest -> Some (Commit (join_rest rest))
  | ["push"] -> Some Push
  | "save" :: rest -> Some (Save (join_rest rest))
  | ["update"] -> Some Update
  | [alias] ->
      let expanded = expand_alias alias in
      if expanded <> alias then parse_command [expanded] else None
  | _ -> None

(* === Flags (immutable record) === *)

type flags = {
  json: bool;
  quiet: bool;
  verbose: bool;
  dry_run: bool;
}

let default_flags = { json = false; quiet = false; verbose = false; dry_run = false }

(* Tail-recursive flag parsing *)
let parse_flags args =
  let rec go flags remaining = function
    | [] -> (flags, List.rev remaining)
    | "--json" :: rest -> go { flags with json = true } remaining rest
    | "-q" :: rest -> go { flags with quiet = true } remaining rest
    | "--quiet" :: rest -> go { flags with quiet = true } remaining rest
    | "-v" :: rest -> go { flags with verbose = true } remaining rest
    | "--verbose" :: rest -> go { flags with verbose = true } remaining rest
    | "--dry-run" :: rest -> go { flags with dry_run = true } remaining rest
    | arg :: rest -> go flags (arg :: remaining) rest
  in
  go default_flags [] args

(* === Hub Name Derivation === *)

let derive_name hub_path =
  hub_path
  |> String.split_on_char '/'
  |> List.rev
  |> List.hd  (* safe: split always returns at least one element *)
  |> fun base -> strip_prefix ~prefix:"cn-" base |> Option.value ~default:base

(* === Frontmatter (pure parsing) === *)

let parse_frontmatter content =
  match String.split_on_char '\n' content with
  | "---" :: rest ->
      let rec collect acc = function
        | "---" :: _ -> List.rev acc
        | line :: rest -> collect (line :: acc) rest
        | [] -> List.rev acc
      in
      collect [] rest
      |> List.filter_map (fun line ->
          match String.index_opt line ':' with
          | None -> None
          | Some i ->
              let key = String.trim (String.sub line 0 i) in
              let value = String.trim (String.sub line (i + 1) (String.length line - i - 1)) in
              if key = "" then None else Some (key, value))
  | _ -> []

let update_frontmatter content updates =
  let existing = parse_frontmatter content in
  let merged = 
    updates |> List.fold_left (fun acc (k, v) ->
      (k, v) :: List.filter (fun (k', _) -> k' <> k) acc
    ) existing
  in
  let body = 
    match String.split_on_char '\n' content with
    | "---" :: rest ->
        let rec skip = function "---" :: r -> r | _ :: r -> skip r | [] -> [] in
        String.concat "\n" (skip rest)
    | _ -> content
  in
  let fm = merged |> List.map (fun (k, v) -> k ^ ": " ^ v) |> String.concat "\n" in
  "---\n" ^ fm ^ "\n---\n" ^ body

(* === Peer Info (semantic record) === *)

type peer_info = {
  name: string;
  hub: string option;
  clone: string option;
  kind: string option;
}

let empty_peer name = { name; hub = None; clone = None; kind = None }

let parse_peer_field peer line =
  let trimmed = String.trim line in
  match strip_prefix ~prefix:"hub: " trimmed with
  | Some v -> { peer with hub = Some v }
  | None ->
      match strip_prefix ~prefix:"clone: " trimmed with
      | Some v -> { peer with clone = Some v }
      | None ->
          match strip_prefix ~prefix:"kind: " trimmed with
          | Some v -> { peer with kind = Some v }
          | None -> peer

let parse_peers_md content =
  content
  |> String.split_on_char '\n'
  |> List.fold_left (fun (current, peers) line ->
      match strip_prefix ~prefix:"- name: " (String.trim line) with
      | Some name ->
          let peers' = match current with Some p -> p :: peers | None -> peers in
          (Some (empty_peer name), peers')
      | None ->
          let current' = Option.map (fun p -> parse_peer_field p line) current in
          (current', peers)
    ) (None, [])
  |> fun (current, peers) ->
      (match current with Some p -> p :: peers | None -> peers)
      |> List.rev

(* === Cadence (exhaustive variant) === *)

type cadence = 
  | Inbox | Outbox | Daily | Weekly | Monthly 
  | Quarterly | Yearly | Adhoc | Doing | Deferred | Unknown

let cadence_of_string = function
  | "inbox" -> Inbox
  | "outbox" -> Outbox
  | "daily" -> Daily
  | "weekly" -> Weekly
  | "monthly" -> Monthly
  | "quarterly" -> Quarterly
  | "yearly" -> Yearly
  | "adhoc" -> Adhoc
  | "doing" -> Doing
  | "deferred" -> Deferred
  | _ -> Unknown

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

let cadence_of_path path =
  path
  |> String.split_on_char '/'
  |> List.find_map (fun part ->
      match cadence_of_string part with
      | Unknown -> None
      | c -> Some c)
  |> Option.value ~default:Unknown

(* === Help Text === *)

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
  sync                Fetch inbound + send outbound
  process             Queue inbox → input.md → wake agent
  queue [list|clear]  View or clear the task queue
  inbox               List inbox threads
  outbox              List outbox threads
  next                Get next inbox item (with cadence)
  read <thread>       Read thread with cadence
  
  # Hub management
  init [name]         Create new hub
  status              Show hub state
  commit [msg]        Stage + commit
  push                Push to origin
  save [msg]          Commit + push
  peer                Manage peers
  doctor              Health check
  update              Update cn to latest version

Aliases:
  i = inbox, o = outbox, s = status, d = doctor

Flags:
  --help, -h          Show help
  --version, -V       Show version
  --json              Machine-readable output
  --quiet, -q         Minimal output
  --dry-run           Show what would happen

Actor Model:
  cn runs on cron (every 5 min). It:
  1. Syncs peers → queues new inbox items to state/queue/
  2. If input.md empty → pops from queue → writes input.md → wakes agent
  Agent reads input.md, processes, deletes when done.
|}

let version = "2.1.10"
