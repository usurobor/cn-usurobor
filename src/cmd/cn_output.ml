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

(** XML pseudo-tool prefixes the LLM sometimes hallucinates.
    Shared between is_control_plane_like (whole-body start check) and
    strip_xml_pseudo_tools (mid-body block removal) so a new tag
    added here protects both paths. *)
let xml_prefixes = [
  "<observe>"; "<fs_read>"; "<fs_list>"; "<fs_glob>";
  "<git_status>"; "<git_diff>"; "<git_log>"; "<git_grep>";
  "<fs_write>"; "<fs_patch>"; "<git_branch>"; "<git_commit>";
  "<exec>"; "<tool_call>"; "<tool_calls>"; "<function_call>";
  "<function_calls>"; "<tool_result>"; "<tool_results>";
  "<invoke>"; "<thinking>"; "<cn:ops>";
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
  else if List.exists (fun prefix -> starts_with ~prefix trimmed) xml_prefixes then
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

(** Strip XML pseudo-tool blocks from mid-body text.
    Removes lines starting with an xml_prefix and any continuation lines
    up to and including the closing tag.  Also removes inline same-line
    XML spans (e.g. "Hello <cn:ops>…</cn:ops> world" → "Hello  world").
    Analogous to strip_embedded_frontmatter but for XML pseudo-tool
    hallucinations.

    Returns None if stripping empties the body entirely. *)
let strip_xml_pseudo_tools s =
  let lines = String.split_on_char '\n' s in
  let is_xml_open line =
    let t = String.trim line in
    List.exists (fun prefix -> starts_with ~prefix t) xml_prefixes
  in
  let has_close line =
    let t = String.trim line in
    (* closing tag present: </…> — scan for </ at any position *)
    let len = String.length t in
    let rec scan i =
      if i + 1 >= len then false
      else if t.[i] = '<' && t.[i + 1] = '/' then true
      else scan (i + 1)
    in
    scan 0
  in
  (* Remove inline XML spans: find <prefix> ... </...> within a line *)
  let strip_inline line =
    let find_prefix_at line pos =
      List.find_opt (fun prefix ->
        let plen = String.length prefix in
        pos + plen <= String.length line
        && String.sub line pos plen = prefix
      ) xml_prefixes
    in
    let find_close_from line pos =
      (* Find next </...> starting from pos *)
      let len = String.length line in
      let rec scan i =
        if i + 1 >= len then None
        else if line.[i] = '<' && line.[i + 1] = '/' then
          (* Find the matching > *)
          let rec find_gt j =
            if j >= len then None
            else if line.[j] = '>' then Some (j + 1)
            else find_gt (j + 1)
          in
          find_gt (i + 2)
        else scan (i + 1)
      in
      scan pos
    in
    let len = String.length line in
    let buf = Buffer.create len in
    let rec scan i =
      if i >= len then Buffer.contents buf
      else if line.[i] = '<' then
        match find_prefix_at line i with
        | Some _ ->
          (* Found an XML prefix — find matching close *)
          (match find_close_from line i with
           | Some end_pos -> scan end_pos  (* skip the span *)
           | None ->
             (* No close found — strip from here to end of line *)
             Buffer.contents buf)
        | None ->
          Buffer.add_char buf line.[i];
          scan (i + 1)
      else begin
        Buffer.add_char buf line.[i];
        scan (i + 1)
      end
    in
    scan 0
  in
  (* Pass 1: block-level stripping *)
  let rec walk acc in_block = function
    | [] -> List.rev acc
    | line :: rest ->
      if in_block then
        (* Inside an XML block — skip until closing tag *)
        if has_close line then walk acc false rest
        else walk acc true rest
      else if is_xml_open line then
        (* Opening line — skip it; check if self-closing *)
        if has_close line then walk acc false rest
        else walk acc true rest
      else
        walk (line :: acc) false rest
  in
  let after_blocks = walk [] false lines in
  (* Pass 2: inline stripping on surviving lines *)
  let after_inline = List.map strip_inline after_blocks in
  let filtered = after_inline |> String.concat "\n" |> String.trim in
  if filtered = "" then None else Some filtered

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
  (* Sanitize candidates: strip embedded frontmatter blocks and XML
     pseudo-tool blocks.  Applied uniformly to body AND reply payloads
     so mid-body control-plane patterns are caught regardless of which
     candidate source they appear in.  is_control_plane_like (applied
     later) only checks the start of the string — these strippers
     handle mid-string and multi-line patterns. *)
  let sanitize s =
    let s = match strip_embedded_frontmatter s with Some v -> v | None -> "" in
    if s = "" then None
    else strip_xml_pseudo_tools s
  in
  let sanitized_body = match parsed.body with
    | Some b -> sanitize b
    | None -> None
  in
  let sanitized_reply = match resolved_reply with
    | Some r -> sanitize r
    | None -> None
  in
  let sanitized_raw_reply = match raw_reply with
    | Some r when raw_reply <> resolved_reply -> sanitize r
    | _ -> None
  in
  let real_candidates =
    (match sanitized_body with Some b -> [b] | None -> [])
    @ (match sanitized_reply with Some msg -> [msg] | None -> [])
    @ (match sanitized_raw_reply with Some msg -> [msg] | None -> [])
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
