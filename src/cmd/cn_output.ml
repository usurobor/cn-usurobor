(** cn_output.ml — Output Plane Separation (v3.6.0)

    Owns the boundary between control plane and presentation plane.
    Parses state/output.md once into a structured form, then provides
    sink-specific renderers that guarantee human-facing sinks never
    receive raw ops/frontmatter/pseudo-tool syntax.

    Pure module — no I/O. *)

open Cn_lib

(* === Types === *)

type sink =
  | AuditFile
  | HumanSurface of [ `Telegram | `Discord | `Generic ]
  | ConversationStore
  | PeerOutbox

type render_reason =
  | Control_plane_leak
  | Raw_frontmatter
  | Xml_tool_syntax
  | No_presentation_payload

type render_result =
  | Renderable of string
  | Fallback of string * render_reason  (** fallback text + reason first candidate was blocked *)
  | Skipped
  | Invalid of render_reason

type parsed_output = {
  id : string option;
  body : string option;
  coordination_ops : agent_op list;       (** resolved ops (body consumed into Reply/Send) *)
  raw_coordination_ops : agent_op list;   (** unresolved ops (original frontmatter payloads) *)
  typed_ops : Cn_shell.typed_op list;
  ops_receipts : Cn_shell.receipt list;
  ops_version : string option;
  raw_output : string;
  has_misplaced_ops : bool;               (** body contains ops-like syntax that should be in frontmatter *)
}

(* === Reason codes === *)

let string_of_render_reason = function
  | Control_plane_leak -> "control_plane_leak"
  | Raw_frontmatter -> "raw_frontmatter"
  | Xml_tool_syntax -> "xml_tool_syntax"
  | No_presentation_payload -> "no_presentation_payload"

(* === Control-plane leak detection === *)

(** Frontmatter key prefixes that indicate control-plane content.
    Shared between is_control_plane_like (whole-body check) and
    strip_embedded_frontmatter (mid-body block check) so a new key
    added here protects both paths. *)
let control_key_prefixes = [
  "id:"; "ops:"; "ops_version:";
  "ack:"; "done:"; "fail:"; "reply:"; "send:";
  "delegate:"; "defer:"; "delete:"; "surface:"; "mca:";
]

(** Detect whether a candidate presentation string contains control-plane
    syntax that must not reach a human-facing sink.

    Returns Some reason if blocked, None if safe.

    Heuristic: exact/anchored patterns only to avoid over-blocking
    normal prose that happens to mention "ops" or use angle brackets. *)
let is_control_plane_like s =
  let trimmed = String.trim s in
  (* Empty / blank *)
  if trimmed = "" then None
  (* Raw frontmatter fences at the start *)
  else if starts_with ~prefix:"---\n" trimmed
       || trimmed = "---" then
    Some Raw_frontmatter
  (* Control-plane key prefixes (ops:, id:, ack:, etc.) *)
  else if List.exists (fun prefix -> starts_with ~prefix trimmed) control_key_prefixes then
    Some Control_plane_leak
  (* XML pseudo-tool wrappers the LLM sometimes hallucinates *)
  else
    let xml_prefixes = [
      "<observe>"; "<fs_read>"; "<fs_list>"; "<fs_glob>";
      "<git_status>"; "<git_diff>"; "<git_log>"; "<git_grep>";
      "<fs_write>"; "<fs_patch>"; "<git_branch>"; "<git_commit>";
      "<exec>"; "<tool_call>"; "<function_call>";
    ] in
    if List.exists (fun prefix -> starts_with ~prefix trimmed) xml_prefixes then
      Some Xml_tool_syntax
    else
      None

(* === Parsing === *)

(** Parse output content into a structured parsed_output.
    Extracts frontmatter, body, coordination ops, typed ops, and receipts
    in a single pass over the raw output string. *)
let parse_output raw_output =
  let fm = parse_frontmatter raw_output in
  let id = fm |> List.find_map (fun (k, v) ->
    if k = "id" then Some v else None) in
  let body = extract_body raw_output in
  let raw_coordination_ops = extract_ops fm in
  let coordination_ops =
    List.map (resolve_payload body) raw_coordination_ops in
  let ops_version = fm |> List.find_map (fun (k, v) ->
    if k = "ops_version" then Some v else None) in
  let ops_raw = fm |> List.find_map (fun (k, v) ->
    if k = "ops" then Some v else None) in
  let typed_ops, ops_receipts = match ops_raw with
    | None -> ([], [])
    | Some raw_value -> Cn_shell.parse_ops_manifest raw_value
  in
  (* Detect coordination ops or typed ops leaked into body text *)
  let has_misplaced_ops = match body with
    | Some b ->
       let op_prefixes = [
         "send: "; "reply: "; "done: "; "ack: "; "fail: ";
         "delegate: "; "defer: "; "delete: "; "surface: "; "ops: ["
       ] in
       let is_op_line line =
         let trimmed = String.trim line in
         List.exists (fun prefix ->
           String.length trimmed >= String.length prefix
           && String.sub trimmed 0 (String.length prefix) = prefix
         ) op_prefixes
       in
       let lines = String.split_on_char '\n' b in
       let leaked = List.filter is_op_line lines in
       if leaked <> [] then begin
         Cn_trace.gemit ~component:"output" ~layer:Mind
           ~event:"output.ops_in_body" ~severity:Warn ~status:Degraded
           ~reason_code:"misplaced_ops"
           ~reason:(Printf.sprintf "Found %d op-like line(s) in body text instead of frontmatter"
             (List.length leaked))
           ~details:[
             "count", Cn_json.Int (List.length leaked);
             "first_line", Cn_json.String (List.hd leaked |> String.trim);
           ] ();
         true
       end else
         false
    | None -> false
  in
  { id; body; coordination_ops; raw_coordination_ops;
    typed_ops; ops_receipts; ops_version; raw_output; has_misplaced_ops }

(* === Rendering === *)

(** Strip embedded frontmatter blocks (--- ... ---) from a body string.
    These appear when the LLM places control-plane syntax mid-body rather
    than at the document top.  Surrounding prose is preserved.

    Only blocks containing at least one control-plane key (id:, ops:, etc.)
    are stripped.  A bare --- used as a markdown horizontal rule is kept. *)
let strip_embedded_frontmatter s =
  let lines = String.split_on_char '\n' s in
  let is_control_line line =
    let t = String.trim line in
    List.exists (fun pfx -> starts_with ~prefix:pfx t) control_key_prefixes
  in
  let rec walk acc inside block_acc = function
    | [] ->
      (* Unclosed block: flush buffered lines back as prose *)
      let acc = if inside then
        List.rev_append ("---" :: block_acc) acc
      else acc in
      List.rev acc
    | "---" :: rest when not inside ->
      walk acc true [] rest
    | "---" :: rest when inside ->
      (* Block closed — strip only if it has control-plane content *)
      if List.exists is_control_line block_acc then
        walk acc false [] rest
      else
        (* Not a control block — restore the --- delimiters and content
           in original order onto acc (which is reversed). *)
        let acc = "---" :: List.rev_append block_acc ("---" :: acc) in
        walk acc false [] rest
    | line :: rest when inside ->
      walk acc true (line :: block_acc) rest
    | line :: rest ->
      walk (line :: acc) false block_acc rest
  in
  let cleaned = walk [] false [] lines |> String.concat "\n" |> String.trim in
  if cleaned = "" then None else Some cleaned

(** Find the first Reply payload from coordination ops. *)
let first_reply_payload ops =
  ops |> List.find_map (fun (op : agent_op) ->
    match op with Reply (_, msg) -> Some msg | _ -> None)

(** Resolve the best presentation candidate for human-facing sinks.
    Precedence: body -> first Reply payload -> "(acknowledged)" fallback.

    Each candidate is checked for control-plane leaks. If the chosen
    candidate is blocked, falls through to the next. When real candidates
    existed but were all blocked, returns Fallback with the first block
    reason so the caller can emit a distinct trace event. *)
let render_human_facing parsed =
  (* Candidates: body, then resolved reply, then raw (pre-consumption) reply.
     The raw reply matters when body was control-plane text that consumed
     into the reply via resolve_payload — the original notification is
     still a valid presentation candidate. Dedup to avoid double-checking. *)
  let resolved_reply = first_reply_payload parsed.coordination_ops in
  let raw_reply = first_reply_payload parsed.raw_coordination_ops in
  (* Strip any embedded frontmatter blocks from the body before
     considering it as a human-facing candidate. This catches the
     mid-body ops pattern that is_control_plane_like misses because
     the body starts with normal prose. *)
  let sanitized_body = match parsed.body with
    | Some b -> strip_embedded_frontmatter b
    | None -> None
  in
  let real_candidates =
    (match sanitized_body with Some b -> [b] | None -> [])
    @ (match resolved_reply with Some msg -> [msg] | None -> [])
    @ (match raw_reply with
       | Some msg when raw_reply <> resolved_reply -> [msg]
       | _ -> [])
  in
  let rec try_candidates ~first_block = function
    | [] ->
      (* All real candidates exhausted — use "(acknowledged)" *)
      (match first_block with
       | Some reason -> Fallback ("(acknowledged)", reason)
       | None -> Renderable "(acknowledged)")
    | candidate :: rest ->
        match is_control_plane_like candidate with
        | Some reason ->
          let first_block = match first_block with
            | None -> Some reason | already -> already in
          try_candidates ~first_block rest
        | None -> Renderable candidate
  in
  try_candidates ~first_block:None real_candidates

(** Render output for a specific sink.

    | Sink              | Rule                                           |
    |-------------------|------------------------------------------------|
    | AuditFile         | Always raw_output unchanged                    |
    | HumanSurface _    | body -> Reply -> "(acknowledged)", leak-checked |
    | ConversationStore | Same as HumanSurface                           |
    | PeerOutbox        | Skipped (caller renders Send ops directly)     | *)
let render_for_sink sink parsed =
  match sink with
  | AuditFile -> Renderable parsed.raw_output
  | HumanSurface _ | ConversationStore -> render_human_facing parsed
  | PeerOutbox -> Skipped

(* === Structured output: tool schema + parser + compiler (v3.9.0) === *)

(** The cn_respond tool definition for structured LLM output.
    Forces the model to emit body, coordination_ops, and typed_ops as
    separate typed fields instead of markdown-with-frontmatter. *)
let cn_respond_tool : Cn_llm.tool = {
  name = "cn_respond";
  description = "Emit your response with structured control-plane and presentation-plane fields.";
  input_schema = Cn_json.Object [
    "type", Cn_json.String "object";
    "properties", Cn_json.Object [
      "body", Cn_json.Object [
        "type", Cn_json.String "string";
        "description", Cn_json.String "Presentation text for the user (markdown). This is the only field that reaches human-facing sinks.";
      ];
      "coordination_ops", Cn_json.Object [
        "type", Cn_json.String "array";
        "items", Cn_json.Object [
          "type", Cn_json.String "object";
          "properties", Cn_json.Object [
            "kind", Cn_json.Object [
              "type", Cn_json.String "string";
              "enum", Cn_json.Array (List.map (fun s -> Cn_json.String s)
                ["ack"; "done"; "fail"; "reply"; "send";
                 "delegate"; "defer"; "delete"; "surface"]);
            ];
            "id", Cn_json.Object ["type", Cn_json.String "string"];
            "message", Cn_json.Object ["type", Cn_json.String "string"];
            "peer", Cn_json.Object ["type", Cn_json.String "string"];
            "reason", Cn_json.Object ["type", Cn_json.String "string"];
            "body", Cn_json.Object ["type", Cn_json.String "string"];
          ];
          "required", Cn_json.Array [Cn_json.String "kind"];
        ];
        "description", Cn_json.String "Coordination ops (reply, send, done, ack, etc.).";
      ];
      "typed_ops", Cn_json.Object [
        "type", Cn_json.String "array";
        "items", Cn_json.Object [
          "type", Cn_json.String "object";
          "properties", Cn_json.Object [
            "kind", Cn_json.Object ["type", Cn_json.String "string"];
            "op_id", Cn_json.Object ["type", Cn_json.String "string"];
            "path", Cn_json.Object ["type", Cn_json.String "string"];
            "content", Cn_json.Object ["type", Cn_json.String "string"];
            "unified_diff", Cn_json.Object ["type", Cn_json.String "string"];
            "command", Cn_json.Object ["type", Cn_json.String "string"];
            "ref", Cn_json.Object ["type", Cn_json.String "string"];
            "message", Cn_json.Object ["type", Cn_json.String "string"];
            "pattern", Cn_json.Object ["type", Cn_json.String "string"];
            "branch", Cn_json.Object ["type", Cn_json.String "string"];
            "files", Cn_json.Object [
              "type", Cn_json.String "array";
              "items", Cn_json.Object ["type", Cn_json.String "string"];
            ];
          ];
          "required", Cn_json.Array [Cn_json.String "kind"];
        ];
        "description", Cn_json.String "CN Shell typed capability ops (fs_read, fs_write, git_diff, etc.).";
      ];
    ];
    "required", Cn_json.Array [Cn_json.String "body"];
  ];
}

(** Parse a coordination op from a structured JSON object. *)
let parse_structured_coord_op (obj : Cn_json.t) : Cn_lib.agent_op option =
  match Cn_json.get_string "kind" obj with
  | None -> None
  | Some kind ->
    let get_str key = match Cn_json.get_string key obj with
      | Some s -> s | None -> "" in
    match kind with
    | "ack" -> Some (Cn_lib.Ack (get_str "id"))
    | "done" -> Some (Cn_lib.Done (get_str "id"))
    | "fail" -> Some (Cn_lib.Fail (get_str "id", get_str "reason"))
    | "reply" -> Some (Cn_lib.Reply (get_str "id", get_str "message"))
    | "send" ->
      let body_opt = Cn_json.get_string "body" obj in
      Some (Cn_lib.Send (get_str "peer", get_str "message", body_opt))
    | "delegate" -> Some (Cn_lib.Delegate (get_str "id", get_str "peer"))
    | "defer" -> Some (Cn_lib.Defer (get_str "id", Cn_json.get_string "reason" obj))
    | "delete" -> Some (Cn_lib.Delete (get_str "id"))
    | "surface" -> Some (Cn_lib.Surface (get_str "message"))
    | _ -> None

(** Parse a structured tool_use response into parsed_output.
    The input is the JSON object from cn_respond tool_use block.
    has_misplaced_ops is always false — ops cannot be misplaced
    when using structured output. *)
let parse_structured ~trigger_id (input : Cn_json.t) =
  let body = Cn_json.get_string "body" input in

  (* Parse coordination ops *)
  let coord_ops = match Cn_json.get_list "coordination_ops" input with
    | Some ops -> List.filter_map parse_structured_coord_op ops
    | None -> []
  in

  (* Parse typed ops via existing manifest validator *)
  let typed_ops_raw = match Cn_json.get_list "typed_ops" input with
    | Some ops -> ops
    | None -> []
  in
  let typed_ops, ops_receipts =
    if typed_ops_raw = [] then ([], [])
    else
      (* Serialize to JSON array string and delegate to parse_ops_manifest
         for full validation, dedup, auto-assign, denial receipts *)
      let json_str = "[" ^
        (typed_ops_raw |> List.map Cn_json.to_string |> String.concat ",")
        ^ "]" in
      Cn_shell.parse_ops_manifest json_str
  in

  (* Compile raw_output for audit *)
  let raw_output = compile_output_md ~trigger_id ~body ~coord_ops ~typed_ops_raw in

  {
    id = Some trigger_id;
    body;
    coordination_ops = coord_ops;
    raw_coordination_ops = coord_ops;
    typed_ops;
    ops_receipts;
    ops_version = Some "3.9";
    raw_output;
    has_misplaced_ops = false;
  }

(** Compile a structured output into markdown for audit.
    Produces the canonical state/output.md format from structured fields. *)
and compile_output_md ~trigger_id ~body ~coord_ops ~typed_ops_raw =
  let buf = Buffer.create 1024 in
  Buffer.add_string buf "---\n";
  Buffer.add_string buf (Printf.sprintf "id: %s\n" trigger_id);
  if typed_ops_raw <> [] then begin
    Buffer.add_string buf "ops: [";
    Buffer.add_string buf
      (typed_ops_raw |> List.map Cn_json.to_string |> String.concat ",");
    Buffer.add_string buf "]\n"
  end;
  List.iter (fun (op : Cn_lib.agent_op) ->
    let line = match op with
      | Cn_lib.Ack id -> "ack: " ^ id
      | Cn_lib.Done id -> "done: " ^ id
      | Cn_lib.Fail (id, reason) -> "fail: " ^ id ^ "|" ^ reason
      | Cn_lib.Reply (id, msg) -> "reply: " ^ id ^ "|" ^ msg
      | Cn_lib.Send (peer, msg, _) -> "send: " ^ peer ^ "|" ^ msg
      | Cn_lib.Delegate (id, peer) -> "delegate: " ^ id ^ "|" ^ peer
      | Cn_lib.Defer (id, None) -> "defer: " ^ id
      | Cn_lib.Defer (id, Some until) -> "defer: " ^ id ^ "|" ^ until
      | Cn_lib.Delete id -> "delete: " ^ id
      | Cn_lib.Surface desc -> "surface: " ^ desc
    in
    Buffer.add_string buf line;
    Buffer.add_char buf '\n'
  ) coord_ops;
  Buffer.add_string buf "ops_version: 3.9\n";
  Buffer.add_string buf "---\n";
  (match body with
   | Some b -> Buffer.add_string buf b
   | None -> ());
  Buffer.contents buf
