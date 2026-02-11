(* Agent Layer — prelude for executable spec *)

(* === Types === *)

type cadence = Inbox | Daily | Weekly | Monthly | Quarterly | Yearly | Adhoc

type input_item = {
  id: string;
  from: string;
  content: string;
  cadence: cadence;
}

type op =
  | Reply of { message: string }
  | Send of { to_: string; message: string; body: string option }
  | Noop of { reason: string }
  | Ack of { reason: string }
  | Surface of { desc: string }
  | Commit of { artifact: string }

type gtd =
  | Do of op
  | Defer of { reason: string }
  | Delegate of { to_: string }
  | Delete of { reason: string }

(* === Interface constraints === *)

let agent_interface = ["cn input"; "cn out"]

let agent_cannot = [
  "access filesystem";
  "execute commands";
  "call APIs";
  "list inbox";
  "choose processing order"
]

let agent_can_only = ["call cn input"; "call cn out"]

(* === Input === *)

let cn_input_returns = {
  id = "abc123";
  from = "pi";
  content = "Please review";
  cadence = Inbox;
}

let all_cadences = [Inbox; Daily; Weekly; Monthly; Quarterly; Yearly; Adhoc]

(* === Output === *)

let gtd_options = ["do"; "defer"; "delegate"; "delete"]

let all_operations = ["reply"; "send"; "noop"; "ack"; "surface"; "commit"]

(* === Parsing cn out commands === *)

(* Extract value after a flag like --message "value" *)
let extract_flag flag args =
  let rec find = function
    | [] -> None
    | x :: rest when x = flag ->
        (match rest with
         | v :: _ -> Some v
         | [] -> None)
    | _ :: rest -> find rest
  in find args

(* Split string on spaces, respecting quoted strings *)
let tokenize s =
  let len = String.length s in
  let rec collect acc cur i in_quote =
    if i >= len then
      if cur = "" then List.rev acc else List.rev (cur :: acc)
    else
      let c = s.[i] in
      if c = '"' then
        collect acc cur (i + 1) (not in_quote)
      else if c = ' ' && not in_quote then
        if cur = "" then collect acc "" (i + 1) false
        else collect (cur :: acc) "" (i + 1) false
      else
        collect acc (cur ^ String.make 1 c) (i + 1) in_quote
  in collect [] "" 0 false

let parse_cn_out cmd =
  let tokens = tokenize cmd in
  match tokens with
  | "cn" :: "out" :: "do" :: "reply" :: rest ->
      let msg = match extract_flag "--message" rest with
        | Some m -> m
        | None -> failwith "reply requires --message"
      in Do (Reply {message = msg})
  | "cn" :: "out" :: "do" :: "send" :: rest ->
      let to_ = match extract_flag "--to" rest with
        | Some t -> t
        | None -> failwith "send requires --to"
      in
      let message = match extract_flag "--message" rest with
        | Some m -> m
        | None -> failwith "send requires --message"
      in
      let body = extract_flag "--body" rest in
      Do (Send {to_; message; body})
  | "cn" :: "out" :: "do" :: "noop" :: rest ->
      let reason = match extract_flag "--reason" rest with
        | Some r -> r
        | None -> failwith "noop requires --reason"
      in Do (Noop {reason})
  | "cn" :: "out" :: "do" :: "ack" :: rest ->
      let reason = match extract_flag "--reason" rest with
        | Some r -> r
        | None -> failwith "ack requires --reason"
      in Do (Ack {reason})
  | "cn" :: "out" :: "do" :: "surface" :: rest ->
      let desc = match extract_flag "--desc" rest with
        | Some d -> d
        | None -> failwith "surface requires --desc"
      in Do (Surface {desc})
  | "cn" :: "out" :: "do" :: "commit" :: rest ->
      let artifact = match extract_flag "--artifact" rest with
        | Some a -> a
        | None -> failwith "commit requires --artifact"
      in Do (Commit {artifact})
  | "cn" :: "out" :: "defer" :: rest ->
      let reason = match extract_flag "--reason" rest with
        | Some r -> r
        | None -> failwith "defer requires --reason"
      in Defer {reason}
  | "cn" :: "out" :: "delegate" :: rest ->
      let to_ = match extract_flag "--to" rest with
        | Some t -> t
        | None -> failwith "delegate requires --to"
      in Delegate {to_}
  | "cn" :: "out" :: "delete" :: rest ->
      let reason = match extract_flag "--reason" rest with
        | Some r -> r
        | None -> failwith "delete requires --reason"
      in Delete {reason}
  | _ -> failwith ("Unknown cn out command: " ^ cmd)

(* === Type representations === *)

let type_op = "type op = Reply of {message: string} | Send of {to_: string; message: string; body: string option} | Noop of {reason: string} | Ack of {reason: string} | Surface of {desc: string} | Commit of {artifact: string}"

let type_gtd = "type gtd = Do of op | Defer of {reason: string} | Delegate of {to_: string} | Delete of {reason: string}"

(* === Auto notification === *)

let auto_notify = true
