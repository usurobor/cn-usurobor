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

(* Subcommand modules - clean names, module-scoped *)
module Inbox = struct
  type cmd = Check | Process | Flush
end

module Outbox = struct
  type cmd = Check | Flush
end

module Peer = struct
  type cmd = List | Add of string * string | Remove of string | Sync
end

module Queue = struct
  type cmd = List | Clear
end

module Mca = struct
  type cmd = List | Add of string
end

module Gtd = struct
  type cmd =
    | Delete of string
    | Defer of string * string option
    | Delegate of string * string
    | Do of string
    | Done of string
end

(* === Agent Output — the ONLY way agent can respond ===
   
   GTD protocol for handling input:
   - Do: complete with an op for cn to execute
   - Defer: postpone with reason
   - Delegate: forward to peer
   - Delete: discard with reason
   
   cn auto-notifies input creator of action taken. *)

module Out = struct
  (* What cn executes when agent does Do *)
  type op =
    | Reply of { message: string }
    | Send of { to_: string; message: string }
    | Surface of { desc: string }
    | Noop of { reason: string }  (* no action, but creator notified *)
    | Commit of { artifact: string }
  
  (* GTD protocol — ONLY 4 OPTIONS *)
  type gtd =
    | Do of op
    | Defer of { reason: string }
    | Delegate of { to_: string }
    | Delete of { reason: string }
end

(* === Agent Output Operations ===
   
   These are operations an agent can write to output.md.
   cn parses output.md and executes matching operations. *)

type agent_op =
  | Ack of string                      (* Acknowledge input, no further action *)
  | Done of string                     (* Mark input/thread complete *)
  | Fail of string * string            (* Failed to process: id, reason *)
  | Reply of string * string           (* Reply to thread: id, message *)
  | Send of string * string            (* Send to peer: peer, message *)
  | Delegate of string * string        (* Forward to peer: id, peer *)
  | Defer of string * string option    (* Postpone: id, until *)
  | Delete of string                   (* Discard: id *)
  | Surface of string                  (* Surface MCA for community *)

let string_of_agent_op = function
  | Ack id -> "ack:" ^ id
  | Done id -> "done:" ^ id
  | Fail (id, reason) -> "fail:" ^ id ^ " reason:" ^ reason
  | Reply (id, _) -> "reply:" ^ id
  | Send (peer, _) -> "send:" ^ peer
  | Delegate (id, peer) -> "delegate:" ^ id ^ " to:" ^ peer
  | Defer (id, None) -> "defer:" ^ id
  | Defer (id, Some until) -> "defer:" ^ id ^ " until:" ^ until
  | Delete id -> "delete:" ^ id
  | Surface desc -> "surface:" ^ desc

(* Parse agent_op from frontmatter key-value pairs *)
let parse_agent_op key value =
  match key with
  | "ack" -> Some (Ack value)
  | "done" -> Some (Done value)
  | "fail" -> 
      (match String.index_opt value '|' with
       | Some i -> Some (Fail (String.sub value 0 i, String.sub value (i+1) (String.length value - i - 1)))
       | None -> Some (Fail (value, "unspecified")))
  | "reply" ->
      (match String.index_opt value '|' with
       | Some i -> Some (Reply (String.sub value 0 i, String.sub value (i+1) (String.length value - i - 1)))
       | None -> None)
  | "send" ->
      (match String.index_opt value '|' with
       | Some i -> Some (Send (String.sub value 0 i, String.sub value (i+1) (String.length value - i - 1)))
       | None -> None)
  | "delegate" ->
      (match String.index_opt value '|' with
       | Some i -> Some (Delegate (String.sub value 0 i, String.sub value (i+1) (String.length value - i - 1)))
       | None -> None)
  | "defer" ->
      (match String.index_opt value '|' with
       | Some i -> Some (Defer (String.sub value 0 i, Some (String.sub value (i+1) (String.length value - i - 1))))
       | None -> Some (Defer (value, None)))
  | "delete" -> Some (Delete value)
  | "surface" -> Some (Surface value)
  | "mca" -> Some (Surface value)  (* alias *)
  | _ -> None

(* Extract all agent_ops from frontmatter *)
let extract_ops frontmatter =
  frontmatter |> List.filter_map (fun (k, v) -> parse_agent_op k v)

type command =
  | Help
  | Version
  | Status
  | Doctor
  | Init of string option
  | Inbox of Inbox.cmd
  | Outbox of Outbox.cmd
  | Peer of Peer.cmd
  | Queue of Queue.cmd
  | Mca of Mca.cmd
  | Sync
  | Next
  | Read of string
  | Reply of string * string
  | Send of string * string
  | Gtd of Gtd.cmd
  | Out of Out.gtd  (* Agent output — ONLY way to respond *)
  | Commit of string option
  | Push
  | Save of string option
  | Inbound  (* was: Process *)
  | Update

(* Exhaustive - compiler warns on missing cases *)
let string_of_command = function
  | Help -> "help"
  | Version -> "version"
  | Status -> "status"
  | Doctor -> "doctor"
  | Init None -> "init"
  | Init (Some n) -> "init " ^ n
  | Inbox Inbox.Check -> "inbox check"
  | Inbox Inbox.Process -> "inbox process"
  | Inbox Inbox.Flush -> "inbox flush"
  | Outbox Outbox.Check -> "outbox check"
  | Outbox Outbox.Flush -> "outbox flush"
  | Peer Peer.List -> "peer list"
  | Peer (Peer.Add (n, _)) -> "peer add " ^ n
  | Peer (Peer.Remove n) -> "peer remove " ^ n
  | Peer Peer.Sync -> "peer sync"
  | Queue Queue.List -> "queue list"
  | Queue Queue.Clear -> "queue clear"
  | Mca Mca.List -> "mca list"
  | Mca (Mca.Add d) -> "mca add " ^ d
  | Sync -> "sync"
  | Next -> "next"
  | Read t -> "read " ^ t
  | Reply (t, _) -> "reply " ^ t
  | Send (p, _) -> "send " ^ p
  | Gtd (Gtd.Delete t) -> "delete " ^ t
  | Gtd (Gtd.Defer (t, _)) -> "defer " ^ t
  | Gtd (Gtd.Delegate (t, p)) -> "delegate " ^ t ^ " " ^ p
  | Gtd (Gtd.Do t) -> "do " ^ t
  | Gtd (Gtd.Done t) -> "done " ^ t
  | Out (Out.Do (Out.Reply { message = _ })) -> "out do reply"
  | Out (Out.Do (Out.Send { to_; message = _ })) -> "out do send " ^ to_
  | Out (Out.Do (Out.Surface { desc = _ })) -> "out do surface"
  | Out (Out.Do (Out.Noop { reason = _ })) -> "out do noop"
  | Out (Out.Do (Out.Commit { artifact })) -> "out do commit " ^ artifact
  | Out (Out.Defer { reason = _ }) -> "out defer"
  | Out (Out.Delegate { to_ }) -> "out delegate " ^ to_
  | Out (Out.Delete { reason = _ }) -> "out delete"
  | Commit None -> "commit"
  | Commit (Some m) -> "commit " ^ m
  | Push -> "push"
  | Save None -> "save"
  | Save (Some m) -> "save " ^ m
  | Inbound -> "inbound"
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
  | [] | ["check"] -> Some Inbox.Check
  | ["process"] -> Some Inbox.Process
  | ["flush"] -> Some Inbox.Flush
  | _ -> None

let parse_outbox_cmd = function
  | [] | ["check"] -> Some Outbox.Check
  | ["flush"] -> Some Outbox.Flush
  | _ -> None

let parse_peer_cmd = function
  | [] | ["list"] -> Some Peer.List
  | ["add"; name; url] -> Some (Peer.Add (name, url))
  | ["remove"; name] -> Some (Peer.Remove name)
  | ["sync"] -> Some Peer.Sync
  | _ -> None

let parse_queue_cmd = function
  | [] | ["list"] -> Some Queue.List
  | ["clear"] -> Some Queue.Clear
  | _ -> None

let parse_mca_cmd = function
  | [] | ["list"] -> Some Mca.List
  | "add" :: rest when rest <> [] -> Some (Mca.Add (String.concat " " rest))
  | _ -> None

let parse_gtd_cmd = function
  | ["delete"; t] -> Some (Gtd.Delete t)
  | "defer" :: t :: rest -> Some (Gtd.Defer (t, List.nth_opt rest 0))
  | ["delegate"; t; p] -> Some (Gtd.Delegate (t, p))
  | ["do"; t] -> Some (Gtd.Do t)
  | ["done"; t] -> Some (Gtd.Done t)
  | _ -> None

(* Parse --key value pairs from args *)
let rec parse_flags_from_args acc = function
  | [] -> acc
  | "--message" :: v :: rest -> parse_flags_from_args (("message", v) :: acc) rest
  | "--to" :: v :: rest -> parse_flags_from_args (("to", v) :: acc) rest
  | "--reason" :: v :: rest -> parse_flags_from_args (("reason", v) :: acc) rest
  | "--desc" :: v :: rest -> parse_flags_from_args (("desc", v) :: acc) rest
  | "--artifact" :: v :: rest -> parse_flags_from_args (("artifact", v) :: acc) rest
  | "--id" :: v :: rest -> parse_flags_from_args (("id", v) :: acc) rest
  | _ :: rest -> parse_flags_from_args acc rest

let get_flag key flags = List.find_map (fun (k, v) -> if k = key then Some v else None) flags

(* Parse cn out commands *)
let parse_out_cmd args =
  let flags = parse_flags_from_args [] args in
  match args with
  | "do" :: "reply" :: _ ->
      get_flag "message" flags |> Option.map (fun m -> Out.Do (Out.Reply { message = m }))
  | "do" :: "send" :: _ ->
      (match get_flag "to" flags, get_flag "message" flags with
       | Some t, Some m -> Some (Out.Do (Out.Send { to_ = t; message = m }))
       | _ -> None)
  | "do" :: "surface" :: _ ->
      get_flag "desc" flags |> Option.map (fun d -> Out.Do (Out.Surface { desc = d }))
  | "do" :: "noop" :: _ ->
      (match get_flag "reason" flags with
       | None -> None
       | Some r ->
           (* Reason must be coherent - reject trivial *)
           let trivial = ["ack"; "ok"; "done"; "yes"; "no"; "acknowledged"; "noted"] in
           let r_lower = String.lowercase_ascii r in
           if List.mem r_lower trivial || String.length r < 10 then None
           else Some (Out.Do (Out.Noop { reason = r })))
  | "do" :: "commit" :: _ ->
      get_flag "artifact" flags |> Option.map (fun a -> Out.Do (Out.Commit { artifact = a }))
  | "defer" :: _ ->
      get_flag "reason" flags |> Option.map (fun r -> Out.Defer { reason = r })
  | "delegate" :: _ ->
      get_flag "to" flags |> Option.map (fun t -> Out.Delegate { to_ = t })
  | "delete" :: _ ->
      get_flag "reason" flags |> Option.map (fun r -> Out.Delete { reason = r })
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
  | "mca" :: rest -> parse_mca_cmd rest |> Option.map (fun c -> Mca c)
  | ["sync"] -> Some Sync
  | ["next"] -> Some Next
  | ["inbound"] | ["process"] -> Some Inbound  (* process is alias for backward compat *)
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
  | "out" :: rest -> parse_out_cmd rest |> Option.map (fun c -> Out c)
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
  inbound             Queue inbox → input.md → wake agent (alias: process)
  queue [list|clear]  View or clear the task queue
  mca [list|add <desc>] Surface MCAs for community pickup
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

let version = "2.2.0"
